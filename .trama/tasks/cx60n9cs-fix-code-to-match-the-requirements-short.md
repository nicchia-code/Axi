---
column: done
technical: true
refs:
  - requirements/tech#impostazioni
drift: 9leithoj
proposal: null
agent: false
created: 2026-10-19T10:35:03.037Z
finished: 2026-10-19T11:33:08.548Z
---
# Fix code to match the Requirements: Shortcut stores app at release

## What happens

Le scorciatoie Archivia e Chat memorizzano l'app in primo piano quando il tasto viene rilasciato, non quando viene premuto. Se l'utente cambia app tra la pressione e il rilascio, Axi legge l'app sbagliata.

## What should happen

Come chiede il requisito per le scorciatoie, l'app in primo piano si memorizza al momento della pressione; l'azione resta al rilascio del tasto.

## Chosen option

**Salvare l'app alla pressione**

Ogni scorciatoia salva l'app in primo piano quando il tasto scende e lascia l'azione al rilascio, come oggi. Il rilascio usa l'app salvata alla pressione, e le ripetizioni del tasto tenuto premuto non la sovrascrivono. Il Model e i Requisiti restano invariati. Costo: ogni scorciatoia ascolta anche la pressione, non solo il rilascio, e il codice che gestisce la pressione va aggiunto.

## Where in the code

`Axi/Impostazioni/Scorciatoie.swift`, `registra` ed `emetti` (la memorizzazione avviene nel rilascio, con l'azione); `Axi/Impostazioni/AppInPrimoPiano.swift`, `registraAppInPrimoPiano`
