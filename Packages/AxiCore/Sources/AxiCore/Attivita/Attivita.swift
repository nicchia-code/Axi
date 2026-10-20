import AxiScreen
import Foundation

/// A document that entered the vault, as the bubble of the dot shows it.
public struct DocumentoNelVault: Sendable, Equatable {
    public let titolo: String
    public let tag: [String]
    /// Attachments of an email that could not be taken, by name.
    public let allegatiNonPresi: [String]
    /// The copy in the vault, opened when the bubble is clicked.
    public let copia: URL
    /// A web page whose PDF did not match the visible text: only its text and address are in the vault.
    public let pdfNonPresente: Bool
    /// An email archived while its receipt date was not known: the bubble says so.
    public let dataRicezioneSconosciuta: Bool

    public init(
        titolo: String, tag: [String], allegatiNonPresi: [String], copia: URL,
        pdfNonPresente: Bool = false, dataRicezioneSconosciuta: Bool = false
    ) {
        self.titolo = titolo
        self.tag = tag
        self.allegatiNonPresi = allegatiNonPresi
        self.copia = copia
        self.pdfNonPresente = pdfNonPresente
        self.dataRicezioneSconosciuta = dataRicezioneSconosciuta
    }
}

/// Why a document did not enter the vault (`archiviazione.NON_ARCHIVIATO`).
public enum MotivoNonArchiviato: Sendable, Equatable {
    /// The document is already in the vault; `copia` is the copy that is there.
    case giaPresente(copia: URL)
    case ompNonPronto
    case ompFermato
    case benvenutoNonCompletato
    case documentoIllegibile
    case testoAssente
    case aiNonRisponde
    case indicizzazioneFallita
    /// The PDF of a web page could not be downloaded.
    case pdfNonScaricato
    /// The PDF of a web page is over the size limit.
    case pdfTroppoGrande
    /// An error no other reason foresees: nothing of the document stays in the vault.
    case erroreImprevisto
}

/// The Events the `attivita` Machine reacts to, from the queue, the vault, the screen reader,
/// the mini-chat, the timer of the bubble and the clicks on the bubble.
public enum EventoAttivita: Sendable, Equatable {
    /// `coda-archiviazione.PROSSIMO_DOCUMENTO`, with the documents still waiting in the queue and the origin name of the document that starts.
    case prossimoDocumento(inCoda: Int, nome: String?)
    /// `archiviazione.ARCHIVIATO`, with the documents still waiting in the queue.
    case archiviato(DocumentoNelVault, inCoda: Int)
    /// `archiviazione.NON_ARCHIVIATO`, with the documents still waiting in the queue.
    case nonArchiviato(MotivoNonArchiviato, inCoda: Int)
    /// `archiviazione/Generazione dei metadati` begins for the document being archived.
    case generazioneMetadatiIniziata
    /// The metadata step ends, with its metadata or with a failure.
    case generazioneMetadatiFinita
    /// `lettura-schermo.NESSUN_DOCUMENTO`, with the reason, and whether another archiving request waits for its search.
    case nessunDocumento(NoDocumentReason, altreRichieste: Bool = false)
    /// `utente.CHIEDE_ARCHIVIAZIONE`: the search for the document starts.
    case chiedeArchiviazione
    /// `mini-chat.NON_DISPONIBILE`.
    case chatNonDisponibile
    /// `tempo.NUVOLETTA_SCADUTA`.
    case nuvolettaScaduta
    /// `utente.CLIC_NUVOLETTA`.
    case clicNuvoletta
}

/// States of the `attivita` Machine.
public enum StatoAttivita: Sendable, Equatable {
    case nessuna
    case inRicerca
    case inCorso
    case esito
}

/// What the bubble of the dot says.
public enum Nuvoletta: Sendable, Equatable {
    /// The search, or the start of a document: `nome` is its origin name, nil while searching or when it has none.
    case archiviando(nome: String?)
    case archiviato(DocumentoNelVault, nome: String?)
    case nonArchiviato(MotivoNonArchiviato, nome: String?)
    case nessunDocumento(NoDocumentReason)
    case chatNonDisponibile

    /// The outcome the dot animates; nil while a document is being archived.
    public enum Esito: Sendable, Equatable {
        case successo
        case errore
        case giaPresente
    }

    public var esito: Esito? {
        switch self {
        case .archiviando: nil
        case .archiviato: .successo
        case .nonArchiviato(.giaPresente, _): .giaPresente
        case .nonArchiviato, .nessunDocumento, .chatNonDisponibile: .errore
        }
    }

    /// The vault copy a click on the bubble opens: an archived or already present document.
    public var copia: URL? {
        switch self {
        case .archiviando: nil
        case .archiviato(let documento, _): documento.copia
        case .nonArchiviato(.giaPresente(let copia), _): copia
        case .nonArchiviato, .nessunDocumento, .chatNonDisponibile: nil
        }
    }
}

/// The phase of `inCorso`, which decides what the bubble of the dot shows.
public enum FaseInCorso: Sendable, Equatable {
    /// The bubble shows the document being archived.
    case avvio
    /// The bubble was closed: the dot shows no bubble until the outcome.
    case senzaNuvoletta
    /// An outcome or an explanation is in the bubble, and its timer runs; the queue goes on behind it.
    case passaggio
}

/// The `attivita` Machine: the work of the archive queue as the dot shows it.
///
/// `nessuna` (idle), `inRicerca` (searching for a document), `inCorso` (working, in a `fase`, with the documents
/// waiting in the queue) and `esito` (showing the last outcome). The bubble is part of the state: it is `nil` when
/// nothing is shown. The caller runs the bubble timer while `nuvolettaScade` is true and sends `nuvolettaScaduta`.
public struct Attivita: Sendable, Equatable {
    public private(set) var stato: StatoAttivita = .nessuna
    /// The phase of `inCorso`; meaningful only while `inCorso`.
    public private(set) var fase: FaseInCorso = .avvio
    /// Documents waiting in the queue, shown while `inCorso`.
    public private(set) var inCoda = 0
    /// Origin name of the document being archived, nil when it has none or nothing is archived.
    public private(set) var nomeInCorso: String?
    public private(set) var nuvoletta: Nuvoletta?
    /// Counts every outcome and explanation shown, so that a repeated one is still a new event for the dot.
    public private(set) var esiti = 0
    /// The document being archived is in `archiviazione/Generazione dei metadati`; only while `inCorso`.
    public private(set) var generandoMetadati = false

    /// True from the request of an archiving to the last outcome: the dot shows three dots.
    public var archiviando: Bool { stato == .inRicerca || stato == .inCorso }

    /// True while the bubble leaves by itself after its timer: an explanation or an outcome, in `esito`, in `inRicerca`
    /// or in a `passaggio`. The bubble that says Axi is archiving never leaves by itself.
    public var nuvolettaScade: Bool {
        guard let nuvoletta else { return false }
        if case .archiviando = nuvoletta { return false }
        switch stato {
        case .nessuna: return false
        case .esito, .inRicerca: return true
        case .inCorso: return fase == .passaggio
        }
    }

    public init() {}

    /// Applies an Event following the Transitions of the Model. Events that the current
    /// state does not handle change nothing.
    public mutating func riceve(_ evento: EventoAttivita) {
        switch evento {
        case .chiedeArchiviazione:
            guard stato == .nessuna || stato == .esito else { return }
            stato = .inRicerca
            nuvoletta = .archiviando(nome: nil)
        case .prossimoDocumento(let inCoda, let nome):
            prossimo(inCoda: inCoda, nome: nome)
        case .generazioneMetadatiIniziata:
            guard stato == .inCorso else { return }
            generandoMetadati = true
        case .generazioneMetadatiFinita:
            generandoMetadati = false
        case .archiviato(let documento, let inCoda):
            concludi(.archiviato(documento, nome: nomeInCorso), inCoda: inCoda)
        case .nonArchiviato(let motivo, let inCoda):
            concludi(.nonArchiviato(motivo, nome: nomeInCorso), inCoda: inCoda)
        case .nessunDocumento(let motivo, let altreRichieste):
            // While another archiving request waits for its search, the dot stays in the three dots.
            mostra(.nessunDocumento(motivo), restaInRicerca: altreRichieste)
        case .chatNonDisponibile:
            mostra(.chatNonDisponibile, restaInRicerca: true)
        case .nuvolettaScaduta:
            switch (stato, fase) {
            case (.esito, _):
                nuvoletta = nil
                stato = .nessuna
            case (.inRicerca, _):
                // An explanation of the search leaves after its time, and the bubble that says Axi is archiving returns.
                nuvoletta = .archiviando(nome: nil)
            case (.inCorso, .passaggio):
                fase = .avvio
                nuvoletta = .archiviando(nome: nomeInCorso)
            default:
                break
            }
        case .clicNuvoletta:
            clic()
        }
    }

    /// A document starts. From idle, Esito or a search it begins in `avvio`, or in `senzaNuvoletta` when the bubble
    /// was closed during the search. Behind an outcome in `passaggio` it only records the queue and the name.
    private mutating func prossimo(inCoda: Int, nome: String?) {
        self.inCoda = inCoda
        nomeInCorso = nome
        switch stato {
        case .nessuna, .esito, .inRicerca:
            let chiusa = stato == .inRicerca && nuvoletta == nil
            stato = .inCorso
            fase = chiusa ? .senzaNuvoletta : .avvio
            nuvoletta = chiusa ? nil : .archiviando(nome: nome)
        case .inCorso:
            break
        }
    }

    /// An outcome closes the document: the queue goes on in `passaggio` while documents are waiting, else the work ends in Esito.
    private mutating func concludi(_ outcome: Nuvoletta, inCoda: Int) {
        guard stato == .inCorso else { return }
        generandoMetadati = false
        self.inCoda = inCoda
        nomeInCorso = nil
        nuvoletta = outcome
        esiti += 1
        if inCoda > 0 {
            fase = .passaggio
        } else {
            stato = .esito
        }
    }

    /// An explanation: during the work it goes to `passaggio`; during a search it stays searching when
    /// `restaInRicerca`; otherwise it ends in Esito.
    private mutating func mostra(_ spiegazione: Nuvoletta, restaInRicerca: Bool) {
        switch stato {
        case .inCorso:
            fase = .passaggio
        case .inRicerca where restaInRicerca:
            break
        case .nessuna, .esito, .inRicerca:
            stato = .esito
        }
        nuvoletta = spiegazione
        esiti += 1
    }

    /// A click on the bubble: it closes the bubble of a search or of the start, and the outcome leads back to the
    /// start of the next document, showing its name.
    private mutating func clic() {
        switch (stato, fase) {
        case (.esito, _):
            nuvoletta = nil
            stato = .nessuna
        case (.inRicerca, _):
            nuvoletta = nil
        case (.inCorso, .avvio):
            fase = .senzaNuvoletta
            nuvoletta = nil
        case (.inCorso, .passaggio):
            fase = .avvio
            nuvoletta = .archiviando(nome: nomeInCorso)
        case (.inCorso, .senzaNuvoletta), (.nessuna, _):
            break
        }
    }
}
