---
status: resolved
resolution: fix-code
refs:
  - puntino/Menu aperto
  - requirements/ui#General
proposal: null
task: g61ngybc
origin: null
critical: false
option: 1
note: null
resolvedBy: stsg18fb
created: 2026-10-18T19:11:17.166Z
---
# Menu senza Liquid Glass

## What happens

Attorno al puntino, i cinque pulsanti del menu hanno uno sfondo di materiale standard di macOS, traslucido ma non **Liquid Glass**. Le nuvolette e le finestre di Axi usano invece il Liquid Glass di macOS 26, quindi il menu appare di un altro stile.

## What should happen

Lo stile di macOS 26 richiede materiali **Liquid Glass** per menu, nuvolette e finestre. Il menu del puntino è uno dei tre casi e deve usarlo.

## Fix options

### Liquid Glass su ogni azione

Ogni pulsante del menu prende il materiale **Liquid Glass** al posto di quello standard, con la stessa forma circolare, icona ed etichetta di oggi. Il menu si allinea così alle nuvolette e alle finestre. Costo: va verificata la leggibilità dell'etichetta sia su sfondi chiari sia su sfondi scuri, e il menu cambia aspetto in modo visibile.

### Vetro unico per il menu

I cinque pulsanti stanno dentro un unico contenitore **Liquid Glass**, così il vetro si fonde tra le azioni vicine come un solo materiale, mentre icona ed etichetta restano invariate. Costo: il contenitore deve seguire l'animazione di apertura e chiusura del menu, e il risultato visivo di ciascuna azione va controllato a parte.

## Where in the code

Axi/Puntino/MenuRadialeVista.swift: lo sfondo di VoceMenuVista, il cerchio dietro l'icona di ogni azione del menu.
