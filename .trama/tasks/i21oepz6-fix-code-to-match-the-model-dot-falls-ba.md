---
column: done
technical: false
refs:
  - puntino/Visibile
  - requirements/ui#puntino/Visibile
drift: tjsgbwd7
proposal: null
agent: false
created: 2026-10-19T15:26:56.347Z
finished: 2026-10-19T15:43:15.572Z
---
# Fix code to match the Model: Dot falls back to focused screen

## What happens

When the dot has no saved place, or its saved screen is gone, it appears at the bottom right of the screen that has keyboard focus. That is not always the main screen with the menu bar.

## What should happen

When the dot has no saved place, or its saved screen is gone, it appears at the bottom right of the main screen, the one with the menu bar.

## Chosen option

**Use the menu bar screen**

Use the screen with the menu bar as the fallback, both when there is no saved place and when the saved screen is gone. The dot then always lands in the same place, as the Requirement says. Cost: a user working on another screen finds the dot on the main screen, away from the window in use.

## Where in the code

Axi/Puntino/PuntinoController.swift:359-373 (originePuntinoIniziale; the fallback to the focused screen is at line 370)
