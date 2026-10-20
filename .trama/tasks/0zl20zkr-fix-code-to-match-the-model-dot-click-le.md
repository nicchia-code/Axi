---
column: done
technical: false
refs:
  - puntino/Chat aperta
  - requirements/ui#puntino
drift: m5svplpq
proposal: null
agent: false
created: 2026-10-19T03:02:16.460Z
finished: 2026-10-19T10:49:40.015Z
---
# Fix code to match the Model: Dot click leaves chat open

## What happens

Con la chat aperta, un clic sul puntino non fa nulla: la chat resta aperta e il menu non si apre. La chat si chiude solo con la scorciatoia Chat o con il tasto di chiusura nella finestra della chat.

## What should happen

Con la chat aperta, un clic sul puntino chiude la chat, il puntino torna a riposo nello stesso posto e il menu non si apre.

## Chosen option

**Close the chat on dot click**

Il clic sul puntino, quando la chat è aperta, chiede alla mini-chat di chiudersi, come fa già la scorciatoia Chat. Il puntino torna a riposo quando la chat si chiude, come oggi. Costo: il gestore del clic deve sapere se la chat è aperta, ma questa informazione è già disponibile nel punto in cui il clic viene gestito, e non cambia nessuna regola del Model.

## Where in the code

Axi/Puntino/PuntinoController.swift, `clicPuntino`; Axi/AppDelegate.swift, `riceve` (il ramo di default ignora il clic sul puntino).
