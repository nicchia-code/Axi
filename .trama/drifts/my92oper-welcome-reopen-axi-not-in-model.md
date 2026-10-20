---
status: resolved
resolution: proposal
refs:
  - benvenuto/Permessi
  - requirements/ui#benvenuto
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: 0zmrvfhb
created: 2026-10-19T12:04:26.412Z
---
# Welcome Reopen Axi not in Model

## What happens

Nel passo Permessi del benvenuto, dopo che l'utente ha chiesto Registrazione schermo, la riga mostra il pulsante «Riapri Axi». Premerlo chiude Axi e ne apre una nuova; nella nuova istanza il benvenuto compare di nuovo, perché non è ancora completato. Il Model del benvenuto, al passo Permessi, prevede solo la richiesta di un permesso e il proseguimento: non prevede la riapertura di Axi.

## What should happen

Il Model e il comportamento devono coincidere: se dal passo Permessi del benvenuto Axi può riavviarsi, il Model deve dirlo; altrimenti quel passo non deve offrire la riapertura.

## Fix options

### Nascondere Riapri Axi nel benvenuto

Nel benvenuto la riga mostra la spiegazione «Registrazione schermo vale dopo aver riaperto Axi.» senza il pulsante Riapri Axi. Il pulsante resta nella finestra dei permessi, dove il Requirement lo prevede già. Il benvenuto torna a fare solo ciò che il suo Model descrive. Costo: le righe del benvenuto e della finestra dei permessi differiscono per un pulsante, mentre il Requirement del benvenuto le vuole uguali.

### Lasciare com'è e aggiornare il Model

Il benvenuto mantiene il pulsante e la riapertura come sono. Il Model del benvenuto viene aggiornato in seguito con una proposta che aggiunga al passo Permessi la riapertura di Axi. Costo: finché la proposta non è decisa, il Model resta incompleto rispetto a ciò che l'utente vede; il codice non cambia.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift:81; Axi/Permessi/PermessiRighe.swift:91-92; Axi/AppDelegate.swift:125-128; Axi/Permessi/PermessiController.swift:59-60 e 116-127
