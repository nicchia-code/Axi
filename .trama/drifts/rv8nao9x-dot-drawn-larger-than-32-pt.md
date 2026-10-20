---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#puntino/Visibile
proposal: null
task: ascssjjy
origin: null
critical: false
option: 1
note: null
resolvedBy: v830zia0
created: 2026-10-19T14:42:51.216Z
---
# Dot drawn larger than 32 pt

## What happens

The character on the screen is drawn in a 36-point square, larger than the about 32 points the requirements set for it.

## What should happen

The character on the screen is about 32 points high, as the requirements set, in every state it shows.

## Fix options

### Draw the character at about 32 pt

Draw the character at about 32 points inside the same 56-point window. The drops, the eyes, the outcome symbols and the counter scale with it, while the menu, the bubbles and the mini-chat keep their place, because they follow the window and not the drawing. The menu bar icon stays at 18 points. Cost: the figure gets slightly smaller, so the counter and the symbols must be checked for readability.

### Shrink the window to the figure

Shrink the whole window of the dot to about 32 points, so that the clickable and drop area is exactly the figure. The menu, the bubbles and the mini-chat are anchored to the window, so their placement moves with it and must be checked. Cost: the dot is harder to click and to drop files on, and the counter, which sits outside the body, may fall outside the window.

## Where in the code

Axi/Puntino/PuntinoVista.swift:13 (default side 36), Axi/Puntino/PuntinoVista.swift:71 (figure frame 36), Axi/Puntino/PuntinoController.swift:65-66 (window 56 pt, default side used).
