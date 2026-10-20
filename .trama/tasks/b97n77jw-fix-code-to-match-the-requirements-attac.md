---
column: done
technical: true
refs:
  - requirements/tech#archiviazione
drift: i8xcptio
proposal: null
agent: false
created: 2026-10-19T17:18:05.507Z
finished: 2026-10-19T17:51:45.171Z
---
# Fix code to match the Requirements: Attachment error stops archiving

## What happens

When an attachment fails for an unexpected reason while its text is read, the whole archiving ends as an unexpected error, instead of listing that attachment as missing.

## What should happen

A failed attachment is listed as missing with its name, and the email and its other attachments are still archived.

## Chosen option

**Treat any attachment error as its failure**

Treat any error raised while an attachment is read the same as a known failure: remove its copy, list it as missing with its name, and log its step and reason. The email and the other attachments are still archived. Costs: a real fault in an attachment shows only as a missing attachment, and its cause stays in the log rather than in the outcome.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift: process(_:staging:passo:_:) catches only archiving failures for an attachment, so any other error from the text extraction of an attachment (extract, where only the text extractor's unreadable case is mapped) escapes to archive() and ends the archiving as an unexpected error.
