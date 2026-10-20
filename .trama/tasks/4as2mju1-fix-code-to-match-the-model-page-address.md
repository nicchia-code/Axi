---
column: done
technical: false
refs:
  - lettura-schermo
  - requirements/tech#lettura-schermo
drift: p632kwvt
proposal: null
agent: false
created: 2026-10-19T18:14:30.570Z
finished: 2026-10-19T18:19:12.541Z
---
# Fix code to match the Model: Page address read order

## What happens

Per una pagina web Axi prende l'indirizzo dalla finestra prima che dall'area della pagina, mentre il requisito fissa l'ordine: prima l'area della pagina, e solo se lì manca la barra degli indirizzi.

## What should happen

Per una pagina web Axi legge prima l'indirizzo dell'area della pagina, e solo se lì manca lo legge dalla barra degli indirizzi.

## Chosen option

**Read the page area first**

Axi cerca l'indirizzo nell'area della pagina, come dice il requisito, e usa l'indirizzo della finestra solo se lì manca, prima della barra degli indirizzi. Quando la finestra mostra un indirizzo diverso dalla pagina, la lettura riguarda la pagina che l'utente vede. Il cambiamento tocca solo la scelta dell'indirizzo, non il rifiuto per file o cartelle.

## Where in the code

Packages/AxiScreen/Sources/AxiScreen/DocumentFinder.swift:127-133
