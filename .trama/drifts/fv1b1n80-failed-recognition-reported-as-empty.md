---
status: resolved
resolution: fix-code
refs:
  - archiviazione/Estrazione del testo
  - requirements/quality#archiviazione
proposal: null
task: ot54yl20
origin: null
critical: false
option: 1
note: null
resolvedBy: 7ln2nfjv
created: 2026-10-19T03:05:52.113Z
---
# Failed recognition reported as empty

## What happens

When the text recognition of a document fails for a reason of the recognition service, the archiving stops saying that the document has no text, which is one of the predicted reasons.

## What should happen

A recognition failure is an unexpected error: it is not presented as a predicted reason, and the failed step is logged with its reason and origin.

## Fix options

### Treat recognition errors as unexpected

Keep the errors of the recognizer apart from missing text. When the recognition service fails, the archiving ends as an unexpected error, which Axi reports without naming a predicted reason, and the failure is logged. The document is not archived and Axi stays open. The cost is that a service outage shows the generic message instead of a specific reason, which is the honest report of what happened.

### Retry recognition before giving up

Retry a failed recognition a couple of times before ending the archiving, so a short network or service hiccup does not lose the document. If every attempt fails, the archiving ends as an unexpected error, as in the first option. The cost is a longer wait for each failing document and some repeated calls to the recognition service.

## Where in the code

ArchivingPipeline.swift, extract step (lines 363-382): a recognizer error that is not a text extractor failure is mapped to the no-text failure.
