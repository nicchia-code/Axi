---
column: done
technical: false
refs:
  - connessione-omp/Pronta
drift: cur5aszm
proposal: null
agent: false
created: 2026-10-18T18:45:27.760Z
finished: 2026-10-18T19:17:39.640Z
---
# Fix code to match the Model: Cambio percorso con OMP pronto

## What happens

Mentre OMP è pronto, o sta ancora avviandosi, ogni cambio del percorso nelle impostazioni riavvia OMP: la connessione torna in avvio e l'archiviazione e la chat in corso vengono interrotte, anche se il percorso non è davvero cambiato. Il cambio viene inviato anche quando il campo perde il fuoco senza modifiche.

## What should happen

Il Model prevede il cambio del percorso solo da Non disponibile: da Pronta non c'è nessuna transizione, quindi OMP resta pronto e il nuovo percorso vale dalla prossima partenza.

## Chosen option

**Ignorare il cambio mentre OMP è pronto**

Il percorso viene salvato, ma OMP non riparte: il nuovo percorso vale alla prossima partenza di Axi o quando OMP passa a Non disponibile. Nessuna interruzione dell'archiviazione o della chat. Il Model resta invariato; serve solo cambiare il punto in cui le impostazioni inviano il cambio.

## Where in the code

Packages/AxiOMP/Sources/AxiOMP/OMPConnection.swift:65-68; Axi/Impostazioni/ImpostazioniModel.swift:89-92
