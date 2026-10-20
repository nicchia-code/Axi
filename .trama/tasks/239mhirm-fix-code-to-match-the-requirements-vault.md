---
column: done
technical: true
refs:
  - requirements/tech#mini-chat
drift: elu97kqh
proposal: null
agent: false
created: 2026-10-18T21:41:02.020Z
finished: 2026-10-19T03:11:28.102Z
---
# Fix code to match the Requirements: Vault search ignores its filters

## What happens

When the assistant searches the vault, it always searches every document. It cannot narrow the search by tag, document type, origin or date.

## What should happen

The assistant can narrow a vault search by tags, document type, origin and dates.

## Chosen option

**Expose filters in the search tool**

Add the tags, document type, origin and date filters to the search tool offered to the assistant, and pass them to the hybrid search instead of an empty filter. The assistant can then narrow each search to the documents the user means. It costs a larger tool description and validation of the filter values before the search runs.

## Where in the code

Packages/AxiOMP/Sources/AxiOMP/OMPHostTools.swift, search_vault definition; Axi/MiniChat/ChatTools.swift, OMPChatTools.searchVault with VaultFilter()
