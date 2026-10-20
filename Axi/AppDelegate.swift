import AppKit
import AxiCore
import AxiEmbedding
import AxiOMP
import AxiScreen
import OSLog

private let logger = Logger(subsystem: "Axi", category: "app")

/// Composition root of the app: services and windows are created here.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Kept for the whole run: nothing else holds the dot's controller.
    private var puntino: PuntinoController?
    /// Kept while open: the welcome window comes back at each launch until it is completed.
    private var benvenuto: BenvenutoWindowController?
    /// The vault of this Mac, opened once for the whole run. The chat and the archiving are
    /// given this same store when they are connected.
    private var vault: VaultStore?
    /// The settings window's controller, built at launch on the shared OMP connection, so the dot's settings Events always have a receiver.
    private var impostazioni: ImpostazioniController?
    /// The Permissions window's controller, kept for the whole run: it opens at launch when a permission is missing.
    private var permessi: PermessiController?
    /// The shared permission model: the Permissions window, the welcome and the settings read and ask through it.
    private let permessiModel = PermessiModel()
    /// The global shortcuts, registered once at launch so they work from any app.
    private var scorciatoie: Scorciatoie?
    /// The Spotlight and Dictation keys' event tap, kept for the whole run: it follows the "Tasti Apple" switch and the permission.
    private var tastiApple: TastiAppleController?
    /// The one archiving service of the app, built on the shared OMP connection by `collegaArchiviazione`.
    /// Kept for the whole run; the files released to the dot and the documents the user identifies enter here.
    private(set) var archiviazione: ArchivingService?
    /// Forwards the archiving events to the dot's activity, for as long as the service lives.
    private var archiviazioneEventi: Task<Void, Never>?
    /// The shared OMP connection. The mini-chat's chat and vault tools are given to it here; the OMP Task starts it.
    private(set) var omp: OMPConnection?
    /// The one screen reading service of the app, read by the mini-chat and the archiving.
    private let lettura = LetturaSchermoService()
    /// The mini-chat's controller, kept for the whole run.
    private var chat: MiniChatController?
    /// The mini-chat's window, anchored to the dot, or to its icon in the menu bar while the dot is hidden.
    private var finestraChat: MiniChatWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            // 768 is the size of the vectors the embedding model produces.
            vault = try VaultLocation.open(embeddingDimension: 768)
        } catch {
            fatalError("The vault cannot be opened: \(error)")
        }
        guard let vault else { return }
        // The mini-chat's tools: the vault search and documents, the deletion the user confirms, and the turn of the chat.
        let documents = VaultDocumentsAdapter(vault: vault)
        let deletion = DeletionBridge()
        let turn = OMPChatTurn()
        let embedder = TextEmbedderLoader()
        let omp = OMPConnection(
            dataDirectory: Self.ompDirectory,
            chatTools: OMPChatTools(
                search: HybridVaultSearch(backend: VaultIndexSearchBackend(store: vault, embedder: embedder)),
                documents: documents,
                turn: turn
            ),
            vaultTools: OMPVaultTools(documents: documents, confirmer: deletion)
        )
        self.omp = omp
        // The archiving is connected to the shared connection once; it does not wait for OMP to be ready.
        collegaArchiviazione(omp: omp)
        let impostazioniStore = ImpostazioniStore()
        // The settings window gets the store, the shared OMP connection, the Azure check and the permissions; the dot's settings Events reach it through `riceve`.
        impostazioni = ImpostazioniController(
            store: impostazioniStore,
            omp: omp,
            provaAzure: ImpostazioniController.provaAzure,
            sink: { [weak self] evento in self?.riceve(evento) },
            permessi: permessiModel
        )
        Task { await omp.start(executablePath: impostazioniStore.percorsoOMP, model: impostazioniStore.modelloAI) }
        let store: ConversationStore
        do {
            store = ConversationStore(directory: try ConversationStore.defaultDirectory())
        } catch {
            fatalError("The conversations folder cannot be opened: \(error)")
        }
        let chat = MiniChatController(
            store: store,
            assistant: OMPAssistantService(provider: omp, turn: turn, documents: documents),
            screen: LetturaContestoChat(lettura: lettura),
            documents: WorkspaceDocumentOpener(
                fileURL: { id in (try? vault.copyURL(ofDocument: id)) ?? nil },
                addressURL: { id in (try? vault.sourceURL(ofDocument: id)) ?? nil }
            ),
            events: MiniChatEventRelay(handler: { [weak self] evento in self?.riceveChat(evento) }),
            deletion: deletion,
            utente: { [weak self] evento in self?.riceve(evento) }
        )
        self.chat = chat
        chat.alCambioRisposta = { [weak self] inCorso in self?.puntino?.riceveRisposta(inCorso: inCorso) }
        finestraChat = MiniChatWindowController(controller: chat, ancora: { [weak self] in self?.puntino?.ancoraggioChat ?? .puntino(.zero) })
        let puntino = PuntinoController(
            chatAperta: { [weak self] in self?.chat?.isOpen ?? false },
            chatFrame: { [weak self] in self?.finestraChat?.frameAperta ?? .zero },
            // The menu shows the Spotlight and Dictation symbols only while the event tap takes those keys.
            tastiAssegnati: { [weak self] in self?.tastiApple?.attivo ?? false },
            sink: { [weak self] evento in self?.riceve(evento) }
        )
        self.puntino = puntino
        puntino.alSpostamento = { [weak self] in self?.finestraChat?.riposiziona() }
        puntino.avvia()
        let scorciatoie = Scorciatoie(
            memoria: AppInPrimoPiano.shared,
            chatAperta: { [weak self] in self?.chat?.isOpen ?? false },
            sink: { [weak self] evento in
                // The dot applies the shortcut's Event to its own state before the Event is forwarded, as it does for its menu items.
                self?.puntino?.riceveScorciatoia(evento)
                self?.riceve(evento)
            }
        )
        scorciatoie.registra()
        self.scorciatoie = scorciatoie
        let tastiApple = TastiAppleController(
            store: impostazioniStore,
            codici: .predefiniti,
            memoria: AppInPrimoPiano.shared,
            chatAperta: { [weak self] in self?.chat?.isOpen ?? false },
            sink: { [weak self] evento in
                // Same as the shortcuts: the dot applies the Event to its own state before it is forwarded.
                self?.puntino?.riceveScorciatoia(evento)
                self?.riceve(evento)
            }
        )
        tastiApple.avvia()
        self.tastiApple = tastiApple
        // The welcome's permission rows ask through `riceve` straight to the shared permission model.
        benvenuto = BenvenutoWindowController.showIfNeeded(
            omp: omp,
            permessi: permessiModel,
            sink: { [weak self] evento in self?.riceve(evento) })
        let permessi = PermessiController(modello: permessiModel)
        self.permessi = permessi
        permessi.controllaAllAvvio()
    }

    /// Routes the dot's Events to the Machines that consume them.
    private func riceve(_ evento: EventoUtente) {
        switch evento {
        case .apreImpostazioni, .chiudeImpostazioni:
            impostazioni?.riceve(evento)
        case .riapreAxi:
            // Both windows end with the run: the settings window closes, and the app starts the new instance.
            impostazioni?.riceve(evento)
            permessi?.riceve(evento)
            riapriAxi()
        case .apreChat:
            apriChat()
        case .chiedeArchiviazione:
            puntino?.riceveAttivita(.chiedeArchiviazione)
            lettura.riceve(evento, target: AppInPrimoPiano.shared.bersaglioArchiviazione)
        case .clicPuntino:
            // With the chat open, a click on the dot closes it, as the Chat shortcut does; the menu does not open.
            if chat?.isOpen == true { chat?.send(.closeChat) }
        case .chiudeChat:
            chat?.send(.closeChat)
        case .rilasciaFile(let urls):
            liberaFile(urls)
        case .cambiaPercorsoOMP(let percorso):
            Task { await omp?.changePath(percorso.isEmpty ? nil : percorso) }
        case .apriPermessi, .chiudePermessi:
            permessi?.riceve(evento)
        case .chiedePermesso(let permesso):
            // The welcome and the settings ask through the shared model, so a closed Permissions window takes no request.
            Task { await permessiModel.chiede(permesso) }
        default:
            break
        }
    }

    /// `utente.RIAPRE_AXI`: starts a new instance of Axi from its bundle, then ends this one. The new start checks again.
    private func riapriAxi() {
        let configurazione = NSWorkspace.OpenConfiguration()
        configurazione.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configurazione) { _, errore in
            if let errore {
                logger.error("Axi could not be reopened: \(errore.localizedDescription, privacy: .public)")
                return
            }
            Task { @MainActor in NSApp.terminate(nil) }
        }
    }

    /// Opens the chat, telling it whether OMP is ready to answer. The readiness is read asynchronously.
    private func apriChat() {
        guard let chat, let omp else { return }
        Task {
            let pronta = await omp.state == .ready
            chat.send(.openChat(ompReady: pronta))
        }
    }

    /// Applies the mini-chat's events: the window follows them and the dot shows them.
    private func riceveChat(_ evento: MiniChatEvent) {
        switch evento {
        case .aperta:
            finestraChat?.mostra()
        case .chiusa:
            finestraChat?.nascondi()
        case .nonDisponibile:
            break
        }
        puntino?.riceveChat(evento)
    }

    /// Where the OMP connection keeps its working folder and the session of each conversation.
    private static var ompDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Axi/omp", directoryHint: .isDirectory)
    }

    /// Builds the one archiving service on the shared OMP connection. Called once the connection exists.
    /// Its events reach the dot's activity; a document enters the vault only if every step succeeds.
    func collegaArchiviazione(omp: OMPConnection) {
        guard archiviazione == nil, let vault else { return }
        let servizio = ArchivingService(
            vault: vault,
            recognizer: ArchiveTextRecognizer(),
            assistant: OMPArchiveAssistant(connection: omp),
            embedder: TextEmbedderLoader(),
            interfaceLanguage: Bundle.main.preferredLocalizations.first ?? "en",
            activeModelContextWindow: { try? await omp.archive().contextWindowTokens() },
            welcomeCompleted: { BenvenutoStore(fileURL: BenvenutoStore.defaultFileURL).isCompleted() },
            ompReady: { await omp.state == .ready }
        )
        servizio.observeOMP(omp.events())
        archiviazione = servizio
        archiviazioneEventi = Task { [weak self] in
            for await evento in servizio.events {
                self?.puntino?.riceveAttivita(evento)
            }
        }
        inoltraDocumenti(di: lettura)
    }

    /// `utente.RILASCIA_FILE`: each released file is a document for the archiving, read as coming from the Finder.
    private func liberaFile(_ urls: [URL]) {
        guard let archiviazione else { return }
        let finder = ApplicationSnapshot(
            bundleIdentifier: "com.apple.finder",
            name: "Finder",
            processIdentifier: NSWorkspace.shared.runningApplications
                .first { $0.bundleIdentifier == "com.apple.finder" }?.processIdentifier ?? 0
        )
        let candidati = urls.map { DocumentCandidate.file(FileDocument(url: $0, source: finder)) }
        Task { await archiviazione.release(candidati) }
    }

    /// `lettura-schermo.DOCUMENTO_INDIVIDUATO`: each document the screen reading finds enters the archive queue.
    /// `lettura-schermo.NESSUN_DOCUMENTO`: each refusal reaches the dot's activity, which shows its bubble.
    /// The shared screen reading connects here by calling this with its service.
    private func inoltraDocumenti(di lettura: LetturaSchermoService) {
        Task { [weak self] in
            for await esito in lettura.esiti {
                switch esito {
                case .documentoIndividuato(let candidati, let momento):
                    await self?.archiviazione?.receive(candidati, at: momento)
                case .nessunDocumento(let motivo, let altreRichieste):
                    self?.puntino?.riceveAttivita(.nessunDocumento(motivo, altreRichieste: altreRichieste))
                case .contestoLetto, .letturaFallita:
                    break
                }
            }
        }
    }
}

/// The archive's AI: its prompts go to the archive session of the shared OMP connection.
struct OMPArchiveAssistant: AIAssistant {
    let connection: OMPConnection

    func complete(_ prompt: String) async throws -> String {
        try await connection.archive().prompt(prompt)
    }
}

/// Embeds the text of the documents with the embedding model. The model is loaded on first use.
actor TextEmbedderLoader: TextEmbedding {
    private var embedder: TextEmbedder?

    func embed(_ texts: [String]) async throws -> [[Float]] {
        let loaded: TextEmbedder
        if let embedder {
            loaded = embedder
        } else {
            loaded = try await TextEmbedder()
            embedder = loaded
        }
        return try await loaded.embed(texts)
    }
}

/// Reads scanned pages with the recognizer the settings choose at the moment of each read.
struct ArchiveTextRecognizer: TextRecognizing {
    /// Only the screen reading reports its source; the archive does not use it.
    var source: TextSource { .vision }

    func recognizeText(in image: CGImage) async throws -> String {
        try await RiconoscimentoTesto.riconoscitore(impostazioni: ImpostazioniStore()).recognizeText(in: image)
    }
}
