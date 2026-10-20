import AppKit
import SwiftUI

/// Window of the mini-chat. Unlike the dot's windows it can become key, so the question field takes the keyboard;
/// it still never becomes main and never activates Axi.
final class PannelloChat: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Esc closes the chat, as the close button does. Only a key window receives it, so Esc typed in other apps never reaches here.
    override func cancelOperation(_ sender: Any?) {
        guard let onEsc else { return super.cancelOperation(sender) }
        onEsc()
    }

    /// Minimum size declared by the chat view (`minWidth`, `minHeight`).
    static let minimoSize = NSSize(width: 320, height: 400)

    /// Called when Esc reaches the window: the text field, while it edits, passes it up the responder chain.
    var onEsc: (@MainActor () -> Void)?

    init(size: NSSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        minSize = Self.minimoSize
    }

    /// Keeps the panel entirely inside the visible part of the screen, also while it is resized.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        guard let visibile = (screen ?? self.screen)?.visibleFrame else { return frameRect }
        var rect = frameRect
        rect.size.width = min(rect.width, visibile.width)
        rect.size.height = min(rect.height, visibile.height)
        rect.origin.x = min(max(rect.minX, visibile.minX), visibile.maxX - rect.width)
        rect.origin.y = min(max(rect.minY, visibile.minY), visibile.maxY - rect.height)
        return rect
    }
}

/// Where the mini-chat is anchored: beside the dot while the dot is shown, or under its icon in the
/// menu bar while the dot is hidden.
enum AncoraggioChat {
    case puntino(NSRect)
    case barra(NSRect)

    var rect: NSRect {
        switch self {
        case .puntino(let rect), .barra(let rect): rect
        }
    }
}

/// Where the mini-chat sits beside the dot: on the side with more room, vertically centred on it,
/// kept inside the visible part of the screen.
enum MiniChatPlacement {
    static let size = NSSize(width: 380, height: 520)
    static let gap: CGFloat = 8

    static func frame(anchoredTo dot: NSRect, visibleFrame: NSRect) -> NSRect {
        let spazioDestra = visibleFrame.maxX - dot.maxX
        let spazioSinistra = dot.minX - visibleFrame.minX
        let x = spazioDestra >= spazioSinistra
            ? dot.maxX + gap
            : dot.minX - gap - size.width
        let y = dot.midY - size.height / 2
        return NSRect(
            x: clamp(x, from: visibleFrame.minX, to: visibleFrame.maxX - size.width),
            y: clamp(y, from: visibleFrame.minY, to: visibleFrame.maxY - size.height),
            width: size.width,
            height: size.height
        )
    }

    /// Under the icon in the menu bar, centred on it and kept inside the visible part of the screen.
    static func frame(sottoBarra icona: NSRect, visibleFrame: NSRect) -> NSRect {
        let x = icona.midX - size.width / 2
        let y = icona.minY - gap - size.height
        return NSRect(
            x: clamp(x, from: visibleFrame.minX, to: visibleFrame.maxX - size.width),
            y: clamp(y, from: visibleFrame.minY, to: visibleFrame.maxY - size.height),
            width: size.width,
            height: size.height
        )
    }

    /// Origin of a bubble of `size` laid over the top of the open chat, centred on it and kept inside the visible screen.
    static func bubbleOrigin(overlayingTopOf chat: NSRect, size: NSSize, visibleFrame: NSRect) -> NSPoint {
        let x = chat.midX - size.width / 2
        let y = chat.maxY - gap - size.height
        return NSPoint(
            x: clamp(x, from: visibleFrame.minX, to: visibleFrame.maxX - size.width),
            y: clamp(y, from: visibleFrame.minY, to: visibleFrame.maxY - size.height)
        )
    }

    static func frame(for ancoraggio: AncoraggioChat, visibleFrame: NSRect) -> NSRect {
        switch ancoraggio {
        case .puntino(let dot): frame(anchoredTo: dot, visibleFrame: visibleFrame)
        case .barra(let icona): frame(sottoBarra: icona, visibleFrame: visibleFrame)
        }
    }

    private static func clamp(_ value: CGFloat, from low: CGFloat, to high: CGFloat) -> CGFloat {
        min(max(value, low), high)
    }
}

/// Shows the mini-chat as a window that grows out of the dot and returns into it when closed.
@MainActor
final class MiniChatWindowController {
    private let panel: PannelloChat
    private let ancora: @MainActor () -> AncoraggioChat
    private var hideTask: Task<Void, Never>?
    /// Whether the chat is open: only then it follows the dot. False while it shrinks back into the dot.
    private var aperta = false

    /// `ancora` gives the current anchor, so the chat follows the dot where it was moved, or the icon while the dot is hidden.
    init(controller: MiniChatController, ancora: @escaping @MainActor () -> AncoraggioChat) {
        self.ancora = ancora
        panel = PannelloChat(size: MiniChatPlacement.size)
        panel.contentView = NSHostingView(rootView: MiniChatView(controller: controller))
        panel.onEsc = { [weak controller] in
            guard let controller, controller.isOpen else { return }
            controller.send(.closeChat)
        }
    }

    /// Expands from the dot into the chat, which takes the keyboard.
    func mostra() {
        hideTask?.cancel()
        aperta = true
        let ancoraggio = ancora()
        let origine = ancoraggio.rect
        let destinazione = MiniChatPlacement.frame(for: ancoraggio, visibleFrame: schermo(vicino: origine))
        panel.alphaValue = 0
        panel.setFrame(origine, display: false)
        panel.makeKeyAndOrderFront(nil)
        anima(verso: destinazione, opacita: 1)
    }

    /// Shrinks back into the dot, then leaves the screen.
    func nascondi() {
        aperta = false
        let destinazione = ancora().rect
        anima(verso: destinazione, opacita: 0)
        hideTask?.cancel()
        let panel = self.panel
        let durata = Self.durata
        hideTask = Task {
            try? await Task.sleep(for: .seconds(durata))
            guard !Task.isCancelled else { return }
            panel.orderOut(nil)
        }
    }

    /// Moves the open chat with the dot, so it keeps its place beside it. Called after each move of the dot.
    func riposiziona() {
        guard aperta else { return }
        panel.setFrame(frameAperta, display: true)
    }

    /// Where the open chat sits now: its final frame, also while it is still animating in.
    var frameAperta: NSRect {
        let ancoraggio = ancora()
        return MiniChatPlacement.frame(for: ancoraggio, visibleFrame: schermo(vicino: ancoraggio.rect))
    }

    private func anima(verso frame: NSRect, opacita: CGFloat) {
        let panel = self.panel
        NSAnimationContext.runAnimationGroup { contesto in
            contesto.duration = Self.durata
            contesto.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
            panel.animator().alphaValue = opacita
        }
    }

    /// The motion is skipped for users who reduce motion.
    private static var durata: TimeInterval {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.25
    }

    /// Visible area of the screen that holds the dot's centre; the main screen when none does.
    private func schermo(vicino dot: NSRect) -> NSRect {
        let centro = NSPoint(x: dot.midX, y: dot.midY)
        let schermo = NSScreen.screens.first { $0.frame.contains(centro) } ?? NSScreen.main
        return schermo?.visibleFrame ?? dot
    }
}

/// Carries the mini-chat's events to the app. The handler runs on the main actor, after the event is posted.
struct MiniChatEventRelay: MiniChatEventSink {
    let handler: @MainActor @Sendable (MiniChatEvent) -> Void

    func post(_ event: MiniChatEvent) {
        Task { @MainActor in handler(event) }
    }
}
