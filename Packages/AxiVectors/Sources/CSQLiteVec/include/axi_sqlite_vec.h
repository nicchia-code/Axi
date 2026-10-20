#ifndef AXI_SQLITE_VEC_H
#define AXI_SQLITE_VEC_H

/// Registers sqlite-vec on an existing SQLite connection (`sqlite3 *`, passed as `void *`
/// so that no SQLite header leaks into Swift). Returns the SQLite result code (0 = SQLITE_OK).
int axi_sqlite_vec_register(void *db);

#endif
