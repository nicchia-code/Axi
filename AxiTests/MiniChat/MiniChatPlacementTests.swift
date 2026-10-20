import AppKit
import Foundation
import Testing
@testable import Axi

@Suite("Mini-chat placement")
struct MiniChatPlacementTests {
    private let screen = NSRect(x: 0, y: 0, width: 1440, height: 900)

    @Test("A dot with more room on its right opens the chat beside it, on the right, vertically centred on the dot")
    func opensOnRoomierSide() {
        let dot = NSRect(x: 600, y: 420, width: 56, height: 56)
        let frame = MiniChatPlacement.frame(anchoredTo: dot, visibleFrame: screen)

        #expect(frame.minX == dot.maxX + MiniChatPlacement.gap)
        #expect(frame.midY == dot.midY)
        #expect(frame.size == MiniChatPlacement.size)
    }

    @Test("A dot near the right edge opens the chat on its left, beside the dot")
    func opensOnLeftNearRightEdge() {
        let dot = NSRect(x: 1380, y: 420, width: 56, height: 56)
        let frame = MiniChatPlacement.frame(anchoredTo: dot, visibleFrame: screen)

        #expect(frame.maxX == dot.minX - MiniChatPlacement.gap)
        #expect(frame.midY == dot.midY)
    }

    @Test("A dot near the top of the screen keeps the chat inside the visible screen")
    func clampsToTopEdge() {
        let dot = NSRect(x: 600, y: 820, width: 56, height: 56)
        let frame = MiniChatPlacement.frame(anchoredTo: dot, visibleFrame: screen)

        #expect(frame.maxY == screen.maxY)
        #expect(frame.minX == dot.maxX + MiniChatPlacement.gap)
    }

    @Test("The chat stays inside the visible screen near any edge")
    func staysOnScreen() {
        for dot in [
            NSRect(x: 100, y: 0, width: 60, height: 60),
            NSRect(x: 1380, y: 840, width: 60, height: 60),
        ] {
            let frame = MiniChatPlacement.frame(anchoredTo: dot, visibleFrame: screen)

            #expect(frame.minY >= screen.minY)
            #expect(frame.maxY <= screen.maxY)
            #expect(frame.minX >= screen.minX)
            #expect(frame.maxX <= screen.maxX)
        }
    }

    @Test("With the dot hidden, the chat opens under the menu bar icon, centred on it")
    func opensUnderIcon() {
        let icona = NSRect(x: 900, y: 876, width: 24, height: 24)
        let frame = MiniChatPlacement.frame(sottoBarra: icona, visibleFrame: screen)

        #expect(frame.midX == icona.midX)
        #expect(frame.maxY == icona.minY - MiniChatPlacement.gap)
        #expect(frame.size == MiniChatPlacement.size)
    }

    @Test("An icon near the left edge keeps the chat inside the visible screen")
    func clampsUnderIconNearEdge() {
        let icona = NSRect(x: 0, y: 876, width: 24, height: 24)
        let frame = MiniChatPlacement.frame(sottoBarra: icona, visibleFrame: screen)

        #expect(frame.minX == screen.minX)
        #expect(frame.maxX <= screen.maxX)
    }

    @Test("The anchor picks the beside-dot or under-icon placement")
    func frameForAncoraggio() {
        let dot = NSRect(x: 600, y: 420, width: 56, height: 56)
        let icona = NSRect(x: 900, y: 876, width: 24, height: 24)

        #expect(MiniChatPlacement.frame(for: .puntino(dot), visibleFrame: screen)
            == MiniChatPlacement.frame(anchoredTo: dot, visibleFrame: screen))
        #expect(MiniChatPlacement.frame(for: .barra(icona), visibleFrame: screen)
            == MiniChatPlacement.frame(sottoBarra: icona, visibleFrame: screen))
    }

    @Test("A moved dot takes the chat with it: the chat is placed again beside the new place of the dot")
    func followsMovedDot() {
        let dot = NSRect(x: 600, y: 420, width: 56, height: 56)
        let moved = NSRect(x: 100, y: 420, width: 56, height: 56)
        let frame = MiniChatPlacement.frame(for: .puntino(moved), visibleFrame: screen)

        #expect(frame.minX == moved.maxX + MiniChatPlacement.gap)
        #expect(frame.midY == moved.midY)
        #expect(frame != MiniChatPlacement.frame(for: .puntino(dot), visibleFrame: screen))
    }

    @Test("An open chat takes the bubble on its top: the bubble is centred on the chat and inside the screen")
    func bubbleOverlaysChatTop() {
        let chat = NSRect(x: 600, y: 300, width: MiniChatPlacement.size.width, height: MiniChatPlacement.size.height)
        let size = NSSize(width: 280, height: 80)
        let origin = MiniChatPlacement.bubbleOrigin(overlayingTopOf: chat, size: size, visibleFrame: screen)

        #expect(origin.x == chat.midX - size.width / 2)
        #expect(origin.y + size.height == chat.maxY - MiniChatPlacement.gap)
    }

    @Test("A chat at the left edge keeps the bubble inside the visible screen")
    func bubbleOverChatStaysOnScreen() {
        let chat = NSRect(x: 0, y: 380, width: 100, height: 520)
        let size = NSSize(width: 280, height: 80)
        let origin = MiniChatPlacement.bubbleOrigin(overlayingTopOf: chat, size: size, visibleFrame: screen)

        #expect(origin.x == screen.minX)
        #expect(origin.x + size.width <= screen.maxX)
        #expect(origin.y + size.height <= screen.maxY)
    }
}
