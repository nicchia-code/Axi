---
column: done
technical: false
refs:
  - mini-chat/Aperta
drift: ipxadqpo
proposal: null
agent: false
created: 2026-10-19T10:35:03.000Z
finished: 2026-10-19T10:44:47.556Z
---
# Fix code to match the Model: Unreadable latest conversation opens empty

## What happens

When the chat opens and the latest saved conversation cannot be read, the chat shows an empty conversation with no notice, as if no conversation had ever been saved.

## What should happen

When the latest saved conversation cannot be read, the chat shows the same unreadable notice as the conversation list, and it never shows the conversation as empty nor saves over it.

## Chosen option

**Show unreadable notice on open**

Opening the chat shows a notice that the latest conversation could not be read, with the conversation list still reachable. The empty chat is not shown, and no new conversation takes the place of the stored one. It costs a small amount of extra state in the chat and a notice the user has to read before continuing.

## Where in the code

Axi/MiniChat/MiniChatController.swift, loading the latest conversation when the chat opens (the fallback to an empty conversation after a failed read)
