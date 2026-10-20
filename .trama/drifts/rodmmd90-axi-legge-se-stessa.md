---
status: resolved
resolution: fix-code
refs:
  - lettura-schermo/Ricerca del documento
  - lettura-schermo/Lettura del contesto
  - requirements/tech#lettura-schermo
proposal: null
task: vt4ozlqu
origin: null
critical: false
option: 1
note: null
resolvedBy: stsg18fb
created: 2026-10-18T19:11:47.349Z
---
# Axi legge se stessa

## What happens

Se al momento della scorciatoia o del puntino Axi è già in primo piano (per esempio con la finestra di Benvenuto o delle Impostazioni aperta), Axi memorizza sé stessa come app da leggere. La ricerca del documento allora non trova nulla e la chat riceve il testo della finestra di Axi invece di quello dell'app di lavoro.

## What should happen

Il Modello e il Requisito dicono che la lettura riguarda l'app che era in primo piano prima che Axi prendesse il fuoco. Se Axi era già in primo piano, Axi non deve essere letta come se fosse l'app dell'utente.

## Fix options

### Nessuna app da leggere

Quando Axi è in primo piano nel momento della richiesta, non si memorizza alcuna app. La ricerca finisce senza documento e la chat non parte, come quando non c'è un'app. Costo: l'utente deve portare in primo piano l'app di lavoro prima di chiedere, e la chat può mostrare un errore.

### Ultima app diversa da Axi

Quando Axi è in primo piano, la memoria resta sull'ultima app diversa da Axi usata prima. La lettura riguarda quella app, come chiede il Requisito, anche se la finestra in primo piano è di Axi. Costo: l'app letta può non essere quella che l'utente vede in quel momento, e serve tenere la memoria anche fuori dai clic.

## Where in the code

Axi/Impostazioni/AppInPrimoPiano.swift (registraAppInPrimoPiano: salva FrontmostApplication.current() senza escludere Axi); Packages/AxiScreen/Sources/AxiScreen/AccessibilityTree.swift (FrontmostApplication.current); Packages/AxiCore/Sources/AxiCore/LetturaSchermo/LetturaSchermoService.swift (commento di riceve e leggeContesto: dice nil se Axi è in primo piano, il codice non lo fa)
