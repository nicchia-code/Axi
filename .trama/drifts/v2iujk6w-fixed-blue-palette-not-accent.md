---
status: resolved
resolution: dismissed
refs:
  - requirements/tech#puntino
  - requirements/ui#puntino
proposal: null
task: obdb5l5p
origin: null
critical: false
option: 1
note: null
resolvedBy: fxquz3ah
created: 2026-10-19T18:57:39.106Z
---
# Fixed blue palette, not accent

## What happens

Il personaggio è disegnato con tinte di blu fisse, in ogni aspetto e nella barra dei menu. Corpo, ombra, riflesso e occhi non seguono l'accento scelto in Impostazioni di Sistema, né l'aspetto chiaro o scuro.

## What should happen

Il corpo è nel colore accento dell'utente, e ombra, riflesso e occhi sono tinte dello stesso accento; con accento grafite il puntino è grigio, e un cambio di accento o di aspetto vale subito.

## Fix options

### Derive tones from the accent

Il corpo prende il colore accento risolto nell'aspetto della vista; ombra, riflesso e occhi si ottengono mescolando l'accento con nero o bianco, come chiede il requisito tecnico. Costo: le tinte si ricalcolano a ogni cambio di aspetto e i colori fissi nel disegno vanno sostituiti.

### Pass the palette from the view

Una vista legge l'accento e l'aspetto e passa al disegno la tavolozza a ogni cambio. Costo: un valore in più da propagare alle superfici che disegnano il personaggio, ma il disegno resta unico.

## Where in the code

Axi/Puntino/PuntinoDisegno.swift:155-158
