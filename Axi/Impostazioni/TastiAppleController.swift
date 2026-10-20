import AppKit
import AxiCore
import AxiScreen

/// Takes the Spotlight and Dictation keys of Apple keyboards while the "Tasti Apple" switch is on.
///
/// A session event tap is installed only when all of these hold, and it is removed as soon as one stops:
/// the switch is on, both key codes are verified (`CodiciTastiApple.completi`), and Accessibility is granted.
/// Checked every second, so a permission granted later takes effect without a restart.
///
/// The tap looks at system events only (`NSSystemDefined`, the type of media and function keys), passes every
/// other event through unchanged, and never records, stores or logs a key. A key it matches is consumed, so macOS
/// does not open Spotlight or start Dictation for it.
@MainActor
final class TastiAppleController {
    /// `NX_SYSDEFINED`, the event type of media and function keys, which the tap listens to.
    private static let tipoSistema: UInt32 = 14
    /// Subtype of the `NSSystemDefined` events that carry key data (media and function keys).
    private static let sottotipoTasti: Int16 = 8

    private let store: ImpostazioniStore
    private let codici: CodiciTastiApple
    private let memoria: AppInPrimoPiano
    private let chatAperta: @MainActor () -> Bool
    private let sink: @MainActor (EventoUtente) -> Void
    private var tap: CFMachPort?
    private var sorgente: CFRunLoopSource?
    private var sequenza = SequenzaTastiApple()
    private var timer: Timer?

    /// Whether the tap is installed now; the Puntino menu shows the keys' symbols only then.
    var attivo: Bool { tap != nil }

    /// - Parameters:
    ///   - store: holds the switch.
    ///   - codici: the key codes; shipped unverified, so the tap is never installed until they are set.
    ///   - memoria: remembers the app in front at the press.
    ///   - chatAperta: whether the mini-chat is open at the release.
    ///   - sink: receives the Events of the keys, as the Scorciatoie do.
    init(
        store: ImpostazioniStore,
        codici: CodiciTastiApple,
        memoria: AppInPrimoPiano,
        chatAperta: @escaping @MainActor () -> Bool,
        sink: @escaping @MainActor (EventoUtente) -> Void
    ) {
        self.store = store
        self.codici = codici
        self.memoria = memoria
        self.chatAperta = chatAperta
        self.sink = sink
    }

    /// Starts following the switch and the permission. Call once, at launch.
    func avvia() {
        aggiorna()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.aggiorna() }
        }
    }

    /// Installs the tap when it is wanted and possible, removes it when it is not.
    private func aggiorna() {
        let voluto = store.tastiAppleAttivi && codici.completi && Permissions.accessibilityGranted()
        if voluto, tap == nil {
            installa()
        } else if !voluto, tap != nil {
            rimuovi()
        }
    }

    private func installa() {
        let maschera = CGEventMask(1) << CGEventMask(Self.tipoSistema)
        guard let porta = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: maschera,
            callback: tastiAppleCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            // Accessibility is missing or the tap is refused: the next check tries again.
            return
        }
        let nuovaSorgente = CFMachPortCreateRunLoopSource(nil, porta, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), nuovaSorgente, .commonModes)
        CGEvent.tapEnable(tap: porta, enable: true)
        tap = porta
        sorgente = nuovaSorgente
    }

    private func rimuovi() {
        if let sorgente {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), sorgente, .commonModes)
        }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        tap = nil
        sorgente = nil
        sequenza.annulla()
    }

    /// Called by the tap callback on the main run loop, for system events only.
    /// Returns `true` when the event is a matched key's event, which the tap consumes; `false` to let it through.
    fileprivate func gestisci(tipo: CGEventType, evento: CGEvent) -> Bool {
        if tipo == .tapDisabledByTimeout || tipo == .tapDisabledByUserInput {
            // macOS turns a slow or interrupted tap off: switch it back on, the event passes through.
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return false
        }
        guard tipo.rawValue == Self.tipoSistema,
              let ns = NSEvent(cgEvent: evento),
              ns.subtype.rawValue == Self.sottotipoTasti
        else {
            return false
        }
        let sistema = TastoSistema(data1: ns.data1)
        guard let tasto = codici.riconosci(codice: sistema.codice) else {
            return false
        }
        switch sequenza.gestisci(tasto: tasto, fase: sistema.fase) {
        case .premi:
            memoria.registraAppInPrimoPiano()
        case .rilascia(let premuto):
            sink(premuto.evento(chatAperta: chatAperta()))
        case .ignora:
            break
        }
        return true
    }
}

/// The event of a tap callback, handed to the main actor. The callback runs on the main run loop, and the event is used only there.
private struct EventoTap: @unchecked Sendable {
    let evento: CGEvent
}

/// C callback of the event tap. The tap runs on the main run loop, where the controller lives.
private let tastiAppleCallback: CGEventTapCallBack = { _, tipo, evento, refcon in
    guard let refcon else {
        return Unmanaged.passUnretained(evento)
    }
    let controller = Unmanaged<TastiAppleController>.fromOpaque(refcon).takeUnretainedValue()
    let ricevuto = EventoTap(evento: evento)
    let consuma = MainActor.assumeIsolated {
        controller.gestisci(tipo: tipo, evento: ricevuto.evento)
    }
    return consuma ? nil : Unmanaged.passUnretained(evento)
}
