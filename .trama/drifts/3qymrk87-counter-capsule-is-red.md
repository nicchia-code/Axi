---
status: resolved
resolution: dismissed
refs:
  - requirements/ui#attivita
proposal: null
task: ym8zqg6c
origin: null
critical: false
option: 1
note: null
resolvedBy: fxquz3ah
created: 2026-10-19T18:57:02.815Z
---
# Counter capsule is red

## What happens

The queue count on the dot is white on a red capsule, not on the accent colour.

## What should happen

The queue count is white inside a small circle or capsule in the accent colour, as the requirement says.

## Fix options

### Use the accent colour

Change the capsule background from the fixed red to the accent colour, keeping the white number and the size rules. This matches the requirement and keeps the counter readable on both light and dark menu bars. The change is local to the counter view and does not affect the dot's states or the bubble.

### Keep red and change requirement

Keep the red capsule as a deliberate warning colour for queued work and update the requirement to say so. This avoids a code change but records a visual decision the developer must confirm. The Model and the other tints stay unchanged.

## Where in the code

Axi/Puntino/PuntinoVista.swift:158
