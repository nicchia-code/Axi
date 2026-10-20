---
column: done
technical: true
refs:
  - requirements/tech#archiviazione
drift: dzuhdmf9
proposal: null
agent: false
created: 2026-10-19T19:00:04.478Z
finished: 2026-10-19T19:09:23.560Z
---
# Fix code to match the Requirements: Oversize PDF downloads start

## What happens

When the server declares a PDF bigger than the maximum at an address that does not end in .pdf, the download starts anyway: the copy is written until the received bytes pass the limit, so the refusal comes late or as a timeout.

## What should happen

A PDF that the server declares bigger than the maximum is refused at once, for every address, and its download never starts.

## Chosen option

**Check declared size for all**

Check the size the server declares as soon as the answer arrives, for every web address, before any byte is written. A declared size above the maximum is refused at once as too large, with the same logged cause as today. Costs: one more check on each web address and no new screen or setting. A server that declares no size is still handled by the byte limit.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchiveSources.swift, WebPageDownloader.receive: the declared size check, which runs only for addresses ending in .pdf
