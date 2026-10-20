---
column: done
technical: false
refs:
  - lettura-schermo/Ricerca del documento
  - requirements/tech#lettura-schermo
drift: null
proposal: axxxv89o
agent: false
created: 2026-10-19T16:49:18.317Z
finished: 2026-10-19T16:57:01.896Z
---
# File locali nel browser

Quando in primo piano c'è Safari, Chrome o Firefox e l'indirizzo letto è quello di un file sul Mac (`file://`), qualunque sia il suo formato, il browser lo sta solo mostrando: Axi lo tratta come un file aperto in qualsiasi altra app, come l'`AXDocument` delle altre app, e non come una pagina web. Il documento individuato è quindi un file, che segue la stessa strada dei file (copia originale, testo estratto, regole dei file), con il browser come app di provenienza.

L'indirizzo `file://` vale da qualunque punto venga letto: dall'area della pagina (`AXWebArea`, `AXURL` e poi `AXDocument`), dalla barra degli indirizzi o, per Safari e Chrome quando Accessibility non basta, dall'Automazione. Se l'indirizzo letto non è né `file://` né `http`/`https` resta il rifiuto attuale per indirizzo illeggibile.

Una pagina web ha un indirizzo `http` o `https`. Un PDF mostrato dal browser a un indirizzo `http`/`https` resta una pagina web, con il suo indirizzo, anche quando il testo visibile letto con Accessibility è vuoto: la ricerca del documento non lo scarta e non lo rifiuta per mancanza di testo.

Codice da toccare: `Packages/AxiScreen/Sources/AxiScreen/DocumentFinder.swift`, il ramo dei browser in `DocumentFinder.find` (oggi sempre `.webPage`) e `BrowserAddress`, che oggi accetta solo indirizzi `http`/`https` sia dall'albero sia dalla barra degli indirizzi e scarta quindi i `file://`; verificare anche il fallback dell'Automazione in `LiveAdapters.swift`, che oggi si attiva solo se nessun nodo ha un indirizzo, perché un `file://` letto con Accessibility basti senza ricorrere all'Automazione. I test di `DocumentFinder` coprono: `file://` dall'area della pagina, dalla barra degli indirizzi e dall'Automazione dà un file; `http`/`https` dà una pagina web, anche con testo visibile vuoto.
