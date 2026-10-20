---
column: done
technical: true
refs:
  - requirements/ui#permessi
drift: 3ulnuyom
proposal: null
agent: false
created: 2026-10-19T12:39:46.605Z
finished: 2026-10-19T13:29:17.144Z
---
# Fix code to match the Requirements: Allow shown for Finder alone

## What happens

The Automation row shows the Allow button whenever the Finder's Automation or a browser's Automation is not granted. With only the Finder not granted, the window shows Allow while it also reports All set and closes. Pressing Allow also asks macOS for the Finder when that is still undecided.

## What should happen

The Allow button appears only when a missing permission is shown, which is a browser's Automation. The Finder's Automation is shown with its state, but its absence does not count, so it should not offer Allow alone.

## Chosen option

**Give the Finder its own Allow**

Keep the Finder in the row with its own Allow button, which asks only for the Finder's Automation through the request the app already has for it. Costs: one more button in a small window, shown for a permission that still does not count as missing at startup.

## Where in the code

Axi/Permessi/PermessiRighe.swift (RigaAutomazione, the condition that shows the Allow button); Packages/AxiScreen/Sources/AxiScreen/Permissions.swift (requestAccess for browser Automation, which includes the Finder)
