import AxiCore
import Observation

/// What the dot and its menu show. Written only by `PuntinoController`.
@MainActor
@Observable
final class PuntinoModello {
    var stato: StatoPuntino = .aRiposo
    var attivita = Attivita()
    /// Files are being dragged over the dot.
    var riceveFile = false
    /// The Spotlight and Dictation keys are Axi's and Accessibility is granted: the menu shows the key symbols. Read at each opening.
    var mostraSimboliTasti = false
    /// The radial menu is on screen; stays `true` while its close animation runs.
    var menuVisibile = false
    /// The mini-chat is answering: the dot shows the three dots until it stops.
    var chatRisponde = false

    /// What the character shows, by precedence: an outcome shows still, then the three dots while an archiving
    /// runs (from the request to the last outcome) or the mini-chat answers, then the wait, then rest.
    func aspetto(segnale: Bool) -> PuntinoAspetto {
        if !segnale, attivita.archiviando || chatRisponde { return .trePuntini }
        return animato(segnale: segnale) ? .attesa : .fermo
    }

    /// The wait animation plays while the user interacts with the dot or files are dragged over it, unless an outcome is showing.
    private func animato(segnale: Bool) -> Bool {
        !segnale && (
            stato == .menuAperto || stato == .menuBarra
                || stato == .espanso || stato == .chatSottoBarra
                || riceveFile
        )
    }
}
