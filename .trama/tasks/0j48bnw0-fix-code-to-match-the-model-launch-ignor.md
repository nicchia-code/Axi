---
column: done
technical: false
refs:
  - puntino
  - requirements/data#puntino
drift: jh9we7ze
proposal: null
agent: false
created: 2026-10-19T10:35:03.013Z
finished: 2026-10-19T13:32:31.623Z
---
# Fix code to match the Model: Launch ignores hidden dot

## What happens

When Axi starts, the dot always appears on screen at its saved place, even when it was hidden in the menu bar when Axi quit.

## What should happen

When Axi starts, the dot comes back the way it was left: on screen where it was, or hidden in the menu bar.

## Chosen option

**Read the hidden flag at launch**

Read the hidden flag that is already saved together with the dot's place. When it is set, Axi starts with the dot hidden and its menu bar icon in place; otherwise the dot appears where it was left, as now. Costs: the menu bar icon must also be created at launch, so the hidden start depends on that part being ready.

## Where in the code

Axi/Puntino/PuntinoController.swift, avvia: the dot always starts visible and at rest
