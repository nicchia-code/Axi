import AppKit
import AxiCore
import AxiScreen
import SwiftUI

/// Runs the `permessi` Machine: the Permissions window is closed or open. Its Events come from the launch check,
/// the mini-chat and the window itself.
@MainActor
final class PermessiController: NSObject, NSWindowDelegate {
    private(set) var stato: StatoPermessi = .controllo
    private let modello: PermessiModel
    private var finestra: NSWindow?
    /// Reads the permissions every second while the window is open.
    private var lettura: Task<Void, Never>?

    /// The model is shared with the settings' Permissions section, so a request made in either shows in both.
    init(modello: PermessiModel) {
        self.modello = modello
        super.init()
    }

    /// The Controllo state at launch: it reads the permissions when the welcome is completed. `PERMESSI_MANCANTI` opens
    /// the window when one of them counts as missing, `PERMESSI_CONCESSI` leaves it closed otherwise.
    /// While the welcome is not completed the check does not run and the window stays closed: the welcome asks the permissions itself.
    /// The readings run off the main thread, so launching Axi is not blocked.
    func controllaAllAvvio(store: BenvenutoStore = BenvenutoStore(fileURL: BenvenutoStore.defaultFileURL)) {
        guard store.isCompleted() else {
            stato = .chiuse
            return
        }
        Task {
            let mancanti = await Task.detached { Permissions.missingAtStartup() }.value
            riceveAvvio(mancanti.isEmpty ? .concessi : .mancanti(mancanti))
        }
    }

    /// Applies the Event of the launch check. `PERMESSI_MANCANTI` opens the window, which then reads the permissions itself.
    private func riceveAvvio(_ evento: EventoPermessi) {
        stato = stato.dopo(evento)
        if case .mancanti = evento {
            mostra()
        }
    }

    /// Receives a `utente` Event of this Machine: `apriPermessi`, `chiudePermessi`, `chiedePermesso` or `riapreAxi`.
    /// `chiedePermesso` comes from the window's rows and is taken only while it is open. Other Events are ignored, as the
    /// Model has no Transition for them; none is taken while the launch check runs.
    func riceve(_ evento: EventoUtente) {
        guard stato != .controllo else { return }
        switch evento {
        case .apriPermessi:
            mostra()
        case .chiudePermessi:
            finestra?.close()
        case .chiedePermesso(let permesso):
            // Asking is a Transition of the open window only: a closed window takes no request.
            guard stato == .aperte else { return }
            Task { await modello.chiede(permesso) }
        case .riapreAxi:
            // The restart is the app's (AppDelegate). This window only takes the state change, which a closed window does not.
            break
        default:
            return
        }
        stato = stato.dopo(evento)
    }

    /// The window was closed by the user, which is `utente.CHIUDE_PERMESSI`.
    func windowWillClose(_ notification: Notification) {
        lettura?.cancel()
        lettura = nil
        finestra = nil
        stato = stato.dopo(.chiudePermessi)
    }

    private func mostra() {
        if let finestra {
            // Already open: bring it to the front, state unchanged.
            NSApp.activate()
            finestra.makeKeyAndOrderFront(nil)
            return
        }
        modello.refresh()
        let nuova = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        nuova.title = String(localized: "Axi permissions")
        nuova.isReleasedWhenClosed = false
        nuova.delegate = self
        let hosting = NSHostingController(
            rootView: PermessiView(model: modello, onEvento: { [weak self] evento in self?.riceve(evento) }))
        hosting.sizingOptions = .preferredContentSize
        nuova.contentViewController = hosting
        nuova.center()
        finestra = nuova
        NSApp.activate()
        nuova.makeKeyAndOrderFront(nil)
        avviaLettura()
    }

    /// Reads the permissions every second while the window is open. When all are granted, the window says so
    /// and closes by itself after 2 seconds.
    private func avviaLettura() {
        lettura?.cancel()
        lettura = Task {
            while !Task.isCancelled {
                modello.refresh()
                if modello.tuttoPronto {
                    stato = stato.dopo(.concessi)
                    try? await Task.sleep(for: .seconds(2))
                    if !Task.isCancelled { finestra?.close() }
                    return
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
