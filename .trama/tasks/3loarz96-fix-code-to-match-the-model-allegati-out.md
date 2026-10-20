---
column: done
technical: false
refs:
  - archiviazione/Acquisizione
drift: 453g9iwm
proposal: null
agent: false
created: 2026-10-18T18:45:27.754Z
finished: 2026-10-18T20:19:59.970Z
---
# Fix code to match the Model: Allegati Outlook senza salvataggio

## What happens

Gli allegati di Outlook vengono presi leggendo il file esposto dall'elemento dell'interfaccia, senza eseguire l'azione di salvataggio dell'allegato; un elemento senza file è registrato come mancante.

## What should happen

Gli allegati di Outlook si prendono con un tentativo via Accessibility che usa le azioni di salvataggio dell'allegato; quelli non riusciti si registrano come mancanti con il nome.

## Chosen option

**Usare l'azione di salvataggio dell'allegato**

Il servizio cerca nell'albero di Accessibility l'allegato per nome, esegue l'azione di salvataggio e prende il file salvato. Se l'azione non c'è o fallisce, l'allegato è mancante. Costo: dipende dall'interfaccia di Outlook, da verificare su app reale.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchiveSources.swift:111-114
