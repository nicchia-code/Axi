import AxiScreen
import CoreGraphics
import Foundation
import Testing
@testable import AxiCore

@Suite("Archiviazione di un documento")
struct ArchivingPipelineTests {
    private func file(_ bench: ArchiveTestBench, _ name: String) throws -> DocumentCandidate {
        .file(FileDocument(url: try bench.userFile(name), source: bench.app))
    }

    @Test("Un PDF nuovo entra nel vault con titolo, tag e copia")
    func newPDFIsArchived() async throws {
        let bench = try ArchiveTestBench()
        let candidate = try file(bench, "documento-testo.pdf")

        let outcome = await bench.pipeline().archive(candidate, moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(result.titolo == "Fattura di prova")
        #expect(result.tag == ["fattura", "progetto"])
        #expect(result.allegatiNonPresi.isEmpty)
        #expect(FileManager.default.fileExists(atPath: result.copia.path()))
        let hash = try Fingerprint.sha256(fileAt: ArchiveFixtures.url("documento-testo.pdf"))
        #expect(try bench.vault.document(withContentHash: hash) != nil)
    }

    @Test("Un documento già nel vault non viene archiviato di nuovo")
    func duplicateIsReported() async throws {
        let bench = try ArchiveTestBench()
        let pipeline = bench.pipeline()
        let first = await pipeline.archive(try file(bench, "documento-testo.pdf"), moment: ArchiveTestBench.readingMoment)
        guard case .archived(let original) = first else {
            Issue.record("Il primo archivio doveva riuscire, ottenuto \(first)")
            return
        }
        let filesAfterFirst = bench.storedFileCount

        let second = await pipeline.archive(try file(bench, "documento-testo.pdf"), moment: ArchiveTestBench.readingMoment)

        guard case .notArchived(.giaPresente(let copy)) = second else {
            Issue.record("Atteso già presente, ottenuto \(second)")
            return
        }
        #expect(copy.lastPathComponent == original.copia.lastPathComponent)
        #expect(bench.storedFileCount == filesAfterFirst)
    }

    @Test("Se l'AI non risponde nel formato atteso, nulla resta nel vault")
    func invalidAIAnswerLeavesNothing() async throws {
        let bench = try ArchiveTestBench()
        let pipeline = bench.pipeline(assistant: FakeAssistant(reply: "non so rispondere"))

        let outcome = await pipeline.archive(try file(bench, "documento-testo.pdf"), moment: ArchiveTestBench.readingMoment)

        #expect(outcome == .notArchived(.aiNonRisponde))
        #expect(bench.storedFileCount == 0)
        let hash = try Fingerprint.sha256(fileAt: ArchiveFixtures.url("documento-testo.pdf"))
        #expect(try bench.vault.document(withContentHash: hash) == nil)
    }

    @Test("Una scansione senza testo riconoscibile non viene archiviata")
    func scanWithoutTextIsRejected() async throws {
        let bench = try ArchiveTestBench()
        let pipeline = bench.pipeline(recognizer: FakeRecognizer(text: "   "))

        let outcome = await pipeline.archive(try file(bench, "documento-scansione.pdf"), moment: ArchiveTestBench.readingMoment)

        #expect(outcome == .notArchived(.testoAssente))
        #expect(bench.storedFileCount == 0)
    }

    @Test("Un errore del riconoscitore di testo è un errore imprevisto, non un testo assente")
    func recognizerFailureIsUnexpected() async throws {
        struct BrokenRecognizer: TextRecognizing {
            let source = TextSource.vision
            func recognizeText(in image: CGImage) async throws -> String {
                throw CocoaError(.fileReadUnknown)
            }
        }
        let bench = try ArchiveTestBench()
        let pipeline = bench.pipeline(recognizer: BrokenRecognizer())

        let outcome = await pipeline.archive(try file(bench, "documento-scansione.pdf"), moment: ArchiveTestBench.readingMoment)

        #expect(outcome == .notArchived(.erroreImprevisto))
        #expect(bench.storedFileCount == 0)
    }

    @Test("Una scansione con Azure configurato viene archiviata con il testo di Azure")
    func scanIsArchivedWithAzureText() async throws {
        let bench = try ArchiveTestBench()
        let pipeline = bench.pipeline(recognizer: azureRecognizer(text: "Testo letto da Azure"))

        let outcome = await pipeline.archive(try file(bench, "documento-scansione.pdf"), moment: ArchiveTestBench.readingMoment)

        guard case .archived = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(bench.storedFileCount > 0)
    }

    @Test("Un file in formato sconosciuto è illeggibile")
    func unknownFormatIsUnreadable() async throws {
        let bench = try ArchiveTestBench()
        let folder = bench.root.appending(path: "user")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let garbage = folder.appending(path: "dati.zip")
        try Data([0x00, 0xFF, 0x13, 0x37]).write(to: garbage)

        let outcome = await bench.pipeline().archive(.file(FileDocument(url: garbage, source: bench.app)), moment: ArchiveTestBench.readingMoment)

        #expect(outcome == .notArchived(.documentoIllegibile))
        #expect(bench.storedFileCount == 0)
    }

    @Test("Se l'indicizzazione fallisce, il documento non entra e le copie vengono rimosse")
    func indexingFailureRollsBack() async throws {
        let bench = try ArchiveTestBench()
        let pipeline = bench.pipeline(embedder: FakeEmbedder(answersCount: 0))

        let outcome = await pipeline.archive(try file(bench, "documento-testo.pdf"), moment: ArchiveTestBench.readingMoment)

        #expect(outcome == .notArchived(.indicizzazioneFallita))
        #expect(bench.storedFileCount == 0)
        let hash = try Fingerprint.sha256(fileAt: ArchiveFixtures.url("documento-testo.pdf"))
        #expect(try bench.vault.document(withContentHash: hash) == nil)
    }

    @Test("Un errore imprevisto in archiviazione non archivia nulla e non è un'indicizzazione fallita")
    func unexpectedErrorRollsBack() async throws {
        let bench = try ArchiveTestBench()
        // Vectors of another size than the vault's: the vault refuses them while committing.
        let pipeline = bench.pipeline(embedder: FakeEmbedder(dimension: 4))

        let outcome = await pipeline.archive(try file(bench, "documento-testo.pdf"), moment: ArchiveTestBench.readingMoment)

        #expect(outcome == .notArchived(.erroreImprevisto))
        #expect(bench.storedFileCount == 0)
        let hash = try Fingerprint.sha256(fileAt: ArchiveFixtures.url("documento-testo.pdf"))
        #expect(try bench.vault.document(withContentHash: hash) == nil)
    }

    @Test("Un'email archiviata registra gli allegati presi e segnala quelli mancanti")
    func emailWithAttachments() async throws {
        let bench = try ArchiveTestBench()
        let taken = try bench.userFile("documento-testo.pdf", as: "contratto.pdf")
        let email = EmailMessage(
            sender: "Mario Rossi <mario.rossi@example.com>",
            recipients: ["luca@example.com"],
            subject: "Contratto",
            sentAt: "Mon, 6 Oct 2025 09:30:00 +0200",
            body: "Ti invio il contratto firmato.",
            attachmentNames: ["contratto.pdf", "firma.png"],
            source: bench.app
        )
        let attachments = FakeAttachments(answers: [
            .file(name: "contratto.pdf", url: taken),
            .missing(name: "firma.png"),
        ])

        let outcome = await bench.pipeline(attachments: attachments).archive(.email(email), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(result.allegatiNonPresi == ["firma.png"])
        #expect(result.titolo == "Fattura di prova")
        let hash = Fingerprint.email(
            sender: "Mario Rossi <mario.rossi@example.com>",
            receivedDay: nil,
            subject: "Contratto",
            body: "Ti invio il contratto firmato."
        )
        let stored = try #require(try bench.vault.document(withContentHash: hash))
        #expect(stored.kind == .email)
        #expect(try bench.vault.attachmentIDs(of: stored.id).count == 1)
    }

    @Test("Un allegato il cui testo non si legge per un errore imprevisto è mancante e non ferma l'email")
    func attachmentTextErrorIsMissingAndEmailIsArchived() async throws {
        let bench = try ArchiveTestBench()
        let taken = try bench.userFile("documento-scansione.pdf", as: "scansione.pdf")
        let email = EmailMessage(
            sender: "Mario Rossi <mario.rossi@example.com>",
            recipients: ["luca@example.com"],
            subject: "Scansione",
            sentAt: "Mon, 6 Oct 2025 09:30:00 +0200",
            body: "Ti invio la scansione firmata.",
            attachmentNames: ["scansione.pdf"],
            source: bench.app
        )
        let attachments = FakeAttachments(answers: [.file(name: "scansione.pdf", url: taken)])

        let outcome = await bench.pipeline(
            recognizer: ThrowingRecognizer(),
            attachments: attachments
        ).archive(.email(email), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(result.allegatiNonPresi == ["scansione.pdf"])
        let hash = Fingerprint.email(
            sender: "Mario Rossi <mario.rossi@example.com>",
            receivedDay: nil,
            subject: "Scansione",
            body: "Ti invio la scansione firmata."
        )
        let stored = try #require(try bench.vault.document(withContentHash: hash))
        #expect(try bench.vault.attachmentIDs(of: stored.id).isEmpty)
    }

    @Test("Un file con il nome di un allegato di un'email nel vault, fuori dalla cartella di Outlook, non ne è allegato")
    func fileOutsideOutlookFolderIsNotLinkedToVaultEmail() async throws {
        let bench = try ArchiveTestBench()
        let email = EmailMessage(
            sender: "Mario Rossi <mario.rossi@example.com>",
            recipients: ["luca@example.com"],
            subject: "Contratto",
            sentAt: "Mon, 6 Oct 2025 09:30:00 +0200",
            body: "Ti invio il contratto firmato.",
            attachmentNames: ["contratto.pdf"],
            source: bench.app
        )
        let attachments = FakeAttachments(answers: [.missing(name: "contratto.pdf")])
        _ = await bench.pipeline(attachments: attachments).archive(.email(email), moment: ArchiveTestBench.readingMoment)

        let copy = try bench.userFile("documento-testo.pdf", as: "contratto.pdf")
        let outcome = await bench.pipeline().archive(.file(FileDocument(url: copy, source: bench.app)), moment: ArchiveTestBench.readingMoment)

        guard case .archived = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        let hash = try Fingerprint.sha256(fileAt: ArchiveFixtures.url("documento-testo.pdf"))
        let stored = try #require(try bench.vault.document(withContentHash: hash))
        #expect(stored.emailID == nil)
    }

    @Test("Una pagina web con PDF corrispondente conserva la copia PDF")
    func webPageKeepsMatchingPDF() async throws {
        let bench = try ArchiveTestBench()
        let pdf = try Data(contentsOf: ArchiveFixtures.url("documento-testo.pdf"))
        let visible = TextExtractor.nativeText(of: ArchiveFixtures.url("documento-testo.pdf"))
        try #require(!visible.isEmpty)
        let page = WebPage(address: URL(string: "https://example.com/pagina")!, visibleText: visible, source: bench.app)

        let outcome = await bench.pipeline(webPages: FakeWebPages(result: pdf)).archive(.webPage(page), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(!result.pdfNonPresente)
        let stored = try #require(try bench.vault.document(withContentHash: Fingerprint.sha256(pdf)))
        #expect(try bench.vault.copyURL(ofDocument: stored.id) != nil)
    }

    @Test("Una pagina web con PDF diverso archivia il testo visibile senza PDF")
    func webPageWithMismatchingPDFDropsIt() async throws {
        let bench = try ArchiveTestBench()
        let pdf = try Data(contentsOf: ArchiveFixtures.url("documento-testo.pdf"))
        let page = WebPage(
            address: URL(string: "https://example.com/altra")!,
            visibleText: "parole completamente diverse da quelle del documento",
            source: bench.app
        )

        let outcome = await bench.pipeline(webPages: FakeWebPages(result: pdf)).archive(.webPage(page), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(bench.storedFileCount == 0)
        #expect(result.pdfNonPresente)
        let stored = try #require(try bench.vault.document(withContentHash: Fingerprint.webPage(
            address: page.address, visibleText: page.visibleText ?? ""
        )))
        #expect(stored.kind == .web)
        #expect(try bench.vault.copyURL(ofDocument: stored.id) == nil)
        #expect(try bench.vault.sourceURL(ofDocument: stored.id) == page.address)
    }

    @Test("Una pagina web che non si può stampare si archivia solo come testo")
    func webPageWithoutPDF() async throws {
        let bench = try ArchiveTestBench()
        let page = WebPage(
            address: URL(string: "https://example.com/senza-pdf")!,
            visibleText: "testo della pagina",
            source: bench.app
        )

        let outcome = await bench.pipeline(webPages: FakeWebPages(result: nil)).archive(.webPage(page), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(bench.storedFileCount == 0)
        #expect(result.pdfNonPresente)
    }

    @Test("Un indirizzo che serve un PDF archivia il PDF scaricato, senza leggere la pagina")
    func downloadedPDFIsArchived() async throws {
        let bench = try ArchiveTestBench()
        let page = WebPage(address: URL(string: "https://example.com/fattura.pdf")!, visibleText: nil, source: bench.app)
        let download = try FakeWebPageDownloader.pdf(fixture: "documento-testo.pdf", suggestedName: "fattura.pdf")
        guard case .pdf(let file, _) = download else { return }

        let outcome = await bench.pipeline(downloads: FakeWebPageDownloader(.success(download)))
            .archive(.webPage(page), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(!result.pdfNonPresente)
        let hash = try Fingerprint.sha256(fileAt: ArchiveFixtures.url("documento-testo.pdf"))
        let stored = try #require(try bench.vault.document(withContentHash: hash))
        #expect(stored.kind == .pdf)
        #expect(try bench.vault.copyURL(ofDocument: stored.id) != nil)
        #expect(!FileManager.default.fileExists(atPath: file.path))
    }

    @Test("Una risposta che non è un PDF prosegue come pagina web")
    func notPDFResponseFallsBackToWebPage() async throws {
        let bench = try ArchiveTestBench()
        let page = WebPage(address: URL(string: "https://example.com/pagina")!, visibleText: "testo della pagina", source: bench.app)

        let outcome = await bench.pipeline(
            webPages: FakeWebPages(result: nil),
            downloads: FakeWebPageDownloader(.success(.notPDF))
        ).archive(.webPage(page), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(result.pdfNonPresente)
        let stored = try #require(try bench.vault.document(withContentHash: Fingerprint.webPage(
            address: page.address, visibleText: page.visibleText ?? ""
        )))
        #expect(stored.kind == .web)
    }

    @Test(
        "Un PDF non scaricato da un indirizzo che lo dichiara non si archivia",
        arguments: [WebPageDownloadFailure.timedOut, .network, .notPDF]
    )
    func declaredPDFNotDownloadedIsNotArchived(failure: WebPageDownloadFailure) async throws {
        let bench = try ArchiveTestBench()
        let page = WebPage(address: URL(string: "https://example.com/fattura.pdf")!, visibleText: "testo", source: bench.app)

        let outcome = await bench.pipeline(downloads: FakeWebPageDownloader(.failure(failure)))
            .archive(.webPage(page), moment: ArchiveTestBench.readingMoment)

        #expect(outcome == .notArchived(.pdfNonScaricato))
        #expect(bench.storedFileCount == 0)
    }

    @Test("Un PDF oltre il limite di dimensione non si archivia")
    func tooLargePDFIsNotArchived() async throws {
        let bench = try ArchiveTestBench()
        let page = WebPage(address: URL(string: "https://example.com/grande.pdf")!, visibleText: "testo", source: bench.app)

        let outcome = await bench.pipeline(downloads: FakeWebPageDownloader(.failure(.tooLarge)))
            .archive(.webPage(page), moment: ArchiveTestBench.readingMoment)

        #expect(outcome == .notArchived(.pdfTroppoGrande))
        #expect(bench.storedFileCount == 0)
    }
}
