import Foundation
import Testing
@testable import AxiCore

@Suite("Lettura del vault per la chat")
struct VaultChatReadsTests {
    private let store: VaultStore

    init() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "vault-chat-\(UUID().uuidString)")
        store = try VaultStore(
            databaseURL: root.appending(path: "vault.sqlite"),
            filesDirectory: root.appending(path: "files"),
            embeddingDimension: 3
        )
    }

    private static let archivedAt = Date(timeIntervalSince1970: 1_760_000_000)

    private func pdf(id: String, pages: [DocumentPage]) -> ArchivedDocument {
        ArchivedDocument(
            id: id,
            title: "Documento \(id)",
            kind: .pdf,
            originalName: "\(id).pdf",
            copyPath: "\(id).pdf",
            source: DocumentSource(path: "/Users/me/\(id).pdf"),
            contentHash: "hash-\(id)",
            archivedAt: Self.archivedAt,
            language: "it",
            summary: "Riassunto \(id)",
            tags: ["fattura"],
            pages: pages,
            chunks: [DocumentChunk(text: "brano di \(id)", embedding: [0.1, 0.2, 0.3])]
        )
    }

    private func email(id: String) -> ArchivedDocument {
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
                recipients: ["luca@example.com"],
                subject: "Oggetto \(id)",
                sentAt: Self.archivedAt,
                missingAttachmentNames: []
            )
        )
    }

    private func attachment(id: String, of emailID: String) -> ArchivedDocument {
        var document = pdf(id: id, pages: [DocumentPage(number: 1, text: "Testo di \(id)")])
        document.emailID = emailID
        return document
    }

    @Test("The full text joins the pages in page order")
    func fullTextFollowsPageOrder() throws {
        try store.archive([pdf(id: "a", pages: [
            DocumentPage(number: 2, text: "seconda"),
            DocumentPage(number: 1, text: "prima"),
        ])])

        #expect(try store.fullText(ofDocument: "a") == "prima\n\nseconda")
    }

    @Test("The full text of a missing document is nil")
    func fullTextOfMissingDocument() throws {
        #expect(try store.fullText(ofDocument: "assente") == nil)
    }

    @Test("One page is read by its number, a missing page is nil")
    func pageTextByNumber() throws {
        try store.archive([pdf(id: "a", pages: [
            DocumentPage(number: 1, text: "uno"),
            DocumentPage(number: 2, text: "due"),
        ])])

        #expect(try store.pageText(ofDocument: "a", page: 2) == "due")
        #expect(try store.pageText(ofDocument: "a", page: 3) == nil)
        #expect(try store.pageText(ofDocument: "assente", page: 1) == nil)
    }

    @Test("The deletion plan of an email lists its attachments")
    func deletionPlanOfEmail() throws {
        try store.archive([email(id: "mail"), attachment(id: "fattura", of: "mail")])

        let plan = try #require(try store.deletionPlan(ofDocument: "mail"))
        #expect(plan.documentID == "mail")
        #expect(plan.title == "Email mail")
        #expect(plan.kind == .email)
        #expect(plan.archivedAt == Self.archivedAt)
        #expect(plan.attachmentTitles == ["Documento fattura"])
    }

    @Test("The deletion plan of an attachment lists no attachments")
    func deletionPlanOfAttachment() throws {
        try store.archive([email(id: "mail"), attachment(id: "fattura", of: "mail")])

        let plan = try #require(try store.deletionPlan(ofDocument: "fattura"))
        #expect(plan.kind == .pdf)
        #expect(plan.attachmentTitles.isEmpty)
    }

    @Test("The deletion plan of a missing document is nil")
    func deletionPlanOfMissingDocument() throws {
        #expect(try store.deletionPlan(ofDocument: "assente") == nil)
    }
}
