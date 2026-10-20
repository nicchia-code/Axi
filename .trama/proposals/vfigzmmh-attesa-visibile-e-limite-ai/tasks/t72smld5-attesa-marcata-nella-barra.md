---
refs:
  - puntino/Nascosto
  - requirements/ui#puntino
  - requirements/ui#puntino/Nascosto
---
# Attesa marcata nella barra

A riposo il puntino mostra l'aspetto fermo. L'attesa si vede mentre l'utente interagisce con il puntino (menu aperto, chat aperta, file trascinati sopra), durante un'archiviazione e ora anche mentre Axi cerca a schermo il documento da archiviare (stato `attivita/In ricerca`, introdotto dal Task di `attivita`; qui l'aspetto del puntino deve reagire a quello stato). I tre puntini hanno sempre la precedenza sull'attesa e il segnale di un esito su entrambi; finito il segnale il puntino torna all'aspetto del momento. Il calcolo dell'aspetto animato sta probabilmente in `Axi/Puntino/PuntinoVista.swift` (`animato`).

Nella barra dei menu, quando il puntino è nascosto, l'icona (circa 18 pt, `PuntinoVista(dimensione: 18, mostraContatore: true)` in `Axi/Puntino/PuntinoPannelli.swift`) mostra gli stessi aspetti e le stesse animazioni dello schermo, tranne l'attesa, che è più marcata perché si noti: il corpo si gonfia di circa il 10% della sua altezza (quasi 2 pt), restando un'ellisse perfetta con ombra, riflesso e occhi che la seguono, e restando interamente dentro il riquadro dell'icona. Il ciclo resta di circa 2,2 s e con "Riduci movimento" rallenta a metà velocità (circa 4,4 s) come sullo schermo; i tre puntini nella barra sono identici a quelli sullo schermo. Sullo schermo l'attesa non cambia. L'ampiezza del respiro è in `Axi/Puntino/PuntinoDisegno.swift` (`PuntinoGeometria.forme`): va resa più ampia solo per l'icona della barra.
