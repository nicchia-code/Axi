---
status: resolved
resolution: fix-code
refs:
  - archiviazione.ARCHIVIATO
  - archiviazione/Acquisizione
proposal: null
task: iw4hvui6
origin: null
critical: false
option: 1
note: null
resolvedBy: h7n8rxmk
created: 2026-10-19T17:21:45.946Z
---
# Linked email date not flagged

## What happens

A file is archived together with its Outlook email, and the email has no known receipt date. The archived file's bubble does not say that the email was archived without one.

## What should happen

When an email enters the vault without a known receipt date, the archiving says so, also when that email is archived together with a file attached to it.

## Fix options

### Flag any email in the batch

Set the unknown-date mark when any email archived in the batch has no receipt date, not only when the primary document is the email. The bubble then reports the unknown date for the linked email too, as the Model asks for an email archived without a received date. The change stays inside the commit step and touches no other rule.

### Name the email in the bubble

Keep the current mark for the primary document and add a line in the bubble naming the linked email whose receipt date is unknown. The user then knows which email lacks the date. This needs the bubble view to read the linked email's title.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift:541
