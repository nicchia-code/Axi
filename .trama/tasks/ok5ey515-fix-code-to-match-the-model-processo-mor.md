---
column: done
technical: false
refs:
  - connessione-omp/Pronta
drift: fgf7r0w2
proposal: null
agent: false
created: 2026-10-18T18:45:27.763Z
finished: 2026-10-18T19:21:32.101Z
---
# Fix code to match the Model: Processo morto durante l'avvio

## What happens

Se il processo dell'archiviazione si ferma mentre parte quello della chat, Axi non se ne accorge: la connessione diventa Pronta lo stesso, con un processo fermo, e non riparte né passa a Non disponibile.

## What should happen

Quando OMP si ferma da Pronta, la connessione torna in Avvio, oppure in Non disponibile se si ferma di nuovo entro 30 secondi dal riavvio (connessione-omp).

## Chosen option

**Controllare ogni processo appena è pronto**

Ogni processo viene osservato subito dopo il suo avvio, prima di avviare l'altro. Se si ferma durante l'attesa, la connessione segue la regola di riavvio. Costo: un po' più di codice nell'avvio della connessione; Pronta arriva solo dopo la verifica di entrambi.

## Where in the code

Packages/AxiOMP/Sources/AxiOMP/OMPConnection.swift:221-230
