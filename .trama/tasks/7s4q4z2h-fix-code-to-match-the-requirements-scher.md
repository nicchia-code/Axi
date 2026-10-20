---
column: done
technical: true
refs:
  - requirements/ui#puntino
drift: 2hal6jl9
proposal: null
agent: false
created: 2026-10-18T18:45:27.786Z
finished: 2026-10-18T20:22:17.723Z
---
# Fix code to match the Requirements: Schermo perso e posizione salvata

## What happens

Se lo schermo dove era il puntino non c'è più ma la posizione salvata cade ancora dentro un altro schermo, il puntino resta lì. Va in basso a destra dello schermo principale solo quando la posizione non cade in nessuno schermo.

## What should happen

Se lo schermo dove era il puntino non c'è più, compare in basso a destra dello schermo principale.

## Chosen option

**Riconoscere lo schermo salvato**

Al riavvio Axi cerca lo schermo salvato per il suo identificativo. Se non c'è più, il puntino va in basso a destra dello schermo principale, anche se la posizione salvata cade in un altro schermo. Costo: il puntino non resta dove era sull'altro schermo, anche quando lo spazio ci sarebbe; chi ha un altro schermo al posto di quello di prima vede il puntino spostarsi.

## Where in the code

Axi/Puntino/PuntinoController.swift (originePuntinoIniziale, righe 287-300, in particolare il controllo alla riga 292)
