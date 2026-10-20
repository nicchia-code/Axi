---
status: resolved
resolution: dismissed
refs:
  - puntino/Menu aperto
  - requirements/ui#puntino/Menu aperto
proposal: null
task: mirjzsti
origin: null
critical: false
option: 1
note: null
resolvedBy: avbyf7dh
created: 2026-10-19T19:06:44.152Z
notBlocking:
  - task: ssfn1zrv
    reason: Tocca la forma ellittica del personaggio, non le voci del menu radiale.
  - task: arddwrb1
    reason: Tocca i contorni del personaggio, non il cerchio di vetro delle voci.
  - task: jg91pbfp
    reason: Tocca l'ombra dei tre puntini, non l'evidenziazione delle voci.
  - task: jdbx1fx9
    reason: Tocca il velo del trascinamento file, non il passaggio del puntatore sulle voci.
---
# Radial items lack hover highlight

## What happens

Passando il puntatore su una voce del menu radiale il suo cerchio e la sua icona non cambiano: l'utente non vede quale azione sta per scegliere.

## What should happen

Al passaggio del puntatore il cerchio di vetro della voce si tinge di un velo del colore dell'accento e la sua icona prende lo stesso colore.

## Fix options

### Highlight circle and icon on hover

Ogni voce del menu radiale rileva il passaggio del puntatore e applica il velo dell'accento al cerchio di vetro, portando l'icona allo stesso colore. Il costo è una modifica alla sola vista della voce, senza cambiare posizioni, testi o scorciatoie delle azioni.

### Highlight only the icon on hover

Al passaggio cambia solo il colore dell'icona, lasciando il cerchio di vetro com'è. È più sobrio e più semplice da fare, ma non ottiene il velo sul cerchio descritto nella richiesta, quindi resta una versione ridotta di quello che serve.

## Where in the code

Axi/Puntino/MenuRadialeVista.swift, vista della singola voce `VoceMenuVista` (intorno alle righe 40-65).
