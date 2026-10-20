import GRDB
import Testing
@testable import AxiVectors

enum RegistrationTestError: Error { case noConnection }

@Test func vec0TableWorksOnGRDBConnection() throws {
    var configuration = Configuration()
    configuration.prepareDatabase { db in
        guard let connection = db.sqliteConnection else { throw RegistrationTestError.noConnection }
        try AxiVectors.register(connection)
    }
    let queue = try DatabaseQueue(configuration: configuration)
    let nearest: Int64? = try queue.write { db in
        try db.execute(sql: "CREATE VIRTUAL TABLE v USING vec0(embedding float[3])")
        try db.execute(sql: "INSERT INTO v(rowid, embedding) VALUES (1, ?), (2, ?)",
                       arguments: ["[1.0, 0.0, 0.0]", "[0.0, 1.0, 0.0]"])
        return try Int64.fetchOne(db, sql: """
            SELECT rowid FROM v WHERE embedding MATCH ? ORDER BY distance LIMIT 1
            """, arguments: ["[0.9, 0.1, 0.0]"])
    }
    #expect(nearest == 1)
}
