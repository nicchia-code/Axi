import Foundation
import GRDB
import AxiVectors

public enum VaultError: Error, Equatable {
    case emptyBatch
    case duplicateDocument(String)
    case invalidDocument(id: String, reason: String)
    case documentNotFound(String)
    case emailNotFound(String)
    /// The chat has not asked to confirm the deletion of this document.
    case noPendingDeletion(documentID: String)
    case inconsistent(String)
}

/// The vault: documents, their text and index, tags and the links between emails and attachments.
///
/// Every operation is one database transaction, so a document is either in the vault
/// with all its data or not at all.
public final class VaultStore: Sendable {
    let dbQueue: DatabaseQueue
    let embeddingDimension: Int
    public let filesDirectory: URL

    /// Opens (or creates) the vault database and applies its migrations.
    public init(databaseURL: URL, filesDirectory: URL, embeddingDimension: Int) throws {
        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(at: filesDirectory, withIntermediateDirectories: true)
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            guard let connection = db.sqliteConnection else {
                throw VaultError.inconsistent("the database has no SQLite connection")
            }
            try AxiVectors.register(connection)
        }
        dbQueue = try DatabaseQueue(path: databaseURL.path, configuration: configuration)
        try VaultSchema.migrator(embeddingDimension: embeddingDimension).migrate(dbQueue)
        self.filesDirectory = filesDirectory
        self.embeddingDimension = embeddingDimension
        try recoverTrash()
    }

    /// Puts documents into the vault, in one transaction. Use it for an email together with
    /// its attachments: an attachment's `emailID` must name an email in the same batch or
    /// one already in the vault.
    public func archive(_ documents: [ArchivedDocument]) throws {
        guard !documents.isEmpty else { throw VaultError.emptyBatch }
        try dbQueue.write { db in
            var batchKinds: [String: DocumentKind] = [:]
            for document in documents {
                try Self.validate(document)
                guard batchKinds[document.id] == nil, try Self.storedKind(of: document.id, in: db) == nil else {
                    throw VaultError.duplicateDocument(document.id)
                }
                batchKinds[document.id] = document.kind
            }
            for document in documents {
                guard let emailID = document.emailID else { continue }
                let emailKind = try batchKinds[emailID] ?? Self.storedKind(of: emailID, in: db)
                guard emailKind == .email else { throw VaultError.emailNotFound(emailID) }
            }
            for document in documents {
                try Self.insert(document, dimension: embeddingDimension, in: db)
            }
        }
    }

    /// Replaces the tags of a document with the ones the chat set. A new tag joins the
    /// vocabulary; a tag no document uses any more leaves it.
    public func updateTags(of documentID: String, to tags: [String]) throws {
        try dbQueue.write { db in
            guard try Self.storedKind(of: documentID, in: db) != nil else {
                throw VaultError.documentNotFound(documentID)
            }
            try Self.setTags(tags, of: documentID, in: db)
            try Self.removeUnusedTags(in: db)
        }
    }

    /// Deletes a document after the user confirmed it in the chat. `pendingRequest` is the
    /// document the chat is asking to confirm: nothing is deleted when it does not match.
    /// Deleting an email deletes its attachments too; deleting an attachment only unlinks it.
    ///
    /// The rows and the copies go in one operation: the copies are moved into the trash of the
    /// files folder inside the transaction, and leave it for good only after the commit. If the
    /// operation fails, the copies go back to their place. Once committed, the deletion is done
    /// even when the trash cannot be emptied: the names of the copies left there are returned,
    /// and the next launch empties the trash.
    @discardableResult
    public func confirmDeletion(of documentID: String, pendingRequest: String?) throws -> [String] {
        guard pendingRequest == documentID else {
            throw VaultError.noPendingDeletion(documentID: documentID)
        }
        let batch = trashRoot.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        var moved: [MovedCopy] = []
        do {
            try dbQueue.write { db in
                guard let kind = try Self.storedKind(of: documentID, in: db) else {
                    throw VaultError.documentNotFound(documentID)
                }
                // Attachments go first: their link to the email is a foreign key.
                var victims: [String] = []
                if kind == .email {
                    victims = try String.fetchAll(
                        db,
                        sql: "SELECT id FROM documents WHERE email_id = ?",
                        arguments: [documentID]
                    )
                }
                victims.append(documentID)

                var copies: [String] = []
                for victim in victims {
                    if let copy = try String.fetchOne(
                        db,
                        sql: "SELECT copy_path FROM documents WHERE id = ?",
                        arguments: [victim]
                    ) {
                        copies.append(copy)
                    }
                    // The full-text index is not a foreign-key child: remove it by hand.
                    try db.execute(sql: "DELETE FROM chunk_fts WHERE document_id = ?", arguments: [victim])
                    // Pages, chunks, vectors, email data and tag links go by cascade.
                    // Vectors are a virtual table without foreign keys: remove them by hand.
                    try db.execute(
                        sql: "DELETE FROM chunk_vectors WHERE rowid IN (SELECT id FROM chunks WHERE document_id = ?)",
                        arguments: [victim]
                    )
                    try db.execute(sql: "DELETE FROM documents WHERE id = ?", arguments: [victim])
                }
                try Self.removeUnusedTags(in: db)
                try moveCopies(copies, to: batch, into: &moved)
            }
        } catch {
            restoreCopies(moved)
            throw error
        }
        return emptyTrash(batch, copies: moved)
    }

    // MARK: - Reading

    /// The document with the given id, with its kind, its email link and its tags.
    public func document(id: String) throws -> StoredDocument? {
        try dbQueue.read { db in
            guard let row = try Row.fetchOne(
                db,
                sql: "SELECT id, title, kind, email_id FROM documents WHERE id = ?",
                arguments: [id]
            ) else { return nil }
            let kindName: String = row["kind"]
            guard let kind = DocumentKind(rawValue: kindName) else {
                throw VaultError.inconsistent("unknown kind \(kindName)")
            }
            let tags = try String.fetchAll(db, sql: """
                SELECT tags.name FROM tags
                JOIN document_tags ON document_tags.tag_id = tags.id
                WHERE document_tags.document_id = ?
                ORDER BY tags.name
                """, arguments: [id])
            return StoredDocument(
                id: row["id"],
                title: row["title"],
                kind: kind,
                emailID: row["email_id"],
                tags: tags
            )
        }
    }

    /// Ids of the attachments linked to an email, by title.
    public func attachmentIDs(of emailID: String) throws -> [String] {
        try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: "SELECT id FROM documents WHERE email_id = ? ORDER BY title, id",
                arguments: [emailID]
            )
        }
    }

    /// The shared tag vocabulary, by name.
    public func vocabulary() throws -> [String] {
        try dbQueue.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM tags ORDER BY name")
        }
    }

    /// The stored document with the given content hash, if any. Used to detect duplicates.
    public func document(withContentHash hash: String) throws -> StoredDocument? {
        let id = try dbQueue.read { db in
            try String.fetchOne(
                db,
                sql: "SELECT id FROM documents WHERE content_hash = ? ORDER BY archived_at LIMIT 1",
                arguments: [hash]
            )
        }
        guard let id else { return nil }
        return try document(id: id)
    }

    /// Ids of the emails that have an attachment with this name, case-insensitive: either an
    /// attachment Axi did not take, or an attachment already in the vault (matched by title).
    public func emailIDs(havingAttachmentNamed name: String) throws -> [String] {
        try dbQueue.read { db in
            try String.fetchAll(db, sql: """
                SELECT document_id FROM email_missing_attachments WHERE name = ? COLLATE NOCASE
                UNION
                SELECT email_id FROM documents WHERE email_id IS NOT NULL AND title = ? COLLATE NOCASE
                ORDER BY 1
                """, arguments: [name, name])
        }
    }

    /// The file of the copy kept in the files folder for a document, if it has one.
    public func copyURL(ofDocument id: String) throws -> URL? {
        let path = try dbQueue.read { db in
            try String.fetchOne(
                db,
                sql: "SELECT copy_path FROM documents WHERE id = ?",
                arguments: [id]
            )
        }
        guard let path, !path.isEmpty else { return nil }
        return filesDirectory.appendingPathComponent(path)
    }

    /// The web address kept with a document, if it has one.
    public func sourceURL(ofDocument id: String) throws -> URL? {
        let address = try dbQueue.read { db in
            try String.fetchOne(
                db,
                sql: "SELECT source_url FROM documents WHERE id = ?",
                arguments: [id]
            )
        }
        guard let address, !address.isEmpty else { return nil }
        return URL(string: address)
    }

    // MARK: - Private

    /// A copy moved into the trash by a deletion, with where it came from.
    private struct MovedCopy {
        let name: String
        let original: URL
        let trashed: URL
    }

    /// The folder that holds the copies of deletions in progress, inside the files folder.
    private var trashRoot: URL {
        filesDirectory.appending(path: Self.trashFolderName, directoryHint: .isDirectory)
    }

    private static let trashFolderName = ".trash"

    /// Moves the copies into a batch folder of the trash. Throws at the first move that fails;
    /// the copies moved so far are appended to `moved`, so the caller can put them back.
    private func moveCopies(_ copies: [String], to batch: URL, into moved: inout [MovedCopy]) throws {
        let fileManager = FileManager.default
        for name in copies where !name.isEmpty {
            let original = filesDirectory.appending(path: name)
            guard fileManager.fileExists(atPath: original.path) else { continue }
            if !fileManager.fileExists(atPath: batch.path) {
                try fileManager.createDirectory(at: batch, withIntermediateDirectories: true)
            }
            let trashed = batch.appending(path: name)
            try fileManager.moveItem(at: original, to: trashed)
            moved.append(MovedCopy(name: name, original: original, trashed: trashed))
        }
    }

    /// Puts back the copies of a deletion that did not commit. A copy that cannot be put back
    /// stays in the trash, and the next launch restores it, because its row is still in the vault.
    private func restoreCopies(_ moved: [MovedCopy]) {
        for copy in moved.reversed() {
            try? FileManager.default.moveItem(at: copy.trashed, to: copy.original)
        }
    }

    /// Empties the batch of a committed deletion. Returns the names of the copies still in the
    /// trash when it cannot be emptied; the next launch empties it.
    private func emptyTrash(_ batch: URL, copies: [MovedCopy]) -> [String] {
        guard !copies.isEmpty else { return [] }
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: batch)
            let rest = try fileManager.contentsOfDirectory(at: trashRoot, includingPropertiesForKeys: nil)
            if rest.isEmpty {
                try fileManager.removeItem(at: trashRoot)
            }
            return []
        } catch {
            return copies.map(\.name)
        }
    }

    /// Settles the trash left by a deletion that did not finish, typically because the app quit
    /// in the middle: a copy whose row is still in the vault goes back to the files folder, any
    /// other copy is removed.
    private func recoverTrash() throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: trashRoot.path) else { return }
        for batch in try fileManager.contentsOfDirectory(at: trashRoot, includingPropertiesForKeys: nil) {
            for trashed in try fileManager.contentsOfDirectory(at: batch, includingPropertiesForKeys: nil) {
                let name = trashed.lastPathComponent
                let inVault = try dbQueue.read { db in
                    try Bool.fetchOne(
                        db,
                        sql: "SELECT EXISTS(SELECT 1 FROM documents WHERE copy_path = ?)",
                        arguments: [name]
                    ) ?? false
                }
                if !inVault {
                    try fileManager.removeItem(at: trashed)
                } else if fileManager.fileExists(atPath: filesDirectory.appending(path: name).path) {
                    // The copy is already back in place: the trashed one is a leftover.
                    try fileManager.removeItem(at: trashed)
                } else {
                    try fileManager.moveItem(at: trashed, to: filesDirectory.appending(path: name))
                }
            }
            try fileManager.removeItem(at: batch)
        }
        try fileManager.removeItem(at: trashRoot)
    }

    private static func validate(_ document: ArchivedDocument) throws {
        func invalid(_ reason: String) -> VaultError {
            VaultError.invalidDocument(id: document.id, reason: reason)
        }
        if document.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw invalid("empty id")
        }
        if document.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw invalid("empty title")
        }
        if (document.kind == .email) != (document.email != nil) {
            throw invalid("email details belong to an email and only to an email")
        }
        if document.kind == .email && document.emailID != nil {
            throw invalid("an email cannot be an attachment")
        }
        if document.pdfMissing && (document.kind != .web || document.copyPath != nil) {
            throw invalid("a missing PDF applies only to a web page without a copy")
        }
        if document.kind == .web && !document.pdfMissing && document.copyPath == nil {
            throw invalid("a web page needs its PDF copy or the mark that it is missing")
        }
        if document.citedDates.count > 20 {
            throw invalid("more than 20 cited dates")
        }
        if document.citedDates.contains(where: { $0.date == nil }) {
            // A relative date has no date only in an email whose receipt date is unknown.
            guard document.kind == .email, let email = document.email, email.sentAt == nil else {
                throw invalid("a cited date without a date needs an email with unknown receipt date")
            }
        }
    }

    private static func storedKind(of id: String, in db: Database) throws -> DocumentKind? {
        guard let name = try String.fetchOne(
            db,
            sql: "SELECT kind FROM documents WHERE id = ?",
            arguments: [id]
        ) else { return nil }
        guard let kind = DocumentKind(rawValue: name) else {
            throw VaultError.inconsistent("unknown kind \(name)")
        }
        return kind
    }

    private static func insert(_ document: ArchivedDocument, dimension: Int, in db: Database) throws {
        try db.execute(sql: """
            INSERT INTO documents (
                id, title, kind, original_name, copy_path, pdf_missing,
                source_app, source_path, source_url, content_hash,
                document_date, archived_at, page_count, language, summary, email_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, arguments: [
                document.id, document.title, document.kind.rawValue, document.originalName,
                document.copyPath, document.pdfMissing,
                document.source.app, document.source.path, document.source.url, document.contentHash,
                document.documentDate.map(Self.dayText), document.archivedAt, document.pages.count,
                document.language, document.summary, document.emailID,
            ])

        for page in document.pages {
            try db.execute(
                sql: "INSERT INTO document_pages (document_id, page_number, text) VALUES (?, ?, ?)",
                arguments: [document.id, page.number, page.text]
            )
        }

        for (position, chunk) in document.chunks.enumerated() {
            guard chunk.embedding.count == dimension else {
                throw VaultError.invalidDocument(
                    id: document.id,
                    reason: "embedding of \(chunk.embedding.count) values, expected \(dimension)"
                )
            }
            try db.execute(
                sql: "INSERT INTO chunks (document_id, position, text, page_number) VALUES (?, ?, ?, ?)",
                arguments: [document.id, position, chunk.text, chunk.page]
            )
            let chunkID = db.lastInsertedRowID
            try db.execute(
                sql: "INSERT INTO chunk_fts (text, chunk_id, document_id) VALUES (?, ?, ?)",
                arguments: [chunk.text, chunkID, document.id]
            )
            let vector = chunk.embedding.withUnsafeBufferPointer { Data(buffer: $0) }
            try db.execute(
                sql: "INSERT INTO chunk_vectors (rowid, embedding) VALUES (?, ?)",
                arguments: [chunkID, vector]
            )
        }

        if let email = document.email {
            try db.execute(
                sql: "INSERT INTO email_details (document_id, sender, subject, sent_at, sent_at_displayed) VALUES (?, ?, ?, ?, ?)",
                arguments: [
                    document.id, email.sender, email.subject,
                    email.sentAt.map { Self.databaseText(of: .instant($0)) }, email.displayedSentAt,
                ]
            )
            for (position, address) in email.recipients.enumerated() {
                try db.execute(
                    sql: "INSERT INTO email_recipients (document_id, position, address) VALUES (?, ?, ?)",
                    arguments: [document.id, position, address]
                )
            }
            for (position, name) in email.missingAttachmentNames.enumerated() {
                try db.execute(
                    sql: "INSERT INTO email_missing_attachments (document_id, position, name) VALUES (?, ?, ?)",
                    arguments: [document.id, position, name]
                )
            }
        }
        for (position, cited) in document.citedDates.enumerated() {
            try db.execute(
                sql: "INSERT INTO cited_dates (document_id, position, date, about, original_text) VALUES (?, ?, ?, ?, ?)",
                arguments: [
                    document.id, position, cited.date.map { Self.databaseText(of: $0) }, cited.about, cited.originalText,
                ]
            )
        }

        try setTags(document.tags, of: document.id, in: db)
    }

    /// The text a date is kept as: an instant with its UTC offset, read in the Mac's time zone
    /// (`2025-10-06T09:30:00+02:00`), or a day as `yyyy-MM-dd`.
    static func databaseText(of date: AbsoluteDate) -> String {
        switch date {
        case .instant(let instant):
            return formatter("yyyy-MM-dd'T'HH:mm:ssxxx", timeZone: .current).string(from: instant)
        case .day(let day):
            return dayText(day)
        }
    }

    /// A document's day, as `yyyy-MM-dd` in UTC: the time is not kept.
    static func dayText(_ date: Date) -> String {
        formatter("yyyy-MM-dd", timeZone: .gmt).string(from: date)
    }

    /// Reads a date kept by `databaseText(of:)`: a day when the text is `yyyy-MM-dd`, else an instant.
    static func absoluteDate(databaseText text: String) -> AbsoluteDate? {
        if text.count == 10 {
            return formatter("yyyy-MM-dd", timeZone: .gmt).date(from: text).map(AbsoluteDate.day)
        }
        return formatter("yyyy-MM-dd'T'HH:mm:ssxxx", timeZone: .current).date(from: text).map(AbsoluteDate.instant)
    }

    private static func formatter(_ format: String, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }

    /// Replaces the tag links of a document, adding new names to the vocabulary.
    private static func setTags(_ tags: [String], of documentID: String, in db: Database) throws {
        try db.execute(sql: "DELETE FROM document_tags WHERE document_id = ?", arguments: [documentID])
        for name in normalizedTags(tags) {
            try db.execute(sql: "INSERT OR IGNORE INTO tags (name) VALUES (?)", arguments: [name])
            guard let tagID = try Int64.fetchOne(
                db,
                sql: "SELECT id FROM tags WHERE name = ?",
                arguments: [name]
            ) else {
                throw VaultError.inconsistent("tag \(name) not stored")
            }
            try db.execute(
                sql: "INSERT INTO document_tags (document_id, tag_id) VALUES (?, ?)",
                arguments: [documentID, tagID]
            )
        }
    }

    private static func removeUnusedTags(in db: Database) throws {
        try db.execute(sql: """
            DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM document_tags)
            """)
    }

    /// Trims the names, drops empty ones and keeps the first spelling of each tag.
    private static func normalizedTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for tag in tags {
            let name = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(name.lowercased()).inserted else { continue }
            result.append(name)
        }
        return result
    }
}
