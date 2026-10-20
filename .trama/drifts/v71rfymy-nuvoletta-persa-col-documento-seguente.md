---
status: resolved
resolution: fix-code
refs:
  - attivita
proposal: null
task: 6zcykrhc
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:42:14.266Z
---
# Nuvoletta persa col documento seguente

## What happens

Quando un documento finisce e in coda ne resta un altro, la nuvoletta con l'esito sparisce subito, nell'istante in cui parte il documento successivo. L'esito non resta quindi visibile mentre il lavoro continua.

## What should happen

Il Modello dice che, in corso, una nuvoletta mostra l'esito e il lavoro continua. Il Requisito dice che la nuvoletta resta 5 secondi o finché il puntatore ci resta sopra: non deve sparire al documento successivo.

## Fix options

### Non azzerare la nuvoletta al documento successivo

All'inizio del documento successivo si aggiorna solo il contatore della coda, e la nuvoletta resta dov'è fino alla sua scadenza di 5 secondi. Il lavoro continua sotto l'esito. Costo: con più documenti in coda, la nuvoletta del documento precedente può restare accanto a quella successiva, quindi conviene mostrare un solo esito alla volta.

### Riepilogo degli esiti della coda

Il puntino mostra un riepilogo unico degli esiti della coda, ad esempio quanti documenti sono archiviati e quanti no, invece di una nuvoletta per documento. Costo: il contenuto della nuvoletta cambia rispetto al Modello e al Requisito, quindi serve prima una decisione di prodotto e probabilmente un Proposal.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Attivita/Attivita.swift:111-114 (prossimoDocumento azzera la nuvoletta); Packages/AxiCore/Sources/AxiCore/Archive/ArchivingService.swift:119-125 (finish emette l'esito e subito start(next))
