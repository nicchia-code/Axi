import AxiOMP
import AxiScreen
import Foundation
import Testing
@testable import AxiCore

@Suite("Servizio di archiviazione")
struct ArchivingServiceTests {
    private func makeService(
        bench: ArchiveTestBench,
        assistant: any AIAssistant = FakeAssistant(),
        welcomeCompleted: Bool = true,
        ompReady: Bool = true
    ) -> ArchivingService {
        ArchivingService(
            vault: bench.vault,
            recognizer: FakeRecognizer(),
            assistant: assistant,
            embedder: FakeEmbedder(),
            attachments: nil,
            webPages: FakeWebPages(result: nil),
            downloads: FakeWebPageDownloader(),
            outlook: FakeOutlook(),
            interfaceLanguage: "it",
            activeModelContextWindow: { 32_000 },
            welcomeCompleted: { welcomeCompleted },
            ompReady: { ompReady }
        )
    }

    @Test("Senza benvenuto completato il documento non entra nel vault")
    func welcomeNotCompleted() async throws {
        let bench = try ArchiveTestBench()
        let service = makeService(bench: bench, welcomeCompleted: false)
        var events = service.events.makeAsyncIterator()
        let file = try bench.userFile("documento-testo.pdf")

        await service.receive([.file(FileDocument(url: file, source: bench.app))], at: .now)

        #expect(await events.next() == .prossimoDocumento(inCoda: 0, nome: "documento-testo.pdf"))
        #expect(await events.next() == .nonArchiviato(.benvenutoNonCompletato, inCoda: 0))
        #expect(bench.storedFileCount == 0)
    }

    @Test("Con OMP non pronto il documento non entra nel vault")
    func ompNotReady() async throws {
        let bench = try ArchiveTestBench()
        let service = makeService(bench: bench, ompReady: false)
        var events = service.events.makeAsyncIterator()
        let file = try bench.userFile("documento-testo.pdf")

        await service.receive([.file(FileDocument(url: file, source: bench.app))], at: .now)

        #expect(await events.next() == .prossimoDocumento(inCoda: 0, nome: "documento-testo.pdf"))
        #expect(await events.next() == .nonArchiviato(.ompNonPronto, inCoda: 0))
        #expect(bench.storedFileCount == 0)
    }

    @Test("Un archivio riuscito emette l'esito con il titolo e i tag")
    func successfulArchiving() async throws {
        let bench = try ArchiveTestBench()
        let service = makeService(bench: bench)
        var events = service.events.makeAsyncIterator()
        let file = try bench.userFile("documento-testo.pdf")

        await service.receive([.file(FileDocument(url: file, source: bench.app))], at: .now)

        #expect(await events.next() == .prossimoDocumento(inCoda: 0, nome: "documento-testo.pdf"))
        #expect(await events.next() == .generazioneMetadatiIniziata)
        #expect(await events.next() == .generazioneMetadatiFinita)
        guard case .archiviato(let result, let inCoda) = await events.next() else {
            Issue.record("Atteso un esito di archiviazione riuscita")
            return
        }
        #expect(inCoda == 0)
        #expect(result.titolo == "Fattura di prova")
        #expect(result.tag == ["fattura", "progetto"])
    }

    @Test("Con un documento in coda l'esito conta il prossimo e non passa per il riposo")
    func outcomeCountsNextDocumentAsWaiting() async throws {
        let bench = try ArchiveTestBench()
        let service = makeService(bench: bench)
        var events = service.events.makeAsyncIterator()
        let first = try bench.userFile("documento-testo.pdf", as: "primo.pdf")
        let second = try bench.userFile("documento-testo.pdf", as: "secondo.pdf")

        await service.receive([
            .file(FileDocument(url: first, source: bench.app)),
            .file(FileDocument(url: second, source: bench.app)),
        ], at: .now)

        #expect(await events.next() == .prossimoDocumento(inCoda: 1, nome: "primo.pdf"))
        #expect(await events.next() == .generazioneMetadatiIniziata)
        #expect(await events.next() == .generazioneMetadatiFinita)
        guard case .archiviato(_, let inCoda) = await events.next() else {
            Issue.record("Atteso un esito di archiviazione riuscita")
            return
        }
        #expect(inCoda == 1)
        #expect(await events.next() == .prossimoDocumento(inCoda: 0, nome: "secondo.pdf"))
    }

    @Test("OMP che termina interrompe l'archiviazione in corso senza lasciare copie")
    func ompTerminationStopsArchiving() async throws {
        let bench = try ArchiveTestBench()
        let service = makeService(bench: bench, assistant: SilentAssistant())
        let (ompEvents, ompContinuation) = AsyncStream.makeStream(of: OMPEvent.self)
        service.observeOMP(ompEvents)
        var events = service.events.makeAsyncIterator()
        let file = try bench.userFile("documento-testo.pdf")

        await service.receive([.file(FileDocument(url: file, source: bench.app))], at: .now)
        #expect(await events.next() == .prossimoDocumento(inCoda: 0, nome: "documento-testo.pdf"))
        #expect(await events.next() == .generazioneMetadatiIniziata)
        ompContinuation.yield(.terminated)

        #expect(await events.next() == .generazioneMetadatiFinita)
        #expect(await events.next() == .nonArchiviato(.ompFermato, inCoda: 0))
        #expect(bench.storedFileCount == 0)
        ompContinuation.finish()
    }
}
