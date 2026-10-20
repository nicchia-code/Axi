---
column: done
technical: true
refs:
  - requirements/quality#archiviazione
drift: mjcboxgk
proposal: null
agent: false
created: 2026-10-19T12:39:46.591Z
finished: 2026-10-19T12:45:29.978Z
---
# Fix code to match the Requirements: Receipt date failure not logged

## What happens

When OMP gives no valid receipt date for an Outlook email, or does not answer in time, the email is archived with its date unknown and nothing is written to the log. Diagnostics cannot show why the date is missing.

## What should happen

Each failure of a step of archiving is written to the log with the step, the reason and the origin of the document. A receipt date that cannot be found is logged too, while archiving goes on.

## Chosen option

**Log the receipt date failure**

Write a log entry in the acquisition step when OMP gives no valid receipt date, times out or fails. The entry carries the reason and the origin of the document, never the text of the email. Archiving continues with the date unknown, as it does now.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift:325
