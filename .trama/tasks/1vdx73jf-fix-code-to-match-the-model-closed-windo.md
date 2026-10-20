---
column: done
technical: false
refs:
  - permessi/Chiusa
drift: sfuczyyb
proposal: null
agent: false
created: 2026-10-19T12:39:46.601Z
finished: 2026-10-19T13:28:03.577Z
---
# Fix code to match the Model: Closed window restarts Axi

## What happens

Reopen Axi in the welcome or in the settings restarts Axi even when the Permissions window is closed, because the Permissions window takes the reopen request in any state. The Model gives the closed window no reopen Transition.

## What should happen

The closed window takes no reopen. Reopen Axi from the settings still restarts the app, as the settings Model says, but the closed window does not take part in it.

## Chosen option

**Restart from the app**

Let the app itself perform the restart for every reopen request, and keep the state change of the Permissions window only for the open window. The closed window then takes no reopen, as the Model says. Costs: the restart code leaves the Permissions Machine and moves to the app delegate, and the window's reopen case is removed.

## Where in the code

Axi/Permessi/PermessiController.swift (riceve, case for the reopen); Axi/AppDelegate.swift (riceve, routing of the reopen to the Permissions window)
