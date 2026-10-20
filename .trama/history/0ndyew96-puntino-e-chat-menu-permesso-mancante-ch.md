---
created: 2026-10-19T06:58:33.326Z
updated: 2026-10-19T12:48:41.349Z
summary: Menu del puntino con simboli dei tasti, permesso mancante in chat, chat sotto il puntino, Esc chiude la chat; rimosso il codice di ALTERNA_PUNTINO.
tasks:
  - hkovshqm
  - on9xio8g
  - aloymnr0
  - d0clxuj9
  - 8fmv1duj
  - ynvkfqho
  - ibcntzxv
---
# Puntino e chat: menu, permesso mancante, chat sotto il puntino

- hkovshqm: il menu mostra i simboli del microfono e della lente quando i tasti sono assegnati; oggi la lettura dei tasti è ancora a false in AppDelegate, in attesa di T9 (bloccata da D4 e D5), quindi i simboli non compaiono ancora.
- on9xio8g: in chat, permesso mancante con pulsante Apri i permessi; il pulsante non porta ancora a niente finché la finestra dei permessi (T13) non è fatta.
- aloymnr0: chat sotto il puntino con i pannelli che non attivano Axi.
- d0clxuj9: rimosso il codice di mini-chat/Aperta/utente.ALTERNA_PUNTINO, nessuna modifica di comportamento.
- 8fmv1duj: Esc chiude la chat; non provato a runtime.
