---
column: done
technical: false
refs:
  - puntino/Nascosto
  - requirements/ui#puntino/Nascosto
  - requirements/tech#puntino
drift: null
proposal: hi6zcc0k
agent: false
created: 2026-10-20T06:21:29.227Z
finished: 2026-10-20T06:24:25.936Z
---
# Icona della barra più grande

Mentre il puntino è in `puntino/Nascosto`, l'icona nella barra dei menu è alta circa 22,5 pt invece di circa 18 pt: il 25% in più delle altre icone della barra, sempre template nel colore delle icone di sistema.

Quando il Task è finito:

- Il personaggio e tutti i suoi aspetti e animazioni nella barra (fermo, attesa, tre puntini con la loro onda, spunta del successo, lampo, velo e ingrandimento del trascinamento) sono disegnati nell'icona più grande e crescono con lei del 25%.
- Le ampiezze del rimbalzo del successo e della scossa dell'errore nella barra sono in proporzione all'icona, quindi più ampie del 25% rispetto a oggi.
- Il contatore della coda nella barra (cerchio, numero e distanza dal personaggio) è in proporzione all'icona e cresce del 25%; l'elemento della barra si allarga per contenere l'icona intera, con e senza contatore.
- Rimbalzo, scossa, contatore e larghezza dell'elemento derivano da un'unica misura dell'immagine, senza valori fissi in punti ripetuti in altri punti del codice.
- Chat e nuvolette restano ancorate sotto l'elemento della barra, che ora è più grande, e il rilascio di file funziona su tutto l'elemento.
- Il personaggio sullo schermo (`puntino/Visibile`) resta di circa 48 pt e non cambia.
- I test che oggi fissano la misura di 18 pt e la larghezza dell'elemento con il contatore seguono la nuova misura.
