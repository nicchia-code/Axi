import GRDB
import Testing
@testable import AxiCore

@Test func databaseOpensInMemory() throws {
    let queue = try DatabaseQueue()
    let value = try queue.read { try Int.fetchOne($0, sql: "SELECT 1") }
    #expect(value == 1)
    _ = AxiCore.self
}
