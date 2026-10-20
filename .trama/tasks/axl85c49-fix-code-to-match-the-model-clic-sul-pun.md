---
column: done
technical: false
refs:
  - puntino/Menu aperto
drift: 3xotoe1v
proposal: null
agent: false
created: 2026-10-18T18:45:27.773Z
finished: 2026-10-18T19:08:46.838Z
---
# Fix code to match the Model: Clic sul puntino col menu

## What happens

Con il menu aperto, un clic sul puntino chiude il menu e riporta il puntino a riposo, come fa un clic fuori dal menu.

## What should happen

Il menu si chiude con un clic fuori, scegliendo una voce o nascondendo il puntino. Il Model non prevede che un clic sul puntino chiuda il menu.

## Chosen option

**Il clic sul puntino non ha effetto**

Con il menu aperto, un clic sul puntino non cambia nulla: il menu resta aperto finché non si clicca fuori, non si sceglie una voce o non si nasconde il puntino. È il comportamento del Model, senza aggiunte. Costo: chi vuole chiudere il menu deve cliccare altrove, come già succede per le altre aree dello schermo.

## Where in the code

Axi/Puntino/PuntinoController.swift (clicPuntino, riga 144-147); Packages/AxiCore/Sources/AxiCore/Puntino/StatoPuntino.swift (dopo, righe 28-30)
