---
column: done
technical: false
refs:
  - connessione-omp/Non disponibile
drift: e76rkfb9
proposal: null
agent: false
created: 2026-10-18T19:43:27.158Z
finished: 2026-10-18T20:19:43.436Z
---
# Fix code to match the Model: Benvenuto non mostra il motivo

## What happens

Il benvenuto mostra «OMP trovato» o «OMP non trovato» controllando ogni secondo solo se esiste un file `omp` sul Mac (`OMPLocator.find()`). Non legge lo stato della connessione e ignora il percorso indicato nelle impostazioni. Con OMP Non disponibile per uscite ripetute mostra «OMP trovato» e non dice il motivo.

## What should happen

Il Model (`connessione-omp`, stato Non disponibile): le impostazioni e il benvenuto mostrano che OMP non è disponibile e perché. Requirement `tech#connessione-omp`: il percorso di OMP è quello delle impostazioni, se manca Axi lo cerca nel PATH e nelle cartelle usuali.

## Chosen option

**Il benvenuto segue lo stato della connessione**

Il benvenuto legge lo stato della connessione OMP e ne mostra il motivo quando è Non disponibile, come fanno le impostazioni. Il controllo periodico del file sul Mac non serve più e il benvenuto usa il percorso indicato nelle impostazioni.

## Where in the code

Axi/Benvenuto/BenvenutoModel.swift:48; Axi/Benvenuto/BenvenutoView.swift:98-100; Packages/AxiOMP/Sources/AxiOMP/OMPLocator.swift:27-41
