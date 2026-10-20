---
column: done
technical: false
refs:
  - puntino/Menu aperto/utente.CHIEDE_ARCHIVIAZIONE
  - puntino/Menu aperto
drift: 7qny9tfx
proposal: null
agent: false
created: 2026-10-19T03:02:16.465Z
finished: 2026-10-19T10:51:32.012Z
---
# Fix code to match the Model: Archive shortcut leaves menu open

## What happens

Con il menu aperto, la scorciatoia Archivia archivia l'app in primo piano come sempre, ma il menu resta sullo schermo e il puntino resta nello stato di menu aperto. Il menu si chiude solo con Esc, con un clic fuori da esso o scegliendo una voce.

## What should happen

Con il menu aperto, la scorciatoia Archivia archivia come sempre e il menu si chiude, e il puntino torna a riposo, come quando si sceglie Archivia dal menu.

## Chosen option

**Dot applies every archive event**

Il controller del puntino riceve anche gli eventi delle scorciatoie globali e li applica al proprio stato prima di inoltrarli, come già fa per le voci del menu. Così la scorciatoia Archivia riporta il puntino a riposo e chiude il menu. Costo: la scorciatoia passa dal puntino prima di arrivare al resto dell'app, quindi l'ordine di gestione cambia leggermente.

## Note

E ricordiamoci che deve diventare un elemento della tray bar invece di un dot spostabile

## Where in the code

Axi/Impostazioni/Scorciatoie.swift, `emetti`; Axi/AppDelegate.swift, `riceve` (la scorciatoia Archivia non raggiunge lo stato del puntino); Axi/Puntino/PuntinoController.swift, `installaMonitorClic` (il monitor di tastiera chiude il menu solo con Esc).
