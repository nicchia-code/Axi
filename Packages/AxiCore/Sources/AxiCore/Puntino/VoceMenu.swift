/// The five items of the radial menu of the dot, in their order on screen.
public enum VoceMenu: Sendable, Equatable, CaseIterable {
    case archivia
    case chat
    case impostazioni
    case nascondi
    case esci

    /// The global shortcut of the item, shown next to it. Settings and Esci have none.
    public var scorciatoia: Scorciatoia? {
        switch self {
        case .archivia: .archivia
        case .chat: .chat
        case .nascondi: .alterna
        case .impostazioni, .esci: nil
        }
    }

    /// The SF Symbol shown in place of the shortcut when the Spotlight and Dictation keys are Axi's:
    /// the microphone (Dictation key) for Archivia, the lens (Spotlight key) for Chat. `nil` otherwise,
    /// so the item shows its shortcut.
    public func simboloTasto(tastiAxi: Bool) -> String? {
        guard tastiAxi else { return nil }
        switch self {
        case .archivia: return "mic"
        case .chat: return "magnifyingglass"
        case .impostazioni, .nascondi, .esci: return nil
        }
    }

    /// The `utente` Event the item produces. The shortcut items produce the same Event as their
    /// shortcut. `nil` for Esci, which quits Axi without an Event.
    public func evento(chatAperta: Bool) -> EventoUtente? {
        switch self {
        case .impostazioni: .apreImpostazioni
        case .esci: nil
        case .archivia, .chat, .nascondi: scorciatoia?.evento(chatAperta: chatAperta)
        }
    }
}

/// The items of the menu of the icon in the menu bar after Mostra, in their order on screen.
public let vociBarra: [VoceMenu] = [.archivia, .chat, .impostazioni, .esci]

