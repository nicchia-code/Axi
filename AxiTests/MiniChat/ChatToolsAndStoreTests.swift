import Foundation
import Testing
@testable import Axi

@Suite("Chat tools, deletion bridge and conversation store")
struct ChatToolsAndStoreTests {

    // MARK: - Fakes

    /// A vault with a few documents, recording what the tools change.
    actor FakeVault: VaultDocuments {
        var documents: [String: DeletionPreview]
        var pages: [String: [Int: String]]
        var fullTexts: [String: String]
        private(set) var deleted: [String] = []
        private(set) var taggedWith: [String: [String]] = [:]
        /// Names of the copies a deletion leaves in the trash.
        var leftovers: [String] = []

        init(documents: [String: DeletionPreview] = [:],
             pages: [String: [Int: String]] = [:],
             fullTexts: [String: String] = [:]) {
            self.documents = documents
            self.pages = pages
            self.fullTexts = fullTexts
        }

        func exists(documentID: String) async throws -> Bool { documents[documentID] != nil }
        func fullText(documentID: String) async throws -> String? { fullTexts[documentID] }
        func pageText(documentID: String, page: Int) async throws -> String? { pages[documentID]?[page] }
        func title(documentID: String) async throws -> String? { documents[documentID]?.title }
        func setTags(documentID: String, tags: [String]) async throws { taggedWith[documentID] = tags }
        func deletionPreview(documentID: String) async throws -> DeletionPreview? { documents[documentID] }
        func delete(documentID: String) async throws -> [String] {
            documents[documentID] = nil
            deleted.append(documentID)
            return leftovers
        }

        func setLeftovers(_ names: [String]) { leftovers = names }
    }

    /// Answers every confirmation the same way and counts the requests.
    actor FixedConfirmer: DeletionConfirming {
        let answer: Bool
        private(set) var asked = 0
        private(set) var leftoverReports = 0

        init(answer: Bool) { self.answer = answer }

        func confirm(_ preview: DeletionPreview) async -> Bool {
            asked += 1
            return answer
        }

        func reportLeftover() async {
            leftoverReports += 1
        }
    }

    /// Search backend that returns the same hits for both methods.
    struct FixedBackend: VaultSearchBackend {
        let hits: [VaultHit]
        func lexicalMatches(query: String, filter: VaultFilter, limit: Int) async throws -> [VaultHit] { hits }
        func semanticMatches(query: String, filter: VaultFilter, limit: Int) async throws -> [VaultHit] { hits }
    }

    private static let contract = DeletionPreview(
        documentID: "doc-contratto",
        title: "Contratto di locazione",
        kind: "contratto",
        archivedAt: Date(timeIntervalSince1970: 1_741_600_000),
        attachments: ["Appendice canone"]
    )

    private func text(_ data: Data) -> String {
        String(decoding: data, as: UTF8.self)
    }

    // MARK: - Deletion

    @Test("Deleting waits for the confirmation and deletes only when confirmed")
    func deletionOnlyWhenConfirmed() async throws {
        let vault = FakeVault(documents: ["doc-contratto": Self.contract])
        let confirmer = FixedConfirmer(answer: true)
        let tool = RequestDocumentDeletionTool(documents: vault, confirmer: confirmer)
        _ = try await tool.call(arguments: Data(#"{"documentID":"doc-contratto"}"#.utf8))
        #expect(await confirmer.asked == 1)
        #expect(await vault.deleted == ["doc-contratto"])
    }

    @Test("A refused deletion leaves the document in the vault")
    func refusedDeletionKeepsDocument() async throws {
        let vault = FakeVault(documents: ["doc-contratto": Self.contract])
        let confirmer = FixedConfirmer(answer: false)
        let tool = RequestDocumentDeletionTool(documents: vault, confirmer: confirmer)
        _ = try await tool.call(arguments: Data(#"{"documentID":"doc-contratto"}"#.utf8))
        #expect(await vault.deleted.isEmpty)
        #expect(try await vault.exists(documentID: "doc-contratto"))
    }

    @Test("A missing document is reported without asking the user")
    func missingDocumentNotAsked() async throws {
        let vault = FakeVault()
        let confirmer = FixedConfirmer(answer: true)
        let tool = RequestDocumentDeletionTool(documents: vault, confirmer: confirmer)
        let result = try await tool.call(arguments: Data(#"{"documentID":"nope"}"#.utf8))
        #expect(text(result).contains("document_not_found"))
        #expect(await confirmer.asked == 0)
    }

    @Test("The bridge resumes the tool once the chat settles the request")
    func bridgeResumesOnSettle() async throws {
        let bridge = DeletionBridge()
        let waiting = Task { await bridge.confirm(Self.contract) }

        var requests = await bridge.requests.makeAsyncIterator()
        let shown = await requests.next()
        #expect(shown == Self.contract)

        await bridge.settle(documentID: Self.contract.documentID, confirmed: true)
        #expect(await waiting.value == true)
    }

    @Test("Settling an unknown request does nothing")
    func bridgeIgnoresUnknown() async {
        let bridge = DeletionBridge()
        await bridge.settle(documentID: "nessuno", confirmed: true)
        let waiting = Task { await bridge.confirm(Self.contract) }
        // Wait until the request is shown, so the confirmation is registered before settling.
        var requests = await bridge.requests.makeAsyncIterator()
        _ = await requests.next()
        await bridge.settle(documentID: "nessuno", confirmed: true)
        await bridge.settle(documentID: Self.contract.documentID, confirmed: false)
        #expect(await waiting.value == false)
    }

    // MARK: - Search and reading

    @Test("Search returns the whole text of a short document next to its snippet")
    func searchIncludesWholeDocument() async throws {
        let hit = VaultHit(documentID: "doc-contratto", title: "Contratto di locazione", kind: "contratto",
                           origin: "scanner", tags: ["casa"], archivedAt: Date(timeIntervalSince1970: 0),
                           page: 2, snippet: "Il canone è di 850 euro.")
        let vault = FakeVault(documents: ["doc-contratto": Self.contract],
                              fullTexts: ["doc-contratto": "TESTO INTERO DEL CONTRATTO"])
        let tool = SearchVaultTool(
            search: HybridVaultSearch(backend: FixedBackend(hits: [hit])),
            documents: vault,
            policy: ContextPolicy(contextWindowTokens: 100_000)
        )
        let result = text(try await tool.call(arguments: Data(#"{"query":"canone"}"#.utf8)))
        #expect(result.contains("Il canone è di 850 euro."))
        #expect(result.contains("TESTO INTERO DEL CONTRATTO"))
    }

    @Test("A missing page is reported as page_not_found")
    func missingPage() async throws {
        let vault = FakeVault(pages: ["doc-contratto": [1: "Prima pagina"]])
        let tool = ReadDocumentPageTool(documents: vault)
        let result = try await tool.call(arguments: Data(#"{"documentID":"doc-contratto","page":9}"#.utf8))
        #expect(text(result).contains("page_not_found"))
    }

    @Test("An unknown tool name is reported, not thrown")
    func unknownTool() async {
        let registry = ChatToolRegistry(tools: [])
        let result = await registry.call(name: "inventato", arguments: Data("{}".utf8))
        #expect(text(result).contains("unknown_tool"))
    }

    // MARK: - Conversation store

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    @Test("A saved conversation loads back with its messages, citations and session")
    func storeRoundTrip() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(directory: directory)

        var conversation = Conversation.empty(now: Date(timeIntervalSince1970: 1_750_000_000))
        conversation.title = "Canone"
        conversation.ompSessionID = "sess-1"
        conversation.messages.append(ChatMessage(
            id: UUID(), author: .user, text: "Quanto costa?", date: conversation.lastMessageAt,
            screenContext: ScreenContext(appName: "Preview", bundleIdentifier: nil, title: "Bolletta", text: "42"),
            citations: []
        ))
        conversation.messages.append(ChatMessage(
            id: UUID(), author: .axi, text: "850 euro.", date: conversation.lastMessageAt,
            screenContext: nil,
            citations: [DocumentCitation(documentID: "doc-contratto", title: "Contratto", page: 2)]
        ))
        try await store.save(conversation)

        let loaded = try await store.load(conversation.id)
        #expect(loaded == conversation)
    }

    @Test("Summaries list the newest conversation first, and delete removes a conversation")
    func storeSummariesAndDelete() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(directory: directory)

        var older = Conversation.empty(id: UUID(), now: Date(timeIntervalSince1970: 1_000))
        older.title = "Vecchia"
        // lastMessageAt comes from the creation date of an empty conversation.
        var newer = Conversation.empty(id: UUID(), now: Date(timeIntervalSince1970: 2_000))
        newer.title = "Nuova"
        try await store.save(older)
        try await store.save(newer)

        #expect(try await store.summaries().map(\.title) == ["Nuova", "Vecchia"])
        #expect(try await store.latest()?.id == newer.id)

        try await store.delete(newer.id)
        #expect(try await store.load(newer.id) == nil)
        #expect(try await store.summaries().map(\.title) == ["Vecchia"])
    }

    @Test("The latest conversation throws when saved conversations exist but none can be read")
    func unreadableLatestThrows() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: directory.appendingPathComponent("broken.json"))
        let store = ConversationStore(directory: directory)

        await #expect(throws: ConversationStoreError.self) {
            _ = try await store.latest()
        }
    }

    @Test("OMP deletion removes the document only after the user confirms")
    func ompDeletionNeedsConfirmation() async throws {
        let vault = FakeVault(documents: ["doc-contratto": Self.contract])
        let refusing = FixedConfirmer(answer: false)
        let declined = try await OMPVaultTools(documents: vault, confirmer: refusing)
            .requestDocumentDeletion(documentID: "doc-contratto")
        #expect(declined == false)
        #expect(await refusing.asked == 1)
        #expect(await vault.deleted.isEmpty)

        let accepting = FixedConfirmer(answer: true)
        let deleted = try await OMPVaultTools(documents: vault, confirmer: accepting)
            .requestDocumentDeletion(documentID: "doc-contratto")
        #expect(deleted == true)
        #expect(await vault.deleted == ["doc-contratto"])
    }

    @Test("A deletion that leaves a file behind still succeeds and tells the user")
    func ompDeletionWithLeftoverFile() async throws {
        let vault = FakeVault(documents: ["doc-contratto": Self.contract])
        await vault.setLeftovers(["doc-contratto.pdf"])
        let confirmer = FixedConfirmer(answer: true)
        let deleted = try await OMPVaultTools(documents: vault, confirmer: confirmer)
            .requestDocumentDeletion(documentID: "doc-contratto")
        #expect(deleted == true)
        #expect(await vault.deleted == ["doc-contratto"])
        #expect(await confirmer.leftoverReports == 1)
    }

    @Test("OMP tag changes apply to existing documents and fail for missing ones")
    func ompTagsOnlyForExistingDocuments() async throws {
        let vault = FakeVault(documents: ["doc-contratto": Self.contract])
        let tools = OMPVaultTools(documents: vault, confirmer: FixedConfirmer(answer: false))

        try await tools.setDocumentTags(documentID: "doc-contratto", tags: ["locazione"])
        #expect(await vault.taggedWith["doc-contratto"] == ["locazione"])

        await #expect(throws: VaultToolError.documentNotFound) {
            try await tools.setDocumentTags(documentID: "assente", tags: ["x"])
        }
        #expect(await vault.taggedWith["assente"] == nil)
    }
}
