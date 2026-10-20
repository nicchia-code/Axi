import CSQLiteVec

/// sqlite-vec support. Call `register` on every connection that uses `vec0` tables,
/// for example in `Configuration.prepareDatabase` with `db.sqliteConnection`.
public enum AxiVectors {
    public struct RegistrationError: Error, Equatable {
        public let resultCode: Int32
    }

    /// Registers the sqlite-vec functions and the `vec0` module on `db`.
    public static func register(_ db: OpaquePointer) throws {
        let code = axi_sqlite_vec_register(UnsafeMutableRawPointer(db))
        guard code == 0 else { throw RegistrationError(resultCode: code) }
    }
}
