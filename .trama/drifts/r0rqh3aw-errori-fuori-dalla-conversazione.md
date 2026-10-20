---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#mini-chat
proposal: null
task: katep0bc
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:41:15.576Z
---
# Errori fuori dalla conversazione

## What happens

Un errore della risposta compare come una riga sotto la conversazione, con il pulsante Riprova accanto. Non diventa un messaggio nella conversazione e non viene salvato con essa.

## What should happen

Gli errori compaiono come messaggio nella conversazione, con il pulsante Riprova quando ha senso.

## Fix options

### Errore come messaggio nella conversazione

L'errore diventa un messaggio di Axi nella conversazione, con Riprova sotto quando la domanda può essere rifatta. La riga sotto la conversazione sparisce. Costo: serve decidere se l'errore entra nei dati salvati della conversazione o resta solo sullo schermo, e la vista va adattata.

### Riga d'errore sotto la conversazione

Si tiene la riga attuale sotto la conversazione e si cambia il Requirement per dire che l'errore sta fuori dalla conversazione. Nessun cambio di codice, ma la regola della UI va riscritta, e serve un Proposal perché cambia un Requirement già approvato.

## Where in the code

Axi/MiniChat/MiniChatView.swift: statusBar, righe 110–124
