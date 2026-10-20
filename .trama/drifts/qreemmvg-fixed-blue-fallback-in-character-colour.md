---
status: resolved
resolution: fix-code
refs:
  - requirements/tech#puntino
  - requirements/ui#puntino
proposal: null
task: 3mlilncm
origin: null
critical: false
option: 1
note: "Developer chose to reopen T6 and fix the fallback (trama ask, round t6-fallback). Option 1: drop the fixed fallback."
created: 2026-10-19T20:39:27.644Z
---
# Fixed blue fallback in character colour

## What happens

Se il colore accento di sistema non si converte in sRGB, il corpo del personaggio ricade su un blu fisso.

## What should happen

Il personaggio non ha colori fissi: il corpo è l'accento dell'utente, risolto nell'aspetto effettivo della vista, e le tinte ne derivano.

## Fix options

### Drop the fixed fallback

Se la conversione fallisce si usa l'accento così com'è, senza un blu di ripiego, e le tinte si calcolano da quel valore. Costo: il caso raro va riscritto e verificato a mano.

### Read the accent in the view

La vista legge l'accento con l'aspetto effettivo che la disegna, senza passare da una conversione con valore di ripiego. Costo: la tavolozza si calcola nella vista invece che nell'inizializzazione.

## Where in the code

Axi/Puntino/PuntinoDisegno.swift: PuntinoTinte.accento(scuro:), riga 143, fallback srgb 0, 0.478, 1.
