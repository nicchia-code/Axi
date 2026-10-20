import AxiCore
import Foundation
import Testing
@testable import Axi

@Suite("Vault search")
struct VaultSearchTests {
    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// The shared fixture of vault snippets, at `Fixtures/minichat/vault-hits.json`.
    private func fixtureHits() throws -> [VaultHit] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let data = try Data(contentsOf: root.appending(path: "Fixtures/minichat/vault-hits.json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([VaultHit].self, from: data)
    }

    private func hit(_ id: String, tags: [String] = [], page: Int? = 1, snippet: String = "testo") -> VaultHit {
        VaultHit(documentID: id, title: id, kind: "k", origin: "o", tags: tags,
                 archivedAt: Date(timeIntervalSince1970: 0), page: page, snippet: snippet)
    }

    @Test("Filter tags are alternatives inside the group")
    func tagsAreOr() throws {
        let hits = try fixtureHits()
        let filter = VaultFilter(tags: ["casa", "salute"])
        let matched = hits.filter { filter.matches($0, calendar: Self.utc) }.map(\.documentID)
        #expect(matched == ["doc-contratto", "doc-fattura", "doc-referto"])
    }

    @Test("Groups of filters are combined with AND")
    func groupsAreAnd() throws {
        let hits = try fixtureHits()
        let filter = VaultFilter(tags: ["casa"], kinds: ["fattura"])
        let matched = hits.filter { filter.matches($0, calendar: Self.utc) }.map(\.documentID)
        #expect(matched == ["doc-fattura"])
    }

    @Test("Archive dates are inclusive by day")
    func datesAreInclusiveByDay() throws {
        let hits = try fixtureHits()
        let day = Date(timeIntervalSince1970: 1_742_256_000) // 2025-03-18T00:00:00Z
        let filter = VaultFilter(archivedFrom: day, archivedTo: day)
        let matched = hits.filter { filter.matches($0, calendar: Self.utc) }.map(\.documentID)
        #expect(matched == ["doc-fattura"])
    }

    @Test("Document, receipt and cited dates filter by day; a hit without the date never matches a bounded filter")
    func documentReceiptAndCitedDates() {
        let march18 = Date(timeIntervalSince1970: 1_742_256_000)  // 2025-03-18T00:00:00Z
        let march20 = Date(timeIntervalSince1970: 1_742_428_800)  // 2025-03-20T00:00:00Z
        let dated = VaultHit(
            documentID: "dated", title: "dated", kind: "k", origin: "o", tags: [],
            archivedAt: Date(timeIntervalSince1970: 0), page: 1, snippet: "testo",
            documentDate: .day(march18), receivedAt: .day(march18),
            citedDates: [CitedDate(date: .day(march20), about: "scadenza", originalText: "entro il 20 marzo")]
        )
        let undated = hit("undated")
        #expect(VaultFilter(documentFrom: march18, documentTo: march18).matches(dated, calendar: Self.utc))
        #expect(!VaultFilter(documentFrom: march18, documentTo: march18).matches(undated, calendar: Self.utc))
        #expect(VaultFilter(receivedFrom: march18, receivedTo: march18).matches(dated, calendar: Self.utc))
        #expect(VaultFilter(citedFrom: march20, citedTo: march20).matches(dated, calendar: Self.utc))
        #expect(!VaultFilter(citedFrom: march18, citedTo: march18).matches(dated, calendar: Self.utc))
        #expect(!VaultFilter(citedFrom: march18).matches(undated, calendar: Self.utc))
    }

    @Test("Reciprocal rank fusion ranks a snippet found by both methods first")
    func fusionRewardsBothMethods() {
        let a = hit("a"), b = hit("b"), c = hit("c")
        let fused = ReciprocalRankFusion.fuse([[a, b], [b, c]], limit: 10)
        #expect(fused.map(\.documentID) == ["b", "a", "c"])
    }

    @Test("Reciprocal rank fusion keeps the limit and a stable order on ties")
    func fusionLimitAndTies() {
        let a = hit("a"), c = hit("c")
        #expect(ReciprocalRankFusion.fuse([[a], [c]], limit: 10).map(\.documentID) == ["a", "c"])
        #expect(ReciprocalRankFusion.fuse([[a], [c]], limit: 1).map(\.documentID) == ["a"])
    }

    @Test("Hybrid search asks 50 candidates per method, filters, and returns at most 20")
    func hybridSearchLimits() async throws {
        let backend = RecordingBackend(
            lexical: (0..<30).map { hit("lex-\($0)") },
            semantic: (0..<30).map { hit("sem-\($0)") }
        )
        let search = HybridVaultSearch(backend: backend)
        let results = try await search.search(query: "canone", filter: VaultFilter())

        #expect(results.count == HybridVaultSearch.maxResults)
        #expect(await backend.requestedLimits == [50, 50])
    }

    @Test("Hybrid search drops snippets the filter excludes")
    func hybridSearchFilters() async throws {
        let excluded = hit("x", tags: ["altro"])
        let included = hit("y", tags: ["salute"])
        let backend = RecordingBackend(lexical: [excluded, included], semantic: [excluded])
        let search = HybridVaultSearch(backend: backend)
        let results = try await search.search(query: "referto", filter: VaultFilter(tags: ["salute"]))
        #expect(results.map(\.documentID) == ["y"])
    }

    @Test("A blank query returns nothing without asking the backend")
    func blankQuery() async throws {
        let backend = RecordingBackend(lexical: [hit("a")], semantic: [hit("a")])
        let results = try await HybridVaultSearch(backend: backend).search(query: "  ", filter: VaultFilter())
        #expect(results.isEmpty)
        #expect(await backend.requestedLimits.isEmpty)
    }

    @Test("A document goes whole while it fits in half of the context window")
    func wholeDocumentRule() {
        let policy = ContextPolicy(contextWindowTokens: 1000)
        // 2000 UTF-8 bytes are 500 estimated tokens: exactly half of 1000.
        #expect(policy.sendsWholeDocument(String(repeating: "a", count: 2000)))
        #expect(!policy.sendsWholeDocument(String(repeating: "a", count: 2004)))
    }
}

/// Backend with fixed answers that records the limits it was asked for.
/// An actor, because the hybrid search queries both methods concurrently.
private actor RecordingBackend: VaultSearchBackend {
    let lexical: [VaultHit]
    let semantic: [VaultHit]
    private(set) var requestedLimits: [Int] = []

    init(lexical: [VaultHit], semantic: [VaultHit]) {
        self.lexical = lexical
        self.semantic = semantic
    }

    func lexicalMatches(query: String, filter: VaultFilter, limit: Int) async throws -> [VaultHit] {
        requestedLimits.append(limit)
        return Array(lexical.prefix(limit))
    }

    func semanticMatches(query: String, filter: VaultFilter, limit: Int) async throws -> [VaultHit] {
        requestedLimits.append(limit)
        return Array(semantic.prefix(limit))
    }
}
