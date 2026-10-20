---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#permessi
proposal: null
task: 800gsq7h
origin: null
critical: false
option: 2
note: null
resolvedBy: 0zmrvfhb
created: 2026-10-19T12:05:39.777Z
---
# Allow shown for Finder alone

## What happens

The Automation row shows the Allow button whenever the Finder's Automation or a browser's Automation is not granted. With only the Finder not granted, the window shows Allow while it also reports All set and closes. Pressing Allow also asks macOS for the Finder when that is still undecided.

## What should happen

The Allow button appears only when a missing permission is shown, which is a browser's Automation. The Finder's Automation is shown with its state, but its absence does not count, so it should not offer Allow alone.

## Fix options

### Allow only for browsers

Show the Allow button on the Automation row only when a browser's Automation is missing, and keep the Finder's state as a plain status line. Pressing Allow then asks only for the browsers. Costs: the window can no longer ask for the Finder's Automation, so it must be granted in System Settings when the Finder is the only gap.

### Give the Finder its own Allow

Keep the Finder in the row with its own Allow button, which asks only for the Finder's Automation through the request the app already has for it. Costs: one more button in a small window, shown for a permission that still does not count as missing at startup.

## Where in the code

Axi/Permessi/PermessiRighe.swift (RigaAutomazione, the condition that shows the Allow button); Packages/AxiScreen/Sources/AxiScreen/Permissions.swift (requestAccess for browser Automation, which includes the Finder)
