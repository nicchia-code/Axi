---
status: resolved
resolution: dismissed
refs:
  - archiviazione.ARCHIVIATO
  - requirements/ui#attivita
proposal: null
task: pqw2befx
origin: null
critical: false
option: 1
note: null
resolvedBy: 0zmrvfhb
created: 2026-10-19T12:06:11.879Z
---
# Receipt-date line on every document

## What happens

After a document that is not an email is archived, the bubble still adds the line saying it could not tell when the document arrived. That line is meant only for an email archived without a receipt date, so a PDF, a Word file or a web page shows a message that does not apply to it.

## What should happen

The line appears only for an email archived without a receipt date. Any other archived document shows its title, its tags and the attachments not taken, without that line.

## Fix options

### Set the mark only for emails

Set the flag that drives the line only when the archived document is an email whose receipt date is unknown. Documents of other kinds never get the flag, so their bubble stays as it is. This keeps the bubble and the Model unchanged and fixes the one place where the flag is computed. Add a check that a PDF archived through the same path does not carry the line, next to the existing email check.

### Decide the line in the bubble

Keep the flag as it is and let the bubble decide. The archived result also carries the kind of the document, and the bubble shows the line only for an email with an unknown receipt date. This moves the rule to where the text is shown, at the cost of one more field in the value passed to the bubble. Add a check that a PDF does not show the line.

## Where in the code

`Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift`, `commit`, the field `dataRicezioneSconosciuta` (line 521): `primary.email?.sentAt == nil` is also true when there is no email. The bubble line is in `Axi/Puntino/NuvolettaVista.swift` (line 59).
