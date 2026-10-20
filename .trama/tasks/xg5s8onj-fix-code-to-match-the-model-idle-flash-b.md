---
column: done
technical: false
refs:
  - attivita/In corso/archiviazione.ARCHIVIATO
  - attivita/In corso/archiviazione.NON_ARCHIVIATO
drift: ymzal9ed
proposal: null
agent: false
created: 2026-10-19T10:35:03.041Z
finished: 2026-10-19T10:41:41.708Z
---
# Fix code to match the Model: Idle flash between queued documents

## What happens

When a document finishes while another one is waiting, the dot briefly shows the outcome as idle, then starts working again on the next document.

## What should happen

When a document finishes and another one is waiting, the dot stays at work and shows the outcome while the queue goes on, without passing through idle.

## Chosen option

**Count the next document as waiting**

The outcome event reports the documents still to be archived, including the one that starts next, so the dot stays at work on the outcome. The next start then reports the count without it. The change is confined to how the archiving service orders its events and costs nothing visible. The counter shows one more document for the moment of the outcome.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Attivita/Attivita.swift (concludi, which reads the waiting count) and Packages/AxiCore/Sources/AxiCore/Archive/ArchivingService.swift (finish, which removes the next document from the queue before reporting the outcome)
