import Foundation

/// A message read from an `.eml` file, with what the vault needs.
struct ParsedEmail: Equatable, Sendable {
    var sender: String
    var recipients: [String]
    var subject: String
    /// The raw `Date` header, as the hash of the email uses it.
    var sentAt: String?
    var body: String
    var attachmentNames: [String]
}

/// Reads RFC 5322 messages with MIME parts. Works on the bytes: the file is read as ISO Latin-1,
/// which maps every byte to one character, and each part is decoded to text at the end.
enum EmlParser {
    private typealias Headers = [String: String]

    private struct Collected {
        var plain: [String] = []
        var html: [String] = []
        var attachments: [String] = []
    }

    static func parse(_ data: Data) -> ParsedEmail? {
        guard let raw = String(data: data, encoding: .isoLatin1) else { return nil }
        let text = raw.replacingOccurrences(of: "\r\n", with: "\n")
        let (headers, body) = splitHeaders(text)
        guard !headers.isEmpty else { return nil }

        var collected = Collected()
        walk(headers: headers, body: body, into: &collected, depth: 0)

        let plain = collected.plain.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let bodyText: String
        if !plain.isEmpty {
            bodyText = plain.joined(separator: "\n\n")
        } else if let html = collected.html.first(where: { !$0.isEmpty }) {
            bodyText = plainText(fromHTML: html)
        } else {
            bodyText = ""
        }

        return ParsedEmail(
            sender: header("from", in: headers) ?? "",
            recipients: recipients(header("to", in: headers) ?? ""),
            subject: header("subject", in: headers) ?? "",
            sentAt: header("date", in: headers),
            body: bodyText.trimmingCharacters(in: .whitespacesAndNewlines),
            attachmentNames: collected.attachments
        )
    }

    // MARK: Structure

    private static func walk(headers: Headers, body: String, into collected: inout Collected, depth: Int) {
        guard depth < 16 else { return }
        let (mime, fields) = splitParameters(headers["content-type"] ?? "text/plain")

        if mime.hasPrefix("multipart/"), let boundary = fields["boundary"] {
            for piece in parts(of: body, boundary: boundary) {
                let (partHeaders, partBody) = splitHeaders(piece)
                walk(headers: partHeaders, body: partBody, into: &collected, depth: depth + 1)
            }
            return
        }

        let disposition = headers["content-disposition"] ?? ""
        let (dispositionType, dispositionParameters) = splitParameters(disposition)
        let name = attachmentName(dispositionParameters) ?? attachmentName(fields)
        let isInline = dispositionType == "inline"
        let isAttachment = dispositionType == "attachment" || (name != nil && !isInline && !mime.hasPrefix("text/"))

        if isAttachment {
            collected.attachments.append(name ?? "attachment")
            return
        }
        if mime == "message/rfc822" {
            let (embeddedHeaders, embeddedBody) = splitHeaders(body)
            walk(headers: embeddedHeaders, body: embeddedBody, into: &collected, depth: depth + 1)
            return
        }

        let encoding = headers["content-transfer-encoding"]?.lowercased()
        let text = decodeText(
            bytes(of: body, encoding: encoding),
            charset: fields["charset"]
        )
        switch mime {
        case "text/html": collected.html.append(text)
        case "text/plain", "": collected.plain.append(text)
        default: break
        }
    }

    /// Headers up to the first empty line, unfolded; the first occurrence of a name wins.
    private static func splitHeaders(_ text: String) -> (Headers, String) {
        var headers: Headers = [:]
        var lastName: String?
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false)[...]
        while let line = lines.first {
            lines = lines.dropFirst()
            if line.isEmpty { break }
            if let first = line.first, first == " " || first == "\t", let name = lastName {
                headers[name, default: ""] += " " + line.trimmingCharacters(in: .whitespaces)
                continue
            }
            guard let colon = line.firstIndex(of: ":") else { continue }
            let name = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            lastName = name
            if headers[name] == nil { headers[name] = value }
        }
        return (headers, lines.joined(separator: "\n"))
    }

    /// The pieces of a multipart body between its boundary lines.
    private static func parts(of body: String, boundary: String) -> [String] {
        let delimiter = "--" + boundary
        var parts: [String] = []
        var current: [Substring]?
        for line in body.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == delimiter || trimmed == delimiter + "--" {
                if let current { parts.append(current.joined(separator: "\n")) }
                if trimmed != delimiter { return parts }
                current = []
                continue
            }
            current?.append(line)
        }
        if let current { parts.append(current.joined(separator: "\n")) }
        return parts
    }

    /// The value of a header with its parameters: `text/plain; charset="utf-8"`.
    private static func splitParameters(_ value: String) -> (String, [String: String]) {
        let pieces = value.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
        let main = (pieces.first ?? "").lowercased()
        var parameters: [String: String] = [:]
        for piece in pieces.dropFirst() {
            guard let equal = piece.firstIndex(of: "=") else { continue }
            let key = piece[..<equal].trimmingCharacters(in: .whitespaces).lowercased()
            var parameterValue = piece[piece.index(after: equal)...].trimmingCharacters(in: .whitespaces)
            if parameterValue.hasPrefix("\""), parameterValue.hasSuffix("\""), parameterValue.count >= 2 {
                parameterValue = String(parameterValue.dropFirst().dropLast())
            }
            parameters[key] = parameterValue
        }
        return (main, parameters)
    }

    private static func attachmentName(_ parameters: [String: String]) -> String? {
        if let encoded = parameters["filename*"], let decoded = rfc2231(encoded) {
            return decoded
        }
        guard let name = parameters["filename"] ?? parameters["name"], !name.isEmpty else { return nil }
        return decodeWords(name)
    }

    /// `UTF-8''file%20name.pdf`.
    private static func rfc2231(_ value: String) -> String? {
        let parts = value.split(separator: "'", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        let charset = String(parts[0])
        let percentDecoded = String(parts[2]).removingPercentEncoding ?? String(parts[2])
        let bytes = octets(percentDecoded)
        return encoding(named: charset).flatMap { String(data: Data(bytes), encoding: $0) } ?? percentDecoded
    }

    private static func recipients(_ value: String) -> [String] {
        value.split(separator: ",")
            .map { decodeWords($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }
    }

    private static func header(_ name: String, in headers: Headers) -> String? {
        guard let value = headers[name], !value.isEmpty else { return nil }
        return decodeWords(value)
    }

    // MARK: Content transfer and charset

    private static func bytes(of body: String, encoding: String?) -> [UInt8] {
        switch encoding {
        case "base64":
            let clean = String(decoding: octets(body).filter { !isWhitespace($0) }, as: UTF8.self)
            return Array(Data(base64Encoded: clean, options: .ignoreUnknownCharacters) ?? Data())
        case "quoted-printable":
            return quotedPrintable(octets(body))
        default:
            return octets(body)
        }
    }

    private static func quotedPrintable(_ input: [UInt8]) -> [UInt8] {
        var output: [UInt8] = []
        var index = 0
        while index < input.count {
            let byte = input[index]
            guard byte == UInt8(ascii: "=") else {
                output.append(byte)
                index += 1
                continue
            }
            // Soft line break: `=` at the end of a line.
            if index + 1 < input.count, input[index + 1] == 10 || input[index + 1] == 13 {
                index += 2
                if input[index - 1] == 13, index < input.count, input[index] == 10 { index += 1 }
                continue
            }
            if index + 2 < input.count, let high = hexValue(input[index + 1]), let low = hexValue(input[index + 2]) {
                output.append(high << 4 | low)
                index += 3
                continue
            }
            output.append(byte)
            index += 1
        }
        return output
    }

    private static func decodeText(_ bytes: [UInt8], charset: String?) -> String {
        let data = Data(bytes)
        if let charset, let encoding = encoding(named: charset), let text = String(data: data, encoding: encoding) {
            return text
        }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
    }

    private static func encoding(named name: String) -> String.Encoding? {
        let identifier = CFStringConvertIANACharSetNameToEncoding(name as CFString)
        guard identifier != kCFStringEncodingInvalidId else { return nil }
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(identifier))
    }

    /// RFC 2047 encoded words (`=?UTF-8?B?...?=`) in a header value.
    static func decodeWords(_ value: String) -> String {
        let text = utf8IfPossible(value)
        guard text.contains("=?"), let expression = try? NSRegularExpression(pattern: #"=\?([^?]+)\?([BbQq])\?([^?]*)\?="#) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        var result = text
        for match in expression.matches(in: text, range: range).reversed() {
            guard let whole = Range(match.range, in: text),
                  let charsetRange = Range(match.range(at: 1), in: text),
                  let methodRange = Range(match.range(at: 2), in: text),
                  let payloadRange = Range(match.range(at: 3), in: text)
            else { continue }
            let charset = String(text[charsetRange]).components(separatedBy: "*")[0]
            let payload = String(text[payloadRange])
            let bytes: [UInt8]
            if text[methodRange].lowercased() == "b" {
                bytes = Array(Data(base64Encoded: payload, options: .ignoreUnknownCharacters) ?? Data())
            } else {
                bytes = quotedPrintable(octets(payload.replacingOccurrences(of: "_", with: " ")))
            }
            result.replaceSubrange(whole, with: decodeText(bytes, charset: charset))
        }
        return result
    }

    /// A header read as Latin-1 holds UTF-8 bytes when the sender did not encode them.
    private static func utf8IfPossible(_ value: String) -> String {
        let bytes = octets(value)
        guard bytes.contains(where: { $0 >= 0x80 }), let text = String(data: Data(bytes), encoding: .utf8) else {
            return value
        }
        return text
    }

    // MARK: HTML

    /// Text of an HTML body: scripts and styles dropped, block ends as line breaks, entities decoded.
    static func plainText(fromHTML html: String) -> String {
        var text = html
        let rules: [(pattern: String, replacement: String)] = [
            (#"(?is)<(script|style)[^>]*>.*?</\1>"#, ""),
            (#"(?i)<br\s*/?>|</(p|div|li|tr|h[1-6])>"#, "\n"),
            (#"<[^>]+>"#, ""),
        ]
        for rule in rules {
            text = text.replacingOccurrences(of: rule.pattern, with: rule.replacement, options: .regularExpression)
        }
        let entities = ["&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&apos;": "'"]
        for (entity, character) in entities {
            text = text.replacingOccurrences(of: entity, with: character)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Bytes

    /// One scalar per byte: the strings of this parser are Latin-1.
    private static func octets(_ text: String) -> [UInt8] {
        text.unicodeScalars.map { UInt8(truncatingIfNeeded: $0.value) }
    }

    private static func isWhitespace(_ byte: UInt8) -> Bool {
        byte == 10 || byte == 13 || byte == 32 || byte == 9
    }

    private static func hexValue(_ byte: UInt8) -> UInt8? {
        switch byte {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): byte - UInt8(ascii: "0")
        case UInt8(ascii: "A")...UInt8(ascii: "F"): byte - UInt8(ascii: "A") + 10
        case UInt8(ascii: "a")...UInt8(ascii: "f"): byte - UInt8(ascii: "a") + 10
        default: nil
        }
    }
}

/// The date of an email, as its `Date` header writes it.
enum EmailDate {
    static func parse(_ text: String) -> Date? {
        let formats = ["EEE, d MMM yyyy HH:mm:ss Z", "d MMM yyyy HH:mm:ss Z"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = format
            if let date = formatter.date(from: text.trimmingCharacters(in: .whitespaces)) { return date }
        }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        return detector.firstMatch(in: text, range: range)?.date
    }
}
