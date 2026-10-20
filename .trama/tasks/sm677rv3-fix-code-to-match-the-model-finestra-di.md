---
column: done
technical: false
refs:
  - archiviazione/Generazione dei metadati
drift: wxtfwif8
proposal: null
agent: false
created: 2026-10-18T18:45:27.757Z
finished: 2026-10-18T19:02:14.326Z
---
# Fix code to match the Model: Finestra di contesto fissa

## What happens

Il testo di un documento va in un'unica richiesta fino a una soglia fissa di 32.000 token, qualunque sia il modello di OMP scelto.

## What should happen

Un documento va in una richiesta sola se il suo testo occupa al massimo la metà della finestra di contesto del modello scelto; altrimenti va a sezioni.

## Chosen option

**Leggere la finestra dal modello scelto**

Il servizio chiede a OMP la finestra di contesto del modello attivo e calcola la metà da quella. Se il dato non è disponibile, si usa un valore prudente dichiarato. Costo: una richiesta in più a OMP e la gestione del caso non disponibile.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingService.swift:62
