---
status: resolved
resolution: fix-code
refs:
  - mini-chat/Aperta
proposal: null
task: xfy80y60
origin: null
critical: false
option: 1
note: null
resolvedBy: hrfxsylt
created: 2026-10-19T08:14:12.175Z
---
# Unreadable latest conversation opens empty

## What happens

When the chat opens and the latest saved conversation cannot be read, the chat shows an empty conversation with no notice, as if no conversation had ever been saved.

## What should happen

When the latest saved conversation cannot be read, the chat shows the same unreadable notice as the conversation list, and it never shows the conversation as empty nor saves over it.

## Fix options

### Show unreadable notice on open

Opening the chat shows a notice that the latest conversation could not be read, with the conversation list still reachable. The empty chat is not shown, and no new conversation takes the place of the stored one. It costs a small amount of extra state in the chat and a notice the user has to read before continuing.

### Retry reading before the notice

The chat retries reading the latest conversation once before giving up. If the second attempt fails too, it shows the notice as in the first option. It costs a short delay when the chat opens and one more read of the store, but it hides brief read glitches from the user.

### Open the list with the notice

When the latest conversation cannot be read, the chat goes straight to the conversation list, where the unreadable notice is already shown for unreadable conversations. The user can still start a new conversation from the list. It costs one extra step for the user in this rare case.

## Where in the code

Axi/MiniChat/MiniChatController.swift, loading the latest conversation when the chat opens (the fallback to an empty conversation after a failed read)
