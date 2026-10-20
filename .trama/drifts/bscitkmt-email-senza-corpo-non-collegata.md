---
status: resolved
resolution: proposal
refs:
  - archiviazione/Acquisizione
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: 4p713jb5
created: 2026-10-18T19:46:43.062Z
---
# Email senza corpo non collegata

## What happens

Un file salvato da Outlook, allegato di un'email a schermo con lo stesso nome, non viene collegato a quell'email se il corpo dell'email è vuoto: il file viene archiviato da solo e l'email non entra nel vault.

## What should happen

Il Model dice che un file che è allegato di un'email ancora a schermo in Outlook viene collegato a quell'email; la regola richiede solo il nome dell'allegato e la cartella di Outlook, senza condizione sul corpo.

## Fix options

### Collegare anche con corpo vuoto

Rimuovere la condizione sul corpo: l'email entra nel vault e il file si collega a lei, come descrive il Model. Se l'email vuota non ha testo, la sua estrazione fallisce: va deciso come trattarla.

### Mantenere la regola e dichiararla nel Model

Tenere il controllo sul corpo vuoto e scriverlo nel Model: l'allegato viene archiviato da solo, senza email collegata.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift:154-156 (acquireFile, condizione sul corpo dell'email a schermo)
