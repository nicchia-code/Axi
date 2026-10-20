---
status: resolved
resolution: fix-code
refs:
  - permessi/Chiusa
proposal: null
task: 1vdx73jf
origin: null
critical: false
option: 1
note: null
resolvedBy: 0zmrvfhb
created: 2026-10-19T12:05:39.765Z
---
# Closed window restarts Axi

## What happens

Reopen Axi in the welcome or in the settings restarts Axi even when the Permissions window is closed, because the Permissions window takes the reopen request in any state. The Model gives the closed window no reopen Transition.

## What should happen

The closed window takes no reopen. Reopen Axi from the settings still restarts the app, as the settings Model says, but the closed window does not take part in it.

## Fix options

### Restart from the app

Let the app itself perform the restart for every reopen request, and keep the state change of the Permissions window only for the open window. The closed window then takes no reopen, as the Model says. Costs: the restart code leaves the Permissions Machine and moves to the app delegate, and the window's reopen case is removed.

### Reopen only from the open window

Send the Reopen Axi request from the Permissions window only while it is open, and have the welcome and the settings restart through their own route. Costs: two routes perform the same restart, so the restart can differ between them, and the closed window still has no say in it.

## Where in the code

Axi/Permessi/PermessiController.swift (riceve, case for the reopen); Axi/AppDelegate.swift (riceve, routing of the reopen to the Permissions window)
