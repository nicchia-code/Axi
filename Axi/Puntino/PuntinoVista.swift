import AxiCore
import SwiftUI

/// The character, as the dot. At rest it shows the still character. The wait (the body breathes and its outline
/// sways) plays only while the user interacts with the dot or while files are dragged over it; the three dots play
/// from the request of an archiving (or the release of files) to its last outcome, and while the mini-chat answers,
/// without waiting for the metadata. An outcome shows briefly on the character and then it
/// returns to its look: a bounce with a check mark, a red shake, or an accent flash for a document already in the
/// vault. With Reduce Motion on, the shake and the bounce become a fade, and the wait and the three dots run at
/// half speed.
struct PuntinoVista: View {
    let modello: PuntinoModello
    /// Side of the drawn character in points: about 48 on the screen.
    var dimensione: CGFloat = 48
    /// Whether this is the dot on the screen, which shrinks away while it is hidden in the menu bar.
    var sulloSchermo = false
    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @Environment(\.colorScheme) private var schema
    /// The outcome shown on the character right now; while it lasts, the wait animation pauses.
    @State private var segnale: Nuvoletta.Esito?
    @State private var scosse = 0
    @State private var lampi = 0
    @State private var rimbalzi = 0

    var body: some View {
        ZStack {
            personaggio
            if modello.attivita.stato == .inCorso, modello.attivita.inCoda > 0 {
                contatore
            }
        }
        .frame(width: 56, height: 56)
        .scaleEffect(dimensione / 36)
        .scaleEffect(sulloSchermo && modello.stato.nascosto && !riduciMovimento ? 0.4 : 1)
        .animation(riduciMovimento ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: modello.stato)
        .animation(.easeInOut(duration: 0.3), value: modello.attivita.stato)
        .task(id: modello.attivita.esiti) { await mostraSegnale() }
        .onChange(of: modello.attivita.esiti) { _, _ in
            switch modello.attivita.nuvoletta?.esito {
            case .successo: rimbalzi += 1
            case .errore: scosse += 1
            case .giaPresente: lampi += 1
            default: break
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Axi")
    }

    private var scala: CGFloat {
        if modello.riceveFile { return 1.25 }
        if modello.stato == .espanso { return 1.15 }
        return 1
    }

    /// What the character shows, by precedence (see `PuntinoModello.aspetto(segnale:)`).
    private var aspetto: PuntinoAspetto { modello.aspetto(segnale: segnale != nil) }

    private var personaggio: some View {
        immagine
            .frame(width: 36, height: 36)
            .scaleEffect(scala)
            .keyframeAnimator(initialValue: 0.0, trigger: lampi) { vista, luce in
                vista.overlay {
                    PuntinoDisegno(aspetto: aspetto, monocromia: PuntinoTinte(scuro: schema == .dark).riflesso)
                        .opacity(luce)
                }
            } keyframes: { _ in
                LinearKeyframe(0, duration: 0)
                LinearKeyframe(riduciMovimento ? 0.4 : 0.6, duration: 0.15)
                LinearKeyframe(0, duration: 0.35)
            }
            .overlay { tinta }
            .overlay(alignment: .bottomTrailing) { spunta }
            .animation(riduciMovimento ? nil : .easeOut(duration: 0.2), value: segnale)
            .keyframeAnimator(initialValue: Scossa(), trigger: scosse) { vista, valore in
                vista.offset(x: valore.x).opacity(valore.opacita)
            } keyframes: { _ in
                KeyframeTrack(\.x) {
                    LinearKeyframe(0, duration: 0)
                    CubicKeyframe(riduciMovimento ? 0 : -6, duration: 0.06)
                    CubicKeyframe(riduciMovimento ? 0 : 6, duration: 0.08)
                    CubicKeyframe(riduciMovimento ? 0 : -4, duration: 0.08)
                    CubicKeyframe(riduciMovimento ? 0 : 3, duration: 0.08)
                    CubicKeyframe(0, duration: 0.08)
                }
                KeyframeTrack(\.opacita) {
                    LinearKeyframe(1, duration: 0)
                    LinearKeyframe(riduciMovimento ? 0.3 : 1, duration: 0.12)
                    LinearKeyframe(1, duration: 0.28)
                }
            }
            .keyframeAnimator(initialValue: Rimbalzo(), trigger: rimbalzi) { vista, valore in
                vista.offset(y: valore.y).opacity(valore.opacita)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    LinearKeyframe(0, duration: 0)
                    CubicKeyframe(riduciMovimento ? 0 : -8, duration: 0.14)
                    CubicKeyframe(0, duration: 0.2)
                    CubicKeyframe(riduciMovimento ? 0 : -3, duration: 0.1)
                    CubicKeyframe(0, duration: 0.1)
                }
                KeyframeTrack(\.opacita) {
                    LinearKeyframe(1, duration: 0)
                    LinearKeyframe(riduciMovimento ? 0.4 : 1, duration: 0.15)
                    LinearKeyframe(1, duration: 0.35)
                }
            }
    }

    private var immagine: some View {
        PuntinoDisegno(aspetto: aspetto)
    }

    /// Red for an error, the accent colour while files are dragged over the dot; it fills the shapes of the look of the moment.
    @ViewBuilder
    private var tinta: some View {
        if let colore = coloreTinta {
            PuntinoDisegno(aspetto: aspetto, monocromia: colore)
                .opacity(0.45)
        }
    }

    private var coloreTinta: Color? {
        if modello.riceveFile { return Color(nsColor: PuntinoTinte.accento(scuro: schema == .dark)) }
        if segnale == .errore { return .red }
        return nil
    }

    /// Brief check mark on the character after a success.
    @ViewBuilder
    private var spunta: some View {
        if segnale == .successo {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white, .green)
                .transition(.scale.combined(with: .opacity))
        }
    }

    /// Number of documents waiting in the queue, to the right of the character: white on an accent circle, which
    /// becomes a capsule with two or more digits.
    private var contatore: some View {
        Text("\(modello.attivita.inCoda)")
            .font(.system(size: 8 * fattoreContatore, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 2 * fattoreContatore)
            .frame(minWidth: 10 * fattoreContatore, minHeight: 10 * fattoreContatore)
            .background(Color.accentColor, in: Capsule())
            .offset(x: 22)
    }

    /// The counter is drawn in the scale of the dot's frame: in the menu bar that scale is smaller, so it grows back.
    private var fattoreContatore: CGFloat { sulloSchermo ? 1 : 36 / dimensione }

    /// Shows the outcome of the last Event on the character for a moment; a newer outcome replaces it.
    private func mostraSegnale() async {
        guard modello.attivita.esiti > 0, let esito = modello.attivita.nuvoletta?.esito else { return }
        segnale = esito
        do {
            try await Task.sleep(for: .milliseconds(900))
        } catch {
            return
        }
        segnale = nil
    }
}

/// The values the error shake animates: a horizontal offset and an opacity, both back at rest at the end.
private struct Scossa: Equatable {
    var x: CGFloat = 0
    var opacita: Double = 1
}

/// The values the success bounce animates: a vertical offset and an opacity, both back at rest at the end.
private struct Rimbalzo: Equatable {
    var y: CGFloat = 0
    var opacita: Double = 1
}

