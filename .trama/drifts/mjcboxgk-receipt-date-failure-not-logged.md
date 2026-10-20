---
status: resolved
resolution: fix-code
refs:
  - requirements/quality#archiviazione
proposal: null
task: zdyb9d72
origin: null
critical: false
option: 1
note: null
resolvedBy: 0zmrvfhb
created: 2026-10-19T12:05:23.654Z
---
# Receipt date failure not logged

## What happens

When OMP gives no valid receipt date for an Outlook email, or does not answer in time, the email is archived with its date unknown and nothing is written to the log. Diagnostics cannot show why the date is missing.

## What should happen

Each failure of a step of archiving is written to the log with the step, the reason and the origin of the document. A receipt date that cannot be found is logged too, while archiving goes on.

## Fix options

### Log the receipt date failure

Write a log entry in the acquisition step when OMP gives no valid receipt date, times out or fails. The entry carries the reason and the origin of the document, never the text of the email. Archiving continues with the date unknown, as it does now.

### Leave the date failure unlogged

Keep the current behaviour: a missing receipt date is a normal outcome, already shown to the user through the bubble, and not a failed step. Nothing is logged for it. The requirement on logging would then be narrowed to the steps that can stop archiving.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift:325
