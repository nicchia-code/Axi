---
column: done
technical: true
refs:
  - requirements/data#mini-chat
drift: qo1ji20h
proposal: null
agent: false
created: 2026-10-19T03:02:16.432Z
finished: 2026-10-19T06:34:18.898Z
---
# Fix code to match the Requirements: Unreadable conversation opens empty

## What happens

A saved conversation that cannot be read opens as an empty chat under its own ID, and the next question saves over the stored conversation.

## What should happen

A conversation that cannot be read is not shown as empty and is never overwritten by a new question.

## Chosen option

**Show a notice instead of an empty chat**

When a chosen conversation cannot be read, show a short notice and keep the chat closed. No empty conversation is started under the stored ID, so nothing is saved over it. The user can then pick another conversation. This needs a notice in the chat view and a small state change. This is the recommended option.

## Where in the code

Axi/MiniChat/MiniChatController.swift:165
