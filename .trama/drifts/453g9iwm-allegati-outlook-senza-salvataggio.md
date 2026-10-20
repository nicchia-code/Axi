---
status: resolved
resolution: fix-code
refs:
  - archiviazione/Acquisizione
proposal: null
task: 3loarz96
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:41:23.890Z
---
# Allegati Outlook senza salvataggio

## What happens

Gli allegati di Outlook vengono presi leggendo il file esposto dall'elemento dell'interfaccia, senza eseguire l'azione di salvataggio dell'allegato; un elemento senza file è registrato come mancante.

## What should happen

Gli allegati di Outlook si prendono con un tentativo via Accessibility che usa le azioni di salvataggio dell'allegato; quelli non riusciti si registrano come mancanti con il nome.

## Fix options

### Usare l'azione di salvataggio dell'allegato

Il servizio cerca nell'albero di Accessibility l'allegato per nome, esegue l'azione di salvataggio e prende il file salvato. Se l'azione non c'è o fallisce, l'allegato è mancante. Costo: dipende dall'interfaccia di Outlook, da verificare su app reale.

### Tenere la lettura del file e aggiornare la regola

Il servizio continua a leggere il file esposto dall'elemento, senza eseguire azioni. Il Requirement dice invece di usare il salvataggio. Costo: il Requirement cambia e l'efficacia non è verificata su Outlook reale.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchiveSources.swift:111-114
