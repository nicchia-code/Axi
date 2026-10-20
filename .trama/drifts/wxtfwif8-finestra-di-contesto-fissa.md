---
status: resolved
resolution: fix-code
refs:
  - archiviazione/Generazione dei metadati
proposal: null
task: sm677rv3
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:41:30.813Z
---
# Finestra di contesto fissa

## What happens

Il testo di un documento va in un'unica richiesta fino a una soglia fissa di 32.000 token, qualunque sia il modello di OMP scelto.

## What should happen

Un documento va in una richiesta sola se il suo testo occupa al massimo la metà della finestra di contesto del modello scelto; altrimenti va a sezioni.

## Fix options

### Leggere la finestra dal modello scelto

Il servizio chiede a OMP la finestra di contesto del modello attivo e calcola la metà da quella. Se il dato non è disponibile, si usa un valore prudente dichiarato. Costo: una richiesta in più a OMP e la gestione del caso non disponibile.

### Tenere 32.000 e correggere la regola

Il valore fisso resta e la regola dice che la soglia è prudenziale e non dipende dal modello. Nessun cambio di codice. Costo: il Requirement cambia e un modello con finestra più piccola può ricevere un testo troppo lungo.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingService.swift:62
