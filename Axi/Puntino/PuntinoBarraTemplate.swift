import AppKit
import AxiCore

/// The character in the menu bar: a template image of 22.5 pt, one opaque colour on a transparent ground, drawn
/// again at each frame from the same shapes as the character on the screen (`PuntinoGeometria`). macOS paints
/// it in the colour of the system icons, dims it on an inactive screen and highlights it while its menu is open.
/// The outcomes and the queue counter are drawn in the same colour too, as cut-outs of the silhouette or solid
/// shapes: a check mark is a filled circle with the tick cut out, and the counter is a filled capsule with the
/// number cut out.
enum PuntinoBarraTemplate {
    /// Side of the image in points: 25% more than the system icons of about 18 pt.
    static let lato: CGFloat = 22.5
    /// One unit of the icon: the 18 pt of the system icons scaled to `lato`. Every size of the icon that is not the
    /// character itself is this unit times its value at 18 pt, so the whole icon keeps one measure.
    static let unita: CGFloat = lato / 18
    /// Scale of the character while files are dragged over it.
    static let scalaTrascinamento: CGFloat = 1.25
    /// Opacity of the silhouette while files are dragged over it: it lightens, with no colour.
    static let opacitaTrascinamento: CGFloat = 0.45
    /// Where the counter starts: the character's side plus a gap of 4 units.
    static let inizioContatore: CGFloat = lato + 4 * unita
    /// Font of the counter's number: 8 units.
    private static var fontContatore: NSFont { NSFont.systemFont(ofSize: 8 * unita, weight: .bold) }

    /// Width of the image: the side of the character, or with the counter the room the number takes beside it.
    static func larghezza(contatore: String?) -> CGFloat {
        guard let contatore else { return lato }
        return inizioContatore + larghezzaCapsula(contatore)
    }

    /// Width of the counter's capsule: at least a circle, wider for two or more digits.
    static func larghezzaCapsula(_ contatore: String) -> CGFloat {
        let numero = NSAttributedString(string: contatore, attributes: [.font: fontContatore])
        return max(10 * unita, numero.size().width + 4 * unita)
    }

    /// The image of the character at one instant. The drawing runs when macOS paints the image.
    /// - Parameters:
    ///   - scala: scale of the character (the drag enlarges it).
    ///   - opacita: opacity of the character as a whole (the drag and the flash of an outcome).
    ///   - spostamento: shift of the character in points, y up (the shake and the bounce of an outcome).
    ///   - spunta: whether the check mark of a success is shown on the character's corner.
    ///   - contatore: the number of queued documents, shown beside the character, or `nil`.
    static func immagine(
        forme: PuntinoForme,
        scala: CGFloat = 1,
        opacita: CGFloat = 1,
        spostamento: CGSize = .zero,
        spunta: Bool = false,
        contatore: String? = nil
    ) -> NSImage {
        let immagine = NSImage(
            size: NSSize(width: larghezza(contatore: contatore), height: lato),
            flipped: false
        ) { rettangolo in
            guard let contesto = NSGraphicsContext.current?.cgContext else { return false }
            disegnaPersonaggio(
                forme,
                in: contesto,
                scala: scala,
                opacita: opacita,
                spostamento: spostamento,
                spunta: spunta
            )
            if let contatore {
                disegnaContatore(contatore, in: contesto, altezza: rettangolo.height)
            }
            return true
        }
        immagine.isTemplate = true
        return immagine
    }

    /// Paints the silhouette in black, with the eyes cut out. The drops are drawn opaque in a layer that takes
    /// the opacity as a whole, so the parts that overlap do not get darker. A check mark sits on the corner as a
    /// filled circle with the tick cut out; a clear ring separates it from the silhouette.
    private static func disegnaPersonaggio(
        _ forme: PuntinoForme,
        in contesto: CGContext,
        scala: CGFloat,
        opacita: CGFloat,
        spostamento: CGSize,
        spunta: Bool
    ) {
        contesto.saveGState()
        contesto.translateBy(x: spostamento.width, y: spostamento.height)
        // The 100 × 100 drawing space, flipped to the top-down orientation of the image and scaled to it.
        contesto.translateBy(x: 0, y: lato)
        contesto.scaleBy(x: lato / 100, y: -lato / 100)
        contesto.translateBy(x: 50, y: 50)
        contesto.scaleBy(x: scala, y: scala)
        contesto.translateBy(x: -50, y: -50)

        contesto.setAlpha(opacita)
        contesto.beginTransparencyLayer(auxiliaryInfo: nil)
        contesto.setAlpha(1)
        contesto.setFillColor(CGColor(gray: 0, alpha: 1))
        for goccia in forme.gocce {
            riempi(goccia.ellisse, in: contesto)
        }
        if forme.opacitaOcchi > 0 {
            contesto.setBlendMode(.clear)
            contesto.setFillColor(CGColor(gray: 0, alpha: forme.opacitaOcchi))
            for occhio in forme.occhi {
                riempi(occhio, in: contesto)
            }
            contesto.setBlendMode(.normal)
        }
        if spunta {
            disegnaSpunta(in: contesto)
        }
        contesto.endTransparencyLayer()
        contesto.restoreGState()
    }

    /// The check mark of a success, in the 100 × 100 drawing space: a clear ring, a filled circle and the tick cut out.
    private static func disegnaSpunta(in contesto: CGContext) {
        let centro = CGPoint(x: 76, y: 76)
        contesto.setBlendMode(.clear)
        contesto.fillEllipse(in: cerchio(centro, raggio: 27))
        contesto.setBlendMode(.normal)
        contesto.setFillColor(CGColor(gray: 0, alpha: 1))
        contesto.fillEllipse(in: cerchio(centro, raggio: 21))
        contesto.setBlendMode(.clear)
        contesto.setStrokeColor(CGColor(gray: 0, alpha: 1))
        contesto.setLineWidth(9)
        contesto.setLineCap(.round)
        contesto.setLineJoin(.round)
        contesto.move(to: CGPoint(x: 70, y: 76))
        contesto.addLine(to: CGPoint(x: 75, y: 82))
        contesto.addLine(to: CGPoint(x: 86, y: 68))
        contesto.strokePath()
        contesto.setBlendMode(.normal)
    }

    /// The counter: a filled capsule beside the character with the number cut out. Drawn in image points, y up.
    private static func disegnaContatore(_ contatore: String, in contesto: CGContext, altezza: CGFloat) {
        let larghezzaCapsula = larghezzaCapsula(contatore)
        let altezzaCapsula = 10 * unita
        let capsula = CGRect(
            x: inizioContatore,
            y: (altezza - altezzaCapsula) / 2,
            width: larghezzaCapsula,
            height: altezzaCapsula
        )
        contesto.saveGState()
        contesto.beginTransparencyLayer(auxiliaryInfo: nil)
        contesto.setFillColor(CGColor(gray: 0, alpha: 1))
        contesto.addPath(CGPath(roundedRect: capsula, cornerWidth: 5 * unita, cornerHeight: 5 * unita, transform: nil))
        contesto.fillPath()
        contesto.setBlendMode(.clear)
        let numero = NSAttributedString(
            string: contatore,
            attributes: [.font: fontContatore, .foregroundColor: NSColor.black]
        )
        let dimensione = numero.size()
        numero.draw(at: NSPoint(
            x: capsula.midX - dimensione.width / 2,
            y: capsula.midY - dimensione.height / 2
        ))
        contesto.setBlendMode(.normal)
        contesto.endTransparencyLayer()
        contesto.restoreGState()
    }

    private static func cerchio(_ centro: CGPoint, raggio: CGFloat) -> CGRect {
        CGRect(x: centro.x - raggio, y: centro.y - raggio, width: 2 * raggio, height: 2 * raggio)
    }

    private static func riempi(_ ellisse: PuntinoEllisse, in contesto: CGContext) {
        contesto.fillEllipse(in: CGRect(
            x: ellisse.centro.x - ellisse.raggioX,
            y: ellisse.centro.y - ellisse.raggioY,
            width: 2 * ellisse.raggioX,
            height: 2 * ellisse.raggioY
        ))
    }
}

/// Draws the character in the menu bar button, with the look and timing of the character on the screen. Its timer
/// runs only while the look changes, an outcome shows or files are dragged over the icon, so at rest the icon costs
/// nothing. An outcome shows for `durataSegnale`: a bounce with a check mark, a shake, or a brief lightening, all
/// in the one colour of the icon.
@MainActor
final class IconaBarra {
    /// How long an outcome stays on the icon, as on the screen.
    private static let durataSegnale: TimeInterval = 0.9

    private let modello: PuntinoModello
    private weak var bottone: NSButton?
    private var trasformazione = PuntinoTrasformazione()
    private var respiro = PuntinoTrasformazione()
    private var aspettoMostrato: PuntinoAspetto?
    private var riceveFile = false
    private var timer: Timer?
    /// The outcome on the icon and when it started. Only a new outcome starts one: the look at opening is not replayed.
    private var segnale: Nuvoletta.Esito?
    private var inizioSegnale = Date.distantPast
    /// How many outcomes were seen, to tell a new one apart.
    private var esitiVisti: Int

    init(modello: PuntinoModello, bottone: NSButton) {
        self.modello = modello
        self.bottone = bottone
        esitiVisti = modello.attivita.esiti
        osserva()
    }

    /// Stops the timer; called when the icon leaves the menu bar.
    func ferma() {
        timer?.invalidate()
        timer = nil
    }

    /// Reads the look, the drag, the counter and the outcomes again at each change of any of them, then redraws.
    private func osserva() {
        let stato = withObservationTracking {
            (
                aspetto: modello.aspetto(segnale: false),
                riceveFile: modello.riceveFile,
                esiti: modello.attivita.esiti,
                esito: modello.attivita.nuvoletta?.esito,
                inCorso: modello.attivita.stato == .inCorso,
                inCoda: modello.attivita.inCoda
            )
        } onChange: { [weak self] in
            Task { @MainActor in self?.osserva() }
        }
        let ora = Date.now
        riceveFile = stato.riceveFile
        if stato.esiti != esitiVisti {
            esitiVisti = stato.esiti
            if let esito = stato.esito {
                segnale = esito
                inizioSegnale = ora
            }
        }
        disegna(ora, riduci: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        if !riposa(ora) { avviaTimer() }
    }

    private func avviaTimer() {
        guard timer == nil else { return }
        let nuovo = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tic() }
        }
        // Common modes: the wait keeps playing while the menu of the icon is open.
        RunLoop.main.add(nuovo, forMode: .common)
        timer = nuovo
    }

    private func tic() {
        let ora = Date.now
        disegna(ora, riduci: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        if riposa(ora) { ferma() }
    }

    /// `true` when the icon shows the still character, no outcome and no change is running.
    private func riposa(_ ora: Date) -> Bool {
        aspettoMostrato == .fermo && !riceveFile && segnaleAttivo(ora) == nil
            && trasformazione.valore(al: ora) == 0 && respiro.valore(al: ora) == 0
    }

    /// The outcome still on the icon at `ora`, or `nil` once it has lasted `durataSegnale`.
    private func segnaleAttivo(_ ora: Date) -> Nuvoletta.Esito? {
        guard segnale != nil, ora.timeIntervalSince(inizioSegnale) < Self.durataSegnale else {
            segnale = nil
            return nil
        }
        return segnale
    }

    private func disegna(_ ora: Date, riduci: Bool) {
        let esito = segnaleAttivo(ora)
        let aspetto = modello.aspetto(segnale: esito != nil)
        if aspetto != aspettoMostrato {
            let durata = PuntinoGeometria.durataTrasformazione(riduciMovimento: riduci)
            trasformazione.vaVerso(aspetto == .trePuntini ? 1 : 0, al: ora, durata: durata)
            respiro.vaVerso(aspetto == .attesa ? 1 : 0, al: ora, durata: durata)
            aspettoMostrato = aspetto
        }
        let forme = PuntinoGeometria.forme(
            trasformazione: CGFloat(trasformazione.valore(al: ora)),
            fase: PuntinoGeometria.fase(al: ora, velocita: PuntinoGeometria.velocita(riduciMovimento: riduci)),
            respiro: CGFloat(respiro.valore(al: ora))
        )
        let t = ora.timeIntervalSince(inizioSegnale)
        var spostamento = CGSize.zero
        var dissolvenza: CGFloat = 1
        switch esito {
        case .successo:
            if riduci {
                dissolvenza = Self.traccia([(0, 1), (0.15, 0.4), (0.5, 1)], t)
            } else {
                spostamento.height = PuntinoBarraTemplate.unita * Self.traccia([(0, 0), (0.14, 8), (0.34, 0), (0.44, 3), (0.54, 0)], t)
            }
        case .errore:
            if riduci {
                dissolvenza = Self.traccia([(0, 1), (0.12, 0.3), (0.4, 1)], t)
            } else {
                spostamento.width = PuntinoBarraTemplate.unita * Self.traccia([(0, 0), (0.06, -6), (0.14, 6), (0.22, -4), (0.30, 3), (0.38, 0)], t)
            }
        case .giaPresente:
            // A brief lightening of the silhouette, with no shake.
            let picco: CGFloat = riduci ? 0.4 : 0.6
            dissolvenza = 1 - Self.traccia([(0, 0), (0.15, picco), (0.5, 0)], t)
        case nil:
            break
        }
        let contatore = modello.attivita.stato == .inCorso && modello.attivita.inCoda > 0
            ? "\(modello.attivita.inCoda)"
            : nil
        bottone?.image = PuntinoBarraTemplate.immagine(
            forme: forme,
            scala: riceveFile ? PuntinoBarraTemplate.scalaTrascinamento : 1,
            opacita: (riceveFile ? PuntinoBarraTemplate.opacitaTrascinamento : 1) * dissolvenza,
            spostamento: spostamento,
            spunta: esito == .successo,
            contatore: contatore
        )
    }

    /// The value of a track of (second, value) points at `t` seconds: eased between two points, held before the
    /// first and after the last.
    private static func traccia(_ punti: [(TimeInterval, CGFloat)], _ t: TimeInterval) -> CGFloat {
        guard let primo = punti.first, let ultimo = punti.last else { return 0 }
        if t <= primo.0 { return primo.1 }
        if t >= ultimo.0 { return ultimo.1 }
        for (a, b) in zip(punti, punti.dropFirst()) where t < b.0 {
            let k = CGFloat((t - a.0) / (b.0 - a.0))
            return a.1 + (b.1 - a.1) * k * k * (3 - 2 * k)
        }
        return ultimo.1
    }
}
