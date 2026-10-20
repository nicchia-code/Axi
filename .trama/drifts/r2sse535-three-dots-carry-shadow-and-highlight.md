---
status: resolved
resolution: dismissed
refs:
  - requirements/ui#puntino
proposal: null
task: jg91pbfp
origin: null
critical: false
option: 1
note: null
resolvedBy: fxquz3ah
created: 2026-10-19T18:57:39.132Z
---
# Three dots carry shadow and highlight

## What happens

I tre puntini di sospensione sono disegnati come il personaggio, con ombra scura, corpo sfumato, riflesso e occhi. Il requisito chiede cerchi pieni nel colore accento, senza ombra né riflesso.

## What should happen

I tre puntini sono cerchi pieni del colore accento, senza ombra né riflesso, come l'indicatore di scrittura delle chat; il corpo torna con ombra, riflesso e occhi a fine attesa.

## Fix options

### Draw dots as plain circles

Nell'aspetto tre puntini disegna ogni goccia come un cerchio pieno del solo colore accento, senza ombra né riflesso; il corpo torna con le sue ombre al termine. Costo: un ramo di disegno separato per i tre puntini.

### Reuse the flat-colour path

Il disegno ha già un percorso a tinta unita per i segnali; usalo anche per i tre puntini passandogli il colore accento. Costo: la trasformazione tra corpo e puntini deve passare da quel percorso, e il corpo torna con le sue ombre.

## Where in the code

Axi/Puntino/PuntinoDisegno.swift:174-176, 183-213
