---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#puntino
proposal: null
task: 9flp7xp6
origin: null
critical: false
option: 1
note: null
resolvedBy: lqzwxev6
created: 2026-10-19T12:58:05.040Z
---
# Accent-colour flash on known document

## What happens

When a document is already in the vault, the dot flashes in the macOS accent colour: its shape is drawn as a solid silhouette in that colour, not in its own colours.

## What should happen

The dot keeps its own colours at all times, including during the flash. The already-present signal is a brief flash of the dot itself, without changing its colour to the system accent.

## Fix options

### Flash in the dot's own look

The flash keeps the dot's own look: the still image briefly brightens and fades back, without any tint. Only the flash changes, so the dot stays in its colours everywhere. Cost: the flash is less distinct than the accent colour, so users may notice it less on a busy screen.

### Flash with the drag blue

The flash uses the same blue tint that marks files dragged over the dot, so the dot's only highlight colour is its own blue. Cost: a document already present now looks like a file being dragged, which may confuse users who expect a different signal.

## Where in the code

Axi/Puntino/PuntinoVista.swift:158-169 (lampo: template image with Color.accentColor)
