---
column: done
technical: true
refs:
  - requirements/tech#mini-chat
drift: null
proposal: zu8hna6x
agent: false
created: 2026-10-19T06:32:37.717Z
finished: 2026-10-19T06:51:19.091Z
---
# Date nella ricerca vault

Lo strumento `search_vault` (percorso di produzione `OMPChatTools` e `OMPHostTools`, filtri in `VaultPassageSearch`) resta una ricerca ibrida FTS5 (BM25) più similarità dei vettori fusa con Reciprocal Rank Fusion, e oltre a tag, tipo, origine e data di archiviazione si può filtrare per data del documento o di ricezione e per date citate, sempre come intervalli nel fuso del Mac.

Ogni risultato (`OMPSearchHit`) porta documento, pagina e brano e in più la data di archiviazione, la data del documento, la data di ricezione se è un'email e le date citate del documento, così OMP può risolvere gli orari relativi rispetto alla data giusta.

Il messaggio inviato a OMP per una domanda comincia con data, ora e fuso correnti, e il blocco del contesto dello schermo porta il momento della sua lettura. `read_document_page`, `set_document_tags`, `request_document_deletion` e l'apertura dei documenti citati con `NSWorkspace` restano come sono.
