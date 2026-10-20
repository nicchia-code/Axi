---
status: approved
base:
  requirements/ui/companion.md: d81627fa6259d9338ea32600ff6adce94e43590f3b3e103b5d16f53e07d358e5
  requirements/tech/fondamenta.md: 9af43eea11601cce68352fd05da43b2f386754b5557dbd39629e27bd2761fcfc
  requirements/ui/finestre.md: new
delete: []
request: 2026-10-19T20-37-56
created: 2026-10-19T18:47:08.078Z
label: Puntino a ellissi e accento
---
# Puntino a ellissi e accento

Il companion cambia aspetto per allinearsi alla chat: fatto di cerchi ed ellissi nette, nei colori del tema di macOS (colore accento, aspetto chiaro e scuro) invece dei quattro blu fissi. Cambiano solo i Requirements (ui e tech); il comportamento del Model resta lo stesso. Supera la scelta della Drift `7e3h9qmy`, che teneva il puntino nei suoi colori.

Decisioni prese con lo sviluppatore:
- Colori: dal colore accento di macOS, come le bolle dell'utente in chat; con accento grafite il puntino è grigio, con accento multicolore blu.
- Disegno: ellissi nette e piatte, senza contorno irregolare e senza sfocature.
- Anatomia: corpo nel colore accento, mezzaluna d'ombra più scura in basso a sinistra, riflesso ellittico chiaro in alto a destra, due occhi ellittici.
- Occhi: tinta molto chiara dell'accento.
- Chiaro e scuro: i toni derivano dalla variante dell'accento che macOS usa per l'aspetto corrente; nessuna forma in più.
- Animazioni: forme sempre perfette; l'attesa è un respiro dell'ellisse, i tre puntini sono tre cerchi pieni nel colore accento.
- Passaggio ai tre puntini: l'ellisse si restringe nel cerchio centrale mentre due cerchi escono ai lati; al ritorno rientrano.
- Barra dei menu: stesso disegno e animazioni, con i colori scelti in base all'aspetto della barra dei menu.
- Segnali: evidenziazione del trascinamento e lampo del già presente nel colore del tema; errore resta rosso di sistema, successo resta spunta verde.
- Numero in coda: cerchio nel colore del tema (capsula da due cifre) con numero bianco.
- Nuvoletta: angoli come le bolle della chat e coda di due cerchietti di vetro decrescenti verso il personaggio o l'icona; nessuna coda in sovrimpressione sulla chat.
- Menu a raggiera: restano cerchi di vetro; al passaggio del puntatore il cerchio prende un velo d'accento come le bolle dell'utente e l'icona il colore accento.
- Apertura della chat dal personaggio: invariata.
- `Design/puntino.svg`: pose ferma e tre puntini, solo cerchi ed ellissi, in variante chiara e scura con l'accento blu predefinito come esempio.

Assunzione: un cambio di accento o di aspetto mentre Axi è aperto vale subito, come per la chat.
