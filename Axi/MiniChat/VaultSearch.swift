import AxiCore
import Foundation

/// One snippet of a document, as returned by search.
struct VaultHit: Codable, Equatable, Hashable, Sendable {
    var documentID: String
    var title: String
    var kind: String
    var origin: String
    var tags: [String]
    var archivedAt: Date
    var page: Int?
    var snippet: String
    /// The day of the document, when it has one.
    var documentDate: AbsoluteDate? = nil
    /// When the email was received, when the document is an email whose receipt date is known.
    var receivedAt: AbsoluteDate? = nil
    /// The dates the document's text cites; nil when they are not known.
    var citedDates: [CitedDate]? = nil

    /// Identity of the snippet: its document and page, with the text as tie-breaker.
    var chunkKey: String {
        "\(documentID)#\(page ?? 0)#\(snippet)"
    }
}

/// Filters of `search_vault`. Values inside one group are alternatives (OR);
/// the groups are combined with AND. Dates are inclusive, by day, in the Mac's time zone.
struct VaultFilter: Codable, Equatable, Sendable {
    var tags: [String] = []
    var kinds: [String] = []
    var origins: [String] = []
    var archivedFrom: Date?
    var archivedTo: Date?
    var documentFrom: Date?
    var documentTo: Date?
    var receivedFrom: Date?
    var receivedTo: Date?
    /// One of the dates the text cites must fall in the range.
    var citedFrom: Date?
    var citedTo: Date?

    func matches(_ hit: VaultHit, calendar: Calendar = .current) -> Bool {
        if !tags.isEmpty, Set(tags.map { $0.lowercased() }).isDisjoint(with: hit.tags.map { $0.lowercased() }) { return false }
        if !kinds.isEmpty, !kinds.contains(hit.kind) { return false }
        if !origins.isEmpty, !origins.contains(hit.origin) { return false }
        if !Self.within(hit.archivedAt, Self.dayBounds(from: archivedFrom, to: archivedTo, calendar: calendar)) { return false }
        let document = Self.dayBounds(from: documentFrom, to: documentTo, calendar: calendar)
        if !Self.matchesDay(hit.documentDate, document, calendar: calendar) { return false }
        let received = Self.dayBounds(from: receivedFrom, to: receivedTo, calendar: calendar)
        if !Self.matchesDay(hit.receivedAt, received, calendar: calendar) { return false }
        let cited = Self.dayBounds(from: citedFrom, to: citedTo, calendar: calendar)
        if cited.from != nil || cited.to != nil {
            guard hit.citedDates?.contains(where: { Self.matchesDay($0.date, cited, calendar: calendar) }) == true else { return false }
        }
        return true
    }

    /// The bounds as instants: from the start of the first day, to the start of the day after the last.
    /// A side is nil when the filter has no bound on it.
    private static func dayBounds(from: Date?, to: Date?, calendar: Calendar) -> (from: Date?, to: Date?) {
        (
            from.map { calendar.startOfDay(for: $0) },
            to.map { calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: $0)) ?? $0 }
        )
    }

    private static func within(_ instant: Date, _ bounds: (from: Date?, to: Date?)) -> Bool {
        if let from = bounds.from, instant < from { return false }
        if let to = bounds.to, instant >= to { return false }
        return true
    }

    /// Whether a date falls in the bounds by its calendar day. Without bounds every date passes;
    /// with bounds a missing date does not.
    private static func matchesDay(_ date: AbsoluteDate?, _ bounds: (from: Date?, to: Date?), calendar: Calendar) -> Bool {
        guard bounds.from != nil || bounds.to != nil else { return true }
        guard let date, let day = dayStart(date, calendar: calendar) else { return false }
        return within(day, bounds)
    }

    /// The instant at which the calendar day of a date starts in `calendar`. A day is held as its UTC date.
    private static func dayStart(_ date: AbsoluteDate, calendar: Calendar) -> Date? {
        switch date {
        case .instant(let instant):
            return calendar.startOfDay(for: instant)
        case .day(let day):
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = .gmt
            return calendar.date(from: utc.dateComponents([.year, .month, .day], from: day))
        }
    }
}

extension VaultFilter {
    /// The same filters for the vault index: the dates become day bounds in `calendar`.
    func passageFilter(calendar: Calendar) -> VaultPassageFilter {
        let archived = Self.dayBounds(from: archivedFrom, to: archivedTo, calendar: calendar)
        let document = Self.dayBounds(from: documentFrom, to: documentTo, calendar: calendar)
        let received = Self.dayBounds(from: receivedFrom, to: receivedTo, calendar: calendar)
        let cited = Self.dayBounds(from: citedFrom, to: citedTo, calendar: calendar)
        return VaultPassageFilter(
            tags: tags, kinds: kinds, origins: origins,
            archivedFrom: archived.from, archivedTo: archived.to,
            documentFrom: document.from, documentTo: document.to,
            receivedFrom: received.from, receivedTo: received.to,
            citedFrom: cited.from, citedTo: cited.to
        )
    }
}

extension VaultHit {
    init(_ passage: VaultPassage) {
        self.init(
            documentID: passage.documentID, title: passage.title, kind: passage.kind,
            origin: passage.origin, tags: passage.tags, archivedAt: passage.archivedAt,
            page: passage.page, snippet: passage.text,
            documentDate: passage.documentDate, receivedAt: passage.receivedAt, citedDates: passage.citedDates
        )
    }
}

/// The two ways the vault finds snippets. The FTS5 and vector implementations live in
/// the vault and embedding packages; the search logic here only combines them.
protocol VaultSearchBackend: Sendable {
    /// Snippets ranked by word match (BM25), best first, at most `limit`.
    func lexicalMatches(query: String, filter: VaultFilter, limit: Int) async throws -> [VaultHit]
    /// Snippets ranked by meaning (vector similarity), best first, at most `limit`.
    func semanticMatches(query: String, filter: VaultFilter, limit: Int) async throws -> [VaultHit]
}

/// Reciprocal Rank Fusion: each list adds 1 / (k + rank) to a snippet's score.
enum ReciprocalRankFusion {
    static let k = 60.0

    static func fuse(_ rankings: [[VaultHit]], limit: Int) -> [VaultHit] {
        var scores: [String: Double] = [:]
        var firstSeen: [String: VaultHit] = [:]
        var order: [String] = []

        for ranking in rankings {
            for (index, hit) in ranking.enumerated() {
                let key = hit.chunkKey
                if firstSeen[key] == nil {
                    firstSeen[key] = hit
                    order.append(key)
                }
                scores[key, default: 0] += 1 / (k + Double(index + 1))
            }
        }

        // Ties keep the order in which the snippets were first seen, so results are stable.
        let ranked = order.enumerated().sorted { lhs, rhs in
            let left = scores[lhs.element] ?? 0
            let right = scores[rhs.element] ?? 0
            if left != right { return left > right }
            return lhs.offset < rhs.offset
        }
        return ranked.prefix(limit).compactMap { firstSeen[$0.element] }
    }
}

/// Hybrid search: 50 candidates from each method, filtered, fused, at most 20 snippets.
struct HybridVaultSearch: Sendable {
    static let candidatesPerMethod = 50
    static let maxResults = 20

    let backend: any VaultSearchBackend

    func search(query: String, filter: VaultFilter) async throws -> [VaultHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        async let lexical = backend.lexicalMatches(
            query: trimmed, filter: filter, limit: Self.candidatesPerMethod)
        async let semantic = backend.semanticMatches(
            query: trimmed, filter: filter, limit: Self.candidatesPerMethod)
        let (lexicalHits, semanticHits) = try await (lexical, semantic)

        let rankings = [lexicalHits, semanticHits].map { hits in
            hits.filter { filter.matches($0) }
        }
        return ReciprocalRankFusion.fuse(rankings, limit: Self.maxResults)
    }
}

/// The vault's own indexes behind the search: word matches (FTS5) and vector similarity (sqlite-vec).
/// The query is embedded with the same embedder that embeds the passages when they are archived.
struct VaultIndexSearchBackend: VaultSearchBackend {
    let store: VaultStore
    let embedder: any TextEmbedding
    var calendar: Calendar = .current

    func lexicalMatches(query: String, filter: VaultFilter, limit: Int) async throws -> [VaultHit] {
        try store.lexicalPassages(
            matching: query, filter: filter.passageFilter(calendar: calendar), limit: limit
        ).map(VaultHit.init)
    }

    func semanticMatches(query: String, filter: VaultFilter, limit: Int) async throws -> [VaultHit] {
        guard let vector = try await embedder.embed([query]).first else { return [] }
        return try store.semanticPassages(
            nearest: vector, filter: filter.passageFilter(calendar: calendar), limit: limit
        ).map(VaultHit.init)
    }
}

/// Decides whether a whole document goes to the model or only snippets.
struct ContextPolicy: Sendable {
    /// Share of the model's context window a whole document may take.
    static let wholeDocumentShare = 0.5

    let contextWindowTokens: Int

    /// Rough token count: about four UTF-8 bytes per token.
    static func estimatedTokens(_ text: String) -> Int {
        text.utf8.count / 4
    }

    func sendsWholeDocument(_ text: String) -> Bool {
        let limit = Double(contextWindowTokens) * Self.wholeDocumentShare
        return Double(Self.estimatedTokens(text)) <= limit
    }
}
