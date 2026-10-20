---
status: resolved
resolution: dismissed
refs:
  - archiviazione.ARCHIVIATO
  - requirements/tech#archiviazione
proposal: null
task: rztrq1qi
origin: null
critical: false
option: 2
note: null
resolvedBy: hrfxsylt
created: 2026-10-19T08:14:26.782Z
---
# Archive time as receipt date

## What happens

When the receipt date of an email cannot be read from its date text, Axi stores the moment of archiving as the receipt date.

## What should happen

When the receipt date of an email is not known, Axi keeps it unknown and never uses the moment of archiving as the receipt date.

## Fix options

### Keep the receipt date unknown

When the date text cannot be read, store no receipt date and report the email as having an unknown receipt date in the archived result, as the Model says. This keeps the vault honest about what is known. The cost is that emails without a readable date stay without a receipt date until the date can be read another way.

### Ask OMP for the receipt date first

When the date text cannot be read, ask OMP for the absolute receipt date before storing the email. If OMP gives no valid date, keep the receipt date unknown. This matches the separate request the Requirement describes, at the cost of one more OMP request for emails whose date cannot be read.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift, emailWork: sentAt falls back to the current time when EmailDate.parse returns nil
