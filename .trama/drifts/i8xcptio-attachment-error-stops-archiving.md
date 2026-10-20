---
status: resolved
resolution: fix-code
refs:
  - requirements/tech#archiviazione
proposal: null
task: b97n77jw
origin: null
critical: false
option: 1
note: null
resolvedBy: yzey912v
created: 2026-10-19T16:53:59.858Z
---
# Attachment error stops archiving

## What happens

When an attachment fails for an unexpected reason while its text is read, the whole archiving ends as an unexpected error, instead of listing that attachment as missing.

## What should happen

A failed attachment is listed as missing with its name, and the email and its other attachments are still archived.

## Fix options

### Treat any attachment error as its failure

Treat any error raised while an attachment is read the same as a known failure: remove its copy, list it as missing with its name, and log its step and reason. The email and the other attachments are still archived. Costs: a real fault in an attachment shows only as a missing attachment, and its cause stays in the log rather than in the outcome.

### Map it to a known reason

Map an unexpected error of an attachment to a known reason for that attachment, such as an unreadable document, and list it as missing like any other attachment failure. Costs: the reason shown is less precise, and each new kind of error needs its own reason to be chosen.

### Keep the current behaviour

Keep the current behaviour: an unexpected error in one attachment still ends the whole archiving as an unexpected error, and nothing from the email is stored. Costs: one odd attachment blocks the whole email, and the user must remove that attachment and drop the email again.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift: process(_:staging:passo:_:) catches only archiving failures for an attachment, so any other error from the text extraction of an attachment (extract, where only the text extractor's unreadable case is mapped) escapes to archive() and ends the archiving as an unexpected error.
