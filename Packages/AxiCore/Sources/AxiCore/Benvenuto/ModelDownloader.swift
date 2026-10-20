import CryptoKit
import Foundation

public struct ModelDownloadProgress: Sendable, Equatable {
    public var receivedBytes: Int64
    public var totalBytes: Int64

    public init(receivedBytes: Int64, totalBytes: Int64) {
        self.receivedBytes = receivedBytes
        self.totalBytes = totalBytes
    }
}

public enum ModelDownloadError: Error, Sendable, Equatable {
    case catalog(String)
    case http(Int)
    case integrity(file: String)
    case io(String)
}

/// A file of the model repository, with the size and the hash that Hugging Face publishes for it.
struct ModelFile: Sendable, Equatable {
    /// SHA-256 for the files stored with Git LFS, the Git blob hash (SHA-1) for the others.
    enum Digest: Sendable, Equatable {
        case sha256(String)
        case gitBlob(String)
    }

    let name: String
    let size: Int64
    let digest: Digest
}

/// Downloads a model repository from Hugging Face into a folder, resuming partial files
/// and checking every file against the hash that Hugging Face publishes for it.
public actor ModelDownloader {
    private struct Catalog: Decodable {
        struct Sibling: Decodable {
            struct LFS: Decodable {
                let sha256: String
                let size: Int64
            }
            let rfilename: String
            let size: Int64?
            let blobId: String?
            let lfs: LFS?
        }
        let siblings: [Sibling]
    }

    public let repository: String
    public let destination: URL
    private let session: URLSession

    public init(repository: String, destination: URL, session: URLSession = .shared) {
        self.repository = repository
        self.destination = destination
        self.session = session
    }

    /// Downloads every file of the repository that the model needs. Finished files are kept and skipped.
    public func download(
        progress: @escaping @Sendable (ModelDownloadProgress) -> Void
    ) async throws {
        let files = try await listFiles()
        let total = files.reduce(Int64(0)) { $0 + $1.size }
        var received: Int64 = 0
        progress(ModelDownloadProgress(receivedBytes: 0, totalBytes: total))

        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        for file in files {
            let finalURL = destination.appending(path: file.name)
            if try isComplete(finalURL, file: file) {
                received += file.size
                progress(ModelDownloadProgress(receivedBytes: received, totalBytes: total))
                continue
            }
            let base = received
            try await downloadFile(file, to: finalURL) { fileBytes in
                progress(ModelDownloadProgress(receivedBytes: base + fileBytes, totalBytes: total))
            }
            received += file.size
        }
    }

    // MARK: Catalog

    private func listFiles() async throws -> [ModelFile] {
        let url = URL(string: "https://huggingface.co/api/models/\(repository)?blobs=true")!
        let (data, response) = try await session.data(from: url)
        try Self.check(response)
        return try Self.files(listing: data)
    }

    /// Reads the files the model needs, each with its size and hash, from the repository listing.
    static func files(listing data: Data) throws -> [ModelFile] {
        let catalog: Catalog
        do {
            catalog = try JSONDecoder().decode(Catalog.self, from: data)
        } catch {
            throw ModelDownloadError.catalog("unreadable repository listing")
        }
        let wanted = Set(wantedFiles(catalog.siblings.map(\.rfilename)))
        let files = try catalog.siblings.filter { wanted.contains($0.rfilename) }.map(modelFile)
        if files.isEmpty { throw ModelDownloadError.catalog("empty repository listing") }
        return files
    }

    /// A file without a size or without a hash cannot be verified, so it is not accepted.
    private static func modelFile(_ sibling: Catalog.Sibling) throws -> ModelFile {
        let name = sibling.rfilename
        if let lfs = sibling.lfs {
            guard isHash(lfs.sha256, length: 64) else {
                throw ModelDownloadError.catalog("unreadable checksum for \(name)")
            }
            return ModelFile(name: name, size: lfs.size, digest: .sha256(lfs.sha256.lowercased()))
        }
        guard let size = sibling.size, let blob = sibling.blobId else {
            throw ModelDownloadError.catalog("no size or checksum for \(name)")
        }
        guard isHash(blob, length: 40) else {
            throw ModelDownloadError.catalog("unreadable checksum for \(name)")
        }
        return ModelFile(name: name, size: size, digest: .gitBlob(blob.lowercased()))
    }

    private static func isHash(_ text: String, length: Int) -> Bool {
        text.count == length && text.allSatisfy(\.isHexDigit)
    }

    /// Keeps the files the model loads: drops hidden files and Markdown (model cards, READMEs).
    /// The text path is chosen at load time (`TextEmbedder` skips the vision and audio towers),
    /// because the MLX checkpoint stores all tensors in one `model.safetensors` file.
    static func wantedFiles(_ names: [String]) -> [String] {
        names.filter { name in
            !name.hasPrefix(".") && !name.lowercased().hasSuffix(".md")
        }
    }

    private func resolveURL(_ name: String) -> URL {
        URL(string: "https://huggingface.co/\(repository)/resolve/main/\(name)")!
    }

    // MARK: Files

    /// A file is complete when it is on disk with the published size and hash.
    private func isComplete(_ url: URL, file: ModelFile) throws -> Bool {
        guard FileManager.default.fileExists(atPath: url.path), Self.fileSize(url) == file.size else {
            return false
        }
        return try Self.matches(url, file)
    }

    /// Whether the content of the file at `url` is the one Hugging Face publishes for `file`.
    static func matches(_ url: URL, _ file: ModelFile) throws -> Bool {
        switch file.digest {
        case .sha256(let expected):
            return try sha256(of: url) == expected
        case .gitBlob(let expected):
            return try gitBlobSHA1(of: url) == expected
        }
    }

    private func downloadFile(
        _ file: ModelFile, to finalURL: URL, progress: @Sendable (Int64) -> Void
    ) async throws {
        let partURL = finalURL.appendingPathExtension("part")
        try FileManager.default.createDirectory(
            at: finalURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        var offset = Self.fileSize(partURL)
        if offset > file.size { offset = 0 }
        var request = URLRequest(url: resolveURL(file.name))
        if offset > 0 { request.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range") }

        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ModelDownloadError.io("no answer for \(file.name)")
        }
        if http.statusCode == 416 {
            // The partial file already has the whole content: the integrity check decides.
            offset = file.size
        } else {
            guard (200..<300).contains(http.statusCode) else { throw ModelDownloadError.http(http.statusCode) }
            if http.statusCode == 200 { offset = 0 }   // server ignored Range: start again
            try await Self.write(bytes, to: partURL, startingAt: offset, progress: { written in
                progress(offset + written)
            })
        }

        // A short file was interrupted: it is kept, so that the next attempt resumes it.
        if Self.fileSize(partURL) < file.size {
            throw ModelDownloadError.io("incomplete \(file.name)")
        }
        if try !Self.matches(partURL, file) {
            try? FileManager.default.removeItem(at: partURL)
            throw ModelDownloadError.integrity(file: file.name)
        }
        try? FileManager.default.removeItem(at: finalURL)
        try FileManager.default.moveItem(at: partURL, to: finalURL)
    }

    private static func write(
        _ bytes: URLSession.AsyncBytes, to url: URL, startingAt offset: Int64,
        progress: (Int64) -> Void
    ) async throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.truncate(atOffset: UInt64(offset))
        try handle.seek(toOffset: UInt64(offset))

        var buffer = Data()
        var written: Int64 = 0
        for try await byte in bytes {
            buffer.append(byte)
            if buffer.count >= 1 << 16 {
                try handle.write(contentsOf: buffer)
                written += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                progress(written)
            }
        }
        if !buffer.isEmpty {
            try handle.write(contentsOf: buffer)
            written += Int64(buffer.count)
            progress(written)
        }
    }

    private static func sha256(of url: URL) throws -> String {
        var hasher = SHA256()
        try forEachChunk(of: url) { hasher.update(data: $0) }
        return hex(hasher.finalize())
    }

    /// The hash Git gives a blob: SHA-1 over the header `blob <size>` and a NUL byte, then the content.
    private static func gitBlobSHA1(of url: URL) throws -> String {
        var hasher = Insecure.SHA1()
        hasher.update(data: Data("blob \(fileSize(url))\0".utf8))
        try forEachChunk(of: url) { hasher.update(data: $0) }
        return hex(hasher.finalize())
    }

    private static func forEachChunk(of url: URL, _ body: (Data) -> Void) throws {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        while let chunk = try handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            body(chunk)
        }
    }

    private static func hex<Bytes: Sequence<UInt8>>(_ bytes: Bytes) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func fileSize(_ url: URL) -> Int64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes?[.size] as? NSNumber)?.int64Value ?? 0
    }

    private static func check(_ response: URLResponse) throws {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ModelDownloadError.http(http.statusCode)
        }
    }
}
