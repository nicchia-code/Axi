---
status: resolved
resolution: dismissed
refs:
  - requirements/ui#puntino
  - requirements/tech#puntino
proposal: null
task: arddwrb1
origin: null
critical: false
option: 1
note: null
resolvedBy: fxquz3ah
created: 2026-10-19T18:57:39.119Z
---
# Blurred and wobbling outlines

## What happens

Le forme del personaggio hanno contorni che ondeggiano e bordi sfumati: l'attesa deforma il contorno del corpo e delle gocce, e corpo e riflesso sono sfocati. Non sono cerchi ed ellissi con bordi netti.

## What should happen

Ogni forma è un cerchio o un'ellisse perfetta con bordi netti in ogni fotogramma; l'attesa cambia centro e raggi, senza mai deformare un contorno libero.

## Fix options

### Draw pure ellipses, sharp edges

Togli l'ondeggiamento del contorno e il filtro di sfocatura; corpo, gocce e riflesso diventano ellissi con centro e raggi che cambiano nel tempo. Il respiro passa solo da scala e spostamento, come chiede il requisito. Costo: nessuno di rilievo, ma il disegno va riscritto nei punti interessati.

### Use native ellipse shapes

Sostituisci il percorso libero con forme di ellisse e cerchio native, disegnate come forme separate. Costo: più forme nel disegno, ma i contorni restano sempre ellittici e netti anche durante le animazioni.

## Where in the code

Axi/Puntino/PuntinoDisegno.swift:59-66, 200, 210, 224-252
