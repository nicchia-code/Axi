---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#mini-chat
proposal: null
task: 1cprkv52
origin: null
critical: false
option: 1
note: null
resolvedBy: wmsga3yo
created: 2026-10-18T21:25:27.473Z
---
# Chat window cannot be resized

## What happens

The mini-chat window has a fixed size. Its edges do not resize it, so the user cannot make it larger or smaller.

## What should happen

The mini-chat window opens at about 380 by 520 points and the user can resize it.

## Fix options

### Make the window resizable

Add the resizable style to the chat panel and set its minimum and maximum size from the sizes the view already declares, about 320 by 400 points at least. The window keeps its anchor next to the dot and its opening side, so resizing only changes the size. It costs a check that the window stays inside the visible part of the screen while it is resized.

### Draw a corner resize handle

Keep the panel borderless and draw a small handle in the bottom corner of the chat that drags its size, within the same minimum and maximum. The look stays as it is and the window keeps its glass background. It costs handling the mouse drag by hand and redrawing the window frame while the user drags.

## Where in the code

Axi/MiniChat/MiniChatFinestra.swift, PannelloChat init, styleMask
