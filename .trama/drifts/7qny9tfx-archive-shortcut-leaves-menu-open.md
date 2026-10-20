---
status: resolved
resolution: fix-code
refs:
  - puntino/Menu aperto/utente.CHIEDE_ARCHIVIAZIONE
  - puntino/Menu aperto
proposal: null
task: djtzpkmc
origin: null
critical: false
option: 1
note: E ricordiamoci che deve diventare un elemento della tray bar invece di un dot spostabile
resolvedBy: qe7ae4y7
created: 2026-10-18T22:55:13.547Z
---
# Archive shortcut leaves menu open

## What happens

Con il menu aperto, la scorciatoia Archivia archivia l'app in primo piano come sempre, ma il menu resta sullo schermo e il puntino resta nello stato di menu aperto. Il menu si chiude solo con Esc, con un clic fuori da esso o scegliendo una voce.

## What should happen

Con il menu aperto, la scorciatoia Archivia archivia come sempre e il menu si chiude, e il puntino torna a riposo, come quando si sceglie Archivia dal menu.

## Fix options

### Dot applies every archive event

Il controller del puntino riceve anche gli eventi delle scorciatoie globali e li applica al proprio stato prima di inoltrarli, come già fa per le voci del menu. Così la scorciatoia Archivia riporta il puntino a riposo e chiude il menu. Costo: la scorciatoia passa dal puntino prima di arrivare al resto dell'app, quindi l'ordine di gestione cambia leggermente.

### Close menu on the archive shortcut

Quando il menu è aperto, il puntino chiude il menu alla pressione della scorciatoia Archivia, mentre la scorciatoia continua ad archiviare come oggi. Costo: il menu deve conoscere la scorciatoia Archivia, che oggi è nota solo alla sua registrazione, quindi la stessa informazione compare in due punti.

## Where in the code

Axi/Impostazioni/Scorciatoie.swift, `emetti`; Axi/AppDelegate.swift, `riceve` (la scorciatoia Archivia non raggiunge lo stato del puntino); Axi/Puntino/PuntinoController.swift, `installaMonitorClic` (il monitor di tastiera chiude il menu solo con Esc).
