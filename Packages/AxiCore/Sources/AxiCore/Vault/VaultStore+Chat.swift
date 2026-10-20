import Foundation
import GRDB

/// What deleting a document would remove, shown to the user before the deletion is confirmed.
public struct DeletionPlan: Sendable, Equatable {
    public var documentID: String
    public var title: String
    public var kind: DocumentKind
    public var archivedAt: Date
    /// Titles of the attachments that go with an email; empty for any other document.
    public var attachmentTitles: [String]

    public init(
        documentID: String,
        title: String,
        kind: DocumentKind,
        archivedAt: Date,
        attachmentTitles: [String]
    ) {
        self.documentID = documentID
        self.title = title
        self.kind = kind
        self.archivedAt = archivedAt
        self.attachmentTitles = attachmentTitles
    }
}

extension VaultStore {
    /// The text of a document, page after page. A document without pages gives its indexed
    /// passages in order. Nil when the document is not in the vault.
    public func fullText(ofDocument id: String) throws -> String? {
        try dbQueue.read { db in
            guard try String.fetchOne(db, sql: "SELECT id FROM documents WHERE id = ?", arguments: [id]) != nil else {
                return nil
            }
            let pages = try String.fetchAll(
                db,
                sql: "SELECT text FROM document_pages WHERE document_id = ? ORDER BY page_number",
                arguments: [id]
            )
            if !pages.isEmpty {
                return pages.joined(separator: "\n\n")
            }
            let passages = try String.fetchAll(
                db,
                sql: "SELECT text FROM chunks WHERE document_id = ? ORDER BY position",
                arguments: [id]
            )
            return passages.joined(separator: "\n\n")
        }
    }

    /// The text of one page of a document. Nil when the document has no such page.
    public func pageText(ofDocument id: String, page: Int) throws -> String? {
        try dbQueue.read { db in
            try String.fetchOne(
                db,
                sql: "SELECT text FROM document_pages WHERE document_id = ? AND page_number = ?",
                arguments: [id, page]
            )
        }
    }

    /// What deleting the document would remove, or nil when it is not in the vault.
    public func deletionPlan(ofDocument id: String) throws -> DeletionPlan? {
        try dbQueue.read { db in
            guard let row = try Row.fetchOne(
                db,
                sql: "SELECT title, kind, archived_at FROM documents WHERE id = ?",
                arguments: [id]
            ) else { return nil }
            let kindName: String = row["kind"]
            guard let kind = DocumentKind(rawValue: kindName) else {
                throw VaultError.inconsistent("unknown kind \(kindName)")
            }
            let attachmentTitles = try String.fetchAll(
                db,
                sql: "SELECT title FROM documents WHERE email_id = ? ORDER BY title, id",
                arguments: [id]
            )
            return DeletionPlan(
                documentID: id,
                title: row["title"],
                kind: kind,
                archivedAt: row["archived_at"],
                attachmentTitles: attachmentTitles
            )
        }
    }
}
