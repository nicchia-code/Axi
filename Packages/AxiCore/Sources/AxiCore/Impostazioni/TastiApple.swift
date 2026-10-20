/// The two keys of Apple keyboards that Axi takes over while the "Tasti Apple" switch is on:
/// Spotlight (magnifier, above F4) and Dictation (microphone, above F5).
public enum TastoApple: Sendable, Equatable, CaseIterable {
    case spotlight
    case dettatura

    /// The `utente` Event produced at the release of the key. `chatAperta` tells whether the mini-chat is open now.
    public func evento(chatAperta: Bool) -> EventoUtente {
        switch self {
        case .spotlight:
            chatAperta ? .chiudeChat : .apreChat
        case .dettatura:
            .chiedeArchiviazione
        }
    }
}

/// One system event of a key, decoded from the `data1` field of an `NSSystemDefined` event (subtype 8).
///
/// Layout, as used by media-key taps: the high 16 bits are the key code, bits 8–15 of the low 16 bits are the
/// key state (`0x0A` down, `0x0B` up), and bit 0 of the low 16 bits is set on an auto-repeat of a key down.
public struct TastoSistema: Sendable, Equatable {
    public enum Fase: Sendable, Equatable {
        case premuto
        case ripetuto
        case rilasciato
        case altro
    }

    public let codice: Int32
    public let fase: Fase

    public init(data1: Int) {
        let valore = UInt32(truncatingIfNeeded: data1)
        codice = Int32(bitPattern: (valore & 0xFFFF_0000) >> 16)
        let basso = valore & 0xFFFF
        switch (basso & 0xFF00) >> 8 {
        case 0x0A:
            fase = basso & 0x1 == 1 ? .ripetuto : .premuto
        case 0x0B:
            fase = .rilasciato
        default:
            fase = .altro
        }
    }
}

/// The system-event codes that identify the two keys.
///
/// UNVERIFIED: both codes are `nil`, so no event is ever matched and the event tap is never installed.
/// Nothing public confirms the value macOS puts in the system event for these keys. The HID usages in the
/// public tables are not the same numbers: Spotlight is Apple vendor keyboard page 0xFF01 usage 0x0001, and
/// Dictation is Consumer page 0x0C usage 0x00CF (Voice Command). Karabiner-Elements maps them from these usages,
/// not from system events. Using the usage numbers as codes is unsafe: 0x0001 is the code of the sound-down key,
/// which would be swallowed. The codes are set only after a developer confirms them on a real Apple keyboard.
public struct CodiciTastiApple: Sendable, Equatable {
    public let spotlight: Int32?
    public let dettatura: Int32?

    public init(spotlight: Int32?, dettatura: Int32?) {
        self.spotlight = spotlight
        self.dettatura = dettatura
    }

    /// The codes shipped with Axi. UNVERIFIED: see the type's note; set them only after a real-keyboard check.
    public static let predefiniti = CodiciTastiApple(spotlight: nil, dettatura: nil)

    /// True only when both codes are set. The tap is installed only then.
    public var completi: Bool {
        spotlight != nil && dettatura != nil
    }

    /// The key a system-event code belongs to, or `nil` for every other code (always `nil` while codes are unset).
    public func riconosci(codice: Int32) -> TastoApple? {
        if let spotlight, spotlight == codice {
            return .spotlight
        }
        if let dettatura, dettatura == codice {
            return .dettatura
        }
        return nil
    }
}

/// What the event tap does with one system event of a matched key.
public enum PassoTastoApple: Sendable, Equatable {
    /// First key down: the app in front is stored now.
    case premi
    /// Key up of the pressed key: the key's Event is produced now.
    case rilascia(TastoApple)
    /// Auto-repeat, a key up with no key down, or another state: nothing happens.
    case ignora
}

/// Turns the key downs and key ups of the two keys into one action per press, on the release.
public struct SequenzaTastiApple: Sendable, Equatable {
    private var premuto: TastoApple?

    public init() {}

    /// Advances the sequence with one system event of `tasto`; the event itself is always consumed by the tap.
    public mutating func gestisci(tasto: TastoApple, fase: TastoSistema.Fase) -> PassoTastoApple {
        switch fase {
        case .premuto:
            guard premuto != tasto else { return .ignora }
            premuto = tasto
            return .premi
        case .rilasciato:
            guard premuto == tasto else { return .ignora }
            premuto = nil
            return .rilascia(tasto)
        case .ripetuto, .altro:
            return .ignora
        }
    }

    /// Forgets a press in progress, e.g. when the tap is removed.
    public mutating func annulla() {
        premuto = nil
    }
}
