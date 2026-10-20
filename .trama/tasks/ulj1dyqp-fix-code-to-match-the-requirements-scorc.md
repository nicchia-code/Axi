---
column: done
technical: true
refs:
  - requirements/ui#puntino/Menu aperto
drift: e8mh43jq
proposal: null
agent: false
created: 2026-10-18T18:45:27.776Z
finished: 2026-10-18T20:12:19.577Z
---
# Fix code to match the Requirements: Scorciatoia Chat diversa

## What happens

La voce Chat del menu e la scorciatoia della chat usano ⌥Spazio come predefinito. Axi non propone mai F4, neppure dove F4 è disponibile.

## What should happen

Il requisito vuole F4 come scorciatoia della chat, e ⌥Spazio solo quando F4 non è disponibile.

## Chosen option

**F4 come predefinito**

F4 diventa la scorciatoia predefinita della chat, e ⌥Spazio resta l'alternativa per chi registra un altro tasto. Il menu mostra F4 subito. Costo: dove F4 apre altro, per esempio Spotlight, la chat non si apre finché l'utente non cambia tasto nelle Impostazioni, e Axi non può verificarlo da solo.

## Where in the code

Axi/Impostazioni/Scorciatoie.swift (static let chat, riga 13)
