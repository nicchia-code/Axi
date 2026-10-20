import AxiCore
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Archivia (⌥A): produces `utente.CHIEDE_ARCHIVIAZIONE`.
    nonisolated(unsafe) static let archivia = Self("archivia", default: .init(.a, modifiers: [.option]))
    /// Chat (⌥Space): produces `utente.APRE_CHAT` or `utente.CHIUDE_CHAT`.
    ///
    /// Default ⌥Space, as the Requirements ask. F4 (the Spotlight key of Apple keyboards) can still be recorded in the Settings window.
    nonisolated(unsafe) static let chat = Self("chat", default: .init(.space, modifiers: [.option]))
    /// Nascondi/Mostra (⌥H): produces `utente.ALTERNA_PUNTINO`, which hides the dot in the menu bar or shows it again.
    nonisolated(unsafe) static let alterna = Self("alterna", default: .init(.h, modifiers: [.option]))
}

/// Registers the global shortcuts: the app in front is stored at the press, and each release turns it into a `utente` Event.
@MainActor
final class Scorciatoie {
    private let sink: @MainActor (EventoUtente) -> Void
    private let chatAperta: @MainActor () -> Bool
    private let memoria: AppInPrimoPiano

    /// - Parameters:
    ///   - memoria: remembers the app in front when a shortcut is pressed.
    ///   - chatAperta: whether the mini-chat window is open now.
    ///   - sink: receives the Events produced by the shortcuts.
    init(
        memoria: AppInPrimoPiano,
        chatAperta: @escaping @MainActor () -> Bool,
        sink: @escaping @MainActor (EventoUtente) -> Void
    ) {
        self.memoria = memoria
        self.chatAperta = chatAperta
        self.sink = sink
    }

    /// The shortcuts held down now: a key repeat while held does not store the app again.
    private var premute: Set<KeyboardShortcuts.Name> = []

    func registra() {
        KeyboardShortcuts.onKeyDown(for: .archivia) { [self] in
            premi(.archivia)
        }
        KeyboardShortcuts.onKeyUp(for: .archivia) { [self] in
            rilascia(.archivia, name: .archivia)
        }
        KeyboardShortcuts.onKeyDown(for: .chat) { [self] in
            premi(.chat)
        }
        KeyboardShortcuts.onKeyUp(for: .chat) { [self] in
            rilascia(.chat, name: .chat)
        }
        KeyboardShortcuts.onKeyDown(for: .alterna) { [self] in
            premi(.alterna)
        }
        KeyboardShortcuts.onKeyUp(for: .alterna) { [self] in
            rilascia(.alterna, name: .alterna)
        }
    }

    /// Stores the app in front at the press, once per press; the Event waits for the release.
    private func premi(_ name: KeyboardShortcuts.Name) {
        guard premute.insert(name).inserted else { return }
        memoria.registraAppInPrimoPiano()
    }

    /// Produces the Event at the release, using the app stored at the press.
    private func rilascia(_ scorciatoia: Scorciatoia, name: KeyboardShortcuts.Name) {
        premute.remove(name)
        sink(scorciatoia.evento(chatAperta: chatAperta()))
    }

    /// Restores the default shortcuts.
    static func ripristinaPredefinite() {
        KeyboardShortcuts.reset([.archivia, .chat, .alterna])
    }
}
