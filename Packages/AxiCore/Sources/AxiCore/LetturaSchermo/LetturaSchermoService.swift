import os
import AxiScreen
import Foundation

/// The refusals decided before the ScreenReader runs, logged with the same subsystem and category.
private let logLetturaSchermo = Logger(subsystem: "Axi", category: "lettura-schermo")

/// A request waiting for the reading in progress to end.
private enum RichiestaInAttesa {
    case archiviazione(ApplicationSnapshot?)
    case contesto(ApplicationSnapshot, CheckedContinuation<EsitoLetturaSchermo, Never>)
}

/// Runs the `lettura-schermo` Machine: it applies `utente.CHIEDE_ARCHIVIAZIONE` and `utente.APRE_CHAT`,
/// asks the `ScreenReader` to look in the application that was in front, and publishes the results on `esiti`.
///
/// Only one reading runs at a time: a request that arrives meanwhile waits in `coda`, in arrival order,
/// and starts when the reading in progress ends.
@MainActor
public final class LetturaSchermoService {
    /// `lettura-schermo` results, in order: the documents go to the archive queue, the refusals to `attivita`.
    /// The context results (`contestoLetto`, `letturaFallita`) are also published here; consumers ignore them.
    public nonisolated let esiti: AsyncStream<EsitoLetturaSchermo>

    private let continuation: AsyncStream<EsitoLetturaSchermo>.Continuation
    private let reader: ScreenReader
    private var macchina = LetturaSchermo()
    private var letture: Task<Void, Never>?
    /// Requests that arrived while a reading was in progress, in arrival order.
    private var coda: [RichiestaInAttesa] = []
    /// The mini-chat waiting for the context reading in progress, see `leggeContesto`.
    private var attesaContesto: CheckedContinuation<EsitoLetturaSchermo, Never>?

    /// - Parameter makeRecognizer: text recognition for readings that need it, chosen at each reading from the
    ///   settings (Azure when configured, Vision otherwise); the document search never does.
    ///   clock: the moment each reading records; by default the Mac's current instant and time zone.
    public init(
        accessibility: any AccessibilityReading = LiveAccessibilityReader(),
        capturer: any WindowCapturing = WindowCapturer(),
        permissions: any ScreenPermissions = SystemScreenPermissions(),
        finderSelection: any FinderSelectionReading = LiveFinderSelection(),
        makeRecognizer: @escaping @Sendable () -> any TextRecognizing = {
            RiconoscimentoTesto.riconoscitore(impostazioni: ImpostazioniStore())
        },
        clock: @escaping @Sendable () -> ReadingMoment = { .now }
    ) {
        let (esiti, continuation) = AsyncStream.makeStream(of: EsitoLetturaSchermo.self)
        self.esiti = esiti
        self.continuation = continuation

        let (eventi, eventiContinuation) = AsyncStream.makeStream(of: ScreenReadingEvent.self)
        reader = ScreenReader(
            accessibility: accessibility,
            capturer: capturer,
            permissions: permissions,
            finderSelection: finderSelection,
            makeRecognizer: makeRecognizer,
            clock: clock,
            emit: { eventiContinuation.yield($0) })

        letture = Task { [weak self] in
            for await evento in eventi {
                self?.ricevi(evento)
            }
        }
    }

    /// Receives `utente.CHIEDE_ARCHIVIAZIONE`. `target` is the application that was in front when the user asked,
    /// or nil when there was none (or Axi itself was in front). The Event `apreChat` is not handled here:
    /// see `leggeContesto`. Other Events change nothing.
    public func riceve(_ evento: EventoUtente, target: ApplicationSnapshot?) {
        guard evento == .chiedeArchiviazione else { return }
        accoda(.archiviazione(target))
    }

    /// Lettura del contesto for the mini-chat. `utente.APRE_CHAT` asks for it on the application that was in front
    /// when the user asked (`target`). The request waits its turn behind the readings in progress, and the call
    /// returns its outcome: `contestoLetto` or `letturaFallita`. Returns nil, changing no state, when there is no
    /// application to read; that refusal is logged.
    public func leggeContesto(target: ApplicationSnapshot?) async -> EsitoLetturaSchermo? {
        guard let target else {
            // Nothing in front to read: the chat gets no screen context, and the refusal is logged.
            logLetturaSchermo.notice("Context reading refused: reason=nothingInFront app=none in front")
            return nil
        }
        return await withCheckedContinuation { (attesa: CheckedContinuation<EsitoLetturaSchermo, Never>) in
            accoda(.contesto(target, attesa))
        }
    }

    /// Puts a request at the end of the queue and starts the first one if no reading is in progress.
    private func accoda(_ richiesta: RichiestaInAttesa) {
        coda.append(richiesta)
        avviaProssima()
    }

    /// Starts the first request of the queue, when no reading is in progress.
    private func avviaProssima() {
        guard macchina.stato == .inattiva, !coda.isEmpty else { return }
        switch coda.removeFirst() {
        case .archiviazione(let target):
            _ = macchina.riceve(.chiedeArchiviazione)
            guard let target else {
                // Nothing in front to search: the search ends without a document.
                logLetturaSchermo.notice("Document search refused: reason=nothingInFront app=none in front")
                ricevi(.noDocument(.nothingInFront))
                return
            }
            avvia(ReadingRequest(purpose: .archiving, target: target))
        case .contesto(let target, let attesa):
            // The state is Inattiva, checked above: the Event starts the reading.
            _ = macchina.riceve(.apreChat)
            attesaContesto = attesa
            avvia(ReadingRequest(purpose: .chat, target: target))
        }
    }

    private func avvia(_ request: ReadingRequest) {
        let reader = reader
        Task {
            await reader.handle(request)
        }
    }

    private func ricevi(_ evento: ScreenReadingEvent) {
        guard let risultato = macchina.concludi(evento) else { return }
        let esito: EsitoLetturaSchermo
        if case .nessunDocumento(let motivo, _) = risultato {
            // Another archiving request waits for its own search: the dot keeps the three dots.
            let altreRichieste = coda.contains { richiesta in
                if case .archiviazione = richiesta { return true }
                return false
            }
            esito = .nessunDocumento(motivo, altreRichieste: altreRichieste)
        } else {
            esito = risultato
        }
        continuation.yield(esito)
        if let attesa = attesaContesto {
            attesaContesto = nil
            attesa.resume(returning: esito)
        }
        avviaProssima()
    }
}
