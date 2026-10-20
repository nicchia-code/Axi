---
status: resolved
resolution: fix-code
refs:
  - lettura-schermo
  - requirements/tech#lettura-schermo
proposal: null
task: 4as2mju1
origin: null
critical: false
option: 1
note: null
resolvedBy: itkbapgm
created: 2026-10-19T18:12:56.635Z
---
# Page address read order

## What happens

Per una pagina web Axi prende l'indirizzo dalla finestra prima che dall'area della pagina, mentre il requisito fissa l'ordine: prima l'area della pagina, e solo se lì manca la barra degli indirizzi.

## What should happen

Per una pagina web Axi legge prima l'indirizzo dell'area della pagina, e solo se lì manca lo legge dalla barra degli indirizzi.

## Fix options

### Read the page area first

Axi cerca l'indirizzo nell'area della pagina, come dice il requisito, e usa l'indirizzo della finestra solo se lì manca, prima della barra degli indirizzi. Quando la finestra mostra un indirizzo diverso dalla pagina, la lettura riguarda la pagina che l'utente vede. Il cambiamento tocca solo la scelta dell'indirizzo, non il rifiuto per file o cartelle.

### Keep window address first

Axi continua a leggere per primo l'indirizzo della finestra, come oggi, e il requisito si aggiorna per dirlo. Il comportamento attuale resta invariato per Safari e Chrome, dove la finestra e la pagina di solito mostrano lo stesso indirizzo. Serve una decisione dello sviluppatore, perché requisito e codice non concordano.

## Where in the code

Packages/AxiScreen/Sources/AxiScreen/DocumentFinder.swift:127-133
