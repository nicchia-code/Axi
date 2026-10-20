# AxiVectors

Registers sqlite-vec (`vec0` tables) on the GRDB connection of the vault.

## Vendored code

- `Sources/CSQLiteVec/sqlite-vec.c` and `sqlite-vec.h`: sqlite-vec **v0.1.9**, copied unchanged from the `CSQLiteVec` target of `jkrukowski/SQLiteVec` 0.0.15 (which bundles upstream `asg017/sqlite-vec`).
- License: sqlite-vec is by Alex Garcia, MIT OR Apache-2.0 per the upstream repository `asg017/sqlite-vec` (check its LICENSE files when updating).
- Compiled with `SQLITE_CORE` and `SQLITE_VEC_OMIT_FS`, against the system SQLite (`libsqlite3`), so the same database handle GRDB opens can use it.
- `Sources/CSQLiteVec/axi_sqlite_vec.c` is the only file written here: it calls `sqlite3_vec_init` on the connection.

## Usage

```swift
var configuration = Configuration()
configuration.prepareDatabase { db in
    try AxiVectors.register(db.sqliteConnection)
}
```

To update sqlite-vec, replace the two vendored files with a new upstream version and update the version above.
