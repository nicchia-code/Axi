---
status: resolved
resolution: fix-code
refs:
  - coda-archiviazione/Vuota/lettura-schermo.DOCUMENTO_INDIVIDUATO
  - coda-archiviazione/Con documenti in attesa/lettura-schermo.DOCUMENTO_INDIVIDUATO
proposal: null
task: z3wx25my
origin: null
critical: false
option: 1
note: null
resolvedBy: 7ln2nfjv
created: 2026-10-19T06:57:16.599Z
---
# Reading moment lost before archiving

## What happens

The queue keeps the moment of each reading with its document, but when a document leaves the queue for archiving, archiving receives only the document. The moment of the reading and the received date shown on screen are not passed on, so relative dates are resolved against the time archiving runs.

## What should happen

Each document keeps the moment of its reading and, for an Outlook email, the received date as shown. When a document passes from the queue to archiving, these reach archiving unchanged, so relative dates are resolved against the moment the screen was read.

## Fix options

### Pass the moment to archiving

Carry the reading moment and the shown received date from the queue item into the archiving of each document, and give archiving those values instead of the current time. Archiving then uses the moment of the reading for relative dates. Cost: the archiving entry point takes two more inputs, and its callers and tests change.

### Store moment on the document

Keep the reading moment and the shown date on the document record as soon as it is queued, and let archiving read them from there. This avoids changing the archiving entry point, but spreads the same data across the queue and the record. Cost: a schema field and a small migration to add it.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingService.swift (process, which calls the pipeline with only the candidate); Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift (archive takes only the candidate)
