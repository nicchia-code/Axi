import CoreGraphics
import Foundation
import Testing
@testable import Axi

@Suite("Vector drawing of the dot")
struct PuntinoDisegnoTests {
    @Test("On the screen the character is drawn about 48 pt high, as the Requirements set")
    @MainActor
    func dimensioneSulloSchermo() {
        let vista = PuntinoVista(modello: PuntinoModello())
        #expect(vista.dimensione == 48)
    }

    @Test("The dot's window is 1.75 times the character, so it fits the character grown by files, bounce and check")
    @MainActor
    func finestraContieneIlPersonaggio() {
        let vista = PuntinoVista(modello: PuntinoModello())
        let lato = PuntinoController.dimensionePuntino.width
        #expect(lato == vista.dimensione * 1.75)
        // The largest drawn side: the character at its file-drop scale (1.25), with the bounce lifting it.
        #expect(vista.dimensione * 1.25 < lato)
    }

    @Test("At rest the three drops coincide with the body, with the eyes visible")
    func restCoincidesWithBody() {
        let forme = PuntinoGeometria.forme(trasformazione: 0, fase: 0, respiro: 0)
        #expect(forme.gocce.count == 3)
        for goccia in forme.gocce {
            #expect(vicino(goccia.ellisse.centro.x, PuntinoGeometria.centroCorpo.x))
            #expect(vicino(goccia.ellisse.centro.y, PuntinoGeometria.centroCorpo.y))
        }
        #expect(vicino(forme.gocce[1].ellisse.raggioX, 35))
        #expect(vicino(forme.gocce[1].ellisse.raggioY, 31))
        #expect(vicino(forme.gocce[1].dettagli, 1))
        #expect(vicino(forme.opacitaOcchi, 1))
        #expect(nessunSatellite(forme))
    }

    @Test("At rest the body stays still at any phase of the cycle")
    func fermoNonRespira() {
        for fase: CGFloat in [0, CGFloat.pi / 2, -CGFloat.pi / 2] {
            let corpo = PuntinoGeometria.forme(trasformazione: 0, fase: fase, respiro: 0).gocce[1].ellisse
            #expect(vicino(corpo.raggioX, 35))
            #expect(vicino(corpo.raggioY, 31))
        }
    }

    @Test("In the wait the body breathes as an ellipse: wider and flatter, then narrower and taller")
    func attesaRespiraComeEllisse() {
        let forme = PuntinoGeometria.forme(trasformazione: 0, fase: CGFloat.pi / 2, respiro: 1)
        let corpo = forme.gocce[1].ellisse
        #expect(corpo.raggioX < 35)
        #expect(corpo.raggioY > 31)
        #expect(corpo.rotazione == 0)
    }

    @Test("At three dots the drops sit at 25, 50 and 75 with radius 9, as equal solid circles")
    func trePuntini() {
        // A phase at which no drop is lifted yet (sin is negative for all three).
        let forme = PuntinoGeometria.forme(trasformazione: 1, fase: -CGFloat.pi / 2, respiro: 0)
        let ascisse = forme.gocce.map { $0.ellisse.centro.x }
        #expect(ascisse.count == 3)
        for (ascissa, atteso) in zip(ascisse, [25, 50, 75] as [CGFloat]) {
            #expect(vicino(ascissa, atteso))
        }
        for goccia in forme.gocce {
            #expect(vicino(goccia.ellisse.centro.y, 50))
            #expect(vicino(goccia.ellisse.raggioX, 9))
            #expect(vicino(goccia.ellisse.raggioY, 9))
            #expect(vicino(goccia.dettagli, 0))
            #expect(goccia.luce == goccia.ellisse)
        }
        #expect(vicino(forme.opacitaOcchi, 0))
        #expect(nessunSatellite(forme))
    }

    @Test("The change eases from the starting value to the target over its duration")
    func trasformazioneEase() {
        let inizio = Date(timeIntervalSinceReferenceDate: 0)
        var trasformazione = PuntinoTrasformazione()
        trasformazione.vaVerso(1, al: inizio, durata: 0.4)
        #expect(vicino(trasformazione.valore(al: inizio), 0))
        #expect(vicino(trasformazione.valore(al: inizio.addingTimeInterval(0.2)), 0.5))
        #expect(vicino(trasformazione.valore(al: inizio.addingTimeInterval(0.4)), 1))
        #expect(vicino(trasformazione.valore(al: inizio.addingTimeInterval(9)), 1))
    }

    @Test("A change of target starts from the value reached at that moment")
    func trasformazioneInversa() {
        let inizio = Date(timeIntervalSinceReferenceDate: 0)
        var trasformazione = PuntinoTrasformazione()
        trasformazione.vaVerso(1, al: inizio, durata: 0.4)
        let meta = inizio.addingTimeInterval(0.2)
        trasformazione.vaVerso(0, al: meta, durata: 0.4)
        #expect(vicino(trasformazione.valore(al: meta), 0.5))
        #expect(vicino(trasformazione.valore(al: meta.addingTimeInterval(0.2)), 0.25))
        #expect(vicino(trasformazione.valore(al: meta.addingTimeInterval(0.4)), 0))
    }

    @Test("A zero duration jumps straight to the target")
    func durataZero() {
        let inizio = Date(timeIntervalSinceReferenceDate: 0)
        var trasformazione = PuntinoTrasformazione()
        trasformazione.vaVerso(1, al: inizio, durata: 0)
        #expect(vicino(trasformazione.valore(al: inizio), 1))
    }

    @Test("No satellite is drawn at any aspect: the upper-right and lower-left spots stay empty")
    func senzaSatelliti() {
        for trasformazione: CGFloat in [0, 0.25, 0.5, 0.75, 1] {
            for fase: CGFloat in [0, -CGFloat.pi / 2, CGFloat.pi / 2] {
                let forme = PuntinoGeometria.forme(trasformazione: trasformazione, fase: fase, respiro: 1)
                #expect(nessunSatellite(forme))
            }
        }
    }

    private func vicino(_ a: CGFloat, _ b: CGFloat) -> Bool {
        abs(a - b) < 1e-6
    }

    /// True when neither of the old satellite spots (upper right and lower left) is covered by a drop or an eye.
    private func nessunSatellite(_ forme: PuntinoForme) -> Bool {
        let spot = [CGPoint(x: 80, y: 20), CGPoint(x: 18, y: 84)]
        let ellissi = forme.gocce.map(\.ellisse) + forme.occhi
        return spot.allSatisfy { punto in
            ellissi.allSatisfy { e in
                let dx = (punto.x - e.centro.x) / e.raggioX
                let dy = (punto.y - e.centro.y) / e.raggioY
                return dx * dx + dy * dy > 1
            }
        }
    }

    private func vicino(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) < 1e-6
    }
}
