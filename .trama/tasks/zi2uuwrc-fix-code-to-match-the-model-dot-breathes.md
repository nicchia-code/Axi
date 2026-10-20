---
column: done
technical: false
refs:
  - attivita/Nessuna
  - requirements/ui#attivita
drift: edyeghit
proposal: null
agent: false
created: 2026-10-19T08:10:02.972Z
finished: 2026-10-19T08:39:51.163Z
unchanged: "Checked Axi/Puntino/PuntinoVista.swift: at rest scale() is 1 (only riceveFile 1.25 and espanso 1.15 scale up), the rest image is the still PuntinoSprite.fermo (animato is false unless a wait, menu, expanded or file-drag state), and there is no repeatForever animation or avviaMovimento anywhere in Axi/. The Where references (lines 80-81, 157-158, avviaMovimento) no longer exist after T45. The described breathing does not occur."
---
# Fix code to match the Model: Dot breathes at rest

## What happens

A riposo il puntino non sta fermo: si ingrandisce e si rimpicciolisce in continuazione, come se respirasse.

## What should happen

A riposo il puntino è fermo, come dice il Modello e il Requisito: la sua dimensione non cambia finché non c'è un lavoro o un esito.

## Chosen option

**Puntino fermo a riposo**

Si toglie il respiro: a riposo il puntino resta alla dimensione normale, come dice il Modello e il Requisito. Il movimento resta solo durante il lavoro e negli esiti. Costo: il puntino appare meno vivo, e il cambiamento si vede subito anche nella barra dei menu.

## Where in the code

Axi/Puntino/PuntinoVista.swift: scala (ramo a riposo, righe 80-81) e avviaMovimento (animazione repeatForever del respiro, righe 157-158)
