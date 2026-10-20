---
column: done
technical: false
refs:
  - puntino/Menu aperto
  - requirements/ui#General
drift: 5g8sogb6
proposal: null
agent: false
created: 2026-10-18T19:43:27.166Z
finished: 2026-10-18T20:24:06.091Z
---
# Fix code to match the Model: Menu senza Liquid Glass

## What happens

Attorno al puntino, i cinque pulsanti del menu hanno uno sfondo di materiale standard di macOS, traslucido ma non **Liquid Glass**. Le nuvolette e le finestre di Axi usano invece il Liquid Glass di macOS 26, quindi il menu appare di un altro stile.

## What should happen

Lo stile di macOS 26 richiede materiali **Liquid Glass** per menu, nuvolette e finestre. Il menu del puntino è uno dei tre casi e deve usarlo.

## Chosen option

**Liquid Glass su ogni azione**

Ogni pulsante del menu prende il materiale **Liquid Glass** al posto di quello standard, con la stessa forma circolare, icona ed etichetta di oggi. Il menu si allinea così alle nuvolette e alle finestre. Costo: va verificata la leggibilità dell'etichetta sia su sfondi chiari sia su sfondi scuri, e il menu cambia aspetto in modo visibile.

## Where in the code

Axi/Puntino/MenuRadialeVista.swift: lo sfondo di VoceMenuVista, il cerchio dietro l'icona di ogni azione del menu.
