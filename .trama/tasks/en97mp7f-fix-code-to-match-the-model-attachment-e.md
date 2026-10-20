---
column: done
technical: false
refs:
  - archiviazione.NON_ARCHIVIATO
drift: lxhcm7h0
proposal: null
agent: false
created: 2026-10-19T19:00:04.471Z
finished: 2026-10-19T19:08:31.040Z
---
# Fix code to match the Model: Attachment error logged as unreadable

## What happens

Quando un allegato di un'email dà un errore che nessuno si aspettava, il log lo registra come documento illeggibile, lo stesso motivo di un file senza testo leggibile.

## What should happen

Un errore non previsto si registra come errore imprevisto, mai come uno dei motivi previsti; l'allegato resta comunque nella lista di quelli non presi.

## Chosen option

**Separate read failures from errors**

Solo il fallimento di lettura del file conta come documento illeggibile. Ogni altro errore su un allegato si registra come errore imprevisto, e l'allegato resta nella lista di quelli non presi. L'archiviazione prosegue come oggi. Costo: una modifica nel solo passo di testo degli allegati, più un controllo che il motivo nel log cambi davvero.

## Where in the code

ArchivingPipeline.swift, passo di testo degli allegati (funzione extract)
