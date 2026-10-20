---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#attivita
proposal: null
task: fpbsg1zu
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:42:28.630Z
---
# Già presente in arancione

## What happens

Un documento già presente nel vault colora il puntino di arancione, con un'icona fissa per tutta la durata della nuvoletta. Non c'è un lampo di colore.

## What should happen

Il Requisito dice che, se il documento è già presente, il puntino fa un lampo nel colore d'accento, senza scossa.

## Fix options

### Lampo nel colore d'accento

Il puntino usa il colore d'accento di sistema e fa un lampo breve, senza scossa, poi torna al colore neutro dell'esito. Costo: serve un'animazione a tempo in più, e il colore dell'esito è diverso dagli altri due, come chiede il Requisito.

### Colore d'accento per tutta la nuvoletta

Il puntino resta nel colore d'accento per l'intera durata della nuvoletta, senza lampo. Costo: più semplice da fare, ma non segue la parola 'lampo' del Requisito e non si distingue dal rimanere fermi.

## Where in the code

Axi/Puntino/PuntinoVista.swift:50-58 (colore: .giaPresente restituisce .orange, riga 55)
