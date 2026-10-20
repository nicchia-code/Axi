import Foundation

/// The metadata the AI gives for a document.
struct DocumentMetadata: Equatable, Sendable {
    var title: String
    var summary: String
    var tags: [String]
    var documentDate: Date?
    var language: String?
    /// Dates the text cites, in the order they appear, at most `MetadataPrompts.maxCitedDates`.
    var citedDates: [CitedDate]
}

/// The moment the relative dates of a document are resolved against.
enum DateReference: Equatable, Sendable {
    /// The moment an email was received.
    case receipt(Date)
    /// The moment a document that is not an email is archived. Its text may state its own date instead.
    case archiving(Date)
    /// An email whose receipt date is unknown: its relative dates have no date.
    case unknown
}

/// Prompts of the metadata request. Written in English; the answer language is the interface one.
enum MetadataPrompts {
    static let maxTags = 5
    static let maxSentences = 3
    static let maxCitedDates = 20

    static func whole(text: String, vocabulary: [String], language: String, reference: DateReference) -> String {
        """
        You read one document and describe it.
        \(instructions(vocabulary: vocabulary, language: language, reference: reference))
        - "citedDates": \(citedDatesRule(language: language)).

        Document:
        \(text)
        """
    }

    static func section(_ section: Section, language: String) -> String {
        """
        You read one part of a document (pages \(section.firstPage)-\(section.lastPage)).
        Answer with one JSON object and nothing else, with these keys:
        - "summary": at most five sentences, in the language with ISO 639-1 code "\(language)". \
        Write the dates in it in absolute form when the text gives them so; keep a relative date (today, next Friday) \
        in the words of the text.
        - "citedDates": \(citedDatesRule(language: language)). \
        A date relative to a day (today, tomorrow, next Friday, in three days, Friday) is not resolved here: its "date" is null.

        Part:
        \(section.text)
        """
    }

    static func combined(
        summaries: [String], citedDates: [CitedDate], vocabulary: [String], language: String, reference: DateReference
    ) -> String {
        """
        You read one document through the summaries of its consecutive parts, in order.
        \(instructions(vocabulary: vocabulary, language: language, reference: reference))
        - "citedDates": \(citedDatesRule(language: language)). \
        The dates of the parts are listed below: return them all, resolving each relative one by the rule above; \
        a date that cannot be resolved is null.

        Summaries of the parts:
        \(summaries.joined(separator: "\n"))

        Dates of the parts:
        \(partDates(citedDates))
        """
    }

    private static func instructions(vocabulary: [String], language: String, reference: DateReference) -> String {
        let known = vocabulary.isEmpty ? "none yet" : vocabulary.joined(separator: ", ")
        return """
        Answer with one JSON object and nothing else, with these keys:
        - "title": a short title, in the language of the document.
        - "summary": at most \(maxSentences) sentences, in the language with ISO 639-1 code "\(language)". \
        Write the dates in it in absolute form, only the ones that can be resolved.
        - "tags": between 1 and \(maxTags) short lowercase tags, in the singular, in the language with ISO 639-1 code "\(language)". \
        Reuse tags from this list when they fit: \(known).
        - "documentDate": the date the document was written, as yyyy-MM-dd, or null when the text does not say.
        - "language": the language of the document, as an ISO 639-1 code.
        \(referenceRule(reference))
        """
    }

    /// The rule for the relative dates, given the reference the request carries.
    private static func referenceRule(_ reference: DateReference) -> String {
        switch reference {
        case .receipt(let date):
            return "Relative dates (today, tomorrow, next Friday, in three days) are relative to the day the email "
                + "was received: \(isoText(date)), in the time zone of the Mac."
        case .archiving(let date):
            return "Relative dates are relative to the date of the document when its text states it (give it as "
                + "documentDate); otherwise they are relative to \(isoText(date)), the moment the document is archived, "
                + "in the time zone of the Mac."
        case .unknown:
            return "The day the email was received is unknown: a relative date has no date, so give it as null. "
                + "Absolute dates are still resolved."
        }
    }

    private static func citedDatesRule(language: String) -> String {
        """
        the events, deadlines and appointments the text talks about, in the order they appear, at most \(maxCitedDates). \
        Leave out historical references (for example "founded in 1990"). Each is an object with: \
        "date", the absolute date, as yyyy-MM-dd when the text gives no time, or as ISO 8601 with its UTC offset \
        (for example 2025-10-06T09:30:00+02:00) only when the text gives the time; \
        an ambiguous or vague expression (for example "Friday") becomes the most probable date; \
        "about", in short words, in the language with ISO 639-1 code "\(language)", what the date is about; \
        "originalText", the words of the text the date comes from, as they are written
        """
    }

    /// A moment as ISO 8601 with the offset of the Mac's time zone.
    private static func isoText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
        return formatter.string(from: date)
    }

    /// The date of a cited date as the prompt writes it: an instant with the Mac's offset, a day as yyyy-MM-dd.
    private static func dateText(_ date: AbsoluteDate?) -> String {
        switch date {
        case .instant(let moment)?:
            return isoText(moment)
        case .day(let day)?:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: day)
        case nil:
            return "null"
        }
    }

    /// The dates of the parts, as the final step gets them to return them all.
    private static func partDates(_ dates: [CitedDate]) -> String {
        guard !dates.isEmpty else { return "none" }
        return dates.map { cited in
            "- date: \(dateText(cited.date)); about: \(cited.about); original text: \(cited.originalText)"
        }.joined(separator: "\n")
    }
}

/// Reads the AI answer. An answer that does not follow the contract gives nil.
enum MetadataParser {
    private struct Answer: Decodable {
        var title: String?
        var summary: String?
        var tags: [String]?
        var documentDate: String?
        var language: String?
        var citedDates: [Lossy<CitedItem>]?
    }

    private struct SectionAnswer: Decodable {
        var summary: String?
        var citedDates: [Lossy<CitedItem>]?
    }

    /// One cited date as the AI wrote it, before it is checked.
    private struct CitedItem: Decodable {
        var date: String?
        var about: String?
        var originalText: String?
    }

    /// Decodes one element, or nil when it does not decode: one bad element does not void the others.
    private struct Lossy<Value: Decodable>: Decodable {
        let value: Value?

        init(from decoder: Decoder) throws {
            value = try? Value(from: decoder)
        }
    }

    static func parse(_ reply: String, reference: DateReference) -> DocumentMetadata? {
        guard let data = jsonObject(in: reply),
              let answer = try? JSONDecoder().decode(Answer.self, from: data)
        else { return nil }

        let title = (answer.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        var seen = Set<String>()
        var tags: [String] = []
        for raw in answer.tags ?? [] {
            let tag = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !tag.isEmpty, !seen.contains(tag) else { continue }
            seen.insert(tag)
            tags.append(tag)
            if tags.count == MetadataPrompts.maxTags { break }
        }
        guard !tags.isEmpty else { return nil }

        let summary = limitSentences(
            (answer.summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            to: MetadataPrompts.maxSentences
        )
        let language = answer.language?.trimmingCharacters(in: .whitespacesAndNewlines)

        return DocumentMetadata(
            title: title,
            summary: summary,
            tags: tags,
            documentDate: answer.documentDate.flatMap(date(_:)),
            language: language?.isEmpty == false ? language : nil,
            citedDates: citedDates(answer.citedDates, allowsUnresolved: reference == .unknown)
        )
    }

    /// The summary and the cited dates of one part of a document that is sent in sections.
    static func parseSection(_ reply: String) -> (summary: String, citedDates: [CitedDate])? {
        guard let data = jsonObject(in: reply),
              let answer = try? JSONDecoder().decode(SectionAnswer.self, from: data)
        else { return nil }
        let summary = (answer.summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summary.isEmpty else { return nil }
        return (summary, citedDates(answer.citedDates, allowsUnresolved: true))
    }

    /// The dates without duplicates, in order, up to the maximum.
    static func keep(_ dates: [CitedDate]) -> [CitedDate] {
        var kept: [CitedDate] = []
        for cited in dates where !kept.contains(cited) {
            kept.append(cited)
            if kept.count == MetadataPrompts.maxCitedDates { break }
        }
        return kept
    }

    /// The valid cited dates of an answer. One that does not check is dropped, the others stay.
    /// A null date is kept only when `allowsUnresolved`.
    private static func citedDates(_ items: [Lossy<CitedItem>]?, allowsUnresolved: Bool) -> [CitedDate] {
        var valid: [CitedDate] = []
        for lossy in items ?? [] {
            guard let item = lossy.value,
                  let about = item.about?.trimmingCharacters(in: .whitespacesAndNewlines), !about.isEmpty,
                  let original = item.originalText?.trimmingCharacters(in: .whitespacesAndNewlines), !original.isEmpty
            else { continue }

            let text = item.date?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let when: AbsoluteDate?
            if text.isEmpty {
                // Without a date only a relative date resolved later: in a part, or of an email whose receipt date is unknown.
                guard allowsUnresolved else { continue }
                when = nil
            } else {
                guard let absolute = absoluteDate(text) else { continue }
                when = absolute
            }
            valid.append(CitedDate(date: when, about: about, originalText: original))
        }
        return keep(valid)
    }

    /// An instant when the text has a time, with its offset (ISO 8601); a day when it is `yyyy-MM-dd`.
    private static func absoluteDate(_ text: String) -> AbsoluteDate? {
        if text.contains("T") {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: text).map(AbsoluteDate.instant)
        }
        return date(text).map(AbsoluteDate.day)
    }

    /// The JSON object of a reply: the text from its first `{` to its last `}`.
    private static func jsonObject(in reply: String) -> Data? {
        guard let start = reply.firstIndex(of: "{"), let end = reply.lastIndex(of: "}"), start <= end else { return nil }
        return String(reply[start...end]).data(using: .utf8)
    }

    /// The text up to its `maximum`-th sentence end (a `.`, `!` or `?` followed by a space or the end).
    static func limitSentences(_ text: String, to maximum: Int) -> String {
        var count = 0
        var end = text.endIndex
        var index = text.startIndex
        while index < text.endIndex {
            if ".!?".contains(text[index]) {
                let next = text.index(after: index)
                if next == text.endIndex || text[next].isWhitespace {
                    count += 1
                    if count == maximum {
                        end = next
                        break
                    }
                }
            }
            index = text.index(after: index)
        }
        return String(text[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A strict `yyyy-MM-dd` date in UTC; anything that does not round-trip gives nil.
    static func date(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: text), formatter.string(from: date) == text else { return nil }
        return date
    }
}

/// Asks the AI for the metadata of a document, in one prompt or by sections.
struct MetadataGenerator: Sendable {
    let assistant: any AIAssistant
    let contextWindowTokens: Int
    /// ISO 639-1 code of the interface language: summary and tags are written in it.
    let language: String

    /// The metadata, or nil when the answer does not follow the contract.
    /// Errors of the assistant are thrown.
    func generate(pages: [DocumentPage], vocabulary: [String], reference: DateReference) async throws -> DocumentMetadata? {
        switch MetadataPlanner.plan(pages: pages, contextWindowTokens: contextWindowTokens) {
        case .whole(let text):
            let answer = try await assistant.complete(
                MetadataPrompts.whole(text: text, vocabulary: vocabulary, language: language, reference: reference)
            )
            return MetadataParser.parse(answer, reference: reference)
        case .sections(let sections):
            var summaries: [String] = []
            var dates: [CitedDate] = []
            for section in sections {
                let reply = try await assistant.complete(MetadataPrompts.section(section, language: language))
                guard let part = MetadataParser.parseSection(reply) else { return nil }
                let pages = section.firstPage == section.lastPage
                    ? "Page \(section.firstPage)"
                    : "Pages \(section.firstPage)-\(section.lastPage)"
                summaries.append("\(pages): \(part.summary)")
                dates += part.citedDates
            }
            let answer = try await assistant.complete(
                MetadataPrompts.combined(
                    summaries: summaries,
                    citedDates: MetadataParser.keep(dates),
                    vocabulary: vocabulary,
                    language: language,
                    reference: reference
                )
            )
            return MetadataParser.parse(answer, reference: reference)
        }
    }
}
