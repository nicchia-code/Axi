---
column: done
technical: false
refs:
  - attivita/In corso
  - requirements/ui#attivita
drift: 19q583th
proposal: null
agent: false
created: 2026-10-18T20:05:07.477Z
finished: 2026-10-18T21:28:34.921Z
---
# Fix code to match the Model: Nuvoletta sotto il puntatore

## What happens

Durante un'archiviazione la nuvoletta di un esito intermedio non prende il puntatore: passarci sopra non la tiene aperta, e sparisce dopo cinque secondi anche con il puntatore su di lei. Non si può nemmeno cliccare.

## What should happen

La nuvoletta resta cinque secondi, o finché il puntatore ci resta sopra, ed è cliccabile. Il clic però apre la copia solo dallo stato Esito, come dice il modello, quindi durante il lavoro il passaggio del puntatore conta e il clic no.

## Chosen option

**Puntatore sopra anche durante il lavoro**

La nuvoletta prende il puntatore anche in In corso: finché il puntatore ci resta sopra la sua scadenza si ferma. Il clic durante il lavoro non fa nulla, come dice il modello. Costo: per i cinque secondi la nuvoletta intercetta i clic sulla sua area.

## Where in the code

Axi/Puntino/PuntinoController.swift, aggiornaNuvoletta: la finestra della nuvoletta prende il mouse solo nello stato Esito
