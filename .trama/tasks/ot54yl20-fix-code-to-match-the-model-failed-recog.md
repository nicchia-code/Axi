---
column: done
technical: false
refs:
  - archiviazione/Estrazione del testo
  - requirements/quality#archiviazione
drift: fv1b1n80
proposal: null
agent: false
created: 2026-10-19T08:10:02.967Z
finished: 2026-10-19T10:49:03.347Z
---
# Fix code to match the Model: Failed recognition reported as empty

## What happens

When the text recognition of a document fails for a reason of the recognition service, the archiving stops saying that the document has no text, which is one of the predicted reasons.

## What should happen

A recognition failure is an unexpected error: it is not presented as a predicted reason, and the failed step is logged with its reason and origin.

## Chosen option

**Treat recognition errors as unexpected**

Keep the errors of the recognizer apart from missing text. When the recognition service fails, the archiving ends as an unexpected error, which Axi reports without naming a predicted reason, and the failure is logged. The document is not archived and Axi stays open. The cost is that a service outage shows the generic message instead of a specific reason, which is the honest report of what happened.

## Where in the code

ArchivingPipeline.swift, extract step (lines 363-382): a recognizer error that is not a text extractor failure is mapped to the no-text failure.
