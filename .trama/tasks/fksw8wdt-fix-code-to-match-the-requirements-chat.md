---
column: done
technical: true
refs:
  - requirements/ui#puntino/Menu aperto
drift: 310t1oqy
proposal: null
agent: false
created: 2026-10-19T08:10:02.984Z
finished: 2026-10-19T11:30:09.774Z
unchanged: Chat default ⌥Space already set by T39 (kcz7yekn) in Axi/Impostazioni/Scorciatoie.swift
---
# Fix code to match the Requirements: Chat shortcut default differs

## What happens

La voce Chat del menu e la scorciatoia della chat usano F4 come predefinito, mentre il requisito attuale indica ⌥Spazio come valore predefinito della chat.

## What should happen

La scorciatoia predefinita della chat è ⌥Spazio, e il menu la mostra così; F4 resta disponibile se l'utente lo registra nelle Impostazioni.

## Chosen option

**⌥Spazio come predefinito**

La chat torna a ⌥Spazio come scorciatoia predefinita, come dice il requisito, e il menu mostra ⌥Spazio. F4 resta disponibile registrandolo nelle Impostazioni. Costo: chi usa F4 deve sceglierlo a mano, e il ritorno a ⌥Spazio ribalta la scelta del precedente Drift risolto.

## Where in the code

Axi/Impostazioni/Scorciatoie.swift (static let chat, riga 11)
