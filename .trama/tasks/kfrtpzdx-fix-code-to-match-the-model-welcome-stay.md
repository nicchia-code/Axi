---
column: done
technical: false
refs:
  - benvenuto/Completato
  - benvenuto/Scaricamento del modello/benvenuto.MODELLO_SCARICATO
drift: ywqtirq9
proposal: null
agent: false
created: 2026-10-19T08:10:02.962Z
finished: 2026-10-19T10:52:17.258Z
---
# Fix code to match the Model: Welcome stays after completion

## What happens

Quando il modello è scaricato e funziona, il benvenuto non si chiude: passa al passo «Tutto pronto» con il pulsante Fine, e resta aperto finché l'utente non lo preme.

## What should happen

Il Model dice che, una volta completato, il benvenuto non compare più. Quando il modello funziona la finestra deve chiudersi da sola, senza un passo finale da chiudere a mano.

## Chosen option

**Chiude il benvenuto alla fine**

Quando il modello è verificato e il benvenuto è segnato come completato, la finestra si chiude da sola, senza passo finale. Il passo «Tutto pronto» e il pulsante Fine si tolgono. Costo: l'utente non vede più una conferma che Axi è pronto, e la chiusura arriva senza che lui la chieda.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift:23-24 e 244-261; Axi/Benvenuto/BenvenutoModel.swift:111-116
