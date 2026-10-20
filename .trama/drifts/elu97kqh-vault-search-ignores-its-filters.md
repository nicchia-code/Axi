---
status: resolved
resolution: fix-code
refs:
  - requirements/tech#mini-chat
proposal: null
task: 239mhirm
origin: null
critical: false
option: 1
note: null
resolvedBy: wmsga3yo
created: 2026-10-18T21:25:27.483Z
---
# Vault search ignores its filters

## What happens

When the assistant searches the vault, it always searches every document. It cannot narrow the search by tag, document type, origin or date.

## What should happen

The assistant can narrow a vault search by tags, document type, origin and dates.

## Fix options

### Expose filters in the search tool

Add the tags, document type, origin and date filters to the search tool offered to the assistant, and pass them to the hybrid search instead of an empty filter. The assistant can then narrow each search to the documents the user means. It costs a larger tool description and validation of the filter values before the search runs.

### Register the existing filtered tool

Register the filtered search tool that already exists in the chat tools under the same name, in place of the unfiltered handler, so the tool offered to the assistant and its handler agree. It costs removing the unfiltered path and keeping the filter definition in one place.

## Where in the code

Packages/AxiOMP/Sources/AxiOMP/OMPHostTools.swift, search_vault definition; Axi/MiniChat/ChatTools.swift, OMPChatTools.searchVault with VaultFilter()
