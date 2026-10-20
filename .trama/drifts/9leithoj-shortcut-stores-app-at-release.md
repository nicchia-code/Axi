---
status: resolved
resolution: fix-code
refs:
  - requirements/tech#impostazioni
proposal: null
task: cx60n9cs
origin: null
critical: false
option: 1
note: null
resolvedBy: hrfxsylt
created: 2026-10-19T08:29:17.721Z
---
# Shortcut stores app at release

## What happens

Le scorciatoie Archivia e Chat memorizzano l'app in primo piano quando il tasto viene rilasciato, non quando viene premuto. Se l'utente cambia app tra la pressione e il rilascio, Axi legge l'app sbagliata.

## What should happen

Come chiede il requisito per le scorciatoie, l'app in primo piano si memorizza al momento della pressione; l'azione resta al rilascio del tasto.

## Fix options

### Salvare l'app alla pressione

Ogni scorciatoia salva l'app in primo piano quando il tasto scende e lascia l'azione al rilascio, come oggi. Il rilascio usa l'app salvata alla pressione, e le ripetizioni del tasto tenuto premuto non la sovrascrivono. Il Model e i Requisiti restano invariati. Costo: ogni scorciatoia ascolta anche la pressione, non solo il rilascio, e il codice che gestisce la pressione va aggiunto.

### Usare l'ultima app attivata

Axi tiene aggiornata l'ultima app diversa da sé passata in primo piano, come già fa per l'archiviazione. Alla pressione di una scorciatoia usa quella, senza ascoltare la pressione; il rilascio agisce come oggi. Quando Axi è già in primo piano alla pressione, la memoria resta vuota come oggi. Costo: la memoria dipende dal seguire ogni cambio di app.

## Where in the code

`Axi/Impostazioni/Scorciatoie.swift`, `registra` ed `emetti` (la memorizzazione avviene nel rilascio, con l'azione); `Axi/Impostazioni/AppInPrimoPiano.swift`, `registraAppInPrimoPiano`
