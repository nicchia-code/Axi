import AxiScreen
import Foundation

/// States of the `permessi` Machine: the launch check (Controllo), then the Permissions window is closed or open.
///
/// At launch the check reads the permissions (`EventoPermessi`) when the welcome is completed. It opens the window when a
/// permission counts as missing (`PERMESSI_MANCANTI`), and otherwise leaves it closed (`PERMESSI_CONCESSI`). The window
/// also opens from the chat through `utente.APRE_PERMESSI`, closes by `utente.CHIUDE_PERMESSI`, or by itself when every
/// permission is granted (`PERMESSI_CONCESSI`). Asking a permission keeps it open.
public enum StatoPermessi: Sendable, Equatable {
    /// The launch check is running: the Machine has no `utente` Transition here, so its Events wait.
    case controllo
    case chiuse
    case aperte

    /// Next state for a `utente` Event, following the Transitions of the Model.
    /// `riapreAxi` ends this run: the next run starts again from the check at launch, so the Machine goes back to Controllo.
    public func dopo(_ evento: EventoUtente) -> StatoPermessi {
        if self == .controllo {
            return self
        }
        switch evento {
        case .apriPermessi:
            return .aperte
        case .chiudePermessi:
            return .chiuse
        case .riapreAxi:
            // A closed window has no Transition for it: only the open one ends the run.
            return self == .aperte ? .controllo : self
        default:
            return self
        }
    }

    /// Next state for a `permessi` Event emitted by the launch check. `PERMESSI_CONCESSI` closes the window from any state;
    /// `PERMESSI_MANCANTI` opens it only from Controllo, the one place that emits it.
    public func dopo(_ evento: EventoPermessi) -> StatoPermessi {
        switch evento {
        case .concessi:
            return .chiuse
        case .mancanti:
            return self == .controllo ? .aperte : self
        }
    }
}

/// The `permessi` Events that the launch check emits, with the permissions that count as missing.
public enum EventoPermessi: Sendable, Equatable {
    /// `permessi.PERMESSI_CONCESSI`: every permission that counts is granted.
    case concessi
    /// `permessi.PERMESSI_MANCANTI`: at least one permission that counts is missing.
    case mancanti([Permissions.Permission])
}
