import AppKit
import SwiftUI

/// The look of the character while no outcome is showing: at rest, the wait, or the three dots.
enum PuntinoAspetto: Equatable {
    case fermo, attesa, trePuntini
}

/// An ellipse in the 100 × 100 drawing space of the character (see `Design/puntino.svg`).
struct PuntinoEllisse: Equatable {
    var centro: CGPoint
    var raggioX: CGFloat
    var raggioY: CGFloat
    var rotazione: CGFloat = 0
}

/// A drop of the character: the body at rest, or one of the three drops of the three-dot pose. Every part is an
/// ellipse: the shadow (`ellisse`), the lit part clipped to it (`luce`) and the highlight (`riflesso`).
struct PuntinoGoccia: Equatable {
    /// The outline, which is also the shadow.
    var ellisse: PuntinoEllisse
    /// The lit part, clipped to `ellisse`: moved to the upper right at rest, the whole drop at three dots.
    var luce: PuntinoEllisse
    /// The highlight at the upper right.
    var riflesso: PuntinoEllisse
    /// Opacity of the shadow and of the highlight: 1 at rest, 0 at three dots.
    var dettagli: CGFloat
}

/// The shapes of the character at one instant.
struct PuntinoForme: Equatable {
    /// Left drop, middle drop (the body at rest), right drop.
    var gocce: [PuntinoGoccia]
    /// The two eyes of the body.
    var occhi: [PuntinoEllisse]
    var opacitaOcchi: CGFloat
}

/// The geometry of the character as a function of the change from the body to the three drops (0 to 1), of the
/// phase of the wait cycle, and of how much the body breathes (0 at rest, 1 in the wait). At 0 the three drops
/// coincide with the body; at 1 they are three equal drops.
enum PuntinoGeometria {
    static let centroCorpo = CGPoint(x: 50, y: 52)
    static let raggioXCorpo: CGFloat = 35
    static let raggioYCorpo: CGFloat = 31
    /// Horizontal centres of the left, middle and right drop.
    static let ascisseGocce: [CGFloat] = [25, 50, 75]
    static let ordinataGocce: CGFloat = 50
    static let raggioGoccia: CGFloat = 9
    /// Length in seconds of one wait or three-dot cycle at normal speed.
    static let ciclo: Double = 2.2

    /// Speed of the wait and of the three-dot cycle: half with Reduce Motion.
    static func velocita(riduciMovimento: Bool) -> Double { riduciMovimento ? 0.5 : 1 }

    /// Duration of the change between the body and the three dots: doubled with Reduce Motion.
    static func durataTrasformazione(riduciMovimento: Bool) -> TimeInterval { riduciMovimento ? 0.8 : 0.4 }

    /// Phase of the wait and three-dot cycle at `istante`, in radians.
    static func fase(al istante: Date, velocita: Double) -> CGFloat {
        let secondi = istante.timeIntervalSinceReferenceDate * velocita
        let nelCiclo = secondi.truncatingRemainder(dividingBy: ciclo)
        return CGFloat(2 * Double.pi * nelCiclo / ciclo)
    }

    static func forme(trasformazione m: CGFloat, fase: CGFloat, respiro: CGFloat) -> PuntinoForme {
        let attesa = 1 - m
        // The wait: the body breathes as an ellipse; the breath fades in and out with the wait pose.
        let ondata = attesa * respiro
        let sy = 1 + 0.035 * sin(fase) * ondata
        let sx = 1 - 0.0175 * sin(fase) * ondata
        let gocce = ascisseGocce.enumerated().map { i, ascissa -> PuntinoGoccia in
            // The three-dot wave: each drop lifts and swells a little after the one on its left.
            let sollevamento = m * max(0, sin(fase - CGFloat(i) * 0.7))
            let gonfiamento = 1 + 0.12 * sollevamento
            let centro = CGPoint(
                x: lerp(centroCorpo.x, ascissa, m),
                y: lerp(centroCorpo.y, ordinataGocce, m) - 5 * sollevamento
            )
            let ellisse = PuntinoEllisse(
                centro: centro,
                raggioX: lerp(raggioXCorpo * sx, raggioGoccia, m) * gonfiamento,
                raggioY: lerp(raggioYCorpo * sy, raggioGoccia, m) * gonfiamento
            )
            // The lit part sits at the upper right at rest and covers the whole drop at three dots.
            let luce = PuntinoEllisse(
                centro: CGPoint(
                    x: centro.x + attesa * 0.11 * ellisse.raggioX,
                    y: centro.y - attesa * 0.11 * ellisse.raggioY
                ),
                raggioX: ellisse.raggioX * (1 - 0.06 * attesa),
                raggioY: ellisse.raggioY * (1 - 0.06 * attesa)
            )
            let s = ellisse.raggioX / raggioXCorpo
            let riflesso = PuntinoEllisse(
                centro: CGPoint(x: centro.x + 17 * s, y: centro.y - 17 * s),
                raggioX: 7 * s,
                raggioY: 4.5 * s,
                rotazione: -35 * .pi / 180
            )
            return PuntinoGoccia(ellisse: ellisse, luce: luce, riflesso: riflesso, dettagli: attesa)
        }
        // The eyes sit on the body and vanish as it becomes drops.
        let corpo = gocce[1].ellisse
        let s = corpo.raggioX / raggioXCorpo
        let occhi = [-9, 9].map { dx in
            PuntinoEllisse(
                centro: CGPoint(x: corpo.centro.x + dx * s, y: corpo.centro.y - 2 * s),
                raggioX: 3.6 * s,
                raggioY: 5 * s
            )
        }
        return PuntinoForme(gocce: gocce, occhi: occhi, opacitaOcchi: attesa)
    }

    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

/// The change between the body and the three dots: a value from 0 to 1, eased, that moves over a duration from the
/// value it had at the moment the target changed.
struct PuntinoTrasformazione: Equatable {
    private var da: Double = 0
    private var a: Double = 0
    private var inizio: Date = .distantPast
    private var durata: TimeInterval = 0.4

    func valore(al istante: Date) -> Double {
        guard durata > 0 else { return a }
        let frazione = min(max(istante.timeIntervalSince(inizio) / durata, 0), 1)
        let eased = frazione * frazione * (3 - 2 * frazione)
        return da + (a - da) * eased
    }

    mutating func vaVerso(_ obiettivo: Double, al istante: Date, durata nuova: TimeInterval) {
        da = valore(al: istante)
        a = obiettivo
        inizio = istante
        durata = nuova
    }
}

/// The colours of the character: the accent colour macOS uses for the light or the dark appearance, and its shades.
/// The body is the accent (a little brighter in the dark appearance); the shadow is darker, the highlight lighter and
/// the eyes very light. Flat colours only.
@MainActor
struct PuntinoTinte {
    let corpo: Color
    let ombra: Color
    let riflesso: Color
    let occhi: Color

    /// The accent colour macOS uses for the given appearance, resolved now so that it follows the user's setting.
    static func accento(scuro: Bool) -> NSColor {
        var accento = NSColor.controlAccentColor
        NSAppearance(named: scuro ? .darkAqua : .aqua)?.performAsCurrentDrawingAppearance {
            let risolto = NSColor.controlAccentColor
            accento = risolto.usingColorSpace(.sRGB) ?? risolto
        }
        return accento
    }

    init(scuro: Bool) {
        let accento = Self.accento(scuro: scuro)
        let bianco = NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        let nero = NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        let corpo = scuro ? Self.mescola(accento, bianco, 0.10) : accento
        self.corpo = Color(nsColor: corpo)
        ombra = Color(nsColor: Self.mescola(corpo, nero, 0.28))
        riflesso = Color(nsColor: Self.mescola(corpo, bianco, 0.35))
        occhi = Color(nsColor: Self.mescola(corpo, bianco, 0.75))
    }

    private static func mescola(_ colore: NSColor, _ altro: NSColor, _ frazione: CGFloat) -> NSColor {
        colore.blended(withFraction: frazione, of: altro) ?? colore
    }
}

/// The character drawn with vector shapes: circles and ellipses, sharp edges, flat colours. Each drop is a shadow
/// ellipse, a lit body clipped to it (the crescent left at the lower left is the shadow), and a highlight at the
/// upper right; the eyes sit on top. The wait and the three dots animate with a timeline; with Reduce Motion they run
/// at half speed, with doubled durations for the change between the poses.
struct PuntinoDisegno: View {
    let aspetto: PuntinoAspetto
    /// Paints the whole character in one colour, with no details (the drag veil and the error tint).
    var monocromia: Color?
    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @Environment(\.colorScheme) private var schema
    @State private var trasformazione = PuntinoTrasformazione()
    /// How much the body breathes: 1 in the wait, 0 at rest and at three dots.
    @State private var respiro = PuntinoTrasformazione()
    @State private var tinte = PuntinoTinte(scuro: false)
    /// The timeline is stopped while the character rests, once the change back to rest has ended.
    @State private var ferma = true

    private var durata: TimeInterval { PuntinoGeometria.durataTrasformazione(riduciMovimento: riduciMovimento) }
    private var velocita: Double { PuntinoGeometria.velocita(riduciMovimento: riduciMovimento) }

    var body: some View {
        TimelineView(.animation(paused: ferma && aspetto == .fermo)) { linea in
            let istante = linea.date
            let forme = PuntinoGeometria.forme(
                trasformazione: CGFloat(trasformazione.valore(al: istante)),
                fase: fase(al: istante),
                respiro: CGFloat(respiro.valore(al: istante))
            )
            Canvas { contesto, dimensione in
                Self.disegna(forme, in: contesto, dimensione: dimensione, monocromia: monocromia, tinte: tinte)
            }
        }
        .onChange(of: aspetto, initial: true) { _, nuovo in
            ferma = false
            trasformazione.vaVerso(nuovo == .trePuntini ? 1 : 0, al: .now, durata: durata)
            respiro.vaVerso(nuovo == .attesa ? 1 : 0, al: .now, durata: durata)
        }
        .onChange(of: schema, initial: true) { _, nuovo in
            tinte = PuntinoTinte(scuro: nuovo == .dark)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSColor.systemColorsDidChangeNotification)) { _ in
            tinte = PuntinoTinte(scuro: schema == .dark)
        }
        .task(id: aspetto) {
            guard aspetto == .fermo else { return }
            try? await Task.sleep(for: .milliseconds(Int(durata * 1000) + 50))
            if !Task.isCancelled { ferma = true }
        }
    }

    /// Phase of the wait and three-dot cycle, in radians.
    private func fase(al istante: Date) -> CGFloat {
        PuntinoGeometria.fase(al: istante, velocita: velocita)
    }

    private static func disegna(
        _ forme: PuntinoForme,
        in contesto: GraphicsContext,
        dimensione: CGSize,
        monocromia: Color?,
        tinte: PuntinoTinte
    ) {
        var c = contesto
        c.scaleBy(x: dimensione.width / 100, y: dimensione.height / 100)
        // The middle drop (the body at rest) is drawn last, so the two side drops stay under it while they coincide.
        for goccia in [forme.gocce[0], forme.gocce[2], forme.gocce[1]] {
            disegnaGoccia(goccia, in: &c, monocromia: monocromia, tinte: tinte)
        }
        guard monocromia == nil, forme.opacitaOcchi > 0 else { return }
        for occhio in forme.occhi {
            c.fill(forma(occhio), with: .color(tinte.occhi.opacity(Double(forme.opacitaOcchi))))
        }
    }

    private static func disegnaGoccia(
        _ goccia: PuntinoGoccia,
        in c: inout GraphicsContext,
        monocromia: Color?,
        tinte: PuntinoTinte
    ) {
        let contorno = forma(goccia.ellisse)
        if let monocromia {
            c.fill(contorno, with: .color(monocromia))
            return
        }
        if goccia.dettagli > 0 {
            c.fill(contorno, with: .color(tinte.ombra.opacity(Double(goccia.dettagli))))
        }
        c.drawLayer { livello in
            livello.clip(to: contorno)
            livello.fill(forma(goccia.luce), with: .color(tinte.corpo))
        }
        if goccia.dettagli > 0 {
            c.fill(forma(goccia.riflesso), with: .color(tinte.riflesso.opacity(Double(goccia.dettagli))))
        }
    }

    private static func forma(_ e: PuntinoEllisse) -> Path {
        Path(ellipseIn: CGRect(x: -e.raggioX, y: -e.raggioY, width: 2 * e.raggioX, height: 2 * e.raggioY))
            .applying(
                CGAffineTransform(rotationAngle: e.rotazione)
                    .concatenating(CGAffineTransform(translationX: e.centro.x, y: e.centro.y))
            )
    }
}
