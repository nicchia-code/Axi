---
status: resolved
resolution: fix-code
refs:
  - permessi/Chiusa
proposal: null
task: k89fkku4
origin: null
critical: false
option: 1
note: null
resolvedBy: 0zmrvfhb
created: 2026-10-19T12:05:39.753Z
---
# Closed window asks permissions

## What happens

While the Permissions window is closed, a permission request from the welcome still asks macOS for that permission, and the window keeps its closed state. The Model gives the closed window no request Transition.

## What should happen

The closed window takes no permission request. The welcome's requests still reach macOS, as the welcome Model says, without the closed window taking them.

## Fix options

### Welcome asks directly

Send the welcome's permission requests straight to the shared permission model, not through the Permissions window, so the closed window never takes a request. The welcome keeps asking macOS as its Model says. Costs: the request path is split in two, and the welcome and the settings each keep their own route to macOS.

### Requests only while welcome runs

Keep the route through the Permissions window, but let it take a request only while the welcome is open; otherwise a closed window ignores it. Costs: the window must know whether the welcome is open, a coupling that the Model does not describe and that is easy to break when the welcome changes.

## Where in the code

Axi/Permessi/PermessiController.swift (riceve, case for the permission request); Axi/AppDelegate.swift (routing of the permission request to the Permissions window)
