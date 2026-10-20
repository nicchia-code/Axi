---
status: resolved
resolution: fix-code
refs:
  - puntino/Menu aperto
proposal: null
task: 9p4ndlot
origin: null
critical: false
option: 1
note: null
resolvedBy: 4p713jb5
created: 2026-10-18T19:46:52.135Z
---
# Esc non chiude il menu

## What happens

Con il menu del puntino aperto, premere Esc non lo chiude: il menu resta aperto finché l'utente non fa clic altrove o sceglie una voce. Axi ascolta solo i clic del mouse per chiudere il menu.

## What should happen

Con il menu aperto, premere Esc chiude il menu e riporta il puntino a riposo, nello stesso modo in cui lo chiude un clic altrove.

## Fix options

### Esc chiude il menu

Premere Esc con il menu aperto lo chiude subito e riporta il puntino a riposo, come un clic fuori dal menu. È il comportamento che il Model descrive per la chiusura del menu. Costo: Esc viene letto anche quando un'altra app è in primo piano, se la lettura globale della tastiera è attiva, quindi la chiusura va verificata con altre app aperte.

### Esc solo con Axi in primo piano

Esc chiude il menu solo quando Axi riceve la tastiera, senza leggere i tasti delle altre app. Non richiede una lettura globale della tastiera. Costo: con un'altra app in primo piano Esc non chiude il menu, e il comportamento resta diverso dai clic fuori, che funzionano anche con altre app attive.

## Where in the code

Axi/Puntino/PuntinoController.swift (chiudeMenuSeClicFuori, installaMonitorClic)
