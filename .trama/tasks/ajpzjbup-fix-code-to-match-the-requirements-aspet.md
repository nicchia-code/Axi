---
column: done
technical: true
refs:
  - requirements/ui#puntino
drift: 7igqyo7f
proposal: null
agent: false
created: 2026-10-18T18:45:27.780Z
finished: 2026-10-18T20:18:17.060Z
---
# Fix code to match the Requirements: Aspetto del puntino

## What happens

Il cerchio del puntino è largo circa 42 pt e a riposo è indaco, non nel colore d'accento di macOS. Il puntino risulta quindi più grande e di un altro colore rispetto a quanto richiesto.

## What should happen

Il cerchio è di circa 18 pt, nel colore d'accento di macOS, con un leggero alone.

## Chosen option

**Cerchio di 18 pt nella stessa finestra**

Il cerchio disegnato scende a circa 18 pt e prende il colore d'accento di macOS, con un alone leggero. La finestra resta com'è, quindi l'area da cliccare e da usare per i file non cambia. Gli esiti, il contatore e i simboli vanno ridisegnati più piccoli per restare leggibili. Costo: simboli e contatore diventano piccoli e vanno controllati uno per uno.

## Where in the code

Axi/Puntino/PuntinoVista.swift (frame 56×56 riga 31, cerchio con padding 7 riga 24, colore indaco riga 56)
