---
status: resolved
resolution: fix-code
refs:
  - puntino/Nascosto
  - requirements/ui#puntino/Nascosto
proposal: null
task: bh9zahka
origin: null
critical: false
option: 1
note: null
resolvedBy: 8o81tjof
created: 2026-10-19T19:06:44.033Z
notBlocking:
  - task: ssfn1zrv
    reason: Tocca la forma ellittica del personaggio, non la condizione che avvia l'attesa dell'icona.
  - task: obdb5l5p
    reason: Tocca solo i colori fissi del personaggio, non quando l'attesa viene mostrata.
  - task: arddwrb1
    reason: Tocca il contorno ondeggiante dell'attesa, non il fatto che l'attesa parta sull'icona.
  - task: jg91pbfp
    reason: Tocca l'ombra e il riflesso dei tre puntini, non l'attesa dell'icona nella barra.
  - task: jdbx1fx9
    reason: Tocca il velo del trascinamento file, non il menu aperto dall'icona.
---
# Icon wait stops while menu open

## What happens

Quando il menu della barra è aperto dall'icona nella barra dei menu, l'icona resta ferma: l'attesa non si vede, anche se il puntino è nascosto e l'utente sta usando il menu.

## What should happen

Mentre il menu della barra è aperto, l'icona mostra le stesse animazioni del personaggio sullo schermo, incluse quelle dell'attesa.

## Fix options

### Add the menu bar state to the wait

Nella condizione che fa partire l'attesa si aggiunge lo stato in cui il menu della barra è aperto, accanto a quello del menu radiale. Il resto non cambia: a menu chiuso l'icona torna com'era a riposo. Il costo è una riga in più, senza effetti su posizione, scorciatoie o altre animazioni del personaggio.

### Separate wait condition for the icon

Si crea una condizione dedicata all'icona nella barra, che si attiva quando il suo menu è aperto, lasciando invariata quella del personaggio sullo schermo. Il risultato è identico, ma le due condizioni possono divergere in futuro. Costa un poco più di codice da mantenere.

## Where in the code

Axi/Puntino/PuntinoVista.swift, condizione `animato` (intorno alle righe 64-68).
