---
column: done
technical: true
refs:
  - requirements/tech#puntino
  - requirements/ui#puntino
drift: qreemmvg
proposal: null
agent: false
created: 2026-10-19T20:40:59.227Z
finished: 2026-10-19T20:41:32.106Z
---
# Fix code to match the Requirements: Fixed blue fallback in character colour

## What happens

Se il colore accento di sistema non si converte in sRGB, il corpo del personaggio ricade su un blu fisso.

## What should happen

Il personaggio non ha colori fissi: il corpo è l'accento dell'utente, risolto nell'aspetto effettivo della vista, e le tinte ne derivano.

## Chosen option

**Drop the fixed fallback**

Se la conversione fallisce si usa l'accento così com'è, senza un blu di ripiego, e le tinte si calcolano da quel valore. Costo: il caso raro va riscritto e verificato a mano.

## Note

Developer chose to reopen T6 and fix the fallback (trama ask, round t6-fallback). Option 1: drop the fixed fallback.

## Where in the code

Axi/Puntino/PuntinoDisegno.swift: PuntinoTinte.accento(scuro:), riga 143, fallback srgb 0, 0.478, 1.
