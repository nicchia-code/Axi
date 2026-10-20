---
status: resolved
resolution: fix-code
refs:
  - benvenuto/Permessi
proposal: null
task: 3ekn7bjr
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:40:54.014Z
---
# Closed browser shown as not granted

## What happens

La finestra di benvenuto mostra l'Automazione di un browser installato ma chiuso con il segno di permesso non concesso, come per un permesso mancante. Non dice che il browser va aperto per verificarla.

## What should happen

Per un browser installato ma chiuso il benvenuto dice che va aperto per verificare l'Automazione, senza segnarla come non concessa. Con il browser aperto mostra lo stato reale, concesso o non concesso.

## Fix options

### Tre stati per ogni browser

La lettura dei permessi distingue concesso, negato e browser chiuso. Per il browser chiuso il benvenuto mostra «Apri Safari per verificare.» (o Chrome) senza il segno di permesso mancante. Con il browser aperto mostra lo stato reale. La stessa lettura serve anche alla finestra dei permessi, così le due finestre restano coerenti. Costo: la lettura cambia forma e va adattata nei punti che la usano.

### Controllo dell'apertura del browser

Il benvenuto controlla prima se il browser è in esecuzione. Se è chiuso mostra «Apri Safari per verificare.» (o Chrome) senza segno; se è aperto usa la lettura di adesso. La lettura dei permessi resta a due valori. Costo: la regola del browser chiuso sta fuori dalla lettura, quindi la finestra dei permessi va allineata a parte.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift:170-177; Packages/AxiScreen/Sources/AxiScreen/Permissions.swift:44-52
