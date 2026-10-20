---
column: done
technical: false
refs:
  - connessione-omp/Pronta
  - connessione-omp/Avvio
  - requirements/ui#impostazioni
drift: kl0ssxfh
proposal: null
agent: false
created: 2026-10-18T20:05:07.501Z
finished: 2026-10-18T21:28:41.831Z
---
# Fix code to match the Model: Stato OMP fermo durante il riavvio

## What happens

Quando OMP si ferma e Axi lo riavvia (Pronta → Avvio), o quando il percorso cambia dopo Non disponibile (→ Avvio), la finestra Impostazioni continua a mostrare «Connesso» o il motivo di prima: non arriva nessun aggiornamento per lo stato di avvio.

## What should happen

La connessione in Avvio mostra che OMP non è ancora pronto, e la finestra Impostazioni mostra lo stato della connessione e il motivo quando non è disponibile.

## Chosen option

**Evento di avvio dalla connessione**

La connessione emette un evento di avvio a ogni lancio, e la finestra lo segue come gli altri stati.

## Where in the code

Axi/Impostazioni/ImpostazioniModel.swift:69-82 (avvia: solo .ready e .unavailable, default ignora .terminated); Packages/AxiOMP/Sources/AxiOMP/OMPEvents.swift (nessun evento di avvio)
