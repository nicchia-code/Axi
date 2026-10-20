import AxiScreen
import Foundation
import Testing
@testable import AxiCore

/// An Accessibility reader whose Outlook window shows `before` until a save succeeds, then `after`.
private actor FakeAccessibility: AccessibilityReading {
    let before: AccessibilitySnapshot?
    let after: AccessibilitySnapshot?
    let saveSucceeds: Bool
    private(set) var actionsPerformed: [String] = []
    private var saved = false

    init(before: AccessibilitySnapshot?, after: AccessibilitySnapshot? = nil, saveSucceeds: Bool = true) {
        self.before = before
        self.after = after
        self.saveSucceeds = saveSucceeds
    }

    func snapshot(of application: ApplicationSnapshot) async -> AccessibilitySnapshot? {
        saved ? (after ?? before) : before
    }

    func perform(action: String, onElementNamed name: String, in application: ApplicationSnapshot) async -> Bool {
        actionsPerformed.append("\(action) \(name)")
        guard saveSucceeds else { return false }
        saved = true
        return true
    }
}

@Suite("Presa degli allegati da Outlook via Accessibility")
struct OutlookAttachmentTests {
    private let saveAction = "AXSaveAttachment"

    private func window(_ children: [AccessibilityNode]) -> AccessibilityNode {
        AccessibilityNode(role: "AXWindow", title: "Messaggio", children: children)
    }

    /// An attachment element offering the save action; `file` is what it exposes once saved.
    private func attachment(_ name: String, file: URL? = nil) -> AccessibilityNode {
        AccessibilityNode(role: "AXButton", title: name, url: file, actions: [saveAction])
    }

    private func email(_ bench: ArchiveTestBench, attachments: [String]) -> EmailMessage {
        EmailMessage(
            sender: "Mario Rossi <mario.rossi@example.com>",
            recipients: ["luca@example.com"],
            subject: "Contratto",
            sentAt: "Mon, 6 Oct 2025 09:30:00 +0200",
            body: "Ti invio il contratto firmato.",
            attachmentNames: attachments,
            source: bench.app
        )
    }

    private func snapshot(_ bench: ArchiveTestBench, _ children: [AccessibilityNode]) -> AccessibilitySnapshot {
        AccessibilitySnapshot(application: bench.app, window: window(children))
    }

    private func scratch(_ bench: ArchiveTestBench) throws -> URL {
        let directory = bench.root.appending(path: "scratch")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test("Un allegato si salva con la sua azione e il file salvato viene copiato, quello senza azione è mancante")
    func savesAndTakesSavedFileAndNamesTheRest() async throws {
        let bench = try ArchiveTestBench()
        let file = try bench.userFile("documento-testo.pdf", as: "contratto.pdf")
        let reader = FakeAccessibility(
            before: snapshot(bench, [attachment("contratto.pdf"), AccessibilityNode(role: "AXButton", title: "firma.png")]),
            after: snapshot(bench, [attachment("contratto.pdf", file: file), AccessibilityNode(role: "AXButton", title: "firma.png")])
        )
        let taker = OutlookAttachmentTaker(reader: reader)

        let answers = await taker.take(email(bench, attachments: ["contratto.pdf", "firma.png"]), into: try scratch(bench))

        #expect(answers.count == 2)
        guard case .file(let name, let copy) = answers[0] else {
            Issue.record("Atteso un file preso, ottenuto \(answers[0])")
            return
        }
        #expect(name == "contratto.pdf")
        #expect(copy.lastPathComponent == "0-contratto.pdf")
        #expect(try Data(contentsOf: copy) == Data(contentsOf: file))
        #expect(answers[1] == .missing(name: "firma.png"))
        #expect(await reader.actionsPerformed == ["AXSaveAttachment contratto.pdf"])
    }

    @Test("Un salvataggio che fallisce non prende il file, anche se l'elemento lo espone")
    func failedSaveIsMissing() async throws {
        let bench = try ArchiveTestBench()
        let file = try bench.userFile("documento-testo.pdf", as: "contratto.pdf")
        let reader = FakeAccessibility(
            before: snapshot(bench, [attachment("contratto.pdf")]),
            after: snapshot(bench, [attachment("contratto.pdf", file: file)]),
            saveSucceeds: false
        )
        let taker = OutlookAttachmentTaker(reader: reader)

        let answers = await taker.take(email(bench, attachments: ["contratto.pdf"]), into: try scratch(bench))

        #expect(answers == [.missing(name: "contratto.pdf")])
    }

    @Test("Un allegato senza azione di salvataggio non viene preso")
    func attachmentWithoutSaveActionIsMissing() async throws {
        let bench = try ArchiveTestBench()
        let file = try bench.userFile("documento-testo.pdf", as: "contratto.pdf")
        let plain = AccessibilityNode(role: "AXButton", title: "contratto.pdf", url: file)
        let reader = FakeAccessibility(before: snapshot(bench, [plain]), after: snapshot(bench, [plain]))
        let taker = OutlookAttachmentTaker(reader: reader)

        let answers = await taker.take(email(bench, attachments: ["contratto.pdf"]), into: try scratch(bench))

        #expect(answers == [.missing(name: "contratto.pdf")])
        #expect(await reader.actionsPerformed.isEmpty)
    }

    @Test("Un elemento con un percorso che non esiste dopo il salvataggio non prende nulla")
    func missingFileOnDiskIsNotTaken() async throws {
        let bench = try ArchiveTestBench()
        let gone = bench.root.appending(path: "user/sparito.pdf")
        let reader = FakeAccessibility(
            before: snapshot(bench, [attachment("contratto.pdf")]),
            after: snapshot(bench, [attachment("contratto.pdf", file: gone)])
        )
        let taker = OutlookAttachmentTaker(reader: reader)

        let answers = await taker.take(email(bench, attachments: ["contratto.pdf"]), into: try scratch(bench))

        #expect(answers == [.missing(name: "contratto.pdf")])
    }

    @Test("Senza una finestra leggibile non c'è nessuna risposta")
    func unreadableWindowAnswersNothing() async throws {
        let bench = try ArchiveTestBench()
        let taker = OutlookAttachmentTaker(reader: FakeAccessibility(before: nil))

        let answers = await taker.take(email(bench, attachments: ["contratto.pdf"]), into: try scratch(bench))

        #expect(answers.isEmpty)
    }

    @Test("Un'email con allegato salvato dall'albero viene archiviata e segnala solo i mancanti")
    func pipelineUsesTakenAttachments() async throws {
        let bench = try ArchiveTestBench()
        let file = try bench.userFile("documento-testo.pdf", as: "contratto.pdf")
        let taker = OutlookAttachmentTaker(reader: FakeAccessibility(
            before: snapshot(bench, [attachment("contratto.pdf"), AccessibilityNode(role: "AXButton", title: "firma.png")]),
            after: snapshot(bench, [attachment("contratto.pdf", file: file), AccessibilityNode(role: "AXButton", title: "firma.png")])
        ))
        let message = email(bench, attachments: ["contratto.pdf", "firma.png"])

        let outcome = await bench.pipeline(attachments: taker).archive(.email(message), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(result.allegatiNonPresi == ["firma.png"])
        let hash = Fingerprint.email(
            sender: message.sender ?? "",
            receivedDay: nil,
            subject: message.subject ?? "",
            body: message.body
        )
        let stored = try #require(try bench.vault.document(withContentHash: hash))
        #expect(try bench.vault.attachmentIDs(of: stored.id).count == 1)
    }

    @Test("Con Outlook non leggibile l'email entra e tutti gli allegati sono annotati per nome")
    func unreadableOutlookNamesEveryAttachment() async throws {
        let bench = try ArchiveTestBench()
        let taker = OutlookAttachmentTaker(reader: FakeAccessibility(before: nil))
        let message = email(bench, attachments: ["contratto.pdf", "firma.png"])

        let outcome = await bench.pipeline(attachments: taker).archive(.email(message), moment: ArchiveTestBench.readingMoment)

        guard case .archived(let result) = outcome else {
            Issue.record("Atteso archiviato, ottenuto \(outcome)")
            return
        }
        #expect(result.allegatiNonPresi == ["contratto.pdf", "firma.png"])
        let hash = Fingerprint.email(
            sender: message.sender ?? "",
            receivedDay: nil,
            subject: message.subject ?? "",
            body: message.body
        )
        let stored = try #require(try bench.vault.document(withContentHash: hash))
        #expect(try bench.vault.attachmentIDs(of: stored.id).isEmpty)
    }
}
