---
column: done
technical: false
refs:
  - puntino/Visibile
  - requirements/ui#puntino/Visibile
drift: null
proposal: acfkllae
agent: false
created: 2026-10-19T20:49:59.362Z
finished: 2026-10-19T20:59:21.420Z
---
# Personaggio a 48 pt

Quando il puntino è Visibile, il personaggio sullo schermo è alto circa 48 pt invece di 32: 1,5 volte la misura di prima. Il suo riquadro cresce di conseguenza, così che il personaggio non venga mai tagliato, neppure quando si ingrandisce mentre l'utente ci trascina sopra dei file o durante il rimbalzo.

Spunta dell'esito, contatore della coda, rimbalzo e scossa crescono in proporzione al personaggio. Il menu a raggiera non cambia misura. Nuvoletta e chat continuano a posizionarsi rispetto al riquadro del personaggio, dal lato con più spazio.

La posizione salvata non si corregge: al primo avvio dopo l'aggiornamento il riquadro più grande cresce dall'angolo in basso a sinistra della posizione salvata. Senza una posizione salvata, il personaggio compare in basso a destra sullo schermo principale, interamente visibile alla nuova misura.

L'icona della barra dei menu resta di circa 18 pt.
