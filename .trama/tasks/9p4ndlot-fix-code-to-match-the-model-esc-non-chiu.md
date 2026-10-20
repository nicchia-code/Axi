---
column: done
technical: false
refs:
  - puntino/Menu aperto
drift: u0nlqtuj
proposal: null
agent: false
created: 2026-10-18T20:05:07.482Z
finished: 2026-10-18T20:25:09.714Z
---
# Fix code to match the Model: Esc non chiude il menu

## What happens

Con il menu del puntino aperto, premere Esc non lo chiude: il menu resta aperto finché l'utente non fa clic altrove o sceglie una voce. Axi ascolta solo i clic del mouse per chiudere il menu.

## What should happen

Con il menu aperto, premere Esc chiude il menu e riporta il puntino a riposo, nello stesso modo in cui lo chiude un clic altrove.

## Chosen option

**Esc chiude il menu**

Premere Esc con il menu aperto lo chiude subito e riporta il puntino a riposo, come un clic fuori dal menu. È il comportamento che il Model descrive per la chiusura del menu. Costo: Esc viene letto anche quando un'altra app è in primo piano, se la lettura globale della tastiera è attiva, quindi la chiusura va verificata con altre app aperte.

## Where in the code

Axi/Puntino/PuntinoController.swift (chiudeMenuSeClicFuori, installaMonitorClic)
