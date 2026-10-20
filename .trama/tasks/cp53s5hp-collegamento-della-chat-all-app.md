---
column: done
technical: false
refs:
  - mini-chat
  - requirements/ui#mini-chat
drift: null
proposal: null
agent: false
created: 2026-10-18T18:40:52.414Z
finished: 2026-10-18T20:16:27.150Z
---
# Collegamento della chat all'app

L'app crea la chat con il suo controller, lo collega allo schermo, all'apertura dei documenti e agli eventi APERTA, CHIUSA e NON_DISPONIBILE, e la mostra come finestra che nasce dal puntino con animazione di espansione e ritorno, nella stessa posizione, aperta verso il centro dello schermo. Oggi MiniChatView non è mai creata, e nessun tipo di produzione implementa MiniChatEventSink: gli eventi non arrivano a puntino e attività.
