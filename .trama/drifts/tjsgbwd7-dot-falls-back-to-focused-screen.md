---
status: resolved
resolution: fix-code
refs:
  - puntino/Visibile
  - requirements/ui#puntino/Visibile
proposal: null
task: i21oepz6
origin: null
critical: false
option: 1
note: null
resolvedBy: r7movn0w
created: 2026-10-19T14:53:05.345Z
---
# Dot falls back to focused screen

## What happens

When the dot has no saved place, or its saved screen is gone, it appears at the bottom right of the screen that has keyboard focus. That is not always the main screen with the menu bar.

## What should happen

When the dot has no saved place, or its saved screen is gone, it appears at the bottom right of the main screen, the one with the menu bar.

## Fix options

### Use the menu bar screen

Use the screen with the menu bar as the fallback, both when there is no saved place and when the saved screen is gone. The dot then always lands in the same place, as the Requirement says. Cost: a user working on another screen finds the dot on the main screen, away from the window in use.

### Keep the focused screen

Keep the screen that has keyboard focus as the fallback and change the Requirement wording to say active screen. Cost: the Requirement changes, which only the developer may decide; the dot may land on a screen other than the main one, as it does now.

## Where in the code

Axi/Puntino/PuntinoController.swift:359-373 (originePuntinoIniziale; the fallback to the focused screen is at line 370)
