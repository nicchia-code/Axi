import GRDB

/// Schema of the vault database in `~/Library/Application Support/Axi/`.
///
/// Migrations are append-only: a vault already on disk must keep working, so a
/// shipped migration is never edited. Later migrations are added after `v1-documents`.
enum VaultSchema {
    /// `embeddingDimension` is the size of the vectors the embedding model produces. The
    /// connection must have sqlite-vec registered before this migrator runs.
    static func migrator(embeddingDimension: Int) -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1-documents") { db in
            // One row per document. An email and each of its attachments are
            // separate rows; an attachment points to its email through `email_id`.
            try db.execute(sql: """
                CREATE TABLE documents (
                    id TEXT PRIMARY KEY NOT NULL,
                    title TEXT NOT NULL,
                    kind TEXT NOT NULL CHECK (kind IN ('pdf', 'word', 'email', 'web', 'image', 'other')),
                    original_name TEXT,
                    copy_path TEXT,
                    pdf_missing INTEGER NOT NULL DEFAULT 0 CHECK (pdf_missing IN (0, 1)),
                    source_app TEXT,
                    source_path TEXT,
                    source_url TEXT,
                    content_hash TEXT NOT NULL,
                    document_date DATETIME,
                    archived_at DATETIME NOT NULL,
                    page_count INTEGER NOT NULL CHECK (page_count >= 0),
                    language TEXT,
                    summary TEXT NOT NULL,
                    email_id TEXT REFERENCES documents(id)
                );
                CREATE INDEX documents_content_hash ON documents(content_hash);
                CREATE INDEX documents_email_id ON documents(email_id);

                -- Email-only data: sender, subject, date, and the attachment names Axi did not take.
                CREATE TABLE email_details (
                    document_id TEXT PRIMARY KEY NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                    sender TEXT NOT NULL,
                    subject TEXT NOT NULL,
                    sent_at DATETIME NOT NULL
                );
                CREATE TABLE email_recipients (
                    document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                    position INTEGER NOT NULL,
                    address TEXT NOT NULL,
                    PRIMARY KEY (document_id, position)
                );
                CREATE TABLE email_missing_attachments (
                    document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                    position INTEGER NOT NULL,
                    name TEXT NOT NULL,
                    PRIMARY KEY (document_id, position)
                );

                -- Text, page by page, as extracted from the document.
                CREATE TABLE document_pages (
                    document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                    page_number INTEGER NOT NULL,
                    text TEXT NOT NULL,
                    PRIMARY KEY (document_id, page_number)
                );

                -- Indexed passages of the text. Full-text index and vectors hang off them.
                CREATE TABLE chunks (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                    position INTEGER NOT NULL,
                    text TEXT NOT NULL,
                    UNIQUE (document_id, position)
                );
                CREATE VIRTUAL TABLE chunk_fts USING fts5(
                    text,
                    chunk_id UNINDEXED,
                    document_id UNINDEXED
                );
                -- sqlite-vec index: one vector per chunk, with the chunk id as rowid.
                -- Virtual tables take no foreign keys: the store deletes vectors itself.
                CREATE VIRTUAL TABLE chunk_vectors USING vec0(embedding float[\(embeddingDimension)]);

                -- Tags: one shared vocabulary, a tag exists once (case-insensitive).
                CREATE TABLE tags (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL UNIQUE COLLATE NOCASE
                );
                CREATE TABLE document_tags (
                    document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                    tag_id INTEGER NOT NULL REFERENCES tags(id),
                    PRIMARY KEY (document_id, tag_id)
                );
                CREATE INDEX document_tags_tag_id ON document_tags(tag_id);
                """)
        }

        // Each passage remembers the page it comes from. Nullable: v1 never stored passages.
        migrator.registerMigration("v2-chunk-pages") { db in
            try db.execute(sql: "ALTER TABLE chunks ADD COLUMN page_number INTEGER")
        }

        // Absolute dates. An email's receipt date may be unknown, so sent_at becomes nullable; the
        // date Outlook showed is kept as text; cited dates get their own table; a document's date
        // is its day. Rows already stored keep their values. The table is rebuilt because SQLite
        // cannot drop NOT NULL from an existing column.
        migrator.registerMigration("v3-absolute-dates") { db in
            try db.execute(sql: """
                CREATE TABLE email_details_next (
                    document_id TEXT PRIMARY KEY NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                    sender TEXT NOT NULL,
                    subject TEXT NOT NULL,
                    sent_at DATETIME,
                    sent_at_displayed TEXT
                );
                INSERT INTO email_details_next (document_id, sender, subject, sent_at)
                    SELECT document_id, sender, subject, sent_at FROM email_details;
                DROP TABLE email_details;
                ALTER TABLE email_details_next RENAME TO email_details;

                UPDATE documents SET document_date = substr(document_date, 1, 10)
                    WHERE document_date IS NOT NULL;

                CREATE TABLE cited_dates (
                    document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
                    position INTEGER NOT NULL CHECK (position BETWEEN 0 AND 19),
                    date TEXT,
                    about TEXT NOT NULL,
                    original_text TEXT NOT NULL,
                    PRIMARY KEY (document_id, position)
                );
                """)
        }

        return migrator
    }
}
