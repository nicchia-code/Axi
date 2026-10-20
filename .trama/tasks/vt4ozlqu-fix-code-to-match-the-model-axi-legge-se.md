---
column: done
technical: false
refs:
  - lettura-schermo/Ricerca del documento
  - lettura-schermo/Lettura del contesto
  - requirements/tech#lettura-schermo
drift: rodmmd90
proposal: null
agent: false
created: 2026-10-18T19:43:27.177Z
finished: 2026-10-18T20:18:21.499Z
---
# Fix code to match the Model: Axi legge se stessa

## What happens

Se al momento della scorciatoia o del puntino Axi è già in primo piano (per esempio con la finestra di Benvenuto o delle Impostazioni aperta), Axi memorizza sé stessa come app da leggere. La ricerca del documento allora non trova nulla e la chat riceve il testo della finestra di Axi invece di quello dell'app di lavoro.

## What should happen

Il Modello e il Requisito dicono che la lettura riguarda l'app che era in primo piano prima che Axi prendesse il fuoco. Se Axi era già in primo piano, Axi non deve essere letta come se fosse l'app dell'utente.

## Chosen option

**Nessuna app da leggere**

Quando Axi è in primo piano nel momento della richiesta, non si memorizza alcuna app. La ricerca finisce senza documento e la chat non parte, come quando non c'è un'app. Costo: l'utente deve portare in primo piano l'app di lavoro prima di chiedere, e la chat può mostrare un errore.

## Where in the code

Axi/Impostazioni/AppInPrimoPiano.swift (registraAppInPrimoPiano: salva FrontmostApplication.current() senza escludere Axi); Packages/AxiScreen/Sources/AxiScreen/AccessibilityTree.swift (FrontmostApplication.current); Packages/AxiCore/Sources/AxiCore/LetturaSchermo/LetturaSchermoService.swift (commento di riceve e leggeContesto: dice nil se Axi è in primo piano, il codice non lo fa)
