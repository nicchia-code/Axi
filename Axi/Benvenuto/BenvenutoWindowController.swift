import AppKit
import AxiCore
import AxiOMP
import SwiftUI

/// Owns the welcome window. The app keeps a reference while it is open.
@MainActor
final class BenvenutoWindowController: NSWindowController {
    /// Opens the welcome window when it is not completed yet; returns nil when it is already completed.
    /// Closing the window only hides it: it comes back at the next launch.
    static func showIfNeeded(
        omp: OMPConnection,
        permessi: PermessiModel,
        sink: @escaping @MainActor (EventoUtente) -> Void,
        store: BenvenutoStore = BenvenutoStore(fileURL: BenvenutoStore.defaultFileURL)
    ) -> BenvenutoWindowController? {
        guard !store.isCompleted() else { return nil }
        let controller = BenvenutoWindowController(omp: omp, store: store, permessi: permessi, sink: sink)
        controller.showWindow(nil)
        controller.window?.center()
        NSApp.activate()
        return controller
    }

    private init(
        omp: OMPConnection,
        store: BenvenutoStore,
        permessi: PermessiModel,
        sink: @escaping @MainActor (EventoUtente) -> Void
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 470),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        super.init(window: window)
        let model = BenvenutoModel(omp: omp, permessi: permessi, sink: sink, store: store)
        window.contentViewController = NSHostingController(
            rootView: BenvenutoView(model: model, close: { [weak window] in window?.close() }))
    }

    required init?(coder: NSCoder) {
        fatalError("BenvenutoWindowController is created in code only")
    }
}
