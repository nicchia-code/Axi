---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#puntino/Menu aperto
proposal: null
task: ulj1dyqp
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:42:08.516Z
---
# Scorciatoia Chat diversa

## What happens

La voce Chat del menu e la scorciatoia della chat usano ⌥Spazio come predefinito. Axi non propone mai F4, neppure dove F4 è disponibile.

## What should happen

Il requisito vuole F4 come scorciatoia della chat, e ⌥Spazio solo quando F4 non è disponibile.

## Fix options

### F4 come predefinito

F4 diventa la scorciatoia predefinita della chat, e ⌥Spazio resta l'alternativa per chi registra un altro tasto. Il menu mostra F4 subito. Costo: dove F4 apre altro, per esempio Spotlight, la chat non si apre finché l'utente non cambia tasto nelle Impostazioni, e Axi non può verificarlo da solo.

### Provare F4 all'avvio

Axi prova a registrare F4 all'avvio e, se la registrazione non riesce, usa ⌥Spazio. Il menu mostra la scorciatoia effettiva. Costo: una registrazione riuscita non garantisce che F4 arrivi davvero ad Axi, quindi il comportamento va verificato sul dispositivo, e l'utente può vedere ⌥Spazio senza capire perché.

## Where in the code

Axi/Impostazioni/Scorciatoie.swift (static let chat, riga 13)
