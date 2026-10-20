---
column: done
technical: false
refs:
  - puntino
  - requirements/ui#puntino
drift: 9whcqpfd
proposal: null
agent: false
created: 2026-10-19T12:39:46.619Z
finished: 2026-10-19T13:35:01.250Z
---
# Fix code to match the Model: Chat stays when dot moves

## What happens

While the mini-chat is open beside the character, dragging the character leaves the chat where it was, so the chat is no longer next to the character.

## What should happen

The open mini-chat stays beside the character and moves with it when the character is dragged, as the menu does.

## Chosen option

**Follow the character**

Recompute the chat's place each time the character moves while the chat is open, on the side with more room, the same rule used when the chat opens. The chat then keeps its place next to the character. Cost: the chat moves under the user while they type or read, so the move must be smooth and must keep the chat inside the visible screen.

## Where in the code

Axi/MiniChat/MiniChatFinestra.swift: MiniChatWindowController places the chat only in mostra(), with no reaction to moves. Axi/Puntino/PuntinoController.swift: the didMove observer calls riposizionaAncorati(), which moves only the menu and the bubble, not the chat.
