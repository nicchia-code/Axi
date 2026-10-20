---
status: resolved
resolution: fix-code
refs:
  - connessione-omp
proposal: null
task: wcgxm16j
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:41:36.838Z
---
# Impostazioni non aggiornate su OMP

## What happens

Se la finestra Impostazioni si apre mentre OMP sta ancora avviandosi, quando OMP diventa pronto lo stato passa a Connesso ma l'elenco dei modelli resta con l'errore 'Elenco dei modelli non disponibile' finché la finestra non viene riaperta.

## What should happen

Le impostazioni seguono lo stato della connessione: quando OMP è pronto mostrano Connesso e l'elenco dei modelli che OMP fornisce (requirements/tech#connessione-omp).

## Fix options

### Ricaricare i modelli quando OMP è pronto

Quando la connessione diventa pronta, la finestra ricarica l'elenco dei modelli. Prima di seguire gli eventi legge lo stato, così non perde un cambio avvenuto durante il caricamento. Costo: una richiesta in più a OMP ogni volta che diventa pronto mentre la finestra è aperta.

### Pulsante Riprova sull'elenco modelli

Quando l'elenco non è disponibile compare un pulsante Riprova che richiede i modelli a OMP. Lo stato Connesso resta aggiornato come oggi. Costo: l'utente deve premere il pulsante, e l'elenco resta vuoto finché non lo fa.

## Where in the code

Axi/Impostazioni/ImpostazioniModel.swift:63-73
