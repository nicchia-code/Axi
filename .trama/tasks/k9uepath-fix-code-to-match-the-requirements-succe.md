---
column: done
technical: true
refs:
  - requirements/ui#attivita
drift: m41zd9mw
proposal: null
agent: false
created: 2026-10-19T03:02:16.410Z
finished: 2026-10-19T08:33:11.649Z
---
# Fix code to match the Requirements: Success bounce not repeated

## What happens

Quando un documento viene archiviato subito dopo un altro, il puntino fa il rimbalzo con il segno di spunta solo per il primo successo: per i successi che seguono, il segno resta fermo, perché l'animazione parte solo quando cambia il tipo di esito e non a ogni archiviazione riuscita.

## What should happen

Ogni archiviazione riuscita fa rimbalzare il puntino con il segno di spunta, come ogni errore lo fa scuotere, anche se l'esito precedente era già un successo.

## Chosen option

**Rimbalzo a ogni successo**

Il rimbalzo del segno di spunta viene legato al contatore degli esiti, come già accade per la scossa dell'errore e per il lampo del documento già presente. Ogni successo fa così rimbalzare il puntino, anche di seguito a un altro successo, senza toccare colore, forma o testi. Costo: una modifica piccola nel modo in cui si attiva l'animazione del segno; nessun effetto sugli altri esiti, che già usano il contatore.

## Where in the code

Axi/Puntino/PuntinoVista.swift:111 (funzione simbolo: il rimbalzo del successo è legato al valore dell'esito, che non cambia tra due successi di fila)
