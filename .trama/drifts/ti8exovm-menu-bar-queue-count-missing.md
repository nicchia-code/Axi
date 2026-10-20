---
status: resolved
resolution: fix-code
refs:
  - attivita/In corso
  - requirements/ui#attivita
proposal: null
task: wlnszezt
origin: null
critical: false
option: 2
note: null
resolvedBy: yzey912v
created: 2026-10-19T16:52:58.051Z
---
# Menu bar queue count missing

## What happens

Nella barra dei menu il puntino non mostra il numero dei documenti in coda, e la sua voce resta della stessa larghezza fissa anche mentre documenti aspettano.

## What should happen

Quando ci sono documenti in coda, nella barra dei menu compare il numero alla destra del personaggio e la voce si allarga per contenerlo, come accade sullo schermo.

## Fix options

### Voce di larghezza variabile

La voce della barra passa da larghezza quadrata fissa a larghezza variabile e mostra il numero accanto al personaggio, con la stessa vista usata sullo schermo. Ogni volta che cambia il numero in coda la voce riceve la nuova larghezza. Costo: la barra si sposta un poco a ogni variazione della coda, e le voci vicine possono scorrere.

### Spazio riservato al numero

Mentre ci sono documenti in coda la voce si allarga di uno spazio riservato al numero, dimensionato sulle cifre del conteggio, e torna quadrata quando la coda è vuota. Il numero compare in quello spazio, accanto al personaggio. Costo: la voce cambia larghezza solo quando cambia il numero di cifre, ma la misura va tenuta allineata al carattere usato.

## Where in the code

Axi/Puntino/PuntinoPannelli.swift (ElementoBarra: voce di lunghezza fissa e vista della barra creata con il contatore spento); Axi/Puntino/PuntinoVista.swift (il contatore compare solo se mostraContatore è vero)
