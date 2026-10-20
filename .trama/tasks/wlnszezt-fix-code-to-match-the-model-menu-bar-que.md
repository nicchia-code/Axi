---
column: done
technical: false
refs:
  - attivita/In corso
  - requirements/ui#attivita
drift: ti8exovm
proposal: null
agent: false
created: 2026-10-19T17:18:05.498Z
finished: 2026-10-19T17:28:01.914Z
---
# Fix code to match the Model: Menu bar queue count missing

## What happens

Nella barra dei menu il puntino non mostra il numero dei documenti in coda, e la sua voce resta della stessa larghezza fissa anche mentre documenti aspettano.

## What should happen

Quando ci sono documenti in coda, nella barra dei menu compare il numero alla destra del personaggio e la voce si allarga per contenerlo, come accade sullo schermo.

## Chosen option

**Spazio riservato al numero**

Mentre ci sono documenti in coda la voce si allarga di uno spazio riservato al numero, dimensionato sulle cifre del conteggio, e torna quadrata quando la coda è vuota. Il numero compare in quello spazio, accanto al personaggio. Costo: la voce cambia larghezza solo quando cambia il numero di cifre, ma la misura va tenuta allineata al carattere usato.

## Where in the code

Axi/Puntino/PuntinoPannelli.swift (ElementoBarra: voce di lunghezza fissa e vista della barra creata con il contatore spento); Axi/Puntino/PuntinoVista.swift (il contatore compare solo se mostraContatore è vero)
