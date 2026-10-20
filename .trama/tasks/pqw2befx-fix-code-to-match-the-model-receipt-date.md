---
column: done
technical: false
refs:
  - archiviazione.ARCHIVIATO
  - requirements/ui#attivita
drift: iar3mpgv
proposal: null
agent: false
created: 2026-10-19T12:39:46.610Z
finished: 2026-10-19T13:26:13.884Z
unchanged: "Checked ArchivingPipeline.commit (ArchivingPipeline.swift:537): dataRicezioneSconosciuta is set as primary.kind == .email && primary.email?.sentAt == nil, so non-email documents never get the flag; NuvolettaVista.swift:59 shows the line only when the flag is set. ArchiveReceiptDateTests.nonEmailDocumentHasNoReceiptDateNote already covers a PDF archived through the same path. Behaviour matches the Model; no code changed."
---
# Fix code to match the Model: Receipt-date line on every document

## What happens

After a document that is not an email is archived, the bubble still adds the line saying it could not tell when the document arrived. That line is meant only for an email archived without a receipt date, so a PDF, a Word file or a web page shows a message that does not apply to it.

## What should happen

The line appears only for an email archived without a receipt date. Any other archived document shows its title, its tags and the attachments not taken, without that line.

## Chosen option

**Set the mark only for emails**

Set the flag that drives the line only when the archived document is an email whose receipt date is unknown. Documents of other kinds never get the flag, so their bubble stays as it is. This keeps the bubble and the Model unchanged and fixes the one place where the flag is computed. Add a check that a PDF archived through the same path does not carry the line, next to the existing email check.

## Where in the code

`Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift`, `commit`, the field `dataRicezioneSconosciuta` (line 521): `primary.email?.sentAt == nil` is also true when there is no email. The bubble line is in `Axi/Puntino/NuvolettaVista.swift` (line 59).
