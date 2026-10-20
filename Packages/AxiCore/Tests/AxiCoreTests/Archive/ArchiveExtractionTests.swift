import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import AxiCore

@Suite("Estrazione del testo dai file")
struct TextExtractionTests {
    private func copy(_ name: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "extract-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let target = folder.appending(path: name)
        try FileManager.default.copyItem(at: ArchiveFixtures.url(name), to: target)
        return target
    }

    @Test("Un PDF con testo nativo dà il testo di ogni pagina")
    func nativePDFText() async throws {
        let file = try copy("documento-testo.pdf")
        let extractor = TextExtractor(recognizer: FakeRecognizer(text: "non usato"))

        let pages = try await extractor.pages(of: file)

        #expect(!pages.isEmpty)
        #expect(pages.allSatisfy { !$0.text.isEmpty })
        #expect(pages.first?.number == 1)
    }

    @Test("Un PDF scannerizzato passa dal riconoscitore di testo")
    func scannedPDFIsRecognized() async throws {
        let file = try copy("documento-scansione.pdf")
        let extractor = TextExtractor(recognizer: FakeRecognizer(text: "testo riconosciuto"))

        let pages = try await extractor.pages(of: file)

        #expect(pages.contains { $0.text.contains("testo riconosciuto") })
    }

    @Test("Un PDF scannerizzato con Azure configurato prende il testo da Azure")
    func scannedPDFUsesAzureWhenConfigured() async throws {
        let file = try copy("documento-scansione.pdf")
        let extractor = TextExtractor(recognizer: azureRecognizer(text: "Testo letto da Azure"))

        let pages = try await extractor.pages(of: file)

        #expect(pages.contains { $0.text == "Testo letto da Azure" })
    }

    @Test("Un'immagine multipagina dà una pagina per ogni fotogramma")
    func multipageImageGivesOnePagePerFrame() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "extract-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "tre-pagine.tiff")
        let frames = 3
        let destination = try #require(CGImageDestinationCreateWithURL(file as CFURL, "public.tiff" as CFString, frames, nil))
        for _ in 0..<frames {
            let context = try #require(CGContext(
                data: nil, width: 40, height: 40, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            CGImageDestinationAddImage(destination, try #require(context.makeImage()), nil)
        }
        #expect(CGImageDestinationFinalize(destination))
        let extractor = TextExtractor(recognizer: FakeRecognizer(text: "pagina"))

        let pages = try await extractor.pages(of: file)

        #expect(pages.map(\.number) == [1, 2, 3])
        #expect(pages.allSatisfy { $0.text == "pagina" })
    }

    @Test("Un documento Word dà il suo testo")
    func wordTextIsRead() async throws {
        let file = try copy("documento.docx")
        let extractor = TextExtractor(recognizer: FakeRecognizer())

        let pages = try await extractor.pages(of: file)

        #expect(pages.count == 1)
        #expect(!pages[0].text.isEmpty)
    }

    @Test("Un formato sconosciuto è illeggibile")
    func unknownFormatIsUnreadable() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "extract-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let garbage = folder.appending(path: "dati.zip")
        try Data([0x00, 0xFF, 0x13, 0x37]).write(to: garbage)
        let extractor = TextExtractor(recognizer: FakeRecognizer())

        await #expect(throws: TextExtractor.Failure.unreadable) {
            _ = try await extractor.pages(of: garbage)
        }
    }

    @Test("Il tipo di file si riconosce dall'estensione")
    func kindFromExtension() {
        #expect(TextExtractor.kind(of: URL(fileURLWithPath: "/a/b.PDF")) == .pdf)
        #expect(TextExtractor.kind(of: URL(fileURLWithPath: "/a/b.docx")) == .word)
        #expect(TextExtractor.kind(of: URL(fileURLWithPath: "/a/b.eml")) == .email)
        #expect(TextExtractor.kind(of: URL(fileURLWithPath: "/a/b.png")) == .image)
        #expect(TextExtractor.kind(of: URL(fileURLWithPath: "/a/b.xyz")) == .other)
    }
}
