---
status: resolved
resolution: fix-code
refs:
  - lettura-schermo/Inattiva
proposal: null
task: szegecmf
origin: null
critical: false
option: 1
note: null
resolvedBy: 4p713jb5
created: 2026-10-18T19:48:51.949Z
---
# Ricerca non raggiunta da ⌥A

## What happens

Quando l'utente chiede l'archiviazione con ⌥A o dal menu, l'app memorizza l'app in primo piano, ma la richiesta non arriva a nessuna lettura dello schermo: nessuna ricerca del documento parte, quindi né un documento viene individuato né l'attività riceve un rifiuto. La richiesta si perde senza esito.

## What should happen

Il Modello dice che la richiesta di archiviazione porta la lettura dello schermo da Inattiva a Ricerca del documento; la ricerca torna a Inattiva emettendo il documento individuato, verso la coda, oppure il nessun documento, verso l'attività. Il Requisito tecnico chiede che la lettura riguardi l'app memorizzata al momento della richiesta, e oggi questa lettura non avviene.

## Fix options

### Avviare la ricerca all'avvio

L'app crea la lettura dello schermo all'avvio e le invia la richiesta di ⌥A, con l'app in primo piano già memorizzata. La ricerca parte e i suoi due esiti vanno alla coda e all'attività. Costa: il collegamento tocca l'avvio dell'app e il punto dove arrivano le scorciatoie; coda e attività devono ricevere gli esiti, come prevedono i loro Task.

### Creare la lettura alla prima richiesta

La lettura dello schermo nasce solo alla prima richiesta di archiviazione e poi resta in funzione. L'avvio dell'app non cambia, ma la prima ⌥A è più lenta perché aspetta la creazione. Gli esiti seguono lo stesso percorso della prima opzione.

## Where in the code

Axi/AppDelegate.swift (riceve, riceveScorciatoia), Axi/Impostazioni/Scorciatoie.swift (emetti), Packages/AxiCore/Sources/AxiCore/LetturaSchermo/LetturaSchermo.swift
