#include <stddef.h>
#define SQLITE_CORE 1

#include "axi_sqlite_vec.h"
#include "sqlite-vec.h"
#include "sqlite3.h"

int axi_sqlite_vec_register(void *db) {
    return sqlite3_vec_init((sqlite3 *)db, NULL, NULL);
}
