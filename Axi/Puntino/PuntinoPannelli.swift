import AppKit
import SwiftUI
import AxiCore
import KeyboardShortcuts

/// Window of the dot, its menu and its bubble. It never becomes key or main, so using it
/// does not activate Axi, and it floats above every Space and full screen app.
final class PannelloPuntino: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(size: NSSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
    }
}

/// Hosting view for the panels. Accepts the first click without activating Axi.
/// When `alClic` is set (the dot only) it also handles dragging the window and dropping files.
final class Superficie<Content: View>: NSHostingView<Content> {
    /// Called on a click that did not move the window.
    var alClic: (() -> Void)?
    /// Called after the window was dragged to a new place.
    var alTrascinata: (() -> Void)?
    /// Files are dragged over the view (`true`) or leave it / are dropped (`false`).
    var alPassaggioFile: ((Bool) -> Void)?
    /// Files dropped on the view.
    var alRilascioFile: (([URL]) -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard let window, alClic != nil else {
            super.mouseDown(with: event)
            return
        }
        let origine = window.frame.origin
        // Runs the drag loop until the mouse button is released.
        window.performDrag(with: event)
        if window.frame.origin == origine {
            alClic?()
        } else {
            alTrascinata?()
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard alRilascioFile != nil else { return [] }
        alPassaggioFile?(true)
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        alPassaggioFile?(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        alPassaggioFile?(false)
        let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []
        guard !urls.isEmpty else { return false }
        alRilascioFile?(urls)
        return true
    }
}

/// The items of the dot's menu in the menu bar: Mostra first, then the radial items.
enum VoceBarra {
    /// Shows the dot again, where it was last shown.
    case mostra
    case voce(VoceMenu)
}

/// The dot's icon in the menu bar, present while the dot is hidden. It has a fixed autosave name, so
/// its place in the bar is kept when it is created again. A click is reported through `onClick`, which
/// shows the menu with `mostraMenu`. Files dropped on the icon are reported through the drop callbacks.
@MainActor
final class ElementoBarra: NSObject, NSMenuDelegate {
    static let nomeAutosave = "AxiPuntino"

    private let onClick: @MainActor () -> Void
    private let onApertura: @MainActor () -> Void
    private let modello: PuntinoModello
    private let item: NSStatusItem
    /// Draws the character on the button as a template image.
    private var icona: IconaBarra?
    /// The item chosen in the open menu, set by its action and read once the menu has closed.
    private var scelta: VoceBarra?

    init(
        modello: PuntinoModello,
        onClick: @escaping @MainActor () -> Void,
        onApertura: @escaping @MainActor () -> Void,
        alPassaggioFile: @escaping @MainActor (Bool) -> Void,
        alRilascioFile: @escaping @MainActor ([URL]) -> Void
    ) {
        self.onClick = onClick
        self.onApertura = onApertura
        self.modello = modello
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        osservaContatore()
        item.autosaveName = Self.nomeAutosave
        guard let bottone = item.button else { return }
        icona = IconaBarra(modello: modello, bottone: bottone)
        bottone.target = self
        bottone.action = #selector(clic)

        let copertina = CopertinaBarra(bottone: bottone)
        copertina.autoresizingMask = [.width, .height]
        copertina.frame = bottone.bounds
        copertina.alPassaggioFile = alPassaggioFile
        copertina.alRilascioFile = alRilascioFile
        bottone.addSubview(copertina)
    }

    /// Frame of the icon on the screen, or `nil` when the menu bar does not show it (a full screen app hides the bar).
    func frameSulloSchermo() -> NSRect? {
        guard let bottone = item.button, let finestra = bottone.window else { return nil }
        let rect = finestra.convertToScreen(bottone.convert(bottone.bounds, to: nil))
        let centro = NSPoint(x: rect.midX, y: rect.midY)
        return NSScreen.screens.contains { $0.frame.contains(centro) } ? rect : nil
    }

    /// Sizes the item to hold the whole icon: the character alone, or with the queue count beside it, as a circle
    /// for one digit and a capsule for more. It runs again whenever the model changes.
    private func osservaContatore() {
        let larghezza = withObservationTracking { () -> CGFloat in
            let contatore = modello.attivita.stato == .inCorso && modello.attivita.inCoda > 0
                ? "\(modello.attivita.inCoda)"
                : nil
            return PuntinoBarraTemplate.larghezza(contatore: contatore)
        } onChange: { [weak self] in
            Task { @MainActor in self?.osservaContatore() }
        }
        item.length = larghezza
    }

    /// Shows the menu of the icon and returns the item chosen, or `nil` when it closes without a choice.
    /// Blocks until the menu closes, so the caller applies the choice afterwards.
    func mostraMenu(simboliTasti: Bool) -> VoceBarra? {
        guard let bottone = item.button else { return nil }
        scelta = nil
        bottone.highlight(true)
        item.popUpMenu(costruisciMenu(simboliTasti: simboliTasti))
        bottone.highlight(false)
        return scelta
    }

    /// Takes the icon out of the menu bar.
    func rimuovi() {
        icona?.ferma()
        icona = nil
        NSStatusBar.system.removeStatusItem(item)
    }

    private func costruisciMenu(simboliTasti: Bool) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        menu.addItem(voceMenu(.mostra, titolo: "Show", simbolo: "eye", scorciatoia: .alterna, simboloTasto: nil))
        menu.addItem(.separator())
        for voce in vociBarra {
            menu.addItem(voceMenu(
                .voce(voce),
                titolo: voce.titolo,
                simbolo: voce.simbolo,
                scorciatoia: voce.scorciatoia,
                simboloTasto: voce.simboloTasto(tastiAxi: simboliTasti)
            ))
        }
        return menu
    }

    /// An item of the menu. The key symbol replaces the shortcut when the Spotlight and Dictation keys are Axi's.
    private func voceMenu(
        _ voce: VoceBarra,
        titolo: LocalizedStringResource,
        simbolo: String,
        scorciatoia: Scorciatoia?,
        simboloTasto: String?
    ) -> NSMenuItem {
        let elemento = NSMenuItem(title: String(localized: titolo), action: #selector(sceglie(_:)), keyEquivalent: "")
        elemento.target = self
        elemento.representedObject = voce
        elemento.image = NSImage(systemSymbolName: simbolo, accessibilityDescription: nil)
        if let simboloTasto, let immagine = NSImage(systemSymbolName: simboloTasto, accessibilityDescription: nil) {
            let allegato = NSTextAttachment()
            allegato.image = immagine
            let testo = NSMutableAttributedString(string: String(localized: titolo) + " ")
            testo.append(NSAttributedString(attachment: allegato))
            elemento.attributedTitle = testo
        } else if let scorciatoia {
            elemento.setShortcut(for: scorciatoia.nome)
        }
        return elemento
    }

    @objc private func sceglie(_ sender: NSMenuItem) {
        scelta = sender.representedObject as? VoceBarra
    }

    func menuWillOpen(_ menu: NSMenu) {
        onApertura()
    }

    @objc private func clic() {
        onClick()
    }
}

/// Covers the icon in the menu bar: a press is passed to the button as a click, and files dropped on it are
/// reported to the owner, like on the dot.
final class CopertinaBarra: NSView {
    private weak var bottone: NSButton?
    var alPassaggioFile: (@MainActor (Bool) -> Void)?
    var alRilascioFile: (@MainActor ([URL]) -> Void)?

    init(bottone: NSButton) {
        self.bottone = bottone
        super.init(frame: bottone.bounds)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        bottone?.performClick(nil)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        alPassaggioFile?(true)
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        alPassaggioFile?(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        alPassaggioFile?(false)
        let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] ?? []
        guard !urls.isEmpty else { return false }
        alRilascioFile?(urls)
        return true
    }
}
