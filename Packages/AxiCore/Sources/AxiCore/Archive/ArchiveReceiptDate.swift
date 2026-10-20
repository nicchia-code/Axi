import AxiScreen
import Foundation

/// The receipt date of an email shown by Outlook: asked to OMP in a request of its own.
enum ReceiptDate {
    /// How long OMP may take to answer before the email is archived with its receipt date unknown.
    static let timeout: Duration = .seconds(30)

    /// The prompt: the text Outlook shows, with the moment and the time zone of the reading.
    static func prompt(displayed: String, moment: ReadingMoment) -> String {
        """
        You read the date when an email was received, as Outlook shows it on screen.
        Answer with one JSON object and nothing else, with this key:
        - "receivedAt": the moment the email was received, as ISO 8601 with its UTC offset, for example \
        "2025-10-09T14:30:00+02:00". Use null when the text does not give a time of day, or when it cannot be read as a date.
        Relative texts such as "today" or "yesterday at 14:30" refer to the moment of the reading, \
        \(isoText(moment.date, in: moment.timeZone)), in the time zone \(moment.timeZone.identifier).

        Text shown by Outlook: \(displayed)
        """
    }

    /// The instant of a valid answer: `{"receivedAt": "<ISO 8601 with offset>"}`. Anything else gives nil.
    static func parse(_ reply: String) -> Date? {
        guard let start = reply.firstIndex(of: "{"), let end = reply.lastIndex(of: "}"), start <= end,
              let data = String(reply[start...end]).data(using: .utf8),
              let answer = try? JSONDecoder().decode(Answer.self, from: data),
              let text = answer.receivedAt?.trimmingCharacters(in: .whitespacesAndNewlines),
              hasOffset(text)
        else { return nil }
        return formatter(fractional: false).date(from: text) ?? formatter(fractional: true).date(from: text)
    }

    private struct Answer: Decodable {
        var receivedAt: String?
    }

    /// True when the text ends with `Z` or with a `±hh:mm` offset.
    private static func hasOffset(_ text: String) -> Bool {
        text.hasSuffix("Z") || text.range(of: #"[+-]\d{2}:\d{2}$"#, options: .regularExpression) != nil
    }

    private static func formatter(fractional: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = fractional
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter
    }

    /// `yyyy-MM-dd'T'HH:mm:ssxxx` in the given time zone.
    private static func isoText(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
        return formatter.string(from: date)
    }
}
