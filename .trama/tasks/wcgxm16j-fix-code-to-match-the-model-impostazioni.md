---
column: done
technical: false
refs:
  - connessione-omp
drift: mmy8elat
proposal: null
agent: false
created: 2026-10-18T18:45:27.767Z
finished: 2026-10-18T19:52:47.108Z
---
# Fix code to match the Model: Impostazioni non aggiornate su OMP

## What happens

Se la finestra Impostazioni si apre mentre OMP sta ancora avviandosi, quando OMP diventa pronto lo stato passa a Connesso ma l'elenco dei modelli resta con l'errore 'Elenco dei modelli non disponibile' finché la finestra non viene riaperta.

## What should happen

Le impostazioni seguono lo stato della connessione: quando OMP è pronto mostrano Connesso e l'elenco dei modelli che OMP fornisce (requirements/tech#connessione-omp).

## Chosen option

**Ricaricare i modelli quando OMP è pronto**

Quando la connessione diventa pronta, la finestra ricarica l'elenco dei modelli. Prima di seguire gli eventi legge lo stato, così non perde un cambio avvenuto durante il caricamento. Costo: una richiesta in più a OMP ogni volta che diventa pronto mentre la finestra è aperta.

## Where in the code

Axi/Impostazioni/ImpostazioniModel.swift:63-73
