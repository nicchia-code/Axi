---
column: done
technical: false
refs:
  - permessi/Chiusa
drift: try9r9us
proposal: null
agent: false
created: 2026-10-19T12:39:46.596Z
finished: 2026-10-19T13:26:50.608Z
---
# Fix code to match the Model: Closed window asks permissions

## What happens

While the Permissions window is closed, a permission request from the welcome still asks macOS for that permission, and the window keeps its closed state. The Model gives the closed window no request Transition.

## What should happen

The closed window takes no permission request. The welcome's requests still reach macOS, as the welcome Model says, without the closed window taking them.

## Chosen option

**Welcome asks directly**

Send the welcome's permission requests straight to the shared permission model, not through the Permissions window, so the closed window never takes a request. The welcome keeps asking macOS as its Model says. Costs: the request path is split in two, and the welcome and the settings each keep their own route to macOS.

## Where in the code

Axi/Permessi/PermessiController.swift (riceve, case for the permission request); Axi/AppDelegate.swift (routing of the permission request to the Permissions window)
