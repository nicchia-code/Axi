---
column: done
technical: true
refs:
  - requirements/ui#attivita
drift: svn4ktl0
proposal: null
agent: false
created: 2026-10-18T18:45:27.793Z
finished: 2026-10-18T21:27:01.482Z
---
# Fix code to match the Requirements: Già presente in arancione

## What happens

Un documento già presente nel vault colora il puntino di arancione, con un'icona fissa per tutta la durata della nuvoletta. Non c'è un lampo di colore.

## What should happen

Il Requisito dice che, se il documento è già presente, il puntino fa un lampo nel colore d'accento, senza scossa.

## Chosen option

**Lampo nel colore d'accento**

Il puntino usa il colore d'accento di sistema e fa un lampo breve, senza scossa, poi torna al colore neutro dell'esito. Costo: serve un'animazione a tempo in più, e il colore dell'esito è diverso dagli altri due, come chiede il Requisito.

## Where in the code

Axi/Puntino/PuntinoVista.swift:50-58 (colore: .giaPresente restituisce .orange, riga 55)
