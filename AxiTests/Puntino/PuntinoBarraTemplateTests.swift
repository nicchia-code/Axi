import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import Axi

@Suite("Template image of the dot in the menu bar")
struct PuntinoBarraTemplateTests {
    @Test("The menu bar image is a template of 22.5 pt")
    @MainActor
    func immagineTemplate() {
        let immagine = PuntinoBarraTemplate.immagine(forme: forme(trasformazione: 0, fase: 0, respiro: 0))
        #expect(immagine.isTemplate)
        #expect(immagine.size == NSSize(width: 22.5, height: 22.5))
    }

    @Test("At rest the body is one opaque silhouette with the eyes cut out")
    @MainActor
    func fermoConOcchiTrasparenti() throws {
        let pixel = try campioni(forme(trasformazione: 0, fase: 0, respiro: 0))
        // Inside the body, away from the eyes (the test is insensitive to the vertical flip of the image).
        #expect(pixel(50, 70) > 0.99)
        #expect(pixel(50, 35) > 0.99)
        // The centres of the eyes at 41 and 59, on the line of the eyes.
        #expect(pixel(41, 50) < 0.01)
        #expect(pixel(59, 50) < 0.01)
        // Outside the body.
        #expect(pixel(5, 5) < 0.01)
    }

    @Test("Dragged files lighten the silhouette with opacity, the overlapping drops do not get darker")
    @MainActor
    func trascinamentoSchiarisce() throws {
        let pixel = try campioni(
            forme(trasformazione: 0, fase: 0, respiro: 0),
            opacita: PuntinoBarraTemplate.opacitaTrascinamento
        )
        #expect(abs(pixel(50, 70) - 0.45) < 0.03)
        #expect(abs(pixel(50, 35) - 0.45) < 0.03)
    }

    @Test("At three dots the three drops are solid circles with a gap between them")
    @MainActor
    func trePuntiniSonoCerchi() throws {
        let pixel = try campioni(forme(trasformazione: 1, fase: -CGFloat.pi / 2, respiro: 0))
        #expect(pixel(25, 50) > 0.99)
        #expect(pixel(50, 50) > 0.99)
        #expect(pixel(75, 50) > 0.99)
        #expect(pixel(37, 50) < 0.01)
    }

    @MainActor
    private func forme(trasformazione: CGFloat, fase: CGFloat, respiro: CGFloat) -> PuntinoForme {
        PuntinoGeometria.forme(trasformazione: trasformazione, fase: fase, respiro: respiro)
    }

    /// Renders the image and returns the alpha at a point of the 100 × 100 drawing space, from 0 to 1.
    @MainActor
    private func campioni(_ forme: PuntinoForme, opacita: CGFloat = 1) throws -> (CGFloat, CGFloat) -> CGFloat {
        let immagine = PuntinoBarraTemplate.immagine(forme: forme, opacita: opacita)
        let cgImage = try #require(immagine.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let larghezza = cgImage.width
        let altezza = cgImage.height
        let contesto = try #require(CGContext(
            data: nil,
            width: larghezza,
            height: altezza,
            bitsPerComponent: 8,
            bytesPerRow: larghezza * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        contesto.draw(cgImage, in: CGRect(x: 0, y: 0, width: larghezza, height: altezza))
        let base = try #require(contesto.data).assumingMemoryBound(to: UInt8.self)
        let dati = Array(UnsafeBufferPointer(start: base, count: larghezza * altezza * 4))
        return { x, y in
            let colonna = min(larghezza - 1, Int(x / 100 * CGFloat(larghezza)))
            let riga = min(altezza - 1, Int(y / 100 * CGFloat(altezza)))
            return CGFloat(dati[(riga * larghezza + colonna) * 4 + 3]) / 255
        }
    }
}
