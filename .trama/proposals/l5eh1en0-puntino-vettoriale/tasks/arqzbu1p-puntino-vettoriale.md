---
refs:
  - puntino
  - requirements/ui#puntino
  - requirements/tech#puntino
---
# Puntino vettoriale

Quando il Task è finito, il personaggio non è più pixel art: è un disegno vettoriale liscio e fluido, ridisegnato in codice dal disegno di riferimento `Design/puntino.svg`, e le due bitmap non esistono più.

- `Design/puntino.svg` esiste nel repository, fuori dal bundle, con la posa ferma e la posa dei tre puntini; corpo, ombra, riflesso, occhi e satelliti sono forme separate con un `id`. Il codice SwiftUI disegna le stesse forme.
- Aspetto: pallina blu dal contorno tondo e leggermente irregolare, un poco schiacciata, ombra in basso a sinistra, riflesso in alto a destra, due occhi azzurri, due piccoli satelliti (in alto a destra e in basso a sinistra). Colori `#1777F7` (corpo), `#135EEA` (ombra), `#33C9F9` (riflesso), `#68EDF6` (occhi) con passaggi sfumati; mai template, nitido a ogni dimensione.
- Tre aspetti:
  - fermo, a riposo: nessun movimento;
  - attesa, mentre l'utente interagisce (menu aperto, chat aperta, file trascinati sopra) e durante un'archiviazione: il corpo si gonfia e si sgonfia e il contorno ondeggia come una goccia, in modo continuo, ciclo di circa 2,2 s;
  - tre puntini, mentre l'AI pensa, cioè mentre la chat sta rispondendo (`mini-chat/In risposta`): in circa 0,4 s il corpo si allunga e si divide in tre gocce uguali in fila, i satelliti vengono riassorbiti, gli occhi spariscono; le gocce si alzano e si gonfiano a onda una dopo l'altra in un ciclo di circa 2,2 s; finito, in circa 0,4 s si riuniscono nel personaggio. Le gocce restano nel riquadro del personaggio.
- Precedenza: segnale di un esito, poi tre puntini, poi attesa, poi fermo; finito un segnale il puntino torna all'aspetto del momento.
- Con "Riduci movimento" attesa, trasformazione e tre puntini sono gli stessi a metà velocità (durate raddoppiate) invece di diventare dissolvenze.
- I segnali degli esiti (rimbalzo e spunta, scossa con tinta rossa, lampo) e l'evidenziazione dei file trascinati restano come sono, applicati alla forma vettoriale invece che all'immagine in modalità template.
- Animazioni guidate da `TimelineView(.animation)`, interpolando i punti di controllo del contorno.
- `puntino.png` e `puntino-attesa.gif` sono tolti dal target `Axi`, dal progetto Xcode (gruppo e fase Resources) e dal repository; il codice che li decodifica con ImageIO non c'è più.
- Quando esiste l'elemento della barra dei menu (puntino nascosto), il suo pulsante mostra lo stesso disegno vettoriale rimpicciolito a circa 18 pt, satelliti compresi, con gli stessi aspetti e animazioni.
