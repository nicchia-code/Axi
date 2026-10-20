---
status: resolved
resolution: fix-code
refs:
  - requirements/data#mini-chat
proposal: null
task: ya57pca8
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:01:13.596Z
---
# Unreadable conversation opens empty

## What happens

A saved conversation that cannot be read opens as an empty chat under its own ID, and the next question saves over the stored conversation.

## What should happen

A conversation that cannot be read is not shown as empty and is never overwritten by a new question.

## Fix options

### Show a notice instead of an empty chat

When a chosen conversation cannot be read, show a short notice and keep the chat closed. No empty conversation is started under the stored ID, so nothing is saved over it. The user can then pick another conversation. This needs a notice in the chat view and a small state change. This is the recommended option.

### Start a new conversation on failure

When a conversation cannot be read, open a fresh conversation with a new ID. The unreadable file is never written to. The user loses the view of the old conversation without notice, and the old file stays hidden in the list. It costs nothing new in the interface.

### Block saves until the chat is read

Keep the empty view when a conversation cannot be read, but refuse to save it or accept questions in that conversation until it loads. The stored file stays safe. It costs extra state in the chat machine, and the user cannot continue the conversation at all.

## Where in the code

Axi/MiniChat/MiniChatController.swift:165
