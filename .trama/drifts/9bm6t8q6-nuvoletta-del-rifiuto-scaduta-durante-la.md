---
status: resolved
resolution: proposal
refs:
  - attivita
proposal: null
task: null
origin: aotzarmg
critical: false
option: null
note: null
resolvedBy: qe2f3jm3
created: 2026-10-20T07:51:27.225Z
---
# Nuvoletta del rifiuto scaduta durante la ricerca

## What happens

In ricerca, quando un'altra richiesta aspetta la sua ricerca, il rifiuto di una ricerca a schermo mostra una nuvoletta che scade dopo i suoi secondi; alla scadenza il codice torna alla nuvoletta «Sto archiviando» senza nome mentre la ricerca continua.

## What should happen

Il Modello dice che la nuvoletta del rifiuto resta per i suoi secondi e che il personaggio resta nei tre puntini (attivita, In ricerca), ma non definisce quale nuvoletta mostrare alla scadenza mentre la ricerca continua: nessuna transizione di tempo parte da In ricerca.

## Fix options

### Tornare a «Sto archiviando»

Alla scadenza torna la nuvoletta di avvio senza nome, come ora nel codice, finché la ricerca continua; il Modello non cambia.

### Nessuna nuvoletta

Alla scadenza nessuna nuvoletta finché la ricerca non trova il documento; il Modello aggiunge questa transizione.

### Rifiuto fino alla fine della ricerca

La nuvoletta del rifiuto resta fino a quando la ricerca finisce, ignorando i secondi; il Modello va cambiato sul tempo.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Attivita/Attivita.swift: case .nessunDocumento con altreRichieste (righe 183-185) e mostra(_:restaInRicerca:) (righe 240-247); Axi/Puntino/NuvolettaVista.swift
