---
column: done
technical: false
refs:
  - puntino
  - requirements/ui#puntino
  - requirements/ui#puntino/Menu aperto
  - requirements/ui#puntino/Nascosto
  - requirements/tech#puntino
drift: null
proposal: j7smnsvx
agent: false
created: 2026-10-19T18:49:28.722Z
finished: 2026-10-19T19:12:26.420Z
---
# Puntino a ellissi e accento

Il personaggio, sullo schermo e nella barra dei menu, è ridisegnato solo con cerchi ed ellissi a bordi netti e colori piatti, senza sfocature né contorno irregolare: corpo ellittico un poco schiacciato, mezzaluna d'ombra in basso a sinistra, riflesso ellittico in alto a destra, due occhi ellittici.

Quando il lavoro è finito:
- Il corpo è nel colore accento di macOS; ombra, riflesso e occhi sono tinte più scura, più chiara e molto chiara dello stesso accento. Con accento grafite il puntino è grigio, con accento multicolore blu. Nessun colore fisso resta nel disegno.
- I toni seguono l'aspetto chiaro o scuro: il personaggio sullo schermo quello del sistema, l'elemento della barra dei menu quello effettivo della barra. Un cambio di accento o di aspetto con Axi aperto vale subito.
- Fermo: il personaggio non si muove. Attesa: l'ellisse respira restando un'ellisse, ciclo di circa 2,2 s. Tre puntini, mentre l'AI pensa: in circa 0,4 s il corpo si restringe nel cerchio centrale e due cerchi uguali escono ai lati, gli occhi spariscono; i tre cerchi sono pieni nel colore accento e salgono e si gonfiano a onda in un ciclo di circa 2,2 s; al termine rientrano nel corpo in circa 0,4 s. In ogni fotogramma le forme restano cerchi ed ellissi perfetti. Con "Riduci movimento" le durate raddoppiano.
- Con file trascinati sopra il puntino si ingrandisce un poco e si vela del colore accento.
- Nel menu a raggiera ogni azione resta un cerchio di vetro; al passaggio del puntatore il cerchio prende un velo leggero d'accento, come le bolle dell'utente in chat, e l'icona il colore accento, e torna com'era quando il puntatore esce.
- Nella barra dei menu l'elemento mostra lo stesso disegno nei colori del tema, alto circa 18 pt, con le stesse animazioni, e si evidenzia come le altre icone quando il suo menu è aperto.
- `Design/puntino.svg` contiene la posa ferma e quella dei tre puntini, ciascuna in variante chiara e scura con l'accento blu predefinito come esempio, fatte solo di cerchi ed ellissi con `id`, senza path liberi né sfocature; il codice ridisegna le stesse forme.
- I test del disegno descrivono la nuova geometria (forme solo ellittiche, tre cerchi uguali nei tre puntini) invece del contorno irregolare.
