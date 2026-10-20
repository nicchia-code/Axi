---
column: done
technical: true
refs:
  - requirements/ui#puntino/Visibile
drift: rv8nao9x
proposal: null
agent: false
created: 2026-10-19T14:49:50.041Z
finished: 2026-10-19T15:42:17.422Z
---
# Fix code to match the Requirements: Dot drawn larger than 32 pt

## What happens

The character on the screen is drawn in a 36-point square, larger than the about 32 points the requirements set for it.

## What should happen

The character on the screen is about 32 points high, as the requirements set, in every state it shows.

## Chosen option

**Draw the character at about 32 pt**

Draw the character at about 32 points inside the same 56-point window. The drops, the eyes, the outcome symbols and the counter scale with it, while the menu, the bubbles and the mini-chat keep their place, because they follow the window and not the drawing. The menu bar icon stays at 18 points. Cost: the figure gets slightly smaller, so the counter and the symbols must be checked for readability.

## Where in the code

Axi/Puntino/PuntinoVista.swift:13 (default side 36), Axi/Puntino/PuntinoVista.swift:71 (figure frame 36), Axi/Puntino/PuntinoController.swift:65-66 (window 56 pt, default side used).
