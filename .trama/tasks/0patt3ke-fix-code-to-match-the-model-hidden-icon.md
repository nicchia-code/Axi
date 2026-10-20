---
column: done
technical: false
refs:
  - requirements/ui#puntino/Nascosto
  - puntino/Chat sotto la barra
drift: enhmig4b
proposal: null
agent: false
created: 2026-10-19T14:21:28.923Z
finished: 2026-10-19T14:32:39.491Z
---
# Fix code to match the Model: Hidden icon misses wait animation

## What happens

With the dot hidden in the menu bar, the chat opened under the icon leaves the icon still, while the visible dot plays the wait animation whenever the chat is open.

## What should happen

The menu-bar icon plays the same wait animation as the visible dot while the chat is open under it.

## Chosen option

**Animate icon while chat open**

The menu-bar icon plays the wait animation for as long as the chat is open under it, the same as the visible dot with the chat open. The icon keeps its size and its outcome effects, and only the wait changes. This matches the Requirement for the hidden state and the Visibile state, so the two states behave the same way for the user.

## Where in the code

Axi/Puntino/PuntinoVista.swift:61-66
