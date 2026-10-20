---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#puntino
proposal: null
task: 7s4q4z2h
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:42:19.691Z
---
# Schermo perso e posizione salvata

## What happens

Se lo schermo dove era il puntino non c'è più ma la posizione salvata cade ancora dentro un altro schermo, il puntino resta lì. Va in basso a destra dello schermo principale solo quando la posizione non cade in nessuno schermo.

## What should happen

Se lo schermo dove era il puntino non c'è più, compare in basso a destra dello schermo principale.

## Fix options

### Riconoscere lo schermo salvato

Al riavvio Axi cerca lo schermo salvato per il suo identificativo. Se non c'è più, il puntino va in basso a destra dello schermo principale, anche se la posizione salvata cade in un altro schermo. Costo: il puntino non resta dove era sull'altro schermo, anche quando lo spazio ci sarebbe; chi ha un altro schermo al posto di quello di prima vede il puntino spostarsi.

### Riconoscere lo schermo dalla geometria

Axi salva anche l'area dello schermo e, al riavvio, cerca uno schermo con la stessa area. Se non c'è, il puntino va in basso a destra dello schermo principale. Costo: il salvataggio porta più dati, e uno schermo con risoluzione o disposizione cambiate viene considerato perso.

## Where in the code

Axi/Puntino/PuntinoController.swift (originePuntinoIniziale, righe 287-300, in particolare il controllo alla riga 292)
