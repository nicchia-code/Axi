import CryptoKit
import Foundation

/// Content hashes of documents: what finds a duplicate in the vault.
enum Fingerprint {
    /// SHA-256 of a file, read in chunks.
    static func sha256(fileAt url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hex(hasher.finalize())
    }

    static func sha256(_ data: Data) -> String {
        hex(SHA256.hash(data: data))
    }

    /// An email: sender, receipt day, subject and body, normalized. The receipt day is the absolute
    /// day (see `day(of:in:)`); without it the hash is of sender, subject and body only, so the same
    /// message always gives the same hash.
    static func email(sender: String, receivedDay: String?, subject: String, body: String) -> String {
        let fields = [sender] + (receivedDay.map { [$0] } ?? []) + [subject, body]
        return sha256(Data(fields.map(normalized).joined(separator: "\n").utf8))
    }

    /// The day `yyyy-MM-dd` of an instant in the given time zone.
    static func day(of date: Date, in timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// A web page archived without its PDF: address and visible text, normalized.
    static func webPage(address: URL, visibleText: String) -> String {
        sha256(Data([address.absoluteString, visibleText].map(normalized).joined(separator: "\n").utf8))
    }

    /// Lowercased, with single spaces between words.
    static func normalized(_ text: String) -> String {
        text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static func hex<Digest: Sequence>(_ digest: Digest) -> String where Digest.Element == UInt8 {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}

/// Decides whether a PDF of a web page is the page the user was reading.
enum WebPageMatch {
    /// Share of the visible words that must be found in the PDF text.
    static let threshold = 0.8

    /// True when at least `threshold` of the visible words appear in the PDF text.
    /// False when the visible text has no words: nothing to compare.
    static func matches(visibleText: String, pdfText: String) -> Bool {
        let visible = words(in: visibleText)
        guard !visible.isEmpty else { return false }
        let found = Set(words(in: pdfText))
        let matching = visible.filter { found.contains($0) }.count
        return Double(matching) / Double(visible.count) >= threshold
    }

    /// Lowercased letters and digits, split at every other character.
    static func words(in text: String) -> [String] {
        text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    }
}
