---
refs:
  - puntino/Nascosto
  - requirements/ui#puntino
  - requirements/ui#puntino/Nascosto
  - requirements/tech#puntino
---
# Icona della barra template

Quando il puntino è Nascosto, l'icona nella barra dei menu ha il colore delle icone di sistema: nero o bianco secondo l'aspetto della barra dei menu, attenuata come le altre icone su uno schermo non attivo ed evidenziata come le altre quando il suo menu è aperto. Il pulsante mostra un'immagine template di circa 18 pt, ridisegnata a ogni fotogramma dalle stesse forme vettoriali e con la stessa temporizzazione delle animazioni sullo schermo; nel pulsante non resta una vista nei colori del tema.

Il personaggio nella barra è una sagoma piena in un solo colore con i due occhi trasparenti, senza ombra né riflesso. Mostra gli stessi aspetti e le stesse animazioni dello schermo: fermo, il respiro dell'attesa, la trasformazione nei tre puntini, che sono tre cerchi pieni dello stesso colore, e il ritorno. Quando l'utente trascina file sull'icona, l'icona si ingrandisce un poco e la sagoma si schiarisce, senza colore; i file rilasciati vanno ancora in archiviazione.

Sullo schermo il personaggio resta nei colori del tema, non template.

`Design/puntino.svg` riceve la posa ferma monocroma della barra dei menu: la sagoma del corpo in un solo colore con gli occhi ritagliati, senza ombra né riflesso, fatta solo di `<circle>` ed `<ellipse>` con forme separate e con nome.
