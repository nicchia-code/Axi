---
status: resolved
resolution: dismissed
refs:
  - attivita/Nessuna
  - requirements/ui#attivita
proposal: null
task: zi2uuwrc
origin: null
critical: false
option: 1
note: null
resolvedBy: 7ln2nfjv
created: 2026-10-19T03:06:53.771Z
---
# Dot breathes at rest

## What happens

A riposo il puntino non sta fermo: si ingrandisce e si rimpicciolisce in continuazione, come se respirasse.

## What should happen

A riposo il puntino è fermo, come dice il Modello e il Requisito: la sua dimensione non cambia finché non c'è un lavoro o un esito.

## Fix options

### Puntino fermo a riposo

Si toglie il respiro: a riposo il puntino resta alla dimensione normale, come dice il Modello e il Requisito. Il movimento resta solo durante il lavoro e negli esiti. Costo: il puntino appare meno vivo, e il cambiamento si vede subito anche nella barra dei menu.

### Respiro fino al nuovo puntino

Il respiro resta finché il puntino non passa alla barra dei menu, dove il suo disegno viene rifatto; allora si toglie insieme al resto. Costo: fino ad allora il codice non segue il Requisito, e la differenza resta aperta per qualche tempo.

## Where in the code

Axi/Puntino/PuntinoVista.swift: scala (ramo a riposo, righe 80-81) e avviaMovimento (animazione repeatForever del respiro, righe 157-158)
