import Foundation

/// Reads the message open or selected in the new Outlook from its Accessibility tree.
/// Header labels are matched in English and Italian; the body is the largest text container.
public enum OutlookMessageReader {
    private enum Field: CaseIterable {
        case from, to, cc, subject, date, attachments
    }

    private static let labels: [Field: [String]] = [
        .from: ["From", "Da"],
        .to: ["To", "A"],
        .cc: ["Cc", "Copia"],
        .subject: ["Subject", "Oggetto"],
        .date: ["Sent", "Date", "Data"],
        .attachments: ["Attachments", "Allegati"],
    ]

    public static func read(_ window: AccessibilityNode, source: ApplicationSnapshot) -> EmailMessage? {
        let nodes = window.descendantsAndSelf
        let texts = nodes.compactMap { nonEmpty($0.shownText ?? $0.label) }

        var fields: [Field: String] = [:]
        for (index, text) in texts.enumerated() {
            for field in Field.allCases where fields[field] == nil {
                let names = labels[field] ?? []
                if let value = headerValue(text, names: names) {
                    fields[field] = value
                } else if index + 1 < texts.count, names.contains(where: { equalsIgnoringCase(text, $0) }) {
                    fields[field] = texts[index + 1]
                }
            }
        }

        guard fields[.from] != nil || fields[.subject] != nil else { return nil }

        return EmailMessage(
            sender: fields[.from],
            recipients: list(fields[.to]) + list(fields[.cc]),
            subject: fields[.subject],
            sentAt: fields[.date],
            body: body(in: nodes),
            attachmentNames: list(fields[.attachments]),
            source: source)
    }

    /// The text of the largest text container, without the header lines.
    private static func body(in nodes: [AccessibilityNode]) -> String {
        let containers = nodes.filter { $0.role == AccessibilityRole.webArea || $0.role == AccessibilityRole.textArea }
        let pieces = containers.map { container -> [String] in
            let scope = container.role == AccessibilityRole.textArea
                ? container.descendantsAndSelf
                : container.children.flatMap(\.descendantsAndSelf)
            return scope.compactMap { nonEmpty($0.shownText) }.filter(isBodyLine)
        }
        let best = pieces.max { length($0) < length($1) } ?? []
        return best.joined(separator: "\n")
    }

    private static func isBodyLine(_ text: String) -> Bool {
        !labels.values.contains { headerValue(text, names: $0) != nil }
    }

    private static func length(_ lines: [String]) -> Int {
        lines.reduce(0) { $0 + $1.count }
    }

    private static func headerValue(_ text: String, names: [String]) -> String? {
        guard let colon = text.firstIndex(of: ":") else { return nil }
        let name = text[..<colon].trimmingCharacters(in: .whitespaces)
        guard names.contains(where: { equalsIgnoringCase(name, $0) }) else { return nil }
        return nonEmpty(String(text[text.index(after: colon)...]))
    }

    private static func list(_ value: String?) -> [String] {
        guard let value else { return [] }
        return value
            .split(whereSeparator: { $0 == "," || $0 == ";" })
            .compactMap { nonEmpty(String($0)) }
    }

    private static func equalsIgnoringCase(_ a: String, _ b: String) -> Bool {
        a.caseInsensitiveCompare(b) == .orderedSame
    }
}
