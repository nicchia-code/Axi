---
column: done
technical: false
refs:
  - utente.APRE_CHAT
  - requirements/quality#lettura-schermo
drift: xmqzx47z
proposal: null
agent: false
created: 2026-10-19T08:10:02.993Z
finished: 2026-10-19T08:16:32.257Z
---
# Fix code to match the Model: Chat without app ends silently

## What happens

When the user opens the chat while Axi itself is in front, no screen is read: the reading never starts, no outcome is produced and nothing is logged. The chat simply gets no screen context.

## What should happen

Opening the chat with no other app to read should end the reading as a refusal with a reason, and that refusal should be logged like the other refusals.

## Chosen option

**Log the refusal with a reason**

Every chat request that finds no app in front is recorded in the system log with the step, the reason and the source app, as the other refusals are. The chat keeps working without screen text, and the reading outcome stays as it is. This adds a logged refusal only, and the Diagram does not change.

## Where in the code

Packages/AxiCore/Sources/AxiCore/LetturaSchermo/LetturaSchermoService.swift, leggeContesto: the guard that returns nil when there is no target app.
