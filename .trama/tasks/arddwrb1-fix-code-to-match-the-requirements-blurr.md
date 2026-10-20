---
column: done
technical: true
refs:
  - requirements/ui#puntino
  - requirements/tech#puntino
drift: 0c41xjrn
proposal: null
agent: false
created: 2026-10-19T19:03:11.046Z
finished: 2026-10-19T19:13:07.873Z
unchanged: "Checked Axi/Puntino/PuntinoDisegno.swift (lines 53-101 geometry, 164-265 drawing) and PuntinoVista.swift: every shape is an ellipse via Path(ellipseIn:) with an affine transform; the breath only scales the body's radii (sx, sy) and the drops' centres and radii; no blur, shadow or filter on the character (grep for .blur, .shadow, Filter, addCurve, addQuadCurve across Axi/ found none); no free contour is deformed. Behaviour matches What should happen, so the Drift 0c41xjrn is dismissed without changes."
---
# Fix code to match the Requirements: Blurred and wobbling outlines

## What happens

Le forme del personaggio hanno contorni che ondeggiano e bordi sfumati: l'attesa deforma il contorno del corpo e delle gocce, e corpo e riflesso sono sfocati. Non sono cerchi ed ellissi con bordi netti.

## What should happen

Ogni forma è un cerchio o un'ellisse perfetta con bordi netti in ogni fotogramma; l'attesa cambia centro e raggi, senza mai deformare un contorno libero.

## Chosen option

**Draw pure ellipses, sharp edges**

Togli l'ondeggiamento del contorno e il filtro di sfocatura; corpo, gocce e riflesso diventano ellissi con centro e raggi che cambiano nel tempo. Il respiro passa solo da scala e spostamento, come chiede il requisito. Costo: nessuno di rilievo, ma il disegno va riscritto nei punti interessati.

## Where in the code

Axi/Puntino/PuntinoDisegno.swift:59-66, 200, 210, 224-252
