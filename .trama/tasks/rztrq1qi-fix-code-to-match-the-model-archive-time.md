---
column: done
technical: false
refs:
  - archiviazione.ARCHIVIATO
  - requirements/tech#archiviazione
drift: bmheuxob
proposal: null
agent: false
created: 2026-10-19T10:35:03.007Z
finished: 2026-10-19T10:49:43.829Z
unchanged: "Checked ArchivingPipeline.swift (emailWork, acquireEmail, EML path, dateReference) and ArchiveReceiptDate.swift: a receipt date that cannot be read stays nil (EML: parsed.sentAt.flatMap(EmailDate.parse) with no fallback; Outlook: receiptDate returns nil on missing, invalid, failed or timed-out OMP answer). The archiving moment is used only as the reference of relative dates of non-email documents, never as receipt date (dateReference returns .unknown for emails without sentAt). Code already matches the Model and the Requirement; no change."
---
# Fix code to match the Model: Archive time as receipt date

## What happens

When the receipt date of an email cannot be read from its date text, Axi stores the moment of archiving as the receipt date.

## What should happen

When the receipt date of an email is not known, Axi keeps it unknown and never uses the moment of archiving as the receipt date.

## Chosen option

**Ask OMP for the receipt date first**

When the date text cannot be read, ask OMP for the absolute receipt date before storing the email. If OMP gives no valid date, keep the receipt date unknown. This matches the separate request the Requirement describes, at the cost of one more OMP request for emails whose date cannot be read.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift, emailWork: sentAt falls back to the current time when EmailDate.parse returns nil
