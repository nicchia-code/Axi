---
column: done
technical: false
refs:
  - attivita
drift: v71rfymy
proposal: null
agent: false
created: 2026-10-18T18:45:27.783Z
finished: 2026-10-18T19:08:47.753Z
---
# Fix code to match the Model: Nuvoletta persa col documento seguente

## What happens

Quando un documento finisce e in coda ne resta un altro, la nuvoletta con l'esito sparisce subito, nell'istante in cui parte il documento successivo. L'esito non resta quindi visibile mentre il lavoro continua.

## What should happen

Il Modello dice che, in corso, una nuvoletta mostra l'esito e il lavoro continua. Il Requisito dice che la nuvoletta resta 5 secondi o finché il puntatore ci resta sopra: non deve sparire al documento successivo.

## Chosen option

**Non azzerare la nuvoletta al documento successivo**

All'inizio del documento successivo si aggiorna solo il contatore della coda, e la nuvoletta resta dov'è fino alla sua scadenza di 5 secondi. Il lavoro continua sotto l'esito. Costo: con più documenti in coda, la nuvoletta del documento precedente può restare accanto a quella successiva, quindi conviene mostrare un solo esito alla volta.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Attivita/Attivita.swift:111-114 (prossimoDocumento azzera la nuvoletta); Packages/AxiCore/Sources/AxiCore/Archive/ArchivingService.swift:119-125 (finish emette l'esito e subito start(next))
