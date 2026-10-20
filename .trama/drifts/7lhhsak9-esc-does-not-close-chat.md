---
status: resolved
resolution: fix-code
refs:
  - mini-chat/Aperta/utente.CHIUDE_CHAT
  - requirements/ui#mini-chat
proposal: null
task: 8fmv1duj
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:42:22.360Z
---
# Esc does not close chat

## What happens

With the mini-chat open, pressing Esc does nothing and the chat stays open. Esc only closes the dot's menu.

## What should happen

With the mini-chat open, Esc closes it, as the close button does: a running answer is interrupted and the conversation is saved.

## Fix options

### Chat window handles Esc

Let the chat window itself handle the Esc key and send the same close action as the close button. The handler runs only while the chat window is key, so Esc typed in other apps never closes the chat. Cost: one small key handler in the chat window, and a check that the text field does not swallow Esc while the user is editing a question.

### Dot's Esc watcher closes chat

Extend the dot's existing Esc watcher so that, when the chat is open, Esc sends the same close action. That watcher's global monitor sees Esc in every app, so it must act only on local Esc events while the chat is open. Cost: the dot's watcher learns about the chat, coupling the two controllers more closely than today.

## Where in the code

Axi/Puntino/PuntinoController.swift: the Esc watcher (chiudeMenuSuEsc and installaMonitorClic); the chat close path is closeChat in Axi/MiniChat/MiniChatMachine.swift
