import Foundation

/// Keeps whether the welcome window is completed, in the Axi data folder.
public struct BenvenutoStore: Sendable {
    private struct Record: Codable {
        var completed: Bool
    }

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// `~/Library/Application Support/Axi/benvenuto.json`
    public static var defaultFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Axi", directoryHint: .isDirectory)
            .appending(path: "benvenuto.json")
    }

    public func isCompleted() -> Bool {
        guard let data = try? Data(contentsOf: fileURL),
              let record = try? JSONDecoder().decode(Record.self, from: data) else {
            return false
        }
        return record.completed
    }

    public func markCompleted() throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(Record(completed: true))
        try data.write(to: fileURL, options: .atomic)
    }
}
