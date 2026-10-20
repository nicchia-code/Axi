---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#puntino
proposal: null
task: ajpzjbup
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:42:13.713Z
---
# Aspetto del puntino

## What happens

Il cerchio del puntino è largo circa 42 pt e a riposo è indaco, non nel colore d'accento di macOS. Il puntino risulta quindi più grande e di un altro colore rispetto a quanto richiesto.

## What should happen

Il cerchio è di circa 18 pt, nel colore d'accento di macOS, con un leggero alone.

## Fix options

### Cerchio di 18 pt nella stessa finestra

Il cerchio disegnato scende a circa 18 pt e prende il colore d'accento di macOS, con un alone leggero. La finestra resta com'è, quindi l'area da cliccare e da usare per i file non cambia. Gli esiti, il contatore e i simboli vanno ridisegnati più piccoli per restare leggibili. Costo: simboli e contatore diventano piccoli e vanno controllati uno per uno.

### Finestra di 18 pt

Anche la finestra del puntino diventa di circa 18 pt, e la superficie cliccabile coincide col cerchio. Costo: il puntino è più difficile da cliccare e da centrare per i file rilasciati; la posizione del menu, della chat e delle nuvolette va ricalcolata rispetto alla nuova dimensione.

## Where in the code

Axi/Puntino/PuntinoVista.swift (frame 56×56 riga 31, cerchio con padding 7 riga 24, colore indaco riga 56)
