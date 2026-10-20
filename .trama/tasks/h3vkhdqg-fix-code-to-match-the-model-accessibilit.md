---
column: done
technical: false
refs:
  - requirements/tech#lettura-schermo
  - lettura-schermo/Ricerca del documento
drift: 003ir5ky
proposal: null
agent: false
created: 2026-10-19T03:02:16.416Z
finished: 2026-10-19T03:26:18.556Z
---
# Fix code to match the Model: Accessibility tree limits too low

## What happens

La lettura di una finestra scende solo fino a 25 livelli e legge al massimo 3.000 elementi. Un documento, un indirizzo o un testo più in fondo all'albero non viene trovato, e la ricerca risponde come se non ci fosse nulla da archiviare.

## What should happen

La lettura scende fino a 40 livelli e legge fino a 5.000 elementi, come chiede il requisito tecnico, così il documento, l'indirizzo e il testo si trovano anche quando sono più in profondità.

## Chosen option

**Alzare i limiti a 40 e 5.000**

Portare la profondità a 40 livelli e il numero di elementi a 5.000, come scritto nel requisito. È una modifica di due valori. Ogni lettura visita più elementi e può durare di più, anche se ogni chiamata ha già un limite di due secondi. Va verificata su finestre grandi, per esempio una pagina web lunga o una casella di posta con molti messaggi.

## Where in the code

Packages/AxiScreen/Sources/AxiScreen/LiveAdapters.swift:10-11, costanti maxDepth e maxElements di LiveAccessibilityReader, usate da snapshot(of:)
