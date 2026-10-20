import Foundation
import Observation
import os
import AxiCore
import AxiScreen

/// Reads what is on screen when the user asks for it.
protocol ScreenReading: Sendable {
    func readContext() async throws -> ScreenContext
}

/// Reads the screen for the mini-chat through `lettura-schermo`, from the app that was in front when the user asked.
struct LetturaContestoChat: ScreenReading {
    let lettura: LetturaSchermoService

    func readContext() async throws -> ScreenContext {
        let target = await MainActor.run { AppInPrimoPiano.shared.ultima }
        switch await lettura.leggeContesto(target: target) {
        case .contestoLetto(let letto):
            return ScreenContext(
                appName: letto.application.name,
                bundleIdentifier: letto.application.bundleIdentifier,
                title: TitoloSchermo.di(documento: letto.document, finestra: letto.windowTitle),
                text: letto.visibleText,
                moment: ZonedMoment(date: letto.moment.date, timeZone: letto.moment.timeZone))
        case .letturaFallita(let motivo):
            throw LetturaSchermoNonRiuscita.fallita(motivo)
        case .documentoIndividuato, .nessunDocumento, nil:
            throw LetturaSchermoNonRiuscita.nonAvviata
        }
    }
}

/// Why the mini-chat got no screen: the reading did not start, or it failed.
enum LetturaSchermoNonRiuscita: Error, Equatable {
    case nonAvviata
    case fallita(ReadingFailure)

    /// The reason the screen could not be read, when the reading ran and failed for it.
    var motivo: ReadingFailure? {
        if case .fallita(let motivo) = self { return motivo }
        return nil
    }
}

/// The title the mini-chat shows for the screen: the document in front, else the window, else nothing.
enum TitoloSchermo {
    static func di(documento: DocumentCandidate?, finestra: String?) -> String {
        switch documento {
        case .file(let file):
            return file.url.lastPathComponent
        case .email(let email):
            return email.subject ?? finestra ?? ""
        case .webPage(let pagina):
            return finestra ?? pagina.address.absoluteString
        case nil:
            return finestra ?? ""
        }
    }
}

/// Sends the mini-chat events (APERTA, CHIUSA, NON_DISPONIBILE) to the rest of the app.
protocol MiniChatEventSink: Sendable {
    func post(_ event: MiniChatEvent)
}

/// Opens a cited document in the default app.
protocol DocumentOpening: Sendable {
    func open(_ citation: DocumentCitation) async
}

/// Runs the mini-chat machine: feeds it the inputs and carries out its effects.
@MainActor
@Observable
final class MiniChatController {
    private(set) var model: MiniChatModel
    private(set) var summaries: [ConversationSummary] = []

    /// Called with `true` when the mini-chat starts answering and `false` when it stops.
    var alCambioRisposta: ((Bool) -> Void)?

    /// Whether the chat window is open. Other parts of the app read this.
    var isOpen: Bool { model.state != .closed }

    private var machine: MiniChatMachine
    private let store: ConversationStore
    private let assistant: AssistantService?
    private let screen: ScreenReading
    private let documents: DocumentOpening
    private let events: MiniChatEventSink
    private let deletion: DeletionBridge
    private let utente: @MainActor (EventoUtente) -> Void
    private var answerTask: Task<Void, Never>?
    private var saveChain: Task<Void, Never>?

    private let logger = Logger(subsystem: "Axi", category: "MiniChat")

    init(
        store: ConversationStore,
        assistant: AssistantService?,
        screen: ScreenReading,
        documents: DocumentOpening,
        events: MiniChatEventSink,
        deletion: DeletionBridge,
        utente: @escaping @MainActor (EventoUtente) -> Void
    ) {
        self.store = store
        self.assistant = assistant
        self.screen = screen
        self.documents = documents
        self.events = events
        self.deletion = deletion
        self.utente = utente
        let machine = MiniChatMachine()
        self.machine = machine
        self.model = machine.model

        let requests = deletion.requests
        Task { [weak self] in
            for await preview in requests {
                self?.send(.deletionRequested(preview))
            }
        }
        let leftovers = deletion.leftovers
        Task { [weak self] in
            for await _ in leftovers {
                self?.send(.deletionLeftFile)
            }
        }
    }

    /// Feeds one input to the machine and carries out what it asks for.
    func send(_ input: MiniChatInput) {
        let rispondePrima = model.state == .answering
        let effects = machine.handle(input)
        model = machine.model
        let rispondeOra = model.state == .answering
        if rispondeOra != rispondePrima {
            alCambioRisposta?(rispondeOra)
        }
        for effect in effects {
            run(effect)
        }
    }

    /// The "Open permissions" button: the app receives `utente.APRE_PERMESSI`, the window that answers it is not part of the chat.
    func apriPermessi() {
        utente(.apriPermessi)
    }

    /// Opens the chat when the user asks for it. Without an assistant the machine reports that OMP is not ready.
    func openChat() {
        send(.openChat(ompReady: assistant != nil))
    }

    /// Refreshes the conversation list shown by the chat.
    func reloadSummaries() {
        let store = self.store
        Task {
            let loaded = (try? await store.summaries()) ?? []
            self.summaries = loaded
        }
    }

    // MARK: - Effects

    private func run(_ effect: MiniChatEffect) {
        switch effect {
        case .emit(let event):
            events.post(event)

        case .readScreen(let session):
            let screen = self.screen
            Task {
                do {
                    let context = try await screen.readContext()
                    self.send(.screenRead(session: session, context))
                } catch {
                    self.logger.info("Screen not read: \(String(describing: error), privacy: .public)")
                    self.send(.screenReadFailed(session: session, (error as? LetturaSchermoNonRiuscita)?.motivo))
                }
            }

        case .loadLatestConversation(let token):
            let store = self.store
            let logger = self.logger
            Task {
                do {
                    let latest = try await store.latest() ?? Conversation.empty(now: Date())
                    self.send(.conversationLoaded(token: token, latest))
                } catch {
                    logger.error("Latest conversation load failed: \(String(describing: error), privacy: .public)")
                    self.send(.conversationLoadFailed(token: token))
                }
            }

        case .loadConversation(let id, let token):
            let store = self.store
            Task {
                do {
                    let loaded = try await store.load(id) ?? Conversation.empty(id: id, now: Date())
                    self.send(.conversationLoaded(token: token, loaded))
                } catch {
                    self.logger.error("Conversation load failed: \(String(describing: error), privacy: .public)")
                    self.send(.conversationLoadFailed(token: token))
                }
            }

        case .refreshConversationList:
            reloadSummaries()

        case .ask(let request):
            guard let assistant = self.assistant else {
                // No OMP bridge: the answer cannot be made, so it stops at once.
                send(.assistant(.stopped))
                return
            }
            answerTask?.cancel()
            answerTask = Task {
                for await update in assistant.ask(request) {
                    if Task.isCancelled { return }
                    self.send(.assistant(update))
                }
                // A stream that ends without a terminal update counts as stopped.
                if !Task.isCancelled {
                    self.send(.assistant(.stopped))
                }
            }

        case .interruptAnswer:
            answerTask?.cancel()
            answerTask = nil
            let conversationID = model.conversation.id
            let assistant = self.assistant
            Task { await assistant?.interrupt(conversationID: conversationID) }

        case .saveConversation(let conversation):
            save(conversation)

        case .openDocument(let citation):
            let documents = self.documents
            Task { await documents.open(citation) }

        case .settleDeletion(let documentID, let confirmed):
            let deletion = self.deletion
            Task { await deletion.settle(documentID: documentID, confirmed: confirmed) }

        case .deleteConversation(let id):
            let store = self.store
            Task {
                do {
                    try await store.delete(id)
                } catch {
                    self.logger.error("Conversation delete failed: \(String(describing: error), privacy: .public)")
                }
                self.summaries = (try? await store.summaries()) ?? []
            }
        }
    }

    /// Saves are chained, so a later save never lands before an earlier one.
    private func save(_ conversation: Conversation) {
        let previous = saveChain
        let store = self.store
        let logger = self.logger
        saveChain = Task {
            await previous?.value
            do {
                try await store.save(conversation)
            } catch {
                logger.error("Conversation save failed: \(String(describing: error), privacy: .public)")
            }
        }
    }
}
