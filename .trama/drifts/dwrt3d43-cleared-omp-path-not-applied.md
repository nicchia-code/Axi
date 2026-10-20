---
status: resolved
resolution: fix-code
refs:
  - impostazioni
proposal: null
task: s0gpvhfc
origin: null
critical: false
option: 1
note: null
resolvedBy: lqzwxev6
created: 2026-10-19T12:57:10.855Z
---
# Cleared OMP path not applied

## What happens

When the user empties the OMP path field, Axi saves the empty path but does not restart OMP. The OMP already running keeps going, and the change only shows at the next start of Axi.

## What should happen

Every change takes effect at once. Emptying the OMP path restarts OMP now, and Axi looks for it on the PATH and in the usual folders, as the Requirements say when the path is missing.

## Fix options

### Restart OMP on the cleared path

When the path field is emptied, Axi restarts OMP at once, so the connection looks for it on the PATH and in the usual folders now. The restart runs only on this change, as it does for a real path. Costs: clearing the field interrupts the archiving and the chat in progress, and if OMP is not found the connection shows Non disponibile at once.

### Restart only when OMP changes

When the path is emptied, Axi looks for OMP on the PATH and in the usual folders, and restarts it only if the executable found is not the one already running. Costs: each clearing runs a search, and the connection must compare the running executable with the one found, which adds a case to its restart logic.

## Where in the code

Axi/Impostazioni/ImpostazioniModel.swift, `cambiaPercorsoOMP` (the change is sent only when the path names an existing executable, so an empty path is never sent); Axi/AppDelegate.swift, `riceve` (the `cambiaPercorsoOMP` branch, whose nil case is unreachable from the settings).
