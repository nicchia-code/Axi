import AxiScreen
import Foundation

/// The `utente` Events produced by the Settings window, the global shortcuts, the dot and the mini-chat.
/// The other Events of `utente` come from the Task views that own them.
public enum EventoUtente: Sendable, Equatable {
    case apreImpostazioni
    case chiudeImpostazioni
    case cambiaPercorsoOMP(percorso: String)
    case chiedeArchiviazione
    case apreChat
    case chiudeChat
    case clicPuntino
    case alternaPuntino
    case chiudeMenu
    case rilasciaFile(urls: [URL])
    case apriPermessi
    case chiedePermesso(Permissions.Permission)
    case riapreAxi
    case chiudePermessi
}
