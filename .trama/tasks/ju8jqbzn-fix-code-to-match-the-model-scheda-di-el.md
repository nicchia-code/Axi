---
column: done
technical: false
refs:
  - mini-chat/Conferma dell'eliminazione
  - requirements/ui#mini-chat
drift: 9s5nsi7f
proposal: null
agent: false
created: 2026-10-18T18:45:27.747Z
finished: 2026-10-18T20:24:20.843Z
---
# Fix code to match the Model: Scheda di eliminazione sovrapposta

## What happens

La conferma dell'eliminazione è una scheda sovrapposta a tutta la finestra della chat, sopra intestazione e conversazione. Non è una scheda dentro la conversazione.

## What should happen

Una scheda nella conversazione mostra titolo, tipo, data di archiviazione e allegati collegati che spariranno, con i pulsanti Elimina (stile distruttivo) e Annulla.

## Chosen option

**Scheda dentro la conversazione**

La scheda passa nella lista dei messaggi, in fondo alla conversazione, con gli stessi campi e i pulsanti Elimina e Annulla. Resta visibile mentre si scorre la conversazione. Costo: va cambiata la vista e il comportamento con la tastiera (Invio ed Esc) va ricontrollato.

## Where in the code

Axi/MiniChat/MiniChatView.swift: ZStack e DeletionCard, righe 25–32
