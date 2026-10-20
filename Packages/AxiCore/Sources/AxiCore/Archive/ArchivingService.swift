import AxiOMP
import AxiScreen
import Foundation

/// A document waiting for its archiving, with the moment of the reading that found it.
struct DocumentoInCoda: Sendable {
    let candidate: DocumentCandidate
    let moment: ReadingMoment
}

/// Archives the documents the user identifies, one at a time, and reports each outcome as an
/// `EventoAttivita` on `events`.
///
/// Gate: a document starts only if the welcome is completed and OMP is ready; otherwise it ends
/// as `NON_ARCHIVIATO` with the reason. If OMP terminates during an archiving, that archiving
/// is cancelled and ends as `NON_ARCHIVIATO(ompFermato)`.
public actor ArchivingService {
    /// Events for the `attivita` Machine, in order.
    public nonisolated let events: AsyncStream<EventoAttivita>

    private let continuation: AsyncStream<EventoAttivita>.Continuation
    private let pipeline: ArchivingPipeline
    private let welcomeCompleted: @Sendable () -> Bool
    private let ompReady: @Sendable () async -> Bool
    private var queue = ArchiveQueue<DocumentoInCoda>()
    /// The archiving in progress, if any.
    private var running: Task<Void, Never>?

    /// - Parameters:
    ///   - attachments: takes the attachments of an email from Outlook's Accessibility tree; a nil taker lists every attachment as missing.
    ///   - webPages: renders the web page to PDF.
    ///   - downloads: downloads the PDF an address serves, before the page is rendered.
    ///   - outlook: reads the email on screen, to bring in the email of an attachment saved from Outlook.
    ///   - interfaceLanguage: language of the summaries and tags, as the interface.
    ///   - welcomeCompleted: whether the welcome is completed.
    ///   - ompReady: whether OMP is ready to serve the archiving.
    ///   - activeModelContextWindow: context window of the model OMP uses, in tokens; nil when OMP does not report it.
    public init(
        vault: VaultStore,
        recognizer: any TextRecognizing,
        assistant: any AIAssistant,
        embedder: any TextEmbedding,
        attachments: (any AttachmentTaking)? = OutlookAttachmentTaker(),
        webPages: any WebPageRendering = WebPageRenderer(),
        downloads: any WebPageDownloading = WebPageDownloader(),
        outlook: any OutlookEmailReading = OutlookWindowReader(),
        interfaceLanguage: String = "en",
        activeModelContextWindow: @escaping @Sendable () async -> Int?,
        welcomeCompleted: @escaping @Sendable () -> Bool,
        ompReady: @escaping @Sendable () async -> Bool
    ) {
        let (stream, continuation) = AsyncStream.makeStream(of: EventoAttivita.self)
        events = stream
        self.continuation = continuation
        pipeline = ArchivingPipeline(
            vault: vault,
            recognizer: recognizer,
            assistant: assistant,
            embedder: embedder,
            attachments: attachments,
            webPages: webPages,
            downloads: downloads,
            outlook: outlook,
            interfaceLanguage: interfaceLanguage,
            contextWindowTokens: { await activeModelContextWindow() ?? Self.fallbackContextWindowTokens },
            now: { Date() },
            progresso: { continuation.yield($0) }
        )
        self.welcomeCompleted = welcomeCompleted
        self.ompReady = ompReady
    }

    /// Context window assumed when OMP does not report the one of the active model, in tokens.
    /// Small on purpose: a document that fits in it is sent whole, a larger one goes by sections.
    static let fallbackContextWindowTokens = 8_000

    /// Number of documents waiting for their turn; the one being archived is not counted.
    public var pendingCount: Int {
        queue.pendingCount
    }

    /// `lettura-schermo.DOCUMENTO_INDIVIDUATO`: the documents the user identified, in order, with the moment of the reading; a Finder selection brings all its files.
    public func receive(_ candidates: [DocumentCandidate], at moment: ReadingMoment) {
        let items = candidates.map { DocumentoInCoda(candidate: $0, moment: moment) }
        if let next = queue.receive(.documentIdentified(items)) {
            start(next)
        }
    }

    /// `utente.RILASCIA_FILE`: files the user released to the dot, in the order the Finder delivers them; their moment is the release.
    public func release(_ candidates: [DocumentCandidate]) {
        let moment = ReadingMoment.now
        let items = candidates.map { DocumentoInCoda(candidate: $0, moment: moment) }
        if let next = queue.receive(.filesReleased(items)) {
            start(next)
        }
    }

    /// Follows the OMP events: if OMP terminates, the archiving in progress is cancelled.
    public nonisolated func observeOMP(_ ompEvents: AsyncStream<OMPEvent>) {
        Task { [weak self] in
            for await event in ompEvents {
                await self?.handle(event)
            }
        }
    }

    private func handle(_ event: OMPEvent) {
        if case .terminated = event {
            running?.cancel()
        }
    }

    private func start(_ next: DocumentoInCoda) {
        continuation.yield(.prossimoDocumento(inCoda: queue.pendingCount, nome: next.candidate.originName))
        running = Task {
            let outcome = await process(next)
            finish(outcome)
        }
    }

    private func process(_ next: DocumentoInCoda) async -> ArchiveOutcome {
        guard welcomeCompleted() else { return .notArchived(.benvenutoNonCompletato) }
        guard await ompReady() else { return .notArchived(.ompNonPronto) }
        guard !Task.isCancelled else { return .notArchived(.ompFermato) }
        return await pipeline.archive(next.candidate, moment: next.moment)
    }

    private func finish(_ outcome: ArchiveOutcome) {
        running = nil
        let next: DocumentoInCoda?
        switch outcome {
        case .archived(let document):
            let waiting = queue.pendingCount
            next = queue.receive(.archived)
            continuation.yield(.archiviato(document, inCoda: waiting))
        case .notArchived(let motivo):
            let waiting = queue.pendingCount
            next = queue.receive(.notArchived)
            continuation.yield(.nonArchiviato(motivo, inCoda: waiting))
        }
        if let next {
            start(next)
        }
    }
}
