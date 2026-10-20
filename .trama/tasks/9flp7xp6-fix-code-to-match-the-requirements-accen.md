---
column: done
technical: true
refs:
  - requirements/ui#puntino
drift: 7e3h9qmy
proposal: null
agent: false
created: 2026-10-19T13:21:35.729Z
finished: 2026-10-19T13:43:27.631Z
---
# Fix code to match the Requirements: Accent-colour flash on known document

## What happens

When a document is already in the vault, the dot flashes in the macOS accent colour: its shape is drawn as a solid silhouette in that colour, not in its own colours.

## What should happen

The dot keeps its own colours at all times, including during the flash. The already-present signal is a brief flash of the dot itself, without changing its colour to the system accent.

## Chosen option

**Flash in the dot's own look**

The flash keeps the dot's own look: the still image briefly brightens and fades back, without any tint. Only the flash changes, so the dot stays in its colours everywhere. Cost: the flash is less distinct than the accent colour, so users may notice it less on a busy screen.

## Where in the code

Axi/Puntino/PuntinoVista.swift:158-169 (lampo: template image with Color.accentColor)
