---
column: done
technical: true
refs:
  - requirements/rules#archiviazione/Generazione dei metadati
drift: o342blld
proposal: null
agent: false
created: 2026-10-19T17:18:05.503Z
finished: 2026-10-19T17:24:48.085Z
---
# Fix code to match the Requirements: Relative dates in long documents

## What happens

In a long document, which is read in sections, relative dates are counted from the day the document is archived, even when its text states the date of the document.

## What should happen

The relative dates of a long document are counted from the date of the document when its text states it, as for a short document.

## Chosen option

**Resolve dates in a final step**

Send each section without a reference date: its relative dates stay in the words of the text, without a date. The final step, which already has the date of the document, then resolves them, as it does for a short document. Costs: the final step must also return the dates of the sections, a longer answer, and the relative dates of a long document stay unresolved until that step succeeds.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchiveMetadata.swift: MetadataPrompts.section (the section answer asks for a summary and cited dates only, not for the document date) and MetadataPrompts.referenceRule, case archiving (tells the answer to give the document date, which sections do not ask for).
