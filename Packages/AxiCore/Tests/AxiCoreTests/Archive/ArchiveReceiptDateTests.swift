import AxiScreen
import GRDB
import Foundation
import Testing
@testable import AxiCore

/// Answers the receipt-date request with `receipt` (nil: the request fails), and every other prompt with the metadata reply.
struct ReceiptAssistant: AIAssistant {
    var receipt: String?

    func complete(_ prompt: String) async throws -> String {
        guard prompt.contains("\"receivedAt\"") else { return validMetadataReply }
        guard let receipt else { throw URLError(.notConnectedToInternet) }
        return receipt
    }
}

@Suite("Data di ricezione assoluta delle email")
struct ReceiptDateTests {
    @Test("Una risposta con istante e offset dà la data di ricezione")
    func parsesInstantWithOffset() throws {
        let date = try #require(ReceiptDate.parse(#"{"receivedAt": "2025-10-09T14:30:00+02:00"}"#))
        #expect(date == Date(timeIntervalSince1970: 1_760_013_000))
    }

    @Test("Un istante in UTC con Z è valido")
    func parsesUTCInstant() {
        #expect(ReceiptDate.parse(#"{"receivedAt": "2025-10-09T12:30:00Z"}"#) != nil)
    }

    @Test("Un istante senza offset, null, una risposta non JSON o un altro tipo non danno data")
    func invalidAnswersGiveNoDate() {
        #expect(ReceiptDate.parse(#"{"receivedAt": "2025-10-09T14:30:00"}"#) == nil)
        #expect(ReceiptDate.parse(#"{"receivedAt": null}"#) == nil)
        #expect(ReceiptDate.parse(#"{"receivedAt": 1760013000}"#) == nil)
        #expect(ReceiptDate.parse(#"{"altro": "2025-10-09T14:30:00+02:00"}"#) == nil)
        #expect(ReceiptDate.parse("ieri alle 14:30") == nil)
        #expect(ReceiptDate.parse(validMetadataReply) == nil)
    }

    @Test("Un'email con data di ricezione sconosciuta si archivia senza data, con il testo mostrato")
    func unknownReceiptDateStillArchives() async throws {
        let bench = try ArchiveTestBench()
        let email = outlookEmail(bench, displayed: "ieri alle 14:30")

        let outcome = await bench.pipeline(assistant: ReceiptAssistant(receipt: #"{"receivedAt": null}"#))
            .archive(.email(email), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(result.dataRicezioneSconosciuta)
        let hash = Fingerprint.email(sender: email.sender ?? "", receivedDay: nil, subject: email.subject ?? "", body: email.body)
        let stored = try #require(try bench.vault.document(withContentHash: hash))
        let row = try emailRow(bench, documentID: stored.id)
        #expect(row["sent_at"] as String? == nil)
        #expect(row["sent_at_displayed"] as String? == "ieri alle 14:30")
    }

    @Test("Un documento che non è un'email non mostra la nota sulla data di ricezione")
    func nonEmailDocumentHasNoReceiptDateNote() async throws {
        let bench = try ArchiveTestBench()
        let file = try bench.userFile("documento-testo.pdf")

        let outcome = await bench.pipeline(assistant: ReceiptAssistant(receipt: nil))
            .archive(.file(FileDocument(url: file, source: bench.app)), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(!result.dataRicezioneSconosciuta)
    }

    @Test("Se la richiesta di data fallisce l'email si archivia con la data sconosciuta")
    func failedRequestStillArchives() async throws {
        let bench = try ArchiveTestBench()
        let email = outlookEmail(bench, displayed: "ieri alle 14:30")

        let outcome = await bench.pipeline(assistant: ReceiptAssistant(receipt: nil))
            .archive(.email(email), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(result.dataRicezioneSconosciuta)
    }

    @Test("Un file salvato da Outlook con la sua email senza data di ricezione segnala la data sconosciuta")
    func unknownReceiptDateOfLinkedEmailIsFlagged() async throws {
        let bench = try ArchiveTestBench()
        let message = EmailMessage(
            sender: "Mario Rossi <mario.rossi@example.com>",
            recipients: ["luca@example.com"],
            subject: "Contratto",
            sentAt: "ieri alle 14:30",
            body: "Ti invio il contratto firmato.",
            attachmentNames: ["contratto.pdf"],
            source: bench.app
        )
        let folder = bench.root.appending(path: "com.microsoft.Outlook")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "contratto.pdf")
        try FileManager.default.copyItem(at: ArchiveFixtures.url("documento-testo.pdf"), to: file)

        let outcome = await bench.pipeline(
            assistant: ReceiptAssistant(receipt: #"{"receivedAt": null}"#),
            outlook: ScreenOutlook(message: message)
        ).archive(.file(FileDocument(url: file, source: bench.app)), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(result.dataRicezioneSconosciuta)
        let hash = try Fingerprint.sha256(fileAt: ArchiveFixtures.url("documento-testo.pdf"))
        let stored = try #require(try bench.vault.document(withContentHash: hash))
        #expect(stored.emailID != nil)
    }

    @Test("La data di ricezione data da OMP entra nell'impronta come giorno assoluto")
    func knownReceiptDateIsStoredAndHashed() async throws {
        let bench = try ArchiveTestBench()
        let email = outlookEmail(bench, displayed: "ieri alle 14:30")

        let outcome = await bench.pipeline(assistant: ReceiptAssistant(receipt: #"{"receivedAt": "2025-10-09T14:30:00+02:00"}"#))
            .archive(.email(email), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(!result.dataRicezioneSconosciuta)
        let hash = Fingerprint.email(
            sender: email.sender ?? "", receivedDay: "2025-10-09", subject: email.subject ?? "", body: email.body)
        let stored = try #require(try bench.vault.document(withContentHash: hash))
        let row = try emailRow(bench, documentID: stored.id)
        #expect(row["sent_at"] as String? != nil)
        #expect(row["sent_at_displayed"] as String? == "ieri alle 14:30")
    }

    private func emailRow(_ bench: ArchiveTestBench, documentID: String) throws -> Row {
        try #require(try bench.vault.dbQueue.read { db in
            try Row.fetchOne(db, sql: "SELECT sent_at, sent_at_displayed FROM email_details WHERE document_id = ?", arguments: [documentID])
        })
    }

    @Test("La stessa email mostrata con un altro testo lo stesso giorno è riconosciuta come duplicato")
    func sameReceiptDayIsDuplicate() async throws {
        let bench = try ArchiveTestBench()
        let pipeline = bench.pipeline(assistant: ReceiptAssistant(receipt: #"{"receivedAt": "2025-10-09T14:30:00+02:00"}"#))

        let first = await pipeline.archive(.email(outlookEmail(bench, displayed: "ieri alle 14:30")), moment: ArchiveTestBench.readingMoment)
        guard case .archived = first else {
            Issue.record("Il primo archivio doveva riuscire, ottenuto \(first)")
            return
        }
        let second = await pipeline.archive(.email(outlookEmail(bench, displayed: "09/10/2025 14:30")), moment: ArchiveTestBench.readingMoment)

        guard case .notArchived(.giaPresente) = second else {
            Issue.record("Atteso già presente, ottenuto \(second)")
            return
        }
    }

    private func outlookEmail(_ bench: ArchiveTestBench, displayed: String) -> EmailMessage {
        EmailMessage(
            sender: "Mario Rossi <mario.rossi@example.com>",
            recipients: ["luca@example.com"],
            subject: "Contratto",
            sentAt: displayed,
            body: "Ti invio il contratto firmato.",
            attachmentNames: [],
            source: bench.app
        )
    }
}

/// Shows the given email on screen in Outlook, as the archiving reads it.
struct ScreenOutlook: OutlookEmailReading {
    let message: EmailMessage

    func emailOnScreen() async -> EmailMessage? { message }
}
