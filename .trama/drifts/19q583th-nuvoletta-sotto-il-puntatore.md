---
status: resolved
resolution: fix-code
refs:
  - attivita/In corso
  - requirements/ui#attivita
proposal: null
task: eziiwcit
origin: null
critical: false
option: 1
note: null
resolvedBy: 4p713jb5
created: 2026-10-18T19:46:14.740Z
---
# Nuvoletta sotto il puntatore

## What happens

Durante un'archiviazione la nuvoletta di un esito intermedio non prende il puntatore: passarci sopra non la tiene aperta, e sparisce dopo cinque secondi anche con il puntatore su di lei. Non si può nemmeno cliccare.

## What should happen

La nuvoletta resta cinque secondi, o finché il puntatore ci resta sopra, ed è cliccabile. Il clic però apre la copia solo dallo stato Esito, come dice il modello, quindi durante il lavoro il passaggio del puntatore conta e il clic no.

## Fix options

### Puntatore sopra anche durante il lavoro

La nuvoletta prende il puntatore anche in In corso: finché il puntatore ci resta sopra la sua scadenza si ferma. Il clic durante il lavoro non fa nulla, come dice il modello. Costo: per i cinque secondi la nuvoletta intercetta i clic sulla sua area.

### Seguire il puntatore senza prendere i clic

La nuvoletta resta trasparente ai clic, e l'app controlla dal movimento del mouse se il puntatore è sopra di lei, fermandone la scadenza. Costo: un controllo del movimento del mouse finché la nuvoletta è visibile.

## Where in the code

Axi/Puntino/PuntinoController.swift, aggiornaNuvoletta: la finestra della nuvoletta prende il mouse solo nello stato Esito
