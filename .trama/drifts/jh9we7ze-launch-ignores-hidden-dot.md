---
status: resolved
resolution: fix-code
refs:
  - puntino
  - requirements/data#puntino
proposal: null
task: 0j48bnw0
origin: null
critical: false
option: 1
note: null
resolvedBy: hrfxsylt
created: 2026-10-19T08:15:03.179Z
---
# Launch ignores hidden dot

## What happens

When Axi starts, the dot always appears on screen at its saved place, even when it was hidden in the menu bar when Axi quit.

## What should happen

When Axi starts, the dot comes back the way it was left: on screen where it was, or hidden in the menu bar.

## Fix options

### Read the hidden flag at launch

Read the hidden flag that is already saved together with the dot's place. When it is set, Axi starts with the dot hidden and its menu bar icon in place; otherwise the dot appears where it was left, as now. Costs: the menu bar icon must also be created at launch, so the hidden start depends on that part being ready.

### Apply saved state before first showing

Apply the saved state before the dot is first shown, so no frame of the visible dot appears when Axi starts hidden. Costs: the menu bar icon must exist before the dot window is shown, which changes the order of the launch steps and needs care so a failed icon does not leave the dot missing.

## Where in the code

Axi/Puntino/PuntinoController.swift, avvia: the dot always starts visible and at rest
