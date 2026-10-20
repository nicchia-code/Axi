---
column: done
technical: true
refs:
  - requirements/ui#mini-chat
drift: 8di3c353
proposal: null
agent: false
created: 2026-10-18T21:41:02.013Z
finished: 2026-10-19T03:08:32.114Z
---
# Fix code to match the Requirements: Chat window cannot be resized

## What happens

The mini-chat window has a fixed size. Its edges do not resize it, so the user cannot make it larger or smaller.

## What should happen

The mini-chat window opens at about 380 by 520 points and the user can resize it.

## Chosen option

**Make the window resizable**

Add the resizable style to the chat panel and set its minimum and maximum size from the sizes the view already declares, about 320 by 400 points at least. The window keeps its anchor next to the dot and its opening side, so resizing only changes the size. It costs a check that the window stays inside the visible part of the screen while it is resized.

## Where in the code

Axi/MiniChat/MiniChatFinestra.swift, PannelloChat init, styleMask
