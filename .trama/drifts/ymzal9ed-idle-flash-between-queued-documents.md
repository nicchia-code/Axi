---
status: resolved
resolution: fix-code
refs:
  - attivita/In corso/archiviazione.ARCHIVIATO
  - attivita/In corso/archiviazione.NON_ARCHIVIATO
proposal: null
task: xg5s8onj
origin: null
critical: false
option: 1
note: null
resolvedBy: hrfxsylt
created: 2026-10-19T08:44:28.443Z
---
# Idle flash between queued documents

## What happens

When a document finishes while another one is waiting, the dot briefly shows the outcome as idle, then starts working again on the next document.

## What should happen

When a document finishes and another one is waiting, the dot stays at work and shows the outcome while the queue goes on, without passing through idle.

## Fix options

### Count the next document as waiting

The outcome event reports the documents still to be archived, including the one that starts next, so the dot stays at work on the outcome. The next start then reports the count without it. The change is confined to how the archiving service orders its events and costs nothing visible. The counter shows one more document for the moment of the outcome.

### Pass the next-document flag with the outcome

The outcome event carries whether another document is already queued, and the dot stays at work when it is. This keeps the waiting count exact at every moment. It adds a field to two events and a branch in the dot's state, which costs a little more code than the first option.

### Keep the idle pass as it is

Leave the behaviour unchanged: the idle pass lasts only between two consecutive events, so the developer may judge that nothing is visible. The Model's path then differs from the code. Choose this only if the developer accepts that the drawn Transition does not match the code.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Attivita/Attivita.swift (concludi, which reads the waiting count) and Packages/AxiCore/Sources/AxiCore/Archive/ArchivingService.swift (finish, which removes the next document from the queue before reporting the outcome)
