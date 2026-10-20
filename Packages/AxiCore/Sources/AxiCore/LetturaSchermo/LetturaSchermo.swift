import AxiScreen

/// States of the `lettura-schermo` Machine.
public enum StatoLetturaSchermo: Sendable, Equatable {
    /// `Inattiva` (initial): no reading in progress.
    case inattiva
    /// `Ricerca del documento`: looking for an archivable document in the front application.
    case ricercaDelDocumento
    /// `Lettura del contesto`, in `Accessibilità` (initial) or in `Riconoscimento del testo`.
    case letturaDelContesto(FaseLetturaContesto)
}

/// The two phases of `Lettura del contesto`.
public enum FaseLetturaContesto: Sendable, Equatable {
    /// `Accessibilità`: the visible text comes from the Accessibility tree.
    case accessibilita
    /// `Riconoscimento del testo`: the visible text is recognized on the screen.
    case riconoscimentoDelTesto
}

/// The results of the `lettura-schermo` Machine, as it emits them.
public enum EsitoLetturaSchermo: Sendable, Equatable {
    /// `lettura-schermo.DOCUMENTO_INDIVIDUATO`, with the documents in order, where they come from and the moment of the reading.
    case documentoIndividuato([DocumentCandidate], ReadingMoment)
    /// `lettura-schermo.NESSUN_DOCUMENTO`, with the reason, and whether another archiving request waits for its search.
    case nessunDocumento(NoDocumentReason, altreRichieste: Bool = false)
    /// `lettura-schermo.CONTESTO_LETTO`, with the context of the front application.
    case contestoLetto(ScreenContext)
    /// `lettura-schermo.LETTURA_FALLITA`, with the reason the screen could not be read.
    case letturaFallita(ReadingFailure)
}

/// The `lettura-schermo` Machine: the document search and the reading of the context for the mini-chat.
public struct LetturaSchermo: Sendable, Equatable {
    public private(set) var stato: StatoLetturaSchermo = .inattiva

    public init() {}

    /// Applies `utente.CHIEDE_ARCHIVIAZIONE` (starts the document search) and `utente.APRE_CHAT`
    /// (starts the reading of the context, in `Accessibilità`) from `Inattiva`: returns true.
    /// Other Events change nothing and return false.
    public mutating func riceve(_ evento: EventoUtente) -> Bool {
        guard stato == .inattiva else { return false }
        switch evento {
        case .chiedeArchiviazione:
            stato = .ricercaDelDocumento
        case .apreChat:
            stato = .letturaDelContesto(.accessibilita)
        default:
            return false
        }
        return true
    }

    /// Applies a result of the reading in progress. Returns the Event to emit and goes back to `Inattiva`;
    /// `TESTO_NON_ACCESSIBILE` moves the context reading to `Riconoscimento del testo` and emits nothing.
    /// Returns nil, changing nothing, when the result does not apply to the current state.
    public mutating func concludi(_ evento: ScreenReadingEvent) -> EsitoLetturaSchermo? {
        let esito: EsitoLetturaSchermo
        switch (stato, evento) {
        case (.ricercaDelDocumento, .documentFound(let candidates, let moment)):
            esito = .documentoIndividuato(candidates, moment)
        case (.ricercaDelDocumento, .noDocument(let reason)):
            esito = .nessunDocumento(reason)
        case (.letturaDelContesto(.accessibilita), .textNotAccessible):
            stato = .letturaDelContesto(.riconoscimentoDelTesto)
            return nil
        case (.letturaDelContesto, .contextRead(let context)):
            esito = .contestoLetto(context)
        case (.letturaDelContesto(.riconoscimentoDelTesto), .readingFailed(let failure)):
            esito = .letturaFallita(failure)
        default:
            return nil
        }
        stato = .inattiva
        return esito
    }
}
