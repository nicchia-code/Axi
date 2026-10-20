---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#puntino/Nascosto
  - puntino/Chat sotto la barra
proposal: null
task: 0patt3ke
origin: null
critical: false
option: 1
note: null
resolvedBy: hf8aqc7d
created: 2026-10-19T14:11:51.332Z
---
# Hidden icon misses wait animation

## What happens

With the dot hidden in the menu bar, the chat opened under the icon leaves the icon still, while the visible dot plays the wait animation whenever the chat is open.

## What should happen

The menu-bar icon plays the same wait animation as the visible dot while the chat is open under it.

## Fix options

### Animate icon while chat open

The menu-bar icon plays the wait animation for as long as the chat is open under it, the same as the visible dot with the chat open. The icon keeps its size and its outcome effects, and only the wait changes. This matches the Requirement for the hidden state and the Visibile state, so the two states behave the same way for the user.

### Keep icon still with chat

The icon stays still while the chat is open under the bar, and the Requirement is changed to say so. The wait then shows only on the visible dot. The user sees less movement when the dot is hidden, which is a smaller change in code but a different rule between the two states of the character.

## Where in the code

Axi/Puntino/PuntinoVista.swift:61-66
