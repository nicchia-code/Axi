---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#puntino
proposal: null
task: jdbx1fx9
origin: null
critical: false
option: 1
note: null
resolvedBy: fxquz3ah
created: 2026-10-19T18:57:39.145Z
---
# Drag veil in fixed blue

## What happens

Quando i file sono trascinati sopra il puntino, il velo è blu fisso, qualunque sia l'accento dell'utente. Il requisito chiede un velo del colore accento per mostrare che il personaggio può riceverli.

## What should happen

Il velo del trascinamento è del colore accento dell'utente, come le altre tinte del personaggio, e segue cambi di accento e di aspetto.

## Fix options

### Use the accent for the veil

Il velo prende il colore accento risolto nell'aspetto della vista, con la stessa opacità di oggi. Costo: nessuno di rilievo, perché il colore viene già passato al disegno. Il rosso dell'errore resta com'è.

### Reuse the body tone for the veil

Il velo riusa la tinta del corpo calcolata dall'accento, così corpo e velo cambiano insieme. Il rosso dell'errore resta com'è. Costo: il velo dipende dalla soluzione scelta per la tavolozza del corpo.

## Where in the code

Axi/Puntino/PuntinoVista.swift:128-135
