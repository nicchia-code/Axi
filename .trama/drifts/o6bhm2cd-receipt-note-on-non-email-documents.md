---
status: resolved
resolution: fix-code
refs:
  - archiviazione.ARCHIVIATO
proposal: null
task: dx06mxe6
origin: null
critical: false
option: 1
note: null
resolvedBy: 0zmrvfhb
created: 2026-10-19T12:05:23.643Z
---
# Receipt note on non-email documents

## What happens

A document that is not an email, such as a PDF, a Word file, an image or a web page, is archived and its bubble says the arrival time could not be known. The Model says this note is only for an email whose receipt date stayed unknown.

## What should happen

The note appears only for an email archived without a receipt date. Documents that are not emails show no date note.

## Fix options

### Show the note only for emails

Show the date note only when the archived document is an email whose receipt date stayed unknown. Files, web pages and attachments show no date note. This matches the Model, where the archived event carries the flag for an email only.

### Show the note for every document

Keep the note on every archived document and change its wording so that it says the document has no known date. This gives the flag a meaning for files too, but it goes against the Model, which limits the flag to emails.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift:521
