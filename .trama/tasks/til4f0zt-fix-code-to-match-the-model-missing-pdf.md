---
column: done
technical: false
refs:
  - documento/Nel vault
  - requirements/data#documento
drift: csdbsw2i
proposal: null
agent: false
created: 2026-10-19T18:14:29.121Z
finished: 2026-10-19T18:25:28.221Z
---
# Fix code to match the Model: Missing-PDF citation opens nothing

## What happens

Clicking a citation of a web page kept without its PDF opens nothing and gives the user no sign. Such a document has no copy in the vault, so the open action has nothing to open.

## What should happen

Clicking a citation of a web page kept without its PDF tells the user what the vault holds: the saved page address, or a note that the PDF was not kept.

## Chosen option

**Open the saved address**

When a cited document has no copy, open the web address kept with it in the default browser. This matches what the Requirement keeps for such a page. Costs: the live page can differ from the archived text, and it may need a login the user does not have.

## Where in the code

Axi/MiniChat/WorkspaceDocumentOpener.swift (open: returns when there is no copy URL); the copy URL comes from Axi/AppDelegate.swift (line 89).
