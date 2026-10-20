---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#mini-chat
proposal: null
task: 08nrv515
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:01:13.586Z
---
# Citations list unused search results

## What happens

Every snippet that search finds is listed as a citation of the answer, even when the answer does not use it.

## What should happen

A citation is listed only for the documents and pages the answer actually uses.

## Fix options

### Cite only what the answer uses

Have the assistant report the documents it used, through a dedicated tool call or a marker in its answer, and record citations only for those. The answer then lists exactly its sources. It costs a change to the assistant's instructions and tools, and a citation is missed when the assistant forgets to report a source. This is the recommended option.

### Cite only the best hits

Keep the current flow but record citations only for the first few hits of each search, for example the top three. The list gets shorter and cheap to build. It still cites documents the answer may not use, so the difference shrinks rather than disappears.

### Show hits apart from citations

Keep recording every hit, but show them in a separate list of documents the vault found, not among the answer's citations. The citations then match what the answer uses, and the user can still see what was searched. It costs a new section in the chat view and a small change in the citation display.

## Where in the code

Axi/MiniChat/ChatTools.swift:391
