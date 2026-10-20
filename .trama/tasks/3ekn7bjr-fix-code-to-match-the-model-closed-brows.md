---
column: done
technical: false
refs:
  - benvenuto/Permessi
drift: kf706hmc
proposal: null
agent: false
created: 2026-10-19T03:02:16.449Z
finished: 2026-10-19T03:08:42.049Z
---
# Fix code to match the Model: Closed browser shown as not granted

## What happens

La finestra di benvenuto mostra l'Automazione di un browser installato ma chiuso con il segno di permesso non concesso, come per un permesso mancante. Non dice che il browser va aperto per verificarla.

## What should happen

Per un browser installato ma chiuso il benvenuto dice che va aperto per verificare l'Automazione, senza segnarla come non concessa. Con il browser aperto mostra lo stato reale, concesso o non concesso.

## Chosen option

**Tre stati per ogni browser**

La lettura dei permessi distingue concesso, negato e browser chiuso. Per il browser chiuso il benvenuto mostra «Apri Safari per verificare.» (o Chrome) senza il segno di permesso mancante. Con il browser aperto mostra lo stato reale. La stessa lettura serve anche alla finestra dei permessi, così le due finestre restano coerenti. Costo: la lettura cambia forma e va adattata nei punti che la usano.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift:170-177; Packages/AxiScreen/Sources/AxiScreen/Permissions.swift:44-52
