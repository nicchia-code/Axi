/// States of the `puntino` Machine.
///
/// The dot stays on screen in the visible states. Chat expands the dot from any visible state,
/// and closing it returns the dot to `aRiposo` in the same place. Hiding the dot turns it into an
/// icon in the menu bar (`nellaBarra`); from there its menu opens under the icon (`menuBarra`), and the
/// chat opens under the icon (`chatSottoBarra`).
public enum StatoPuntino: Sendable, Equatable {
    case aRiposo
    case menuAperto
    case espanso
    case nellaBarra
    case menuBarra
    case chatSottoBarra

    /// Next state for a `utente` Event, following the Transitions of the Model.
    ///
    /// With the menu open, a click on the dot has no Transition: the menu stays open.
    /// With the chat open under the icon, a click on the icon has no Transition either: the chat closes
    /// through `mini-chat.CHIUSA`.
    public func dopo(_ evento: EventoUtente) -> StatoPuntino {
        switch (self, evento) {
        case (.aRiposo, .clicPuntino):
            .menuAperto
        case (.aRiposo, .alternaPuntino), (.menuAperto, .alternaPuntino):
            .nellaBarra
        case (.menuAperto, .chiudeMenu),
             (.menuAperto, .chiedeArchiviazione), (.menuAperto, .apreImpostazioni):
            .aRiposo
        case (.espanso, .alternaPuntino):
            .chatSottoBarra
        case (.nellaBarra, .clicPuntino):
            .menuBarra
        case (.nellaBarra, .alternaPuntino), (.menuBarra, .alternaPuntino):
            .aRiposo
        case (.menuBarra, .chiudeMenu),
             (.menuBarra, .chiedeArchiviazione), (.menuBarra, .apreImpostazioni):
            .nellaBarra
        case (.chatSottoBarra, .alternaPuntino):
            .espanso
        default:
            self
        }
    }

    /// Next state for `mini-chat.APERTA` (`aperta: true`) and `mini-chat.CHIUSA` (`aperta: false`).
    public func dopoChat(aperta: Bool) -> StatoPuntino {
        switch (self, aperta) {
        case (.nellaBarra, true), (.menuBarra, true), (.chatSottoBarra, true):
            .chatSottoBarra
        case (_, true):
            .espanso
        case (.chatSottoBarra, false):
            .nellaBarra
        case (.espanso, false):
            .aRiposo
        default:
            self
        }
    }

    /// Whether the dot is hidden and lives in the menu bar as an icon.
    public var nascosto: Bool {
        switch self {
        case .nellaBarra, .menuBarra, .chatSottoBarra: true
        case .aRiposo, .menuAperto, .espanso: false
        }
    }
}
