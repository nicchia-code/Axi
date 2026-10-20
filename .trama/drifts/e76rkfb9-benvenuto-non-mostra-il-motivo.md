---
status: resolved
resolution: fix-code
refs:
  - connessione-omp/Non disponibile
proposal: null
task: 6zxa10d4
origin: null
critical: false
option: 1
note: null
resolvedBy: stsg18fb
created: 2026-10-18T19:10:58.696Z
---
# Benvenuto non mostra il motivo

## What happens

Il benvenuto mostra «OMP trovato» o «OMP non trovato» controllando ogni secondo solo se esiste un file `omp` sul Mac (`OMPLocator.find()`). Non legge lo stato della connessione e ignora il percorso indicato nelle impostazioni. Con OMP Non disponibile per uscite ripetute mostra «OMP trovato» e non dice il motivo.

## What should happen

Il Model (`connessione-omp`, stato Non disponibile): le impostazioni e il benvenuto mostrano che OMP non è disponibile e perché. Requirement `tech#connessione-omp`: il percorso di OMP è quello delle impostazioni, se manca Axi lo cerca nel PATH e nelle cartelle usuali.

## Fix options

### Il benvenuto segue lo stato della connessione

Il benvenuto legge lo stato della connessione OMP e ne mostra il motivo quando è Non disponibile, come fanno le impostazioni. Il controllo periodico del file sul Mac non serve più e il benvenuto usa il percorso indicato nelle impostazioni.

### Il benvenuto cerca con il percorso delle impostazioni

Il benvenuto mantiene il controllo del file, ma usa il percorso indicato nelle impostazioni e mostra «OMP non trovato» solo quando il percorso non porta a un eseguibile. Resta il caso di OMP che si ferma: il benvenuto non lo distingue.

## Where in the code

Axi/Benvenuto/BenvenutoModel.swift:48; Axi/Benvenuto/BenvenutoView.swift:98-100; Packages/AxiOMP/Sources/AxiOMP/OMPLocator.swift:27-41
