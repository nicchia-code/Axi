import AxiCore
import AxiOMP
import Foundation

/// What the tools may do to the vault. Implemented by the vault package; tests use a fake.
protocol VaultDocuments: Sendable {
    func exists(documentID: String) async throws -> Bool
    func fullText(documentID: String) async throws -> String?
    func pageText(documentID: String, page: Int) async throws -> String?
    func title(documentID: String) async throws -> String?
    func setTags(documentID: String, tags: [String]) async throws
    func deletionPreview(documentID: String) async throws -> DeletionPreview?
    /// Returns the names of the copies left in the trash; the next launch empties them.
    func delete(documentID: String) async throws -> [String]
}

/// Asks the user to confirm a deletion requested by the assistant.
protocol DeletionConfirming: Sendable {
    /// Returns true only when the user confirmed. Nothing is deleted before.
    func confirm(_ preview: DeletionPreview) async -> Bool
    /// Tells the user that a deleted document left a file on disk until the next launch.
    func reportLeftover() async
}

/// A tool the assistant can call. Arguments and results are JSON.
protocol ChatTool: Sendable {
    var name: String { get }
    var summary: String { get }
    /// JSON Schema of the arguments.
    var parametersSchema: String { get }
    func call(arguments: Data) async throws -> Data
}

enum ChatToolError: Error, Equatable {
    case invalidArguments(String)
}

/// Holds the deletion requests of the assistant until the chat shows them to the user.
actor DeletionBridge: DeletionConfirming {
    let requests: AsyncStream<DeletionPreview>
    private let requestContinuation: AsyncStream<DeletionPreview>.Continuation
    /// One value per deletion that left a file behind.
    let leftovers: AsyncStream<Void>
    private let leftoverContinuation: AsyncStream<Void>.Continuation
    private var waiting: [String: CheckedContinuation<Bool, Never>] = [:]

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: DeletionPreview.self)
        requests = stream
        requestContinuation = continuation
        let (leftoverStream, leftoverContinuation) = AsyncStream.makeStream(of: Void.self)
        leftovers = leftoverStream
        self.leftoverContinuation = leftoverContinuation
    }

    func confirm(_ preview: DeletionPreview) async -> Bool {
        await withCheckedContinuation { continuation in
            waiting[preview.documentID] = continuation
            requestContinuation.yield(preview)
        }
    }

    /// Resolves a pending confirmation. Resolving an unknown request does nothing.
    func settle(documentID: String, confirmed: Bool) {
        waiting.removeValue(forKey: documentID)?.resume(returning: confirmed)
    }

    func reportLeftover() async {
        leftoverContinuation.yield()
    }
}

/// Date-only (`yyyy-MM-dd`) values in tool arguments, in the local calendar.
enum ToolDate {
    static func parse(_ text: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: text) else {
            throw ChatToolError.invalidArguments("date must be yyyy-MM-dd: \(text)")
        }
        return date
    }
}

struct SearchVaultTool: ChatTool {
    let name = "search_vault"
    let summary = "Hybrid word and meaning search in the vault, with optional filters."
    let parametersSchema = """
    {"type":"object","required":["query"],"properties":{\
    "query":{"type":"string"},\
    "tags":{"type":"array","items":{"type":"string"}},\
    "kinds":{"type":"array","items":{"type":"string"}},\
    "origins":{"type":"array","items":{"type":"string"}},\
    "archivedFrom":{"type":"string","description":"yyyy-MM-dd"},\
    "archivedTo":{"type":"string","description":"yyyy-MM-dd"}}}
    """

    let search: HybridVaultSearch
    let documents: VaultDocuments
    let policy: ContextPolicy

    private struct Arguments: Decodable {
        var query: String
        var tags: [String]?
        var kinds: [String]?
        var origins: [String]?
        var archivedFrom: String?
        var archivedTo: String?
    }

    func call(arguments: Data) async throws -> Data {
        let args = try decode(Arguments.self, arguments)
        let filter = VaultFilter(
            tags: args.tags ?? [],
            kinds: args.kinds ?? [],
            origins: args.origins ?? [],
            archivedFrom: try args.archivedFrom.map(ToolDate.parse),
            archivedTo: try args.archivedTo.map(ToolDate.parse)
        )
        let hits = try await search.search(query: args.query, filter: filter)

        // A document that fits in half the model's context goes whole, once per document.
        var wholeDocuments: [String: String] = [:]
        for documentID in Set(hits.map(\.documentID)) {
            guard let text = try await documents.fullText(documentID: documentID),
                  policy.sendsWholeDocument(text) else { continue }
            wholeDocuments[documentID] = text
        }

        return try JSONEncoder.toolEncoder.encode(SearchResult(
            results: hits.map(SearchResult.Hit.init),
            wholeDocuments: wholeDocuments.map { SearchResult.WholeDocument(documentID: $0.key, text: $0.value) }
                .sorted { $0.documentID < $1.documentID }
        ))
    }

    private struct SearchResult: Encodable {
        struct Hit: Encodable {
            var documentID: String
            var title: String
            var kind: String
            var origin: String
            var tags: [String]
            var archivedAt: Date
            var page: Int?
            var snippet: String

            init(_ hit: VaultHit) {
                documentID = hit.documentID
                title = hit.title
                kind = hit.kind
                origin = hit.origin
                tags = hit.tags
                archivedAt = hit.archivedAt
                page = hit.page
                snippet = hit.snippet
            }
        }

        struct WholeDocument: Encodable {
            var documentID: String
            var text: String
        }

        var results: [Hit]
        var wholeDocuments: [WholeDocument]
    }
}

struct ReadDocumentPageTool: ChatTool {
    let name = "read_document_page"
    let summary = "Full text of one page of a vault document."
    let parametersSchema = """
    {"type":"object","required":["documentID","page"],"properties":{\
    "documentID":{"type":"string"},\
    "page":{"type":"integer","minimum":1}}}
    """

    let documents: VaultDocuments

    private struct Arguments: Decodable {
        var documentID: String
        var page: Int
    }

    func call(arguments: Data) async throws -> Data {
        let args = try decode(Arguments.self, arguments)
        guard let text = try await documents.pageText(documentID: args.documentID, page: args.page) else {
            return try JSONEncoder.toolEncoder.encode(ToolFailure(error: "page_not_found"))
        }
        return try JSONEncoder.toolEncoder.encode(PageResult(documentID: args.documentID, page: args.page, text: text))
    }

    private struct PageResult: Encodable {
        var documentID: String
        var page: Int
        var text: String
    }
}

struct SetDocumentTagsTool: ChatTool {
    let name = "set_document_tags"
    let summary = "Replaces the tags of an existing vault document."
    let parametersSchema = """
    {"type":"object","required":["documentID","tags"],"properties":{\
    "documentID":{"type":"string"},\
    "tags":{"type":"array","items":{"type":"string"}}}}
    """

    let documents: VaultDocuments

    private struct Arguments: Decodable {
        var documentID: String
        var tags: [String]
    }

    func call(arguments: Data) async throws -> Data {
        let args = try decode(Arguments.self, arguments)
        guard try await documents.exists(documentID: args.documentID) else {
            return try JSONEncoder.toolEncoder.encode(ToolFailure(error: "document_not_found"))
        }
        try await documents.setTags(documentID: args.documentID, tags: args.tags)
        return try JSONEncoder.toolEncoder.encode(ToolSuccess(ok: true))
    }
}

struct RequestDocumentDeletionTool: ChatTool {
    let name = "request_document_deletion"
    let summary = "Asks the user to confirm deleting an existing vault document. Deletes only after confirmation."
    let parametersSchema = """
    {"type":"object","required":["documentID"],"properties":{\
    "documentID":{"type":"string"}}}
    """

    let documents: VaultDocuments
    let confirmer: DeletionConfirming

    private struct Arguments: Decodable {
        var documentID: String
    }

    func call(arguments: Data) async throws -> Data {
        let args = try decode(Arguments.self, arguments)
        guard let preview = try await documents.deletionPreview(documentID: args.documentID) else {
            return try JSONEncoder.toolEncoder.encode(ToolFailure(error: "document_not_found"))
        }
        let confirmed = await confirmer.confirm(preview)
        if confirmed {
            try await documents.delete(documentID: args.documentID)
        }
        return try JSONEncoder.toolEncoder.encode(DeletionResult(deleted: confirmed))
    }

    private struct DeletionResult: Encodable {
        var deleted: Bool
    }
}

/// The tools offered to the assistant, looked up by name.
struct ChatToolRegistry: Sendable {
    let tools: [any ChatTool]

    func call(name: String, arguments: Data) async -> Data {
        guard let tool = tools.first(where: { $0.name == name }) else {
            return (try? JSONEncoder.toolEncoder.encode(ToolFailure(error: "unknown_tool"))) ?? Data()
        }
        do {
            return try await tool.call(arguments: arguments)
        } catch {
            return (try? JSONEncoder.toolEncoder.encode(ToolFailure(error: "\(error)"))) ?? Data()
        }
    }
}

private struct ToolFailure: Encodable {
    var error: String
}

private struct ToolSuccess: Encodable {
    var ok: Bool
}

private func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        throw ChatToolError.invalidArguments("\(error)")
    }
}

private extension JSONEncoder {
    static var toolEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

/// The chat's view of the vault store the app opens. A deletion is carried out only for a
/// document whose preview was handed out and has not been carried out yet.
actor VaultDocumentsAdapter: VaultDocuments {
    private let vault: VaultStore
    private var previewed: Set<String> = []

    init(vault: VaultStore) {
        self.vault = vault
    }

    func exists(documentID: String) async throws -> Bool {
        try vault.document(id: documentID) != nil
    }

    func fullText(documentID: String) async throws -> String? {
        try vault.fullText(ofDocument: documentID)
    }

    func pageText(documentID: String, page: Int) async throws -> String? {
        try vault.pageText(ofDocument: documentID, page: page)
    }

    func title(documentID: String) async throws -> String? {
        try vault.document(id: documentID)?.title
    }

    func setTags(documentID: String, tags: [String]) async throws {
        try vault.updateTags(of: documentID, to: tags)
    }

    func deletionPreview(documentID: String) async throws -> DeletionPreview? {
        guard let plan = try vault.deletionPlan(ofDocument: documentID) else { return nil }
        previewed.insert(documentID)
        return DeletionPreview(
            documentID: plan.documentID,
            title: plan.title,
            kind: plan.kind.rawValue,
            archivedAt: plan.archivedAt,
            attachments: plan.attachmentTitles
        )
    }

    func delete(documentID: String) async throws -> [String] {
        // The store refuses the deletion when no preview is pending for this document.
        return try vault.confirmDeletion(of: documentID, pendingRequest: previewed.remove(documentID))
    }
}

/// Answers OMP's vault host tools with the chat's vault access and the user's confirmation.
struct OMPVaultTools: OMPVaultHostTools {
    let documents: any VaultDocuments
    let confirmer: any DeletionConfirming

    func setDocumentTags(documentID: String, tags: [String]) async throws {
        guard try await documents.exists(documentID: documentID) else {
            throw VaultToolError.documentNotFound
        }
        try await documents.setTags(documentID: documentID, tags: tags)
    }

    func requestDocumentDeletion(documentID: String) async throws -> Bool {
        guard let preview = try await documents.deletionPreview(documentID: documentID) else {
            throw VaultToolError.documentNotFound
        }
        guard await confirmer.confirm(preview) else { return false }
        let leftovers = try await documents.delete(documentID: documentID)
        if !leftovers.isEmpty {
            await confirmer.reportLeftover()
        }
        return true
    }
}

enum VaultToolError: Error {
    case documentNotFound
}

/// The vault's dates as the search results of the chat process carry them.
extension OMPDate {
    init(_ date: AbsoluteDate) {
        switch date {
        case .instant(let instant): self = .instant(instant)
        case .day(let day): self = .day(day)
        }
    }
}

extension OMPCitedDate {
    init(_ cited: CitedDate) {
        self.init(date: cited.date.map { OMPDate($0) }, about: cited.about, originalText: cited.originalText)
    }
}

/// Answers the chat OMP process's `search_vault`, `read_document_page` and `cite_documents` with the vault's content.
/// Only the documents and pages OMP declares with `cite_documents` are recorded as citations of the answer.
struct OMPChatTools: OMPChatHostTools {
    let search: HybridVaultSearch
    let documents: any VaultDocuments
    let turn: OMPChatTurn

    func searchVault(query: String, limit: Int, filter: OMPSearchFilter) async throws -> [OMPSearchHit] {
        let hits = try await search.search(query: query, filter: VaultFilter(
            tags: filter.tags, kinds: filter.kinds, origins: filter.origins,
            archivedFrom: filter.archivedFrom, archivedTo: filter.archivedTo,
            documentFrom: filter.documentFrom, documentTo: filter.documentTo,
            receivedFrom: filter.receivedFrom, receivedTo: filter.receivedTo,
            citedFrom: filter.citedFrom, citedTo: filter.citedTo
        ))
        let policy = await turn.contextPolicy()
        var documentsSeen: Set<String> = []
        var results: [OMPSearchHit] = []
        for hit in hits.prefix(limit) {
            // A document goes whole once, with its first hit, and only when it fits the model's context.
            var wholeText: String?
            if !documentsSeen.contains(hit.documentID) {
                documentsSeen.insert(hit.documentID)
                if let policy,
                   let text = try await documents.fullText(documentID: hit.documentID),
                   policy.sendsWholeDocument(text) {
                    wholeText = text
                }
            }
            results.append(OMPSearchHit(
                documentID: hit.documentID, title: hit.title, page: hit.page,
                excerpt: hit.snippet, wholeText: wholeText, archivedAt: hit.archivedAt,
                documentDate: hit.documentDate.map { OMPDate($0) }, receivedAt: hit.receivedAt.map { OMPDate($0) },
                citedDates: (hit.citedDates ?? []).map { OMPCitedDate($0) }
            ))
        }
        return results
    }

    func readDocumentPage(documentID: String, page: Int) async throws -> OMPDocumentPage {
        guard let text = try await documents.pageText(documentID: documentID, page: page) else {
            throw OMPChatToolsError.pageNotFound
        }
        return OMPDocumentPage(documentID: documentID, page: page, text: text)
    }

    func citeDocuments(_ citations: [OMPCitation]) async throws {
        for citation in citations {
            guard let title = try await documents.title(documentID: citation.documentID) else {
                throw OMPChatToolsError.documentNotFound
            }
            await turn.cite(DocumentCitation(documentID: citation.documentID, title: title, page: citation.page))
        }
    }
}

enum OMPChatToolsError: Error {
    case pageNotFound
    case documentNotFound
}
