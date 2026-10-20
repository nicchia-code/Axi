---
column: done
technical: false
refs:
  - archiviazione.ARCHIVIATO
drift: o6bhm2cd
proposal: null
agent: false
created: 2026-10-19T12:39:46.584Z
finished: 2026-10-19T12:44:27.675Z
---
# Fix code to match the Model: Receipt note on non-email documents

## What happens

A document that is not an email, such as a PDF, a Word file, an image or a web page, is archived and its bubble says the arrival time could not be known. The Model says this note is only for an email whose receipt date stayed unknown.

## What should happen

The note appears only for an email archived without a receipt date. Documents that are not emails show no date note.

## Chosen option

**Show the note only for emails**

Show the date note only when the archived document is an email whose receipt date stayed unknown. Files, web pages and attachments show no date note. This matches the Model, where the archived event carries the flag for an email only.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift:521
