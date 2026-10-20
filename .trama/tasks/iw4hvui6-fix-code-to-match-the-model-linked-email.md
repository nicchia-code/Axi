---
column: done
technical: false
refs:
  - archiviazione.ARCHIVIATO
  - archiviazione/Acquisizione
drift: idne5r7n
proposal: null
agent: false
created: 2026-10-19T17:47:15.179Z
finished: 2026-10-19T17:53:23.319Z
---
# Fix code to match the Model: Linked email date not flagged

## What happens

A file is archived together with its Outlook email, and the email has no known receipt date. The archived file's bubble does not say that the email was archived without one.

## What should happen

When an email enters the vault without a known receipt date, the archiving says so, also when that email is archived together with a file attached to it.

## Chosen option

**Flag any email in the batch**

Set the unknown-date mark when any email archived in the batch has no receipt date, not only when the primary document is the email. The bubble then reports the unknown date for the linked email too, as the Model asks for an email archived without a received date. The change stays inside the commit step and touches no other rule.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift:541
