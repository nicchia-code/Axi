---
status: resolved
resolution: fix-code
refs:
  - connessione-omp/Pronta
  - connessione-omp/Avvio
  - requirements/ui#impostazioni
proposal: null
task: vsetr4hm
origin: null
critical: false
option: 2
note: null
resolvedBy: 4p713jb5
created: 2026-10-18T19:57:11.197Z
---
# Stato OMP fermo durante il riavvio

## What happens

Quando OMP si ferma e Axi lo riavvia (Pronta → Avvio), o quando il percorso cambia dopo Non disponibile (→ Avvio), la finestra Impostazioni continua a mostrare «Connesso» o il motivo di prima: non arriva nessun aggiornamento per lo stato di avvio.

## What should happen

La connessione in Avvio mostra che OMP non è ancora pronto, e la finestra Impostazioni mostra lo stato della connessione e il motivo quando non è disponibile.

## Fix options

### Seguire anche la fine di OMP

Impostazioni passano a Avvio in corso quando OMP si ferma o riparte, e tornano a Connesso o Non disponibile quando la connessione lo dice.

### Evento di avvio dalla connessione

La connessione emette un evento di avvio a ogni lancio, e la finestra lo segue come gli altri stati.

## Where in the code

Axi/Impostazioni/ImpostazioniModel.swift:69-82 (avvia: solo .ready e .unavailable, default ignora .terminated); Packages/AxiOMP/Sources/AxiOMP/OMPEvents.swift (nessun evento di avvio)
