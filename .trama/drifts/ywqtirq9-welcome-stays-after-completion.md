---
status: resolved
resolution: fix-code
refs:
  - benvenuto/Completato
  - benvenuto/Scaricamento del modello/benvenuto.MODELLO_SCARICATO
proposal: null
task: kfrtpzdx
origin: null
critical: false
option: 1
note: null
resolvedBy: 7ln2nfjv
created: 2026-10-19T03:05:34.342Z
---
# Welcome stays after completion

## What happens

Quando il modello è scaricato e funziona, il benvenuto non si chiude: passa al passo «Tutto pronto» con il pulsante Fine, e resta aperto finché l'utente non lo preme.

## What should happen

Il Model dice che, una volta completato, il benvenuto non compare più. Quando il modello funziona la finestra deve chiudersi da sola, senza un passo finale da chiudere a mano.

## Fix options

### Chiude il benvenuto alla fine

Quando il modello è verificato e il benvenuto è segnato come completato, la finestra si chiude da sola, senza passo finale. Il passo «Tutto pronto» e il pulsante Fine si tolgono. Costo: l'utente non vede più una conferma che Axi è pronto, e la chiusura arriva senza che lui la chieda.

### Conferma per pochi secondi

Il passo «Tutto pronto» resta visibile per alcuni secondi, poi la finestra si chiude da sola; il pulsante Fine la chiude subito. Costo: per quei secondi il benvenuto compare ancora in Completato, quindi la descrizione del Model non vale alla lettera, e serve un temporizzatore da tenere coerente con la chiusura manuale.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift:23-24 e 244-261; Axi/Benvenuto/BenvenutoModel.swift:111-116
