/// The global shortcuts of Axi and the `utente` Event each one produces.
public enum Scorciatoia: Sendable, Equatable, CaseIterable {
    case archivia
    case chat
    case alterna

    /// The Event produced when the shortcut is pressed. `chatAperta` tells whether the
    /// mini-chat is open now: the Chat shortcut closes it, or opens it when it is closed.
    public func evento(chatAperta: Bool) -> EventoUtente {
        switch self {
        case .archivia:
            .chiedeArchiviazione
        case .chat:
            chatAperta ? .chiudeChat : .apreChat
        case .alterna:
            .alternaPuntino
        }
    }
}
