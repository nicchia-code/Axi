---
column: done
technical: false
refs:
  - requirements/tech#mini-chat
  - mini-chat
drift: null
proposal: null
agent: false
created: 2026-10-18T18:40:52.347Z
finished: 2026-10-18T18:58:32.554Z
---
# Ricerca del vault per la chat

La ricerca che OMP usa con search_vault combina la ricerca per parole (FTS5, BM25) e per similarità dei vettori (sqlite-vec), fuse con Reciprocal Rank Fusion, con filtri per tag, tipo, origine e date. Anche read_document_page, set_document_tags e request_document_deletion devono agire sul vault reale, solo su documenti esistenti, e l'eliminazione deve aspettare la conferma dell'utente. Oggi non esistono implementazioni di VaultDocuments né di VaultSearchBackend fuori dai test.
