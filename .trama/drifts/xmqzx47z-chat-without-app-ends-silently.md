---
status: resolved
resolution: fix-code
refs:
  - utente.APRE_CHAT
  - requirements/quality#lettura-schermo
proposal: null
task: in6uv2h8
origin: null
critical: false
option: 1
note: null
resolvedBy: 7ln2nfjv
created: 2026-10-19T06:57:36.037Z
---
# Chat without app ends silently

## What happens

When the user opens the chat while Axi itself is in front, no screen is read: the reading never starts, no outcome is produced and nothing is logged. The chat simply gets no screen context.

## What should happen

Opening the chat with no other app to read should end the reading as a refusal with a reason, and that refusal should be logged like the other refusals.

## Fix options

### Log the refusal with a reason

Every chat request that finds no app in front is recorded in the system log with the step, the reason and the source app, as the other refusals are. The chat keeps working without screen text, and the reading outcome stays as it is. This adds a logged refusal only, and the Diagram does not change.

### Read the last other app for chat

When Axi is in front, the chat reads the last other app that came to the front, as archiving already does. The chat then always gets a screen when one exists. This goes beyond the current Requirement, which gives this fallback only to archiving, so the developer should confirm it before it is built.

## Where in the code

Packages/AxiCore/Sources/AxiCore/LetturaSchermo/LetturaSchermoService.swift, leggeContesto: the guard that returns nil when there is no target app.
