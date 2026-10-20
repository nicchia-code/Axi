---
column: done
technical: false
refs:
  - coda-archiviazione/Vuota/lettura-schermo.DOCUMENTO_INDIVIDUATO
  - coda-archiviazione/Con documenti in attesa/lettura-schermo.DOCUMENTO_INDIVIDUATO
drift: fylcg2yw
proposal: null
agent: false
created: 2026-10-19T08:10:02.989Z
finished: 2026-10-19T08:18:57.415Z
---
# Fix code to match the Model: Reading moment lost before archiving

## What happens

The queue keeps the moment of each reading with its document, but when a document leaves the queue for archiving, archiving receives only the document. The moment of the reading and the received date shown on screen are not passed on, so relative dates are resolved against the time archiving runs.

## What should happen

Each document keeps the moment of its reading and, for an Outlook email, the received date as shown. When a document passes from the queue to archiving, these reach archiving unchanged, so relative dates are resolved against the moment the screen was read.

## Chosen option

**Pass the moment to archiving**

Carry the reading moment and the shown received date from the queue item into the archiving of each document, and give archiving those values instead of the current time. Archiving then uses the moment of the reading for relative dates. Cost: the archiving entry point takes two more inputs, and its callers and tests change.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingService.swift (process, which calls the pipeline with only the candidate); Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift (archive takes only the candidate)
