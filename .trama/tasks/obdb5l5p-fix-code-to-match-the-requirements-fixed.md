---
column: done
technical: true
refs:
  - requirements/tech#puntino
  - requirements/ui#puntino
drift: v2iujk6w
proposal: null
agent: false
created: 2026-10-19T19:03:11.041Z
finished: 2026-10-19T20:41:32.263Z
unchanged: "Reopened on the developer's decision; the fallback change is in Task 3mlilncm (Drift qreemmvg). The body and tones already derive from the accent: nothing to change here."
---
# Fix code to match the Requirements: Fixed blue palette, not accent

## What happens

Il personaggio è disegnato con tinte di blu fisse, in ogni aspetto e nella barra dei menu. Corpo, ombra, riflesso e occhi non seguono l'accento scelto in Impostazioni di Sistema, né l'aspetto chiaro o scuro.

## What should happen

Il corpo è nel colore accento dell'utente, e ombra, riflesso e occhi sono tinte dello stesso accento; con accento grafite il puntino è grigio, e un cambio di accento o di aspetto vale subito.

## Chosen option

**Derive tones from the accent**

Il corpo prende il colore accento risolto nell'aspetto della vista; ombra, riflesso e occhi si ottengono mescolando l'accento con nero o bianco, come chiede il requisito tecnico. Costo: le tinte si ricalcolano a ogni cambio di aspetto e i colori fissi nel disegno vanno sostituiti.

## Where in the code

Axi/Puntino/PuntinoDisegno.swift:155-158
