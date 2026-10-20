---
column: done
technical: false
refs:
  - lettura-schermo/Inattiva
  - lettura-schermo/Ricerca del documento
  - lettura-schermo.DOCUMENTO_INDIVIDUATO
  - lettura-schermo.NESSUN_DOCUMENTO
drift: null
proposal: null
agent: false
created: 2026-10-18T18:40:31.944Z
finished: 2026-10-18T18:56:20.784Z
---
# Ricerca del documento in funzione

Quando l'utente chiede l'archiviazione (⌥A, dal puntino o dal menu), Axi memorizza l'app in primo piano nel momento della richiesta e la passa alla ricerca del documento. La ricerca deve partire da utente.CHIEDE_ARCHIVIAZIONE, portare la Machine lettura-schermo da Inattiva a Ricerca del documento, e tornare a Inattiva emettendo lettura-schermo.DOCUMENTO_INDIVIDUATO (verso la coda di archiviazione) oppure lettura-schermo.NESSUN_DOCUMENTO (verso Attività). Oggi ScreenReader non viene mai creato né riceve richieste dall'app, quindi nessuna delle due uscite è prodotta.
