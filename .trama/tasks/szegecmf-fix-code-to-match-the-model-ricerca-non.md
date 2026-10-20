---
column: done
technical: false
refs:
  - lettura-schermo/Inattiva
drift: 4cf50e30
proposal: null
agent: false
created: 2026-10-18T20:05:07.491Z
finished: 2026-10-18T20:22:09.868Z
---
# Fix code to match the Model: Ricerca non raggiunta da ⌥A

## What happens

Quando l'utente chiede l'archiviazione con ⌥A o dal menu, l'app memorizza l'app in primo piano, ma la richiesta non arriva a nessuna lettura dello schermo: nessuna ricerca del documento parte, quindi né un documento viene individuato né l'attività riceve un rifiuto. La richiesta si perde senza esito.

## What should happen

Il Modello dice che la richiesta di archiviazione porta la lettura dello schermo da Inattiva a Ricerca del documento; la ricerca torna a Inattiva emettendo il documento individuato, verso la coda, oppure il nessun documento, verso l'attività. Il Requisito tecnico chiede che la lettura riguardi l'app memorizzata al momento della richiesta, e oggi questa lettura non avviene.

## Chosen option

**Avviare la ricerca all'avvio**

L'app crea la lettura dello schermo all'avvio e le invia la richiesta di ⌥A, con l'app in primo piano già memorizzata. La ricerca parte e i suoi due esiti vanno alla coda e all'attività. Costa: il collegamento tocca l'avvio dell'app e il punto dove arrivano le scorciatoie; coda e attività devono ricevere gli esiti, come prevedono i loro Task.

## Where in the code

Axi/AppDelegate.swift (riceve, riceveScorciatoia), Axi/Impostazioni/Scorciatoie.swift (emetti), Packages/AxiCore/Sources/AxiCore/LetturaSchermo/LetturaSchermo.swift
