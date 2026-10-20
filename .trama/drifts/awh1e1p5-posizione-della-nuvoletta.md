---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#attivita
proposal: null
task: l3azqkuy
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:42:21.575Z
---
# Posizione della nuvoletta

## What happens

La nuvoletta si mette sopra il puntino, centrata su di lui, e scende sotto solo se sopra non c'è più spazio. Non guarda da quale lato del puntino c'è più spazio libero.

## What should happen

Il Requisito dice che la nuvoletta compare accanto al puntino, dal lato con più spazio.

## Fix options

### Scegliere il lato con più spazio

Si misura lo spazio libero a destra, a sinistra, sopra e sotto il puntino, e la nuvoletta va dal lato più libero, sempre accanto al puntino. Costo: un piccolo calcolo in più a ogni comparsa, e la nuvoletta può spostarsi da un lato all'altro quando il puntino viene trascinato verso un bordo.

### Tenere la posizione attuale

La nuvoletta resta sopra il puntino, o sotto se manca lo spazio, come ora. Costo: il comportamento non segue la regola del Requisito. Se questa posizione è quella voluta, la regola va cambiata con un Proposal, non in questo Drift.

## Where in the code

Axi/Puntino/PuntinoController.swift:272-284 (posizionaNuvoletta: y = ancora.maxY + 8, con ripiego sotto)
