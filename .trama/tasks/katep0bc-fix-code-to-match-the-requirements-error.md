---
column: done
technical: true
refs:
  - requirements/ui#mini-chat
drift: r0rqh3aw
proposal: null
agent: false
created: 2026-10-18T18:45:27.743Z
finished: 2026-10-18T20:23:34.665Z
---
# Fix code to match the Requirements: Errori fuori dalla conversazione

## What happens

Un errore della risposta compare come una riga sotto la conversazione, con il pulsante Riprova accanto. Non diventa un messaggio nella conversazione e non viene salvato con essa.

## What should happen

Gli errori compaiono come messaggio nella conversazione, con il pulsante Riprova quando ha senso.

## Chosen option

**Errore come messaggio nella conversazione**

L'errore diventa un messaggio di Axi nella conversazione, con Riprova sotto quando la domanda può essere rifatta. La riga sotto la conversazione sparisce. Costo: serve decidere se l'errore entra nei dati salvati della conversazione o resta solo sullo schermo, e la vista va adattata.

## Where in the code

Axi/MiniChat/MiniChatView.swift: statusBar, righe 110–124
