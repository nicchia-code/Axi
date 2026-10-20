---
status: resolved
resolution: fix-code
refs:
  - puntino
  - requirements/ui#puntino
proposal: null
task: 3vn7suq6
origin: null
critical: false
option: 1
note: null
resolvedBy: 0zmrvfhb
created: 2026-10-19T12:27:56.442Z
---
# Chat stays when dot moves

## What happens

While the mini-chat is open beside the character, dragging the character leaves the chat where it was, so the chat is no longer next to the character.

## What should happen

The open mini-chat stays beside the character and moves with it when the character is dragged, as the menu does.

## Fix options

### Follow the character

Recompute the chat's place each time the character moves while the chat is open, on the side with more room, the same rule used when the chat opens. The chat then keeps its place next to the character. Cost: the chat moves under the user while they type or read, so the move must be smooth and must keep the chat inside the visible screen.

### Close the chat when the character moves

When the character is dragged while the chat is open, return the chat into the character as when it closes, and reopen it beside the character on the next open. Cost: a drag ends the conversation view, and the user may lose their place in the reply until they reopen the chat.

## Where in the code

Axi/MiniChat/MiniChatFinestra.swift: MiniChatWindowController places the chat only in mostra(), with no reaction to moves. Axi/Puntino/PuntinoController.swift: the didMove observer calls riposizionaAncorati(), which moves only the menu and the bubble, not the chat.
