import AxiCore
import AxiScreen
import Foundation
import Testing
@testable import Axi

@MainActor
@Suite("Mini-chat controller")
struct MiniChatControllerTests {

    // MARK: - Fakes

    /// Streams fixed updates for every question.
    struct FakeAssistant: AssistantService {
        let updates: [AssistantUpdate]

        func ask(_ request: AssistantRequest) -> AsyncStream<AssistantUpdate> {
            let updates = self.updates
            return AsyncStream { continuation in
                for update in updates { continuation.yield(update) }
                continuation.finish()
            }
        }

        func interrupt(conversationID: UUID) async {}
    }

    struct FakeScreen: ScreenReading {
        func readContext() async throws -> Axi.ScreenContext {
            Axi.ScreenContext(appName: "Preview", bundleIdentifier: nil, title: "Bolletta.pdf", text: "Totale 42 euro")
        }
    }

    struct FailingScreen: ScreenReading {
        let failure: LetturaSchermoNonRiuscita

        func readContext() async throws -> Axi.ScreenContext {
            throw failure
        }
    }

    struct NoDocuments: DocumentOpening {
        func open(_ citation: DocumentCitation) async {}
    }

    /// Records the events the chat posts.
    final class EventLog: MiniChatEventSink, @unchecked Sendable {
        private let lock = NSLock()
        private var events: [MiniChatEvent] = []

        func post(_ event: MiniChatEvent) {
            lock.withLock { events.append(event) }
        }

        var posted: [MiniChatEvent] {
            lock.withLock { events }
        }
    }

    /// Records the `utente` Events the chat hands to the app.
    final class UtenteLog: @unchecked Sendable {
        private let lock = NSLock()
        private var events: [EventoUtente] = []

        func record(_ event: EventoUtente) {
            lock.withLock { events.append(event) }
        }

        var received: [EventoUtente] {
            lock.withLock { events }
        }
    }

    /// Polls until the condition holds, failing the test if it never does.
    private func waitUntil(_ condition: @MainActor () async -> Bool) async throws {
        for _ in 0..<300 {
            if await condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("The condition was not reached in time")
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    // MARK: - Tests

    @Test("A question is streamed into the chat, the answer is saved, and the events are posted")
    func answerIsStreamedAndSaved() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(directory: directory)
        let events = EventLog()
        let citation = DocumentCitation(documentID: "doc-contratto", title: "Contratto", page: 2)
        let controller = MiniChatController(
            store: store,
            assistant: FakeAssistant(updates: [
                .session("sess-1"), .text("Il canone è 850 euro."), .citation(citation), .finished,
            ]),
            screen: FakeScreen(),
            documents: NoDocuments(),
            events: events,
            deletion: DeletionBridge(),
            utente: { _ in }
        )

        controller.send(.openChat(ompReady: true))
        #expect(controller.isOpen)
        try await waitUntil { controller.model.state == .ready }
        #expect(controller.model.screen.context?.title == "Bolletta.pdf")

        controller.send(.sendQuestion("Quanto è il canone?"))
        try await waitUntil { controller.model.state == .ready && controller.model.conversation.messages.count == 2 }
        let answer = controller.model.conversation.messages.last
        #expect(answer?.text == "Il canone è 850 euro.")
        #expect(answer?.citations == [citation])
        #expect(controller.model.conversation.ompSessionID == "sess-1")

        let id = controller.model.conversation.id
        try await waitUntil { (try? await store.load(id))?.messages.count == 2 }
        let saved = try await store.load(id)
        #expect(saved?.ompSessionID == "sess-1")
        #expect(saved?.messages.last?.citations == [citation])

        #expect(events.posted == [.aperta])
    }

    @Test("The chat tells the dot when it starts and when it stops answering")
    func answeringIsReportedToTheDot() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let controller = MiniChatController(
            store: ConversationStore(directory: directory),
            assistant: FakeAssistant(updates: [.text("Risposta"), .finished]),
            screen: FakeScreen(),
            documents: NoDocuments(),
            events: EventLog(),
            deletion: DeletionBridge(),
            utente: { _ in }
        )
        var risponde: [Bool] = []
        controller.alCambioRisposta = { risponde.append($0) }

        controller.send(.openChat(ompReady: true))
        try await waitUntil { controller.model.state == .ready }
        controller.send(.sendQuestion("Domanda"))
        try await waitUntil { controller.model.state == .ready && controller.model.conversation.messages.count == 2 }

        #expect(risponde == [true, false])
    }

    @Test("A screen read that fails goes to ready and keeps the missing permission")
    func failedScreenKeepsPermission() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let controller = MiniChatController(
            store: ConversationStore(directory: directory),
            assistant: FakeAssistant(updates: [.finished]),
            screen: FailingScreen(failure: .fallita(.permissionMissing([.screenRecording]))),
            documents: NoDocuments(),
            events: EventLog(),
            deletion: DeletionBridge(),
            utente: { _ in }
        )

        controller.send(.openChat(ompReady: true))
        try await waitUntil { controller.model.state == .ready }
        #expect(controller.model.screen == .unreadable(.permissionMissing([.screenRecording])))
        #expect(controller.model.screen.context == nil)
    }

    @Test("The permission button sends utente.APRE_PERMESSI to the app")
    func permissionButtonSendsEvent() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let utente = UtenteLog()
        let controller = MiniChatController(
            store: ConversationStore(directory: directory),
            assistant: FakeAssistant(updates: [.finished]),
            screen: FakeScreen(),
            documents: NoDocuments(),
            events: EventLog(),
            deletion: DeletionBridge(),
            utente: { utente.record($0) }
        )

        controller.apriPermessi()
        #expect(utente.received == [.apriPermessi])
    }

    @Test("Closing the chat posts chiusa and reports it closed")
    func closingPostsEvent() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let events = EventLog()
        let controller = MiniChatController(
            store: ConversationStore(directory: directory),
            assistant: FakeAssistant(updates: []),
            screen: FakeScreen(),
            documents: NoDocuments(),
            events: events,
            deletion: DeletionBridge(),
            utente: { _ in }
        )

        controller.send(.openChat(ompReady: true))
        try await waitUntil { controller.model.state == .ready }
        controller.send(.closeChat)

        #expect(!controller.isOpen)
        #expect(events.posted == [.aperta, .chiusa])
    }

    @Test("With OMP not ready the chat stays closed and posts non-disponibile")
    func notAvailablePostsEvent() {
        let events = EventLog()
        let controller = MiniChatController(
            store: ConversationStore(directory: temporaryDirectory()),
            assistant: FakeAssistant(updates: []),
            screen: FakeScreen(),
            documents: NoDocuments(),
            events: events,
            deletion: DeletionBridge(),
            utente: { _ in }
        )

        controller.send(.openChat(ompReady: false))
        #expect(!controller.isOpen)
        #expect(events.posted == [.nonDisponibile])
    }
}

@MainActor
@Suite("Lettura del contesto per la mini-chat")
struct LetturaContestoChatTests {
    private let app = ApplicationSnapshot(bundleIdentifier: "com.apple.Preview", name: "Preview", processIdentifier: 7)

    @Test("A file in front gives its name as title")
    func fileTitle() {
        let file = FileDocument(url: URL(fileURLWithPath: "/tmp/Bolletta.pdf"), source: app)
        #expect(TitoloSchermo.di(documento: .file(file), finestra: "Bolletta.pdf — Anteprima") == "Bolletta.pdf")
    }

    @Test("Without a document the title is the window's")
    func windowTitle() {
        #expect(TitoloSchermo.di(documento: nil, finestra: "Finestra") == "Finestra")
    }

    @Test("A web page without window title is titled by its address")
    func webPageTitle() {
        let pagina = WebPage(address: URL(string: "https://example.com/fattura")!, visibleText: nil, source: app)
        #expect(TitoloSchermo.di(documento: .webPage(pagina), finestra: nil) == "https://example.com/fattura")
    }

    @Test("APRE_CHAT with no application in front throws without reading the screen")
    func noTargetThrows() async {
        let adattatore = LetturaContestoChat(lettura: LetturaSchermoService())
        await #expect(throws: LetturaSchermoNonRiuscita.nonAvviata) {
            _ = try await adattatore.readContext()
        }
    }
}
