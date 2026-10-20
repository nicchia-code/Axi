---
status: resolved
resolution: fix-code
refs:
  - puntino/Menu aperto
proposal: null
task: axl85c49
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:42:02.570Z
---
# Clic sul puntino col menu

## What happens

Con il menu aperto, un clic sul puntino chiude il menu e riporta il puntino a riposo, come fa un clic fuori dal menu.

## What should happen

Il menu si chiude con un clic fuori, scegliendo una voce o nascondendo il puntino. Il Model non prevede che un clic sul puntino chiuda il menu.

## Fix options

### Il clic sul puntino non ha effetto

Con il menu aperto, un clic sul puntino non cambia nulla: il menu resta aperto finché non si clicca fuori, non si sceglie una voce o non si nasconde il puntino. È il comportamento del Model, senza aggiunte. Costo: chi vuole chiudere il menu deve cliccare altrove, come già succede per le altre aree dello schermo.

### Il menu copre il puntino

Il menu prende i clic di tutta la sua area, centro compreso, dove oggi sta il puntino. Con il menu aperto il puntino non riceve più il clic, e il menu si chiude come oggi con un clic fuori o con una voce. Costo: il centro del menu va gestito in modo da non far partire azioni del puntino, e va verificato su più schermi e con più posizioni del puntino.

## Where in the code

Axi/Puntino/PuntinoController.swift (clicPuntino, riga 144-147); Packages/AxiCore/Sources/AxiCore/Puntino/StatoPuntino.swift (dopo, righe 28-30)
