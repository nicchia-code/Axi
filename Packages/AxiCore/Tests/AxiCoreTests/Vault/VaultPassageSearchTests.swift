import Foundation
import Testing
@testable import AxiCore

@Suite("Ricerca nei brani del vault")
struct VaultPassageSearchTests {
    private let store: VaultStore
    private let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appending(path: "vault-search-\(UUID().uuidString)")
        store = try VaultStore(
            databaseURL: root.appending(path: "vault.sqlite"),
            filesDirectory: root.appending(path: "files"),
            embeddingDimension: 3
        )
    }

    private static let march = Date(timeIntervalSince1970: 1_742_256_000)   // 2025-03-18T00:00:00Z
    private static let october = Date(timeIntervalSince1970: 1_760_000_000) // 2025-10-09

    private func document(
        id: String,
        text: String,
        vector: [Float],
        kind: DocumentKind = .pdf,
        tags: [String] = [],
        source: DocumentSource = DocumentSource(app: "Mail"),
        archivedAt: Date = march,
        documentDate: Date? = nil,
        email: EmailDetails? = nil,
        citedDates: [CitedDate] = []
    ) -> ArchivedDocument {
        var document = ArchivedDocument(
            id: id,
            title: "Documento \(id)",
            kind: kind,
            source: source,
            contentHash: "hash-\(id)",
            documentDate: documentDate,
            archivedAt: archivedAt,
            summary: "Riassunto \(id)",
            tags: tags,
            pages: [DocumentPage(number: 2, text: text)],
            chunks: [DocumentChunk(text: text, embedding: vector, page: 2)],
            citedDates: citedDates,
            email: email
        )
        // A web page is kept as text and address when it has no PDF.
        document.pdfMissing = kind == .web
        return document
    }

    @Test("Word search finds the passage with the words, with its page and sorted tags")
    func lexicalFindsPassage() throws {
        try store.archive([
            document(id: "a", text: "Il canone mensile è di 800 euro", vector: [1, 0, 0],
                     tags: ["casa", "contratto"]),
            document(id: "b", text: "Referto medico del mese", vector: [0, 1, 0], tags: ["salute"]),
        ])

        let found = try store.lexicalPassages(matching: "canone", filter: VaultPassageFilter(), limit: 10)

        #expect(found.map(\.documentID) == ["a"])
        #expect(found.first?.page == 2)
        #expect(found.first?.tags == ["casa", "contratto"])
        #expect(found.first?.origin == "Mail")
        #expect(found.first?.text == "Il canone mensile è di 800 euro")
    }

    @Test("Characters that mean something to FTS5 cannot break the word search")
    func lexicalQuerySyntaxIsEscaped() throws {
        try store.archive([document(id: "a", text: "fattura numero 7", vector: [1, 0, 0])])

        let found = try store.lexicalPassages(
            matching: "fattura\" AND NOT (*) NEAR:", filter: VaultPassageFilter(), limit: 10)

        #expect(found.map(\.documentID) == ["a"])
        #expect(try store.lexicalPassages(matching: " \"( ", filter: VaultPassageFilter(), limit: 10).isEmpty)
    }

    @Test("Vector search returns the passage nearest to the query first")
    func semanticNearestFirst() throws {
        try store.archive([
            document(id: "a", text: "primo", vector: [1, 0, 0]),
            document(id: "b", text: "secondo", vector: [0, 1, 0]),
            document(id: "c", text: "terzo", vector: [0.9, 0.1, 0]),
        ])

        let found = try store.semanticPassages(nearest: [1, 0, 0], filter: VaultPassageFilter(), limit: 2)

        #expect(found.map(\.documentID) == ["a", "c"])
    }

    @Test("Vector search refuses a query of the wrong dimension")
    func semanticDimension() throws {
        #expect(throws: VaultSearchError.dimensionMismatch(expected: 3, actual: 2)) {
            try store.semanticPassages(nearest: [1, 0], filter: VaultPassageFilter(), limit: 5)
        }
    }

    @Test("Filters apply inside the index, so a match outside them does not take a slot of the limit")
    func filtersBeforeLimit() throws {
        var documents = (0..<30).map { index in
            document(id: "altro-\(index)", text: "canone canone canone \(index)", vector: [1, 0, 0], tags: ["altro"])
        }
        documents.append(document(id: "salute", text: "canone", vector: [0, 1, 0], tags: ["salute"]))
        try store.archive(documents)

        let lexical = try store.lexicalPassages(
            matching: "canone", filter: VaultPassageFilter(tags: ["Salute"]), limit: 1)
        let semantic = try store.semanticPassages(
            nearest: [1, 0, 0], filter: VaultPassageFilter(tags: ["salute"]), limit: 1)

        #expect(lexical.map(\.documentID) == ["salute"])
        #expect(semantic.map(\.documentID) == ["salute"])
    }

    @Test("Kind, origin and archive date filters combine with AND")
    func otherFilters() throws {
        try store.archive([
            document(id: "pdf-mail", text: "contratto", vector: [1, 0, 0], kind: .pdf,
                     source: DocumentSource(app: "Mail"), archivedAt: Self.march),
            document(id: "web", text: "contratto", vector: [1, 0, 0], kind: .web,
                     source: DocumentSource(url: "https://example.com/offerta"), archivedAt: Self.march),
            document(id: "pdf-old", text: "contratto", vector: [1, 0, 0], kind: .pdf,
                     source: DocumentSource(path: "/Users/me/vecchio.pdf"), archivedAt: Self.october),
        ])

        let byKind = try store.lexicalPassages(
            matching: "contratto", filter: VaultPassageFilter(kinds: ["web"]), limit: 10)
        let byOrigin = try store.lexicalPassages(
            matching: "contratto", filter: VaultPassageFilter(origins: ["/Users/me/vecchio.pdf"]), limit: 10)
        let byDate = try store.lexicalPassages(
            matching: "contratto",
            filter: VaultPassageFilter(archivedFrom: Self.march, archivedTo: Self.march.addingTimeInterval(86_400)),
            limit: 10)
        let combined = try store.semanticPassages(
            nearest: [1, 0, 0],
            filter: VaultPassageFilter(kinds: ["pdf"], origins: ["Mail"], archivedFrom: Self.march),
            limit: 10)

        #expect(byKind.map(\.documentID) == ["web"])
        #expect(byKind.first?.origin == "https://example.com/offerta")
        #expect(byOrigin.map(\.documentID) == ["pdf-old"])
        #expect(Set(byDate.map(\.documentID)) == ["pdf-mail", "web"])
        #expect(combined.map(\.documentID) == ["pdf-mail"])
    }

    /// A day at noon in the Mac's time zone, so that the day is the same in any time zone.
    private static func localNoon(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .distantPast
    }

    @Test("Document, receipt and cited date filters match days of the Mac's time zone and return the dates")
    func dateFilters() throws {
        let invoiceDay = Date(timeIntervalSince1970: 1_741_564_800)  // 2025-03-10T00:00:00Z
        let deadline = Date(timeIntervalSince1970: 1_742_428_800)    // 2025-03-20T00:00:00Z
        let sentAt = Self.localNoon(2025, 10, 9)
        try store.archive([
            document(id: "fattura", text: "contratto fattura", vector: [1, 0, 0], documentDate: invoiceDay),
            document(id: "mail", text: "contratto offerta", vector: [1, 0, 0], kind: .email,
                     email: EmailDetails(sender: "a@example.com", recipients: [], subject: "Offerta", sentAt: sentAt)),
            document(id: "scadenza", text: "contratto scadenza", vector: [1, 0, 0],
                     citedDates: [CitedDate(date: .day(deadline), about: "scadenza", originalText: "entro il 20 marzo")]),
        ])

        let byDocumentDate = try store.lexicalPassages(
            matching: "contratto",
            filter: VaultPassageFilter(documentFrom: Self.localNoon(2025, 3, 10), documentTo: Self.localNoon(2025, 3, 11)),
            limit: 10)
        let byReceipt = try store.lexicalPassages(
            matching: "contratto",
            filter: VaultPassageFilter(receivedFrom: Self.localNoon(2025, 10, 9), receivedTo: Self.localNoon(2025, 10, 10)),
            limit: 10)
        let byCited = try store.lexicalPassages(
            matching: "contratto",
            filter: VaultPassageFilter(citedFrom: Self.localNoon(2025, 3, 20), citedTo: Self.localNoon(2025, 3, 21)),
            limit: 10)

        #expect(byDocumentDate.map(\.documentID) == ["fattura"])
        #expect(byReceipt.map(\.documentID) == ["mail"])
        #expect(byCited.map(\.documentID) == ["scadenza"])
        #expect(byDocumentDate.first?.documentDate == .day(invoiceDay))
        #expect(byReceipt.first?.receivedAt == .instant(sentAt))
        #expect(byCited.first?.citedDates == [
            CitedDate(date: .day(deadline), about: "scadenza", originalText: "entro il 20 marzo"),
        ])
    }
}
