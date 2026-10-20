---
column: done
technical: false
refs:
  - mini-chat/In risposta
  - requirements/tech#mini-chat
drift: null
proposal: null
agent: false
created: 2026-10-18T18:41:06.550Z
finished: 2026-10-18T20:21:09.818Z
---
# Ponte verso OMP per la chat

Quando l'utente invia una domanda, la risposta arriva da OMP in streaming, con i documenti citati. OMP può chiamare gli strumenti della chat (ricerca nel vault, lettura di una pagina, tag, richiesta di eliminazione) e riceve la conversazione nella sua sessione. Interrompere la risposta ferma OMP. Oggi non esiste un'implementazione di AssistantService collegata a OMP: la chat non può rispondere.
