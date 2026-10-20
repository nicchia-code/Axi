---
status: resolved
resolution: fix-code
refs:
  - connessione-omp/Pronta
proposal: null
task: ok5ey515
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:41:36.827Z
---
# Processo morto durante l'avvio

## What happens

Se il processo dell'archiviazione si ferma mentre parte quello della chat, Axi non se ne accorge: la connessione diventa Pronta lo stesso, con un processo fermo, e non riparte né passa a Non disponibile.

## What should happen

Quando OMP si ferma da Pronta, la connessione torna in Avvio, oppure in Non disponibile se si ferma di nuovo entro 30 secondi dal riavvio (connessione-omp).

## Fix options

### Controllare ogni processo appena è pronto

Ogni processo viene osservato subito dopo il suo avvio, prima di avviare l'altro. Se si ferma durante l'attesa, la connessione segue la regola di riavvio. Costo: un po' più di codice nell'avvio della connessione; Pronta arriva solo dopo la verifica di entrambi.

### Verificare entrambi prima di dichiarare Pronta

Prima di passare a Pronta, Axi controlla che entrambi i processi siano ancora vivi; se uno si è fermato, la connessione va in avvio fallito. Costo: resta una piccola finestra se un processo si ferma subito dopo il controllo, quindi la regola di riavvio non copre tutti i casi.

## Where in the code

Packages/AxiOMP/Sources/AxiOMP/OMPConnection.swift:221-230
