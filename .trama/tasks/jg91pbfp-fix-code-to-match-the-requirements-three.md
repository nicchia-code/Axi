---
column: done
technical: true
refs:
  - requirements/ui#puntino
drift: r2sse535
proposal: null
agent: false
created: 2026-10-19T19:03:11.051Z
finished: 2026-10-19T19:13:39.679Z
unchanged: Checked Axi/Puntino/PuntinoDisegno.swift (PuntinoGeometria.forme, PuntinoDisegno.disegnaGoccia). At three dots (m=1) dettagli = 0, so shadow and highlight are not drawn; luce equals the full drop ellipse, filled with the accent colour (tinte.corpo); the eyes have opacity 0; drops are full circles, lifted in a wave, inside the 100x100 frame. Matches the Requirement in ui#puntino. No change needed.
---
# Fix code to match the Requirements: Three dots carry shadow and highlight

## What happens

I tre puntini di sospensione sono disegnati come il personaggio, con ombra scura, corpo sfumato, riflesso e occhi. Il requisito chiede cerchi pieni nel colore accento, senza ombra né riflesso.

## What should happen

I tre puntini sono cerchi pieni del colore accento, senza ombra né riflesso, come l'indicatore di scrittura delle chat; il corpo torna con ombra, riflesso e occhi a fine attesa.

## Chosen option

**Draw dots as plain circles**

Nell'aspetto tre puntini disegna ogni goccia come un cerchio pieno del solo colore accento, senza ombra né riflesso; il corpo torna con le sue ombre al termine. Costo: un ramo di disegno separato per i tre puntini.

## Where in the code

Axi/Puntino/PuntinoDisegno.swift:174-176, 183-213
