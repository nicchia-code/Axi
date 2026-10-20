---
column: done
technical: true
refs:
  - requirements/ui#attivita
drift: awh1e1p5
proposal: null
agent: false
created: 2026-10-18T18:45:27.789Z
finished: 2026-10-18T21:26:17.876Z
---
# Fix code to match the Requirements: Posizione della nuvoletta

## What happens

La nuvoletta si mette sopra il puntino, centrata su di lui, e scende sotto solo se sopra non c'è più spazio. Non guarda da quale lato del puntino c'è più spazio libero.

## What should happen

Il Requisito dice che la nuvoletta compare accanto al puntino, dal lato con più spazio.

## Chosen option

**Scegliere il lato con più spazio**

Si misura lo spazio libero a destra, a sinistra, sopra e sotto il puntino, e la nuvoletta va dal lato più libero, sempre accanto al puntino. Costo: un piccolo calcolo in più a ogni comparsa, e la nuvoletta può spostarsi da un lato all'altro quando il puntino viene trascinato verso un bordo.

## Where in the code

Axi/Puntino/PuntinoController.swift:272-284 (posizionaNuvoletta: y = ancora.maxY + 8, con ripiego sotto)
