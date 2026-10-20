---
status: resolved
resolution: fix-code
refs:
  - archiviazione.NON_ARCHIVIATO
proposal: null
task: en97mp7f
origin: null
critical: false
option: 1
note: null
resolvedBy: kmlsasy3
created: 2026-10-19T18:18:07.052Z
notBlocking:
  - task: udugf8s8
    reason: La differenza riguarda il passo di lettura del testo degli allegati, non lo scaricamento dei PDF delle pagine web che il Task introduce.
---
# Attachment error logged as unreadable

## What happens

Quando un allegato di un'email dà un errore che nessuno si aspettava, il log lo registra come documento illeggibile, lo stesso motivo di un file senza testo leggibile.

## What should happen

Un errore non previsto si registra come errore imprevisto, mai come uno dei motivi previsti; l'allegato resta comunque nella lista di quelli non presi.

## Fix options

### Separate read failures from errors

Solo il fallimento di lettura del file conta come documento illeggibile. Ogni altro errore su un allegato si registra come errore imprevisto, e l'allegato resta nella lista di quelli non presi. L'archiviazione prosegue come oggi. Costo: una modifica nel solo passo di testo degli allegati, più un controllo che il motivo nel log cambi davvero.

### Stop archiving on attachment error

Un errore non previsto su un allegato interrompe l'intera archiviazione come errore imprevisto, come già accade per il documento principale. Costo: torna il problema già risolto, quando un allegato bloccava l'archiviazione dell'email o del file, e l'utente perde il documento per un solo allegato.

### Keep the attachment reason

Lasciare il comportamento attuale: gli errori sugli allegati restano registrati come documento illeggibile. Scelta valida solo se lo sviluppatore decide che la regola sul motivo non si applica agli allegati. Costo: il log dà un motivo previsto a un errore non previsto, cosa che i requisiti di qualità vietano.

## Where in the code

ArchivingPipeline.swift, passo di testo degli allegati (funzione extract)
