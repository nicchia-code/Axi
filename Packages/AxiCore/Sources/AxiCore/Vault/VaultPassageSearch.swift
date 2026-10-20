import Foundation
import GRDB

/// A passage of a document found by the vault's index, with the document facts that search filters on.
public struct VaultPassage: Sendable, Equatable {
    public let documentID: String
    public let title: String
    /// The raw value of the document kind (`pdf`, `word`, `email`, `web`, `image`, `other`).
    public let kind: String
    /// The app, the original path or the web address the document comes from, the first one known.
    public let origin: String
    /// Sorted by name.
    public let tags: [String]
    public let archivedAt: Date
    /// The day of the document, when the document has one.
    public let documentDate: AbsoluteDate?
    /// When the email was received, when the document is an email whose receipt date is known.
    public let receivedAt: AbsoluteDate?
    /// The dates the document's text cites, in the order of the text.
    public let citedDates: [CitedDate]
    /// The page the passage comes from; nil for text stored without pages.
    public let page: Int?
    public let text: String

    public init(
        documentID: String, title: String, kind: String, origin: String, tags: [String],
        archivedAt: Date, documentDate: AbsoluteDate?, receivedAt: AbsoluteDate?, citedDates: [CitedDate],
        page: Int?, text: String
    ) {
        self.documentID = documentID
        self.title = title
        self.kind = kind
        self.origin = origin
        self.tags = tags
        self.archivedAt = archivedAt
        self.documentDate = documentDate
        self.receivedAt = receivedAt
        self.citedDates = citedDates
        self.page = page
        self.text = text
    }
}

/// Filters applied inside the index, before the candidates are cut to the limit.
/// Values inside one group are alternatives (OR); the groups are combined with AND.
public struct VaultPassageFilter: Sendable, Equatable {
    public var tags: [String]
    public var kinds: [String]
    public var origins: [String]
    /// Inclusive lower bound on the archive date.
    public var archivedFrom: Date?
    /// Exclusive upper bound on the archive date.
    public var archivedTo: Date?
    /// Lower bound (inclusive) and upper bound (exclusive) on the day of the document, in the Mac's time zone.
    public var documentFrom: Date?
    public var documentTo: Date?
    /// The same bounds on the day an email was received.
    public var receivedFrom: Date?
    public var receivedTo: Date?
    /// The same bounds on the dates the document's text cites: one of them must fall inside.
    public var citedFrom: Date?
    public var citedTo: Date?

    public init(
        tags: [String] = [], kinds: [String] = [], origins: [String] = [],
        archivedFrom: Date? = nil, archivedTo: Date? = nil,
        documentFrom: Date? = nil, documentTo: Date? = nil,
        receivedFrom: Date? = nil, receivedTo: Date? = nil,
        citedFrom: Date? = nil, citedTo: Date? = nil
    ) {
        self.tags = tags
        self.kinds = kinds
        self.origins = origins
        self.archivedFrom = archivedFrom
        self.archivedTo = archivedTo
        self.documentFrom = documentFrom
        self.documentTo = documentTo
        self.receivedFrom = receivedFrom
        self.receivedTo = receivedTo
        self.citedFrom = citedFrom
        self.citedTo = citedTo
    }
}

public enum VaultSearchError: Error, Equatable {
    /// The query vector does not have the dimension the vault index was created with.
    case dimensionMismatch(expected: Int, actual: Int)
}

/// The two indexes of the vault: word matches (FTS5, BM25) and vector similarity (sqlite-vec).
extension VaultStore {
    /// How many nearest vectors sqlite-vec returns at most per query.
    static let vectorPool = 4096

    /// Passages whose text has any of the words of `query`, best BM25 rank first, at most `limit`.
    public func lexicalPassages(
        matching query: String, filter: VaultPassageFilter, limit: Int
    ) throws -> [VaultPassage] {
        // Only letters and digits become terms, so no FTS5 syntax can reach the query.
        let terms = query.split { !$0.isLetter && !$0.isNumber }.map { "\"\($0)\"" }
        guard !terms.isEmpty, limit > 0 else { return [] }

        let conditions = Self.conditions(for: filter)
        var arguments: [(any DatabaseValueConvertible)?] = [terms.joined(separator: " OR ")]
        arguments += conditions.values
        arguments.append(limit)

        return try dbQueue.read { db in
            try Self.passages(db, sql: """
                SELECT \(Self.passageColumns)
                FROM chunk_fts
                JOIN chunks c ON c.id = chunk_fts.chunk_id
                JOIN documents d ON d.id = c.document_id
                WHERE chunk_fts MATCH ?\(conditions.sql)
                ORDER BY bm25(chunk_fts), c.id
                LIMIT ?
                """, arguments: StatementArguments(arguments))
        }
    }

    /// Passages whose vectors are nearest to `embedding`, closest first, at most `limit`.
    ///
    /// sqlite-vec returns the `vectorPool` nearest chunks and the filters are applied to them,
    /// so a filtered search is exact for vaults of up to `vectorPool` passages.
    public func semanticPassages(
        nearest embedding: [Float], filter: VaultPassageFilter, limit: Int
    ) throws -> [VaultPassage] {
        guard embedding.count == embeddingDimension else {
            throw VaultSearchError.dimensionMismatch(expected: embeddingDimension, actual: embedding.count)
        }
        guard limit > 0 else { return [] }

        let vector = embedding.withUnsafeBufferPointer { Data(buffer: $0) }
        let conditions = Self.conditions(for: filter)
        var arguments: [(any DatabaseValueConvertible)?] = [vector, Self.vectorPool]
        arguments += conditions.values
        arguments.append(limit)

        return try dbQueue.read { db in
            try Self.passages(db, sql: """
                WITH nearest AS (
                    SELECT rowid AS chunk_id, distance FROM chunk_vectors
                    WHERE embedding MATCH ? AND k = ?
                )
                SELECT \(Self.passageColumns)
                FROM nearest
                JOIN chunks c ON c.id = nearest.chunk_id
                JOIN documents d ON d.id = c.document_id
                WHERE 1 = 1\(conditions.sql)
                ORDER BY nearest.distance, c.id
                LIMIT ?
                """, arguments: StatementArguments(arguments))
        }
    }

    /// The origin of a document as one string: the first of app, path and address that is known.
    private static let originSQL = "COALESCE(NULLIF(d.source_app, ''), NULLIF(d.source_path, ''), NULLIF(d.source_url, ''), '')"

    /// The columns `passages(_:sql:arguments:)` reads. Expects the aliases `c`, `d`.
    private static let passageColumns = """
        c.text AS text, c.page_number AS page_number, d.id AS document_id, d.title AS title,
        d.kind AS kind, d.archived_at AS archived_at, d.document_date AS document_date,
        (SELECT e.sent_at FROM email_details e WHERE e.document_id = d.id) AS received_at,
        \(originSQL) AS origin,
        (SELECT json_group_array(name) FROM (
            SELECT t.name AS name FROM document_tags dt
            JOIN tags t ON t.id = dt.tag_id
            WHERE dt.document_id = d.id
            ORDER BY t.name
        )) AS tags_json,
        (SELECT json_group_array(json_object('date', s.date, 'about', s.about, 'originalText', s.original_text)) FROM (
            SELECT cd.date AS date, cd.about AS about, cd.original_text AS original_text
            FROM cited_dates cd
            WHERE cd.document_id = d.id
            ORDER BY cd.position
        ) s) AS cited_json
        """

    /// SQL conditions over the aliases `d` (documents), each starting with ` AND `,
    /// and their values in order.
    private static func conditions(
        for filter: VaultPassageFilter
    ) -> (sql: String, values: [(any DatabaseValueConvertible)?]) {
        var sql = ""
        var values: [(any DatabaseValueConvertible)?] = []

        func placeholders(_ items: [String]) -> String {
            items.map { _ in "?" }.joined(separator: ", ")
        }
        func append(_ strings: [String]) {
            values += strings.map { Optional($0 as any DatabaseValueConvertible) }
        }

        /// The calendar day (`yyyy-MM-dd`) of a stored date: a day stands for itself, an instant is read
        /// in the Mac's time zone at the time of the search.
        func localDay(_ column: String) -> String {
            "CASE WHEN length(\(column)) = 10 THEN \(column) ELSE date(\(column), 'localtime') END"
        }
        /// Conditions keeping the days from `from` (inclusive) to `to` (exclusive); the bounds are instants.
        func dayBounds(_ day: String, from: Date?, to: Date?) -> [String] {
            var parts: [String] = []
            if let from {
                parts.append("\(day) >= date(?, 'localtime')")
                values.append(from as any DatabaseValueConvertible)
            }
            if let to {
                parts.append("\(day) < date(?, 'localtime')")
                values.append(to as any DatabaseValueConvertible)
            }
            return parts
        }

        if !filter.tags.isEmpty {
            // Tag names are case-insensitive, like the vocabulary of the vault.
            sql += """
                 AND EXISTS (
                    SELECT 1 FROM document_tags dt
                    JOIN tags t ON t.id = dt.tag_id
                    WHERE dt.document_id = d.id AND t.name IN (\(placeholders(filter.tags)))
                 )
                """
            append(filter.tags)
        }
        if !filter.kinds.isEmpty {
            sql += " AND d.kind IN (\(placeholders(filter.kinds)))"
            append(filter.kinds)
        }
        if !filter.origins.isEmpty {
            sql += " AND \(originSQL) IN (\(placeholders(filter.origins)))"
            append(filter.origins)
        }
        if let from = filter.archivedFrom {
            sql += " AND d.archived_at >= ?"
            values.append(from as any DatabaseValueConvertible)
        }
        if let to = filter.archivedTo {
            sql += " AND d.archived_at < ?"
            values.append(to as any DatabaseValueConvertible)
        }
        let document = dayBounds(localDay("d.document_date"), from: filter.documentFrom, to: filter.documentTo)
        if !document.isEmpty {
            sql += " AND " + document.joined(separator: " AND ")
        }
        let received = dayBounds(localDay("e.sent_at"), from: filter.receivedFrom, to: filter.receivedTo)
        if !received.isEmpty {
            sql += """
                 AND EXISTS (
                    SELECT 1 FROM email_details e
                    WHERE e.document_id = d.id AND e.sent_at IS NOT NULL AND \(received.joined(separator: " AND "))
                 )
                """
        }
        let cited = dayBounds(localDay("cd.date"), from: filter.citedFrom, to: filter.citedTo)
        if !cited.isEmpty {
            sql += """
                 AND EXISTS (
                    SELECT 1 FROM cited_dates cd
                    WHERE cd.document_id = d.id AND cd.date IS NOT NULL AND \(cited.joined(separator: " AND "))
                 )
                """
        }
        return (sql, values)
    }

    private static func passages(
        _ db: Database, sql: String, arguments: StatementArguments
    ) throws -> [VaultPassage] {
        try Row.fetchAll(db, sql: sql, arguments: arguments).map { row in
            let tagsJSON: String = row["tags_json"]
            let tags = try JSONDecoder().decode([String].self, from: Data(tagsJSON.utf8)).sorted()
            let citedJSON: String = row["cited_json"]
            let cited = try JSONDecoder().decode([StoredCitedDate].self, from: Data(citedJSON.utf8))
            let page: Int? = row["page_number"]
            let documentDate: String? = row["document_date"]
            let receivedAt: String? = row["received_at"]
            return VaultPassage(
                documentID: row["document_id"],
                title: row["title"],
                kind: row["kind"],
                origin: row["origin"],
                tags: tags,
                archivedAt: row["archived_at"],
                documentDate: documentDate.flatMap(VaultStore.absoluteDate(databaseText:)),
                receivedAt: receivedAt.flatMap(VaultStore.absoluteDate(databaseText:)),
                citedDates: cited.map(\.citedDate),
                page: page,
                text: row["text"]
            )
        }
    }
}

/// A cited date as `cited_json` holds it, with its date as the database text.
private struct StoredCitedDate: Decodable {
    let date: String?
    let about: String
    let originalText: String

    var citedDate: CitedDate {
        CitedDate(date: date.flatMap(VaultStore.absoluteDate(databaseText:)), about: about, originalText: originalText)
    }
}
