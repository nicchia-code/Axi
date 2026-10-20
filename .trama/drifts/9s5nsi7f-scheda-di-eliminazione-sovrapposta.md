---
status: resolved
resolution: fix-code
refs:
  - mini-chat/Conferma dell'eliminazione
  - requirements/ui#mini-chat
proposal: null
task: ju8jqbzn
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:41:15.667Z
---
# Scheda di eliminazione sovrapposta

## What happens

La conferma dell'eliminazione è una scheda sovrapposta a tutta la finestra della chat, sopra intestazione e conversazione. Non è una scheda dentro la conversazione.

## What should happen

Una scheda nella conversazione mostra titolo, tipo, data di archiviazione e allegati collegati che spariranno, con i pulsanti Elimina (stile distruttivo) e Annulla.

## Fix options

### Scheda dentro la conversazione

La scheda passa nella lista dei messaggi, in fondo alla conversazione, con gli stessi campi e i pulsanti Elimina e Annulla. Resta visibile mentre si scorre la conversazione. Costo: va cambiata la vista e il comportamento con la tastiera (Invio ed Esc) va ricontrollato.

### Sovrapposizione attuale, con Requirement aggiornato

Si tiene la scheda sopra la finestra e si cambia il Requirement per descrivere la sovrapposizione. Nessun cambio di codice, ma serve un Proposal perché il Requirement approvato descrive un'altra disposizione. La scheda copre l'intestazione mentre è aperta.

## Where in the code

Axi/MiniChat/MiniChatView.swift: ZStack e DeletionCard, righe 25–32
