---
status: resolved
resolution: fix-code
refs:
  - puntino/Chat aperta
  - requirements/ui#puntino
proposal: null
task: 0zl20zkr
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:55:13.536Z
---
# Dot click leaves chat open

## What happens

Con la chat aperta, un clic sul puntino non fa nulla: la chat resta aperta e il menu non si apre. La chat si chiude solo con la scorciatoia Chat o con il tasto di chiusura nella finestra della chat.

## What should happen

Con la chat aperta, un clic sul puntino chiude la chat, il puntino torna a riposo nello stesso posto e il menu non si apre.

## Fix options

### Close the chat on dot click

Il clic sul puntino, quando la chat è aperta, chiede alla mini-chat di chiudersi, come fa già la scorciatoia Chat. Il puntino torna a riposo quando la chat si chiude, come oggi. Costo: il gestore del clic deve sapere se la chat è aperta, ma questa informazione è già disponibile nel punto in cui il clic viene gestito, e non cambia nessuna regola del Model.

### Route the click through the app

Il puntino inoltra il clic, con la chat aperta, come evento di chiusura della chat, e l'applicazione lo instrada alla mini-chat come fa per la scorciatoia. Costo: la scelta dell'evento sta in due punti, il puntino e l'instradamento, invece che in uno solo, e va tenuta allineata con la scorciatoia Chat.

## Where in the code

Axi/Puntino/PuntinoController.swift, `clicPuntino`; Axi/AppDelegate.swift, `riceve` (il ramo di default ignora il clic sul puntino).
