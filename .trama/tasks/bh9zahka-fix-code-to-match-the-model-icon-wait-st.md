---
column: done
technical: false
refs:
  - puntino/Nascosto
  - requirements/ui#puntino/Nascosto
drift: 8myldzeb
proposal: null
agent: false
created: 2026-10-19T20:32:46.268Z
finished: 2026-10-19T20:36:39.905Z
---
# Fix code to match the Model: Icon wait stops while menu open

## What happens

Quando il menu della barra è aperto dall'icona nella barra dei menu, l'icona resta ferma: l'attesa non si vede, anche se il puntino è nascosto e l'utente sta usando il menu.

## What should happen

Mentre il menu della barra è aperto, l'icona mostra le stesse animazioni del personaggio sullo schermo, incluse quelle dell'attesa.

## Chosen option

**Add the menu bar state to the wait**

Nella condizione che fa partire l'attesa si aggiunge lo stato in cui il menu della barra è aperto, accanto a quello del menu radiale. Il resto non cambia: a menu chiuso l'icona torna com'era a riposo. Il costo è una riga in più, senza effetti su posizione, scorciatoie o altre animazioni del personaggio.

## Where in the code

Axi/Puntino/PuntinoVista.swift, condizione `animato` (intorno alle righe 64-68).
