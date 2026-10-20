---
status: resolved
resolution: dismissed
refs:
  - requirements/ui#puntino/Menu aperto
proposal: null
task: fksw8wdt
origin: null
previous: e8mh43jq
critical: false
option: 1
note: null
resolvedBy: 7ln2nfjv
created: 2026-10-19T06:19:56.010Z
---
# Chat shortcut default differs

## What happens

La voce Chat del menu e la scorciatoia della chat usano F4 come predefinito, mentre il requisito attuale indica ⌥Spazio come valore predefinito della chat.

## What should happen

La scorciatoia predefinita della chat è ⌥Spazio, e il menu la mostra così; F4 resta disponibile se l'utente lo registra nelle Impostazioni.

## Fix options

### ⌥Spazio come predefinito

La chat torna a ⌥Spazio come scorciatoia predefinita, come dice il requisito, e il menu mostra ⌥Spazio. F4 resta disponibile registrandolo nelle Impostazioni. Costo: chi usa F4 deve sceglierlo a mano, e il ritorno a ⌥Spazio ribalta la scelta del precedente Drift risolto.

### F4 come predefinito, requisito aggiornato

Il codice resta com'è: F4 è predefinito e il menu lo mostra. Il requisito di interfaccia e di tecnica va riscritto con F4 al posto di ⌥Spazio, decisione dello sviluppatore. Costo: il requisito cambia e la storia della scelta va riportata nel requisito stesso.

### Provare F4 all'avvio

Axi prova a registrare F4 all'avvio e, se la registrazione non riesce, usa ⌥Spazio. Il menu mostra la scorciatoia effettiva. Costo: una registrazione riuscita non garantisce che F4 arrivi davvero ad Axi, e l'utente può vedere ⌥Spazio senza capire perché.

## Where in the code

Axi/Impostazioni/Scorciatoie.swift (static let chat, riga 11)
