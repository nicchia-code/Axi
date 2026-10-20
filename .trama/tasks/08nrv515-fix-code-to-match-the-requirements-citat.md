---
column: done
technical: true
refs:
  - requirements/ui#mini-chat
drift: m7bsgou7
proposal: null
agent: false
created: 2026-10-19T03:02:16.427Z
finished: 2026-10-19T06:31:34.333Z
---
# Fix code to match the Requirements: Citations list unused search results

## What happens

Every snippet that search finds is listed as a citation of the answer, even when the answer does not use it.

## What should happen

A citation is listed only for the documents and pages the answer actually uses.

## Chosen option

**Cite only what the answer uses**

Have the assistant report the documents it used, through a dedicated tool call or a marker in its answer, and record citations only for those. The answer then lists exactly its sources. It costs a change to the assistant's instructions and tools, and a citation is missed when the assistant forgets to report a source. This is the recommended option.

## Where in the code

Axi/MiniChat/ChatTools.swift:391
