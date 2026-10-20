import Foundation
import GRDB
import AxiVectors
import Testing
@testable import AxiCore

@Suite("Documento nel vault")
struct VaultStoreTests {
    private let store: VaultStore
    private let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appending(path: "vault-\(UUID().uuidString)")
        store = try VaultStore(
            databaseURL: root.appending(path: "vault.sqlite"),
            filesDirectory: root.appending(path: "files"),
            embeddingDimension: 3
        )
    }

    // MARK: - Fixtures

    private static let archivedAt = Date(timeIntervalSince1970: 1_760_000_000)

    private func pdf(id: String, tags: [String] = ["fattura"], copy: String? = nil) -> ArchivedDocument {
        ArchivedDocument(
            id: id,
            title: "Documento \(id)",
            kind: .pdf,
            originalName: "\(id).pdf",
            copyPath: copy ?? "\(id).pdf",
            source: DocumentSource(path: "/Users/me/\(id).pdf"),
            contentHash: "hash-\(id)",
            archivedAt: Self.archivedAt,
            language: "it",
            summary: "Riassunto \(id)",
            tags: tags,
            pages: [DocumentPage(number: 1, text: "Testo della pagina uno di \(id)")],
            chunks: [
                DocumentChunk(text: "primo brano di \(id)", embedding: [0.1, 0.2, 0.3]),
                DocumentChunk(text: "secondo brano di \(id)", embedding: [0.4, 0.5, 0.6]),
            ]
        )
    }

    private func email(id: String, attachments: [String] = []) -> ArchivedDocument {
        ArchivedDocument(
            id: id,
            title: "Email \(id)",
            kind: .email,
            contentHash: "hash-\(id)",
            archivedAt: Self.archivedAt,
            summary: "Riassunto \(id)",
            tags: ["contratto"],
            pages: [DocumentPage(number: 1, text: "Corpo dell'email \(id)")],
            chunks: [DocumentChunk(text: "corpo dell'email \(id)", embedding: [1, 0, 0])],
            email: EmailDetails(
                sender: "mario@example.com",
                recipients: ["luca@example.com", "anna@example.com"],
                subject: "Oggetto \(id)",
                sentAt: Self.archivedAt,
                missingAttachmentNames: ["logo.png"]
            )
        )
    }

    private func attachment(id: String, of emailID: String, tags: [String] = ["contratto"]) -> ArchivedDocument {
        var document = pdf(id: id, tags: tags)
        document.emailID = emailID
        return document
    }

    /// Writes the copy of a document into the files folder, as the archiving work would.
    private func writeCopy(_ relativePath: String) throws {
        let url = store.filesDirectory.appending(path: relativePath)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("copia".utf8).write(to: url)
    }

    private func copyExists(_ relativePath: String) -> Bool {
        FileManager.default.fileExists(atPath: store.filesDirectory.appending(path: relativePath).path)
    }

    /// Number of rows that belong to a document in each table of its data.
    private func footprint(_ documentID: String) throws -> [String: Int] {
        try store.dbQueue.read { db in
            let queries: [(String, String)] = [
                ("documents", "SELECT COUNT(*) FROM documents WHERE id = ?"),
                ("pages", "SELECT COUNT(*) FROM document_pages WHERE document_id = ?"),
                ("chunks", "SELECT COUNT(*) FROM chunks WHERE document_id = ?"),
                ("fts", "SELECT COUNT(*) FROM chunk_fts WHERE document_id = ?"),
                ("vectors", """
                    SELECT COUNT(*) FROM chunk_vectors
                    WHERE rowid IN (SELECT id FROM chunks WHERE document_id = ?)
                    """),
                ("tagLinks", "SELECT COUNT(*) FROM document_tags WHERE document_id = ?"),
                ("emailDetails", "SELECT COUNT(*) FROM email_details WHERE document_id = ?"),
                ("recipients", "SELECT COUNT(*) FROM email_recipients WHERE document_id = ?"),
                ("missingAttachments", "SELECT COUNT(*) FROM email_missing_attachments WHERE document_id = ?"),
                ("citedDates", "SELECT COUNT(*) FROM cited_dates WHERE document_id = ?"),
            ]
            var result: [String: Int] = [:]
            for (name, sql) in queries {
                result[name] = try Int.fetchOne(db, sql: sql, arguments: [documentID]) ?? 0
            }
            return result
        }
    }

    private func allZero(_ footprint: [String: Int]) -> Bool {
        footprint.values.allSatisfy { $0 == 0 }
    }

    // MARK: - Archiving

    @Test("A PDF enters the vault with its text, index, vectors and tags")
    func archivesPDF() throws {
        try store.archive([pdf(id: "a", tags: ["Fattura", "2026"])])

        let stored = try #require(try store.document(id: "a"))
        #expect(stored.kind == .pdf)
        #expect(stored.emailID == nil)
        #expect(stored.tags == ["2026", "Fattura"])

        let counts = try footprint("a")
        #expect(counts["documents"] == 1)
        #expect(counts["pages"] == 1)
        #expect(counts["chunks"] == 2)
        #expect(counts["fts"] == 2)
        #expect(counts["vectors"] == 2)
        #expect(counts["tagLinks"] == 2)
    }

    @Test("An email and its attachments are separate linked documents")
    func archivesEmailWithAttachments() throws {
        try store.archive([
            email(id: "mail"),
            attachment(id: "fattura", of: "mail"),
            attachment(id: "contratto", of: "mail"),
        ])

        #expect(Set(try store.attachmentIDs(of: "mail")) == ["fattura", "contratto"])
        #expect(try store.document(id: "fattura")?.emailID == "mail")

        let counts = try footprint("mail")
        #expect(counts["emailDetails"] == 1)
        #expect(counts["recipients"] == 2)
        #expect(counts["missingAttachments"] == 1)
    }

    @Test("An attachment must name an email that is in the vault or in the same batch")
    func rejectsAttachmentWithoutEmail() throws {
        #expect(throws: VaultError.emailNotFound("assente")) {
            try store.archive([attachment(id: "fattura", of: "assente")])
        }
        #expect(try store.document(id: "fattura") == nil)
    }

    @Test("A batch that fails leaves nothing of its documents in the vault")
    func batchIsAtomic() throws {
        #expect(throws: VaultError.emailNotFound("assente")) {
            try store.archive([pdf(id: "buono"), attachment(id: "fattura", of: "assente")])
        }
        #expect(try store.document(id: "buono") == nil)
        #expect(allZero(try footprint("buono")))
    }

    @Test("A document id already in the vault is refused")
    func rejectsDuplicateID() throws {
        try store.archive([pdf(id: "a")])
        #expect(throws: VaultError.duplicateDocument("a")) {
            try store.archive([pdf(id: "a", tags: ["altro"])])
        }
        #expect(try store.vocabulary() == ["fattura"])
    }

    @Test("A web page without PDF keeps only its text and address, marked as missing")
    func archivesWebPageWithoutPDF() throws {
        let page = ArchivedDocument(
            id: "web",
            title: "Pagina",
            kind: .web,
            pdfMissing: true,
            source: DocumentSource(url: "https://example.com/area-riservata"),
            contentHash: "hash-web",
            archivedAt: Self.archivedAt,
            summary: "Riassunto",
            pages: [DocumentPage(number: 1, text: "Testo letto a schermo")],
            chunks: [DocumentChunk(text: "testo letto a schermo", embedding: [0, 1, 0])]
        )
        try store.archive([page])

        let stored = try #require(try store.document(id: "web"))
        #expect(stored.kind == .web)
        let flagged = try store.dbQueue.read { db in
            try Bool.fetchOne(db, sql: "SELECT pdf_missing FROM documents WHERE id = 'web'")
        }
        #expect(flagged == true)
    }

    @Test("A web page with neither a PDF nor the missing mark is refused")
    func rejectsWebPageWithoutPDFMark() throws {
        let page = ArchivedDocument(
            id: "web",
            title: "Pagina",
            kind: .web,
            contentHash: "hash-web",
            archivedAt: Self.archivedAt,
            summary: "Riassunto"
        )
        #expect(throws: VaultError.invalidDocument(id: "web", reason: "a web page needs its PDF copy or the mark that it is missing")) {
            try store.archive([page])
        }
    }

    // MARK: - Tags

    @Test("Changing tags adds new names to the vocabulary and drops the unused ones")
    func updatesTags() throws {
        try store.archive([pdf(id: "a", tags: ["fattura", "2026"]), pdf(id: "b", tags: ["fattura"])])

        try store.updateTags(of: "a", to: ["Contratto", "fattura"])

        #expect(try store.document(id: "a")?.tags == ["Contratto", "fattura"])
        // "2026" was used only by "a": it leaves the vocabulary. "fattura" stays for "b".
        #expect(try store.vocabulary() == ["Contratto", "fattura"])
        #expect(try store.document(id: "b")?.tags == ["fattura"])
    }

    @Test("A tag is stored once whatever its case, blanks are dropped")
    func tagsAreUnique() throws {
        try store.archive([pdf(id: "a", tags: [])])

        try store.updateTags(of: "a", to: ["Fattura", "fattura ", "  ", "FATTURA"])

        #expect(try store.document(id: "a")?.tags == ["Fattura"])
        #expect(try store.vocabulary() == ["Fattura"])
    }

    @Test("Tags of a missing document cannot be changed")
    func updateTagsOfMissingDocument() throws {
        #expect(throws: VaultError.documentNotFound("assente")) {
            try store.updateTags(of: "assente", to: ["x"])
        }
    }

    // MARK: - Deletion

    @Test("Nothing is deleted without the confirmation of the pending request")
    func deletionNeedsConfirmation() throws {
        try store.archive([pdf(id: "a"), pdf(id: "b")])
        try writeCopy("a.pdf")
        let before = try footprint("a")

        #expect(throws: VaultError.noPendingDeletion(documentID: "a")) {
            try store.confirmDeletion(of: "a", pendingRequest: nil)
        }
        #expect(throws: VaultError.noPendingDeletion(documentID: "a")) {
            try store.confirmDeletion(of: "a", pendingRequest: "b")
        }

        #expect(try footprint("a") == before)
        #expect(copyExists("a.pdf"))
    }

    @Test("Confirmed deletion removes copy, text, vectors, index and links in one go")
    func deletesPDF() throws {
        try store.archive([pdf(id: "a", tags: ["fattura", "2026"]), pdf(id: "b", tags: ["fattura"])])
        try writeCopy("a.pdf")
        try writeCopy("b.pdf")

        try store.confirmDeletion(of: "a", pendingRequest: "a")

        #expect(allZero(try footprint("a")))
        #expect(try store.document(id: "a") == nil)
        #expect(!copyExists("a.pdf"))
        #expect(!copyExists(".trash"))
        // "b" is untouched, and "2026" leaves the vocabulary with its last user.
        #expect(try store.document(id: "b")?.tags == ["fattura"])
        #expect(copyExists("b.pdf"))
        #expect(try store.vocabulary() == ["fattura"])
    }

    @Test("Deleting an email deletes its attachments and leaves other documents alone")
    func deletesEmailAndAttachments() throws {
        try store.archive([
            email(id: "mail"),
            attachment(id: "fattura", of: "mail", tags: ["fattura"]),
            attachment(id: "contratto", of: "mail", tags: ["contratto"]),
            pdf(id: "altro", tags: ["fattura"]),
        ])
        try writeCopy("fattura.pdf")
        try writeCopy("contratto.pdf")
        try writeCopy("altro.pdf")

        try store.confirmDeletion(of: "mail", pendingRequest: "mail")

        #expect(allZero(try footprint("mail")))
        #expect(allZero(try footprint("fattura")))
        #expect(allZero(try footprint("contratto")))
        #expect(!copyExists("fattura.pdf"))
        #expect(!copyExists("contratto.pdf"))
        #expect(try store.document(id: "altro") != nil)
        #expect(copyExists("altro.pdf"))
        #expect(try store.vocabulary() == ["fattura"])
    }

    @Test("Deleting an attachment only unlinks it from its email")
    func deletesAttachmentOnly() throws {
        try store.archive([
            email(id: "mail"),
            attachment(id: "fattura", of: "mail"),
            attachment(id: "contratto", of: "mail"),
        ])
        try writeCopy("fattura.pdf")

        try store.confirmDeletion(of: "fattura", pendingRequest: "fattura")

        #expect(allZero(try footprint("fattura")))
        #expect(!copyExists("fattura.pdf"))
        #expect(try store.attachmentIDs(of: "mail") == ["contratto"])
        #expect(try store.document(id: "mail") != nil)
        #expect(try footprint("mail")["recipients"] == 2)
    }

    @Test("A deletion that cannot move its copy leaves the document and the copy as they were")
    func failedDeletionKeepsEverything() throws {
        try store.archive([pdf(id: "a")])
        try writeCopy("a.pdf")
        let before = try footprint("a")
        // A file where the trash folder must be makes the move impossible.
        try Data("blocco".utf8).write(to: store.filesDirectory.appending(path: ".trash"))

        #expect(throws: (any Error).self) {
            try store.confirmDeletion(of: "a", pendingRequest: "a")
        }

        #expect(try footprint("a") == before)
        #expect(try store.document(id: "a") != nil)
        #expect(copyExists("a.pdf"))
    }

    @Test("A deletion left unfinished is settled when the vault opens again")
    func recoversUnfinishedDeletion() throws {
        try store.archive([pdf(id: "a"), pdf(id: "b")])
        try writeCopy("a.pdf")
        // A deletion of "a" stopped with its copy in the trash, and a copy that has no row.
        let batch = store.filesDirectory.appending(path: ".trash/batch")
        try FileManager.default.createDirectory(at: batch, withIntermediateDirectories: true)
        try FileManager.default.moveItem(
            at: store.filesDirectory.appending(path: "a.pdf"),
            to: batch.appending(path: "a.pdf")
        )
        try Data("orfano".utf8).write(to: batch.appending(path: "orfano.pdf"))

        _ = try VaultStore(
            databaseURL: root.appending(path: "vault.sqlite"),
            filesDirectory: root.appending(path: "files"),
            embeddingDimension: 3
        )

        #expect(copyExists("a.pdf"))
        #expect(!copyExists("orfano.pdf"))
        #expect(!copyExists(".trash"))
    }

    // MARK: - Absolute dates

    private static let tenOctober = Date(timeIntervalSince1970: 1_760_054_400)  // 2025-10-10, midnight UTC
    private static let nineThirty = Date(timeIntervalSince1970: 1_760_088_600)  // 2025-10-10, 09:30 UTC

    /// The offset of the Mac's time zone at `date`, as an ISO 8601 suffix such as `+02:00`.
    private func offsetSuffix(at date: Date) -> String {
        let seconds = TimeZone.current.secondsFromGMT(for: date)
        let sign = seconds < 0 ? "-" : "+"
        return String(format: "%@%02d:%02d", sign, abs(seconds) / 3600, abs(seconds) % 3600 / 60)
    }

    private func storedRow(_ sql: String) throws -> Row {
        try #require(try store.dbQueue.read { db in try Row.fetchOne(db, sql: sql) })
    }

    @Test("An email whose receipt date is unknown has no sent date, but keeps the date Outlook showed")
    func unknownReceiptDate() throws {
        var document = email(id: "e")
        document.email = EmailDetails(
            sender: "mario@example.com",
            recipients: ["luca@example.com"],
            subject: "Oggetto e",
            sentAt: nil,
            displayedSentAt: "ieri alle 17:40"
        )
        try store.archive([document])

        let row = try storedRow("SELECT sent_at, sent_at_displayed FROM email_details WHERE document_id = 'e'")
        let sentAt: String? = row["sent_at"]
        let displayed: String? = row["sent_at_displayed"]
        #expect(sentAt == nil)
        #expect(displayed == "ieri alle 17:40")
    }

    @Test("A known receipt date is kept as an instant with the Mac's offset")
    func receiptInstant() throws {
        try store.archive([email(id: "e")])

        let row = try storedRow("SELECT sent_at FROM email_details WHERE document_id = 'e'")
        let sentAt: String? = row["sent_at"]
        let text = try #require(sentAt)
        #expect(ISO8601DateFormatter().date(from: text) == Self.archivedAt)
        #expect(text.hasSuffix(offsetSuffix(at: Self.archivedAt)))
    }

    @Test("A document's date is kept as its day, without a time")
    func documentDateIsDay() throws {
        var document = pdf(id: "d")
        document.documentDate = Self.tenOctober
        try store.archive([document])

        let row = try storedRow("SELECT document_date FROM documents WHERE id = 'd'")
        let stored: String? = row["document_date"]
        #expect(stored == "2025-10-10")
    }

    @Test("Cited dates keep their order, their form and their words, and leave with the document")
    func citedDates() throws {
        var document = email(id: "c")
        document.citedDates = [
            CitedDate(date: .day(Self.tenOctober), about: "scadenza del pagamento", originalText: "entro il 10 ottobre"),
            CitedDate(date: .instant(Self.nineThirty), about: "appuntamento", originalText: "alle 9.30 del 10 ottobre"),
        ]
        try store.archive([document])

        let rows = try store.dbQueue.read { db in
            try Row.fetchAll(db, sql: "SELECT date, original_text FROM cited_dates WHERE document_id = 'c' ORDER BY position")
        }
        let dates: [String?] = rows.map { $0["date"] }
        #expect(dates.count == 2)
        #expect(dates[0] == "2025-10-10")
        let instantText = try #require(dates[1])
        #expect(ISO8601DateFormatter().date(from: instantText) == Self.nineThirty)
        #expect(instantText.hasSuffix(offsetSuffix(at: Self.nineThirty)))
        let words: [String] = rows.map { $0["original_text"] }
        #expect(words == ["entro il 10 ottobre", "alle 9.30 del 10 ottobre"])

        try store.confirmDeletion(of: "c", pendingRequest: "c")
        #expect(try footprint("c")["citedDates"] == 0)
    }

    @Test("A cited date has no date only for a relative date of an email whose receipt date is unknown")
    func relativeDateNeedsUnknownReceipt() throws {
        let relative = CitedDate(date: nil, about: "scadenza", originalText: "tra tre giorni")

        var unknown = email(id: "u")
        unknown.email?.sentAt = nil
        unknown.citedDates = [relative]
        try store.archive([unknown])
        #expect(try footprint("u")["citedDates"] == 1)

        var known = email(id: "k")
        known.citedDates = [relative]
        #expect(throws: VaultError.self) { try store.archive([known]) }

        var attachment = pdf(id: "p")
        attachment.citedDates = [relative]
        #expect(throws: VaultError.self) { try store.archive([attachment]) }
        #expect(try store.document(id: "k") == nil)
        #expect(try store.document(id: "p") == nil)
    }

    @Test("A document keeps at most 20 cited dates")
    func citedDateLimit() throws {
        var document = pdf(id: "many")
        document.citedDates = (1...20).map {
            CitedDate(date: .day(Self.tenOctober), about: "data \($0)", originalText: "testo \($0)")
        }
        try store.archive([document])
        #expect(try footprint("many")["citedDates"] == 20)

        var over = pdf(id: "over")
        over.citedDates = (1...21).map {
            CitedDate(date: .day(Self.tenOctober), about: "data \($0)", originalText: "testo \($0)")
        }
        #expect(throws: VaultError.self) { try store.archive([over]) }
    }

    @Test("A vault from before the absolute dates keeps its rows when it is opened again")
    func keepsRowsOfOlderVault() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let url = root.appending(path: "old.sqlite")
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            guard let connection = db.sqliteConnection else {
                throw VaultError.inconsistent("the database has no SQLite connection")
            }
            try AxiVectors.register(connection)
        }
        let old = try DatabaseQueue(path: url.path, configuration: configuration)
        try VaultSchema.migrator(embeddingDimension: 3).migrate(old, upTo: "v2-chunk-pages")
        try old.write { db in
            try db.execute(sql: """
                INSERT INTO documents (id, title, kind, content_hash, document_date, archived_at, page_count, summary)
                VALUES ('old', 'Vecchia email', 'email', 'hash-old', '2025-10-10 00:00:00.000', '2025-10-10 09:30:00.000', 0, 'Riassunto')
                """)
            try db.execute(sql: """
                INSERT INTO email_details (document_id, sender, subject, sent_at)
                VALUES ('old', 'mario@example.com', 'Oggetto', '2025-10-10 09:30:00.000')
                """)
        }

        let upgraded = try VaultStore(
            databaseURL: url,
            filesDirectory: root.appending(path: "files"),
            embeddingDimension: 3
        )
        #expect(try upgraded.document(id: "old")?.kind == .email)
        let row = try #require(try upgraded.dbQueue.read { db in
            try Row.fetchOne(db, sql: """
                SELECT e.sent_at, e.sent_at_displayed, d.document_date
                FROM email_details e JOIN documents d ON d.id = e.document_id
                WHERE e.document_id = 'old'
                """)
        })
        let sentAt: String? = row["sent_at"]
        let displayed: String? = row["sent_at_displayed"]
        let day: String? = row["document_date"]
        #expect(sentAt == "2025-10-10 09:30:00.000")
        #expect(displayed == nil)
        #expect(day == "2025-10-10")
    }
}
