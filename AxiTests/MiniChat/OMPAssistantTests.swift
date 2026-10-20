import AxiOMP
import Foundation
import Testing
@testable import Axi

@Suite("OMP chat bridge")
struct OMPAssistantTests {

    // MARK: - Fakes

    /// A scripted OMP chat session: each step runs in order during `prompt`.
    actor FakeChatSession: OMPChatSession {
        enum Step: Sendable {
            case text(String)
            case messageStart
            case run(@Sendable () async throws -> Void)
            case waitForAbort
            case fail(OMPError)
            case activity(OMPActivity)
        }

        private let window: Int?
        private let steps: [Step]
        private var aborted = false
        private var waiter: CheckedContinuation<Void, Never>?

        init(window: Int? = 1_000, steps: [Step]) {
            self.window = window
            self.steps = steps
        }

        func contextWindowTokens() async throws -> Int? { window }

        func prompt(
            _ message: String,
            sessionDirectory: URL?,
            onTextDelta: @escaping @Sendable (String) -> Void,
            onMessageStart: @escaping @Sendable () -> Void,
            onActivity: @escaping @Sendable (OMPActivity) -> Void
        ) async throws -> String {
            for step in steps {
                switch step {
                case .text(let text):
                    onTextDelta(text)
                case .messageStart:
                    onMessageStart()
                case .activity(let activity):
                    onActivity(activity)
                case .run(let work):
                    try await work()
                case .waitForAbort:
                    await withCheckedContinuation { continuation in
                        if aborted { continuation.resume() } else { waiter = continuation }
                    }
                case .fail(let error):
                    throw error
                }
            }
            if aborted { throw OMPError.aborted }
            return ""
        }

        func abort() async {
            aborted = true
            waiter?.resume()
            waiter = nil
        }
    }

    struct FakeProvider: OMPChatSessionProviding {
        let outcome: Result<FakeChatSession, OMPError>

        func chatSession() async throws -> any OMPChatSession {
            try outcome.get()
        }

        func ompSessionDirectory(forConversation conversation: String) async throws -> URL {
            URL(fileURLWithPath: "/tmp/omp-sessions/\(conversation)")
        }
    }

    /// Keeps what the tools returned, for assertions.
    actor Recorder {
        private(set) var hits: [OMPSearchHit] = []
        private(set) var page: OMPDocumentPage?

        func record(hits: [OMPSearchHit]) { self.hits = hits }
        func record(page: OMPDocumentPage) { self.page = page }
    }

    // MARK: - Helpers

    private static func search(_ hits: [VaultHit]) -> HybridVaultSearch {
        HybridVaultSearch(backend: ChatToolsAndStoreTests.FixedBackend(hits: hits))
    }

    private static func hit(_ documentID: String, title: String, page: Int?, snippet: String) -> VaultHit {
        VaultHit(documentID: documentID, title: title, kind: "fattura", origin: "email", tags: [],
                 archivedAt: Date(timeIntervalSince1970: 1_741_600_000), page: page, snippet: snippet)
    }

    private static func preview(_ documentID: String, title: String) -> DeletionPreview {
        DeletionPreview(documentID: documentID, title: title, kind: "fattura",
                        archivedAt: Date(timeIntervalSince1970: 1_741_600_000), attachments: [])
    }

    private static func request(_ conversation: UUID, question: String = "Quanto è il totale?") -> AssistantRequest {
        AssistantRequest(conversationID: conversation, sessionID: nil, question: question,
                         asked: ZonedMoment(date: Date(timeIntervalSince1970: 1_750_000_000), timeZone: TimeZone(identifier: "Europe/Rome")!),
                         screen: nil)
    }

    private static func collect(_ stream: AsyncStream<AssistantUpdate>) async -> [AssistantUpdate] {
        var updates: [AssistantUpdate] = []
        for await update in stream { updates.append(update) }
        return updates
    }

    // MARK: - Tests

    @Test("The answer streams from OMP and cites only the documents and pages OMP declares")
    func answerStreamsAndCites() async {
        let vault = ChatToolsAndStoreTests.FakeVault(
            documents: ["doc-1": Self.preview("doc-1", title: "Fattura")],
            pages: ["doc-1": [2: "Totale 120 euro"]]
        )
        let turn = OMPChatTurn()
        let tools = OMPChatTools(
            search: Self.search([Self.hit("doc-1", title: "Fattura", page: 1, snippet: "Totale")]),
            documents: vault,
            turn: turn
        )
        let recorder = Recorder()
        let session = FakeChatSession(steps: [
            .run {
                let hits = try await tools.searchVault(query: "totale", limit: 5, filter: OMPSearchFilter())
                await recorder.record(hits: hits)
            },
            .run {
                let page = try await tools.readDocumentPage(documentID: "doc-1", page: 2)
                await recorder.record(page: page)
            },
            .run {
                try await tools.citeDocuments([OMPCitation(documentID: "doc-1", page: 2)])
            },
            .text("Il totale è 120 euro."),
        ])
        let service = OMPAssistantService(provider: FakeProvider(outcome: .success(session)), turn: turn, documents: ChatToolsAndStoreTests.FakeVault())
        let conversation = UUID()

        let updates = await Self.collect(service.ask(Self.request(conversation)))

        #expect(updates == [
            .session(conversation.uuidString),
            .citation(DocumentCitation(documentID: "doc-1", title: "Fattura", page: 2)),
            .text("Il totale è 120 euro."),
            .finished,
        ])
        let hits = await recorder.hits
        let page = await recorder.page
        #expect(hits.map(\.documentID) == ["doc-1"])
        #expect(page?.text == "Totale 120 euro")
    }

    @Test("A document goes whole once, and only when it fits half the context window")
    func wholeDocumentRule() async {
        let big = String(repeating: "x", count: 20_000)
        let vault = ChatToolsAndStoreTests.FakeVault(
            documents: [
                "doc-small": Self.preview("doc-small", title: "Nota"),
                "doc-big": Self.preview("doc-big", title: "Archivio"),
            ],
            fullTexts: ["doc-small": "Piccolo", "doc-big": big]
        )
        let turn = OMPChatTurn()
        let tools = OMPChatTools(
            search: Self.search([
                Self.hit("doc-small", title: "Nota", page: 1, snippet: "a"),
                Self.hit("doc-big", title: "Archivio", page: 4, snippet: "b"),
                Self.hit("doc-small", title: "Nota", page: 2, snippet: "c"),
            ]),
            documents: vault,
            turn: turn
        )
        let recorder = Recorder()
        let session = FakeChatSession(window: 1_000, steps: [
            .run {
                let hits = try await tools.searchVault(query: "q", limit: 10, filter: OMPSearchFilter())
                await recorder.record(hits: hits)
            },
            .text("ok"),
        ])
        let service = OMPAssistantService(provider: FakeProvider(outcome: .success(session)), turn: turn, documents: ChatToolsAndStoreTests.FakeVault())

        _ = await Self.collect(service.ask(Self.request(UUID())))

        let hits = await recorder.hits
        #expect(hits.filter { $0.documentID == "doc-small" }.compactMap(\.wholeText) == ["Piccolo"])
        #expect(hits.filter { $0.documentID == "doc-big" }.allSatisfy { $0.wholeText == nil })
    }

    @Test("The search tool narrows the vault search by the filters OMP gives")
    func searchToolPassesFilters() async throws {
        let backend = FilterRecordingBackend(hits: [Self.hit("doc-1", title: "Fattura", page: 1, snippet: "Totale")])
        let tools = OMPChatTools(
            search: HybridVaultSearch(backend: backend),
            documents: ChatToolsAndStoreTests.FakeVault(documents: [:], pages: [:]),
            turn: OMPChatTurn()
        )
        let since = Date(timeIntervalSince1970: 0)

        _ = try await tools.searchVault(
            query: "totale",
            limit: 5,
            filter: OMPSearchFilter(tags: ["casa"], kinds: ["pdf"], origins: ["Mail"], archivedFrom: since)
        )

        #expect(await backend.filter == VaultFilter(tags: ["casa"], kinds: ["pdf"], origins: ["Mail"], archivedFrom: since))
    }

    @Test("Interrupting stops OMP and keeps the partial answer")
    func interruptStopsTheAnswer() async {
        let turn = OMPChatTurn()
        let session = FakeChatSession(steps: [.text("Parziale"), .waitForAbort])
        let service = OMPAssistantService(provider: FakeProvider(outcome: .success(session)), turn: turn, documents: ChatToolsAndStoreTests.FakeVault())
        let conversation = UUID()

        var updates: [AssistantUpdate] = []
        for await update in service.ask(Self.request(conversation)) {
            updates.append(update)
            if case .text = update {
                await service.interrupt(conversationID: conversation)
            }
        }

        #expect(updates.contains(.text("Parziale")))
        #expect(updates.last == .stopped)
        #expect(!updates.contains(.finished))
    }

    @Test("A failed prompt is reported with OMP's message")
    func failedPromptIsReported() async {
        let turn = OMPChatTurn()
        let session = FakeChatSession(steps: [.fail(.promptFailed(message: "quota"))])
        let service = OMPAssistantService(provider: FakeProvider(outcome: .success(session)), turn: turn, documents: ChatToolsAndStoreTests.FakeVault())
        let conversation = UUID()

        let updates = await Self.collect(service.ask(Self.request(conversation)))

        let message = OMPError.promptFailed(message: "quota").errorDescription ?? ""
        #expect(updates == [.session(conversation.uuidString), .failed(message)])
    }

    @Test("A connection that is not ready fails the answer")
    func notReadyFailsTheAnswer() async {
        let turn = OMPChatTurn()
        let service = OMPAssistantService(provider: FakeProvider(outcome: .failure(.notReady)), turn: turn, documents: ChatToolsAndStoreTests.FakeVault())

        let updates = await Self.collect(service.ask(Self.request(UUID())))

        #expect(updates == [.failed(OMPError.notReady.errorDescription ?? "")])
    }

    @Test("An OMP process that exits stops the answer")
    func exitedProcessStopsTheAnswer() async {
        let turn = OMPChatTurn()
        let session = FakeChatSession(steps: [.fail(.processExited)])
        let service = OMPAssistantService(provider: FakeProvider(outcome: .success(session)), turn: turn, documents: ChatToolsAndStoreTests.FakeVault())
        let conversation = UUID()

        let updates = await Self.collect(service.ask(Self.request(conversation)))

        #expect(updates == [.session(conversation.uuidString), .stopped])
    }

    @Test("OMP starting a new message is passed on before its text")
    func messageStartIsPassedOn() async {
        let turn = OMPChatTurn()
        let session = FakeChatSession(steps: [.text("Cerco."), .messageStart, .text("Risposta")])
        let service = OMPAssistantService(provider: FakeProvider(outcome: .success(session)), turn: turn, documents: ChatToolsAndStoreTests.FakeVault())
        let conversation = UUID()

        let updates = await Self.collect(service.ask(Self.request(conversation)))

        #expect(updates == [.session(conversation.uuidString), .text("Cerco."), .messageStarted, .text("Risposta"), .finished])
    }

    @Test("A question asked while an interrupted answer still runs waits for it to end")
    func questionWaitsForInterruptedTurn() async {
        let turn = OMPChatTurn()
        await turn.begin(conversationID: UUID(), session: FakeChatSession(steps: []), contextWindowTokens: nil) { _ in }
        let session = FakeChatSession(steps: [.text("Risposta")])
        let service = OMPAssistantService(provider: FakeProvider(outcome: .success(session)), turn: turn, documents: ChatToolsAndStoreTests.FakeVault())
        let conversation = UUID()

        let answer = Task { await Self.collect(service.ask(Self.request(conversation))) }
        await turn.end()
        let updates = await answer.value

        #expect(updates == [.session(conversation.uuidString), .text("Risposta"), .finished])
    }

    @Test("OMP activity becomes steps, retries and reasoning")
    func activityBecomesSteps() async {
        let turn = OMPChatTurn()
        let session = FakeChatSession(steps: [
            .activity(.thinking("Penso. ")),
            .activity(.toolStarted(id: "1", name: "search_vault", arguments: .object(["query": .string("fattura")]))),
            .activity(.toolFinished(id: "1")),
            .activity(.retryStarted(attempt: 1, maxAttempts: 3)),
            .activity(.retryEnded),
            .text("Ecco.")
        ])
        let service = OMPAssistantService(provider: FakeProvider(outcome: .success(session)), turn: turn, documents: ChatToolsAndStoreTests.FakeVault())

        let updates = await Self.collect(service.ask(Self.request(UUID())))
        let steps = updates.compactMap { update -> AnswerStep? in
            if case .stepStarted(let step) = update { return step }
            return nil
        }

        #expect(steps.map(\.kind) == [.searchVault(words: "fattura"), .retry(attempt: 1, maxAttempts: 3)])
        #expect(updates.contains(.reasoning("Penso. ")))
        #expect(updates.contains(.stepFinished(steps[0].id)))
    }

    @Test("The message to OMP carries the answering rules and the question")
    func messageCarriesRulesAndQuestion() {
        let message = OMPAssistantService.message(for: Self.request(UUID(), question: "Quanto costa?"))

        #expect(message.contains("search_vault"))
        #expect(message.contains("read_document_page"))
        #expect(message.hasSuffix("Question: Quanto costa?"))
    }

    @Test("The message to OMP starts with the current date and time, and gives the moment the screen was read")
    func messageCarriesMoments() {
        let rome = TimeZone(identifier: "Europe/Rome")!
        let read = ZonedMoment(date: Date(timeIntervalSince1970: 1_749_990_000), timeZone: rome)
        let screen = ScreenContext(appName: "Mail", bundleIdentifier: nil, title: "", text: "Scade domani", moment: read)
        let request = AssistantRequest(
            conversationID: UUID(), sessionID: nil, question: "Quando scade?",
            asked: ZonedMoment(date: Date(timeIntervalSince1970: 1_750_000_000), timeZone: rome), screen: screen)
        let message = OMPAssistantService.message(for: request)

        #expect(message.hasPrefix("Current date and time on the user's Mac: "))
        #expect(message.contains("(UTC+02:00, Europe/Rome)"))
        #expect(message.contains("What is on the user's screen (Mail), read on "))
    }
}

/// Hits for any search, recording the filter of the last one.
private actor FilterRecordingBackend: VaultSearchBackend {
    let hits: [VaultHit]
    private(set) var filter: VaultFilter?

    init(hits: [VaultHit]) {
        self.hits = hits
    }

    func lexicalMatches(query: String, filter: VaultFilter, limit: Int) async throws -> [VaultHit] {
        self.filter = filter
        return hits
    }

    func semanticMatches(query: String, filter: VaultFilter, limit: Int) async throws -> [VaultHit] {
        self.filter = filter
        return hits
    }
}
