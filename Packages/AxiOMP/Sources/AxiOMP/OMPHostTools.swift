import Foundation

/// A document found by `search_vault`. Only identifiers, dates and short excerpts leave the vault.
/// `wholeText` is the full text of the document, sent once, when the app judges it fits the model's context.
public struct OMPSearchHit: Sendable, Equatable {
    public let documentID: String
    public let title: String
    public let page: Int?
    public let excerpt: String
    public let wholeText: String?
    public let archivedAt: Date
    /// The day of the document, when it has one.
    public let documentDate: OMPDate?
    /// When the email was received, when the document is an email whose receipt date is known.
    public let receivedAt: OMPDate?
    /// The dates the document's text cites, in the order of the text.
    public let citedDates: [OMPCitedDate]

    public init(
        documentID: String, title: String, page: Int? = nil, excerpt: String, wholeText: String? = nil,
        archivedAt: Date, documentDate: OMPDate? = nil, receivedAt: OMPDate? = nil, citedDates: [OMPCitedDate] = []
    ) {
        self.documentID = documentID
        self.title = title
        self.page = page
        self.excerpt = excerpt
        self.wholeText = wholeText
        self.archivedAt = archivedAt
        self.documentDate = documentDate
        self.receivedAt = receivedAt
        self.citedDates = citedDates
    }
}

/// A date in a search result: an instant keeps its UTC offset, a day has no time.
public enum OMPDate: Sendable, Equatable {
    case instant(Date)
    /// A calendar day, held as the day of this date in UTC.
    case day(Date)
}

/// A date the document's text cites, with the words it comes from.
public struct OMPCitedDate: Sendable, Equatable {
    /// Nil for a relative date whose anchor is unknown.
    public let date: OMPDate?
    public let about: String
    public let originalText: String

    public init(date: OMPDate?, about: String, originalText: String) {
        self.date = date
        self.about = about
        self.originalText = originalText
    }
}

/// One page of a document, as read by `read_document_page`.
public struct OMPDocumentPage: Sendable, Equatable {
    public let documentID: String
    public let page: Int
    public let text: String

    public init(documentID: String, page: Int, text: String) {
        self.documentID = documentID
        self.page = page
        self.text = text
    }
}

/// A document, and the page when known, that the answer uses. Sent with `cite_documents`.
public struct OMPCitation: Sendable, Equatable {
    public let documentID: String
    public let page: Int?

    public init(documentID: String, page: Int? = nil) {
        self.documentID = documentID
        self.page = page
    }
}

/// Filters of `search_vault`: values inside one group are alternatives (OR), the groups are combined (AND).
/// Dates are inclusive, by day, in the Mac's time zone: the archive date, the day of the document,
/// the day its email was received, and the dates its text cites (one of them must be in range).
public struct OMPSearchFilter: Sendable, Equatable {
    public var tags: [String]
    public var kinds: [String]
    public var origins: [String]
    public var archivedFrom: Date?
    public var archivedTo: Date?
    public var documentFrom: Date?
    public var documentTo: Date?
    public var receivedFrom: Date?
    public var receivedTo: Date?
    public var citedFrom: Date?
    public var citedTo: Date?

    public init(
        tags: [String] = [], kinds: [String] = [], origins: [String] = [],
        archivedFrom: Date? = nil, archivedTo: Date? = nil,
        documentFrom: Date? = nil, documentTo: Date? = nil,
        receivedFrom: Date? = nil, receivedTo: Date? = nil,
        citedFrom: Date? = nil, citedTo: Date? = nil
    ) {
        self.tags = tags
        self.kinds = kinds
        self.origins = origins
        self.archivedFrom = archivedFrom
        self.archivedTo = archivedTo
        self.documentFrom = documentFrom
        self.documentTo = documentTo
        self.receivedFrom = receivedFrom
        self.receivedTo = receivedTo
        self.citedFrom = citedFrom
        self.citedTo = citedTo
    }
}

/// Host tools available to the chat OMP process.
public protocol OMPChatHostTools: Sendable {
    func searchVault(query: String, limit: Int, filter: OMPSearchFilter) async throws -> [OMPSearchHit]
    func readDocumentPage(documentID: String, page: Int) async throws -> OMPDocumentPage
    /// Records the documents and pages the answer uses; only these become citations of the answer.
    func citeDocuments(_ citations: [OMPCitation]) async throws
}

/// Host tools that change the vault. Deletion only asks: the app must confirm it with the user.
public protocol OMPVaultHostTools: Sendable {
    func setDocumentTags(documentID: String, tags: [String]) async throws
    /// Returns `true` when the user confirmed and the document was deleted, `false` when the user declined.
    func requestDocumentDeletion(documentID: String) async throws -> Bool
}

/// Answers `host_tool_call` frames with the host tools and nothing else.
struct OMPHostToolDispatcher: Sendable {
    struct Output: Sendable, Equatable {
        let text: String
        let isError: Bool
    }

    private enum ArgumentError: Error {
        case invalid
    }

    let chat: any OMPChatHostTools
    let vault: any OMPVaultHostTools
    let events: OMPEventHub

    /// Tool definitions sent with `set_host_tools`.
    static let definitions: [JSONValue] = [
        definition(
            name: "search_vault",
            label: "Search vault",
            description: "Search the user's document vault, optionally narrowed by tags, document kinds, origins, archive dates, document dates, receipt dates of emails and dates cited in the text. Returns matching document identifiers, titles, pages, excerpts, archive dates, document dates, receipt dates and cited dates, so relative dates can be resolved.",
            properties: [
                "query": .object(["type": .string("string"), "description": .string("Text to search for.")]),
                "limit": .object(["type": .string("integer"), "description": .string("Maximum number of results, from 1 to 20.")]),
                "tags": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("string")]),
                    "description": .string("Only documents with one of these tags."),
                ]),
                "kinds": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("string")]),
                    "description": .string("Only documents of one of these types, such as pdf."),
                ]),
                "origins": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("string")]),
                    "description": .string("Only documents from one of these origins."),
                ]),
                "archivedFrom": .object(["type": .string("string"), "description": .string("Only documents archived on or after this day, yyyy-MM-dd.")]),
                "archivedTo": .object(["type": .string("string"), "description": .string("Only documents archived on or before this day, yyyy-MM-dd.")]),
                "documentFrom": .object(["type": .string("string"), "description": .string("Only documents dated on or after this day, yyyy-MM-dd.")]),
                "documentTo": .object(["type": .string("string"), "description": .string("Only documents dated on or before this day, yyyy-MM-dd.")]),
                "receivedFrom": .object(["type": .string("string"), "description": .string("Only emails received on or after this day, yyyy-MM-dd.")]),
                "receivedTo": .object(["type": .string("string"), "description": .string("Only emails received on or before this day, yyyy-MM-dd.")]),
                "citedFrom": .object(["type": .string("string"), "description": .string("Only documents whose text cites a date on or after this day, yyyy-MM-dd.")]),
                "citedTo": .object(["type": .string("string"), "description": .string("Only documents whose text cites a date on or before this day, yyyy-MM-dd.")]),
            ],
            required: ["query"]
        ),
        definition(
            name: "read_document_page",
            label: "Read document page",
            description: "Read one page of a document in the vault, by its identifier.",
            properties: [
                "documentID": .object(["type": .string("string"), "description": .string("Document identifier.")]),
                "page": .object(["type": .string("integer"), "description": .string("Page number, starting at 1.")]),
            ],
            required: ["documentID", "page"]
        ),
        definition(
            name: "set_document_tags",
            label: "Set document tags",
            description: "Replace the tags of a document in the vault.",
            properties: [
                "documentID": .object(["type": .string("string"), "description": .string("Document identifier.")]),
                "tags": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("string")]),
                    "description": .string("The new tags."),
                ]),
            ],
            required: ["documentID", "tags"]
        ),
        definition(
            name: "request_document_deletion",
            label: "Request document deletion",
            description: "Ask the user to delete a document. The deletion happens only if the user confirms it.",
            properties: [
                "documentID": .object(["type": .string("string"), "description": .string("Document identifier.")]),
            ],
            required: ["documentID"]
        ),
        definition(
            name: "cite_documents",
            label: "Cite documents",
            description: "Declare the documents and pages your answer uses. Call it once, before writing the answer, with every source the answer relies on, and cite nothing else.",
            properties: [
                "citations": .object([
                    "type": .string("array"),
                    "items": .object([
                        "type": .string("object"),
                        "properties": .object([
                            "documentID": .object(["type": .string("string"), "description": .string("Document identifier.")]),
                            "page": .object(["type": .string("integer"), "description": .string("Page the answer uses, starting at 1; omit it for the whole document.")]),
                        ]),
                        "required": .array([.string("documentID")]),
                    ]),
                    "description": .string("The documents and pages the answer uses."),
                ]),
            ],
            required: ["citations"]
        ),
    ]

    func handle(toolName: String, arguments: JSONValue) async -> Output {
        do {
            switch toolName {
            case "search_vault":
                let query = try string(arguments, "query")
                let limit = min(max(arguments["limit"]?.int ?? 10, 1), 20)
                let filter = try searchFilter(arguments)
                let hits = try await chat.searchVault(query: query, limit: limit, filter: filter)
                return Output(text: encode(.array(hits.map(Self.json))), isError: false)
            case "read_document_page":
                let documentID = try string(arguments, "documentID")
                let page = arguments["page"]?.int ?? 1
                guard page >= 1 else { throw ArgumentError.invalid }
                let result = try await chat.readDocumentPage(documentID: documentID, page: page)
                return Output(text: encode(Self.json(result)), isError: false)
            case "set_document_tags":
                let documentID = try string(arguments, "documentID")
                guard let raw = arguments["tags"]?.array else { throw ArgumentError.invalid }
                let tags = raw.compactMap(\.string)
                guard tags.count == raw.count else { throw ArgumentError.invalid }
                try await vault.setDocumentTags(documentID: documentID, tags: tags)
                events.publish(.tagsChanged(documentID: documentID, tags: tags))
                return Output(text: "Tags updated.", isError: false)
            case "request_document_deletion":
                let documentID = try string(arguments, "documentID")
                let deleted = try await vault.requestDocumentDeletion(documentID: documentID)
                events.publish(.deletionRequested(documentID: documentID))
                return Output(text: deleted ? "Document deleted." : "Deletion declined by the user.", isError: false)
            case "cite_documents":
                guard let raw = arguments["citations"]?.array else { throw ArgumentError.invalid }
                let citations = try raw.map { item -> OMPCitation in
                    let documentID = try string(item, "documentID")
                    let page = item["page"]?.int
                    if let page, page < 1 { throw ArgumentError.invalid }
                    return OMPCitation(documentID: documentID, page: page)
                }
                try await chat.citeDocuments(citations)
                return Output(text: "Citations recorded.", isError: false)
            default:
                return Output(text: "Unknown tool.", isError: true)
            }
        } catch ArgumentError.invalid {
            return Output(text: "Invalid arguments.", isError: true)
        } catch {
            return Output(text: "The operation failed.", isError: true)
        }
    }

    private func string(_ arguments: JSONValue, _ key: String) throws -> String {
        guard let value = arguments[key]?.string, !value.isEmpty else { throw ArgumentError.invalid }
        return value
    }

    /// The filters of `search_vault`; an absent or null argument means no filter on that field.
    private func searchFilter(_ arguments: JSONValue) throws -> OMPSearchFilter {
        OMPSearchFilter(
            tags: try strings(arguments, "tags"),
            kinds: try strings(arguments, "kinds"),
            origins: try strings(arguments, "origins"),
            archivedFrom: try day(arguments, "archivedFrom"),
            archivedTo: try day(arguments, "archivedTo"),
            documentFrom: try day(arguments, "documentFrom"),
            documentTo: try day(arguments, "documentTo"),
            receivedFrom: try day(arguments, "receivedFrom"),
            receivedTo: try day(arguments, "receivedTo"),
            citedFrom: try day(arguments, "citedFrom"),
            citedTo: try day(arguments, "citedTo")
        )
    }

    private func strings(_ arguments: JSONValue, _ key: String) throws -> [String] {
        guard let value = arguments[key], value != .null else { return [] }
        guard let raw = value.array else { throw ArgumentError.invalid }
        let strings = raw.compactMap(\.string)
        guard strings.count == raw.count else { throw ArgumentError.invalid }
        return strings
    }

    /// A `yyyy-MM-dd` day in the local calendar, as the vault's archive dates are read.
    private func day(_ arguments: JSONValue, _ key: String) throws -> Date? {
        guard let value = arguments[key], value != .null else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        guard let text = value.string, let date = formatter.date(from: text) else { throw ArgumentError.invalid }
        return date
    }

    private func encode(_ value: JSONValue) -> String {
        guard let data = try? JSONEncoder().encode(value) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    private static func json(_ hit: OMPSearchHit) -> JSONValue {
        var object: [String: JSONValue] = [
            "documentID": .string(hit.documentID),
            "title": .string(hit.title),
            "excerpt": .string(hit.excerpt),
            "archivedAt": .string(instantText(hit.archivedAt)),
            "citedDates": .array(hit.citedDates.map(citedDateJSON)),
        ]
        if let page = hit.page {
            object["page"] = .number(Double(page))
        }
        if let wholeText = hit.wholeText {
            object["wholeText"] = .string(wholeText)
        }
        if let documentDate = hit.documentDate {
            object["documentDate"] = dateJSON(documentDate)
        }
        if let receivedAt = hit.receivedAt {
            object["receivedAt"] = dateJSON(receivedAt)
        }
        return .object(object)
    }

    private static func dateJSON(_ date: OMPDate) -> JSONValue {
        switch date {
        case .instant(let instant):
            return .string(instantText(instant))
        case .day(let day):
            return .string(dayText(day))
        }
    }

    private static func citedDateJSON(_ cited: OMPCitedDate) -> JSONValue {
        var object: [String: JSONValue] = [
            "about": .string(cited.about),
            "originalText": .string(cited.originalText),
        ]
        if let date = cited.date {
            object["date"] = dateJSON(date)
        }
        return .object(object)
    }

    /// An instant as ISO 8601 in the Mac's time zone, with its UTC offset.
    private static func instantText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
        return formatter.string(from: date)
    }

    /// A day as `yyyy-MM-dd`: the day of the date in UTC, which is how a day is held.
    private static func dayText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .gmt
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func json(_ page: OMPDocumentPage) -> JSONValue {
        .object([
            "documentID": .string(page.documentID),
            "page": .number(Double(page.page)),
            "text": .string(page.text),
        ])
    }

    private static func definition(
        name: String,
        label: String,
        description: String,
        properties: [String: JSONValue],
        required: [String]
    ) -> JSONValue {
        .object([
            "name": .string(name),
            "label": .string(label),
            "description": .string(description),
            "parameters": .object([
                "type": .string("object"),
                "properties": .object(properties),
                "required": .array(required.map { .string($0) }),
            ]),
        ])
    }
}
