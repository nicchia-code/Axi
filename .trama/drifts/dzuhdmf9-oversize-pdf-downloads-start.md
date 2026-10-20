---
status: resolved
resolution: fix-code
refs:
  - requirements/tech#archiviazione
proposal: null
task: 430qnib5
origin: null
critical: false
option: 1
note: null
resolvedBy: kmlsasy3
created: 2026-10-19T18:30:32.938Z
---
# Oversize PDF downloads start

## What happens

When the server declares a PDF bigger than the maximum at an address that does not end in .pdf, the download starts anyway: the copy is written until the received bytes pass the limit, so the refusal comes late or as a timeout.

## What should happen

A PDF that the server declares bigger than the maximum is refused at once, for every address, and its download never starts.

## Fix options

### Check declared size for all

Check the size the server declares as soon as the answer arrives, for every web address, before any byte is written. A declared size above the maximum is refused at once as too large, with the same logged cause as today. Costs: one more check on each web address and no new screen or setting. A server that declares no size is still handled by the byte limit.

### Use the first-answer limit

Keep the size check where it is but run it inside the first-answer limit, so a declared oversize answer is refused within the same time for every address. Costs: a slightly longer code path to follow, and a server that answers slowly still ends as a timeout rather than as too large.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchiveSources.swift, WebPageDownloader.receive: the declared size check, which runs only for addresses ending in .pdf
