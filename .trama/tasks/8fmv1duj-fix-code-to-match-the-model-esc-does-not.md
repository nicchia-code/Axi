---
column: done
technical: false
refs:
  - mini-chat/Aperta/utente.CHIUDE_CHAT
  - requirements/ui#mini-chat
drift: 7lhhsak9
proposal: null
agent: false
created: 2026-10-19T03:02:16.457Z
finished: 2026-10-19T06:35:21.872Z
---
# Fix code to match the Model: Esc does not close chat

## What happens

With the mini-chat open, pressing Esc does nothing and the chat stays open. Esc only closes the dot's menu.

## What should happen

With the mini-chat open, Esc closes it, as the close button does: a running answer is interrupted and the conversation is saved.

## Chosen option

**Chat window handles Esc**

Let the chat window itself handle the Esc key and send the same close action as the close button. The handler runs only while the chat window is key, so Esc typed in other apps never closes the chat. Cost: one small key handler in the chat window, and a check that the text field does not swallow Esc while the user is editing a question.

## Where in the code

Axi/Puntino/PuntinoController.swift: the Esc watcher (chiudeMenuSuEsc and installaMonitorClic); the chat close path is closeChat in Axi/MiniChat/MiniChatMachine.swift
