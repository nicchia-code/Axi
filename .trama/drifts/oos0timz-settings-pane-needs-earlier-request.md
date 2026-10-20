---
status: resolved
resolution: fix-code
refs:
  - permessi/Aperta/utente.CHIEDE_PERMESSO
  - requirements/tech#permessi
proposal: null
task: ehl4101g
origin: null
critical: false
option: 3
note: null
resolvedBy: hrfxsylt
created: 2026-10-19T08:15:04.898Z
---
# Settings pane needs earlier request

## What happens

Pressing Allow for Accessibility or Screen Recording opens the System Settings pane only when Axi has asked for that permission before. If the permission was already refused in System Settings without an earlier request from Axi, Allow asks macOS, macOS shows no request, and nothing else happens.

## What should happen

When macOS no longer shows its request, the System Settings pane for that permission opens, whatever Axi asked before, so that Allow always leads either to macOS's request or to the pane.

## Fix options

### Detect macOS's request by focus

After asking macOS, wait about a second and check whether Axi still has focus. If the app lost focus to macOS's request, open nothing; if Axi stayed in front and the permission is still missing, open the pane for it. Costs: the rule depends on timing and on how macOS shows its request, so it must be tested on a real macOS 26, as the Requirement asks.

### Open the pane when still missing

After asking macOS, open the System Settings pane for the permission whenever it is still missing, without remembering earlier requests. Costs: when macOS does show its request, the pane opens as well, so the first click may show two windows; the Model's rule that the pane opens only when macOS shows no request is not followed.

### Verify the refused case first

Before changing the rule, check on a real macOS 26 what happens when Allow is pressed for a permission refused by hand in System Settings. If macOS shows nothing, use the first or second option; if macOS shows its request, the current rule stays. Costs: the gap stays open until that check is done.

## Where in the code

Packages/AxiScreen/Sources/AxiScreen/Permissions.swift:99-109 (Accessibility and Screen Recording requests) and 130-135 (the asked flag); Axi/Benvenuto/BenvenutoView.swift:155 (Allow button)
