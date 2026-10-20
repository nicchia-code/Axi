---
status: resolved
resolution: fix-code
refs:
  - documento/Nel vault
  - requirements/data#documento
proposal: null
task: til4f0zt
origin: null
critical: false
option: 1
note: null
resolvedBy: zpa8t2i5
created: 2026-10-19T17:50:14.566Z
---
# Missing-PDF citation opens nothing

## What happens

Clicking a citation of a web page kept without its PDF opens nothing and gives the user no sign. Such a document has no copy in the vault, so the open action has nothing to open.

## What should happen

Clicking a citation of a web page kept without its PDF tells the user what the vault holds: the saved page address, or a note that the PDF was not kept.

## Fix options

### Open the saved address

When a cited document has no copy, open the web address kept with it in the default browser. This matches what the Requirement keeps for such a page. Costs: the live page can differ from the archived text, and it may need a login the user does not have.

### Show a note in the chat

Show a short note under the citation saying that the PDF was not kept, with the kept address and text one click away. Costs: a new piece of chat view and two new texts, and the user still cannot open the page from the chat.

### Hide the open action

Show citations of web pages without a PDF as plain text, without the open action, so nothing looks clickable. Costs: the user loses the way to the page from the chat, and the citation still names a document the user cannot open.

## Where in the code

Axi/MiniChat/WorkspaceDocumentOpener.swift (open: returns when there is no copy URL); the copy URL comes from Axi/AppDelegate.swift (line 89).
