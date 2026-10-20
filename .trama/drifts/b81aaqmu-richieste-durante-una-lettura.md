---
status: resolved
resolution: fix-code
refs:
  - lettura-schermo/Inattiva
  - lettura-schermo/Ricerca del documento
  - lettura-schermo/Lettura del contesto
proposal: null
task: m1auv20d
origin: null
critical: false
option: 1
note: null
resolvedBy: stsg18fb
created: 2026-10-18T19:11:42.395Z
---
# Richieste durante una lettura

## What happens

Se arriva una richiesta mentre Axi sta già leggendo lo schermo, il codice la scarta. Una richiesta di archiviazione non ha alcun effetto e non viene servita dopo, né l'utente riceve un avviso. Una richiesta di chat non parte: la mini-chat riceve un errore come se la lettura non fosse avviata. Il lavoro in corso non è interrotto.

## What should happen

Il Modello dice che una richiesta arrivata durante un'altra lettura viene servita appena quella finisce. Quindi la richiesta deve restare in attesa e partire quando la lettura in corso è conclusa, senza perdersi.

## Fix options

### Coda delle richieste

Axi tiene in attesa le richieste arrivate durante una lettura, in ordine di arrivo, e avvia ciascuna quando la lettura precedente è conclusa. Un'archiviazione chiesta durante una chat parte dopo di essa; la chat aspetta il proprio contesto senza errori. Costo: l'attesa si somma alla lettura in corso, e serve una regola per le richieste che si accumulano.

### Un'attesa sola

Axi tiene in attesa una sola richiesta, l'ultima arrivata: la richiesta precedente ancora in attesa è sostituita. Più semplice della coda e senza accumulo, ma una richiesta di archiviazione può andare persa se ne arriva un'altra prima della fine. Costo: il comportamento va spiegato all'utente nei casi di sostituzione.

## Where in the code

Packages/AxiCore/Sources/AxiCore/LetturaSchermo/LetturaSchermo.swift (riceve: guard stato == .inattiva); Packages/AxiCore/Sources/AxiCore/LetturaSchermo/LetturaSchermoService.swift (riceve, leggeContesto: ritornano senza avviare la lettura); Packages/AxiScreen/Sources/AxiScreen/ScreenReader.swift (coda acquire/release, mai usata in parallelo)
