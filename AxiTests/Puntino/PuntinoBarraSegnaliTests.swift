import Testing
@testable import Axi

@Suite("Monochrome counter in the menu bar")
struct PuntinoBarraSegnaliTests {
    @Test("A single digit gets a circle as wide as the minimum capsule, beside the character")
    @MainActor
    func unaCifraCerchio() {
        let larghezza = PuntinoBarraTemplate.larghezza(contatore: "3")
        let atteso = PuntinoBarraTemplate.inizioContatore + PuntinoBarraTemplate.larghezzaCapsula("3")
        #expect(abs(larghezza - atteso) < 0.001)
        #expect(abs(larghezza - 40) < 0.001)
    }

    @Test("Two or more digits widen the capsule, so the item grows with the number")
    @MainActor
    func piuCifreAllargano() {
        #expect(PuntinoBarraTemplate.larghezzaCapsula("12") > PuntinoBarraTemplate.larghezzaCapsula("3"))
        #expect(PuntinoBarraTemplate.larghezza(contatore: "120") > PuntinoBarraTemplate.larghezza(contatore: "12"))
    }

    @Test("Without a counter the image is the square of the character")
    @MainActor
    func senzaContatoreQuadrato() {
        #expect(PuntinoBarraTemplate.larghezza(contatore: nil) == PuntinoBarraTemplate.lato)
    }
}
