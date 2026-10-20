import AxiCore
import KeyboardShortcuts
import SwiftUI

/// The radial menu around the dot: five items, the first one at the top, clockwise.
struct MenuRadialeVista: View {
    let modello: PuntinoModello
    let scegli: (VoceMenu) -> Void
    @Environment(\.accessibilityReduceMotion) private var riduciMovimento

    static let lato: CGFloat = 300
    private static let raggio: CGFloat = 100

    var body: some View {
        ZStack {
            ForEach(Array(VoceMenu.allCases.enumerated()), id: \.element) { indice, voce in
                let angolo = (-90.0 + 72.0 * Double(indice)) * .pi / 180
                Button {
                    scegli(voce)
                } label: {
                    VoceMenuVista(voce: voce, simboliTasti: modello.mostraSimboliTasti)
                }
                .buttonStyle(.plain)
                .position(
                    x: Self.lato / 2 + Self.raggio * CGFloat(cos(angolo)),
                    y: Self.lato / 2 + Self.raggio * CGFloat(sin(angolo))
                )
                .opacity(modello.menuVisibile ? 1 : 0)
                .scaleEffect(modello.menuVisibile ? 1 : 0.4)
                .animation(
                    riduciMovimento ? nil : .spring(response: 0.35, dampingFraction: 0.75).delay(Double(indice) * 0.03),
                    value: modello.menuVisibile
                )
            }
        }
        .frame(width: Self.lato, height: Self.lato)
    }
}

private struct VoceMenuVista: View {
    let voce: VoceMenu
    /// The Spotlight and Dictation keys are Axi's: the items show their key symbols instead of the shortcuts.
    let simboliTasti: Bool
    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @State private var sopra = false

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: voce.simbolo)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(sopra ? Color.accentColor : Color.primary)
                .frame(width: 44, height: 44)
                .glassEffect(sopra ? .regular.tint(Color.accentColor.opacity(0.18)) : .regular, in: Circle())
                .animation(riduciMovimento ? nil : .easeOut(duration: 0.2), value: sopra)
                .onHover { sopra = $0 }
            Text(voce.titolo)
                .font(.caption.weight(.medium))
            if let simbolo = voce.simboloTasto(tastiAxi: simboliTasti) {
                Image(systemName: simbolo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let testo = scorciatoiaTesto {
                Text(testo)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 92)
        .contentShape(Rectangle())
    }

    /// The shortcut as the user sees it in Settings, if the item has one.
    private var scorciatoiaTesto: String? {
        guard let scorciatoia = voce.scorciatoia else { return nil }
        return KeyboardShortcuts.getShortcut(for: scorciatoia.nome)?.description
    }
}

extension VoceMenu {
    /// The SF Symbol of the item, shared by the radial menu and the menu of the menu bar.
    var simbolo: String {
        switch self {
        case .archivia: "archivebox"
        case .chat: "bubble.left.and.bubble.right"
        case .impostazioni: "gearshape"
        case .nascondi: "eye.slash"
        case .esci: "power"
        }
    }

    /// The title of the item, shared by the radial menu and the menu of the menu bar.
    var titolo: LocalizedStringResource {
        switch self {
        case .archivia: "Archive"
        case .chat: "Chat"
        case .impostazioni: "Settings…"
        case .nascondi: "Hide"
        case .esci: "Quit Axi"
        }
    }
}

extension Scorciatoia {
    var nome: KeyboardShortcuts.Name {
        switch self {
        case .archivia: .archivia
        case .chat: .chat
        case .alterna: .alterna
        }
    }
}
