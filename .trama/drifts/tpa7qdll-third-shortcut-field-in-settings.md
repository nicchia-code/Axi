---
status: resolved
resolution: dismissed
refs:
  - requirements/ui#impostazioni
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:41:00.129Z
---
# Third shortcut field in settings

## What happens

La finestra delle impostazioni mostra tre campi di scorciatoia: Archivia, Chat e Mostra/nascondi puntino (⌥H). Il ripristino dei valori predefiniti riporta anche la scorciatoia del puntino.

## What should happen

Il campo registrabile c'è solo per Archivia e Chat, con il ripristino dei valori predefiniti. La scorciatoia del puntino non compare nelle impostazioni.

## Fix options

### Remove field, keep ⌥H fixed

Il campo Mostra/nascondi puntino esce dalla finestra delle impostazioni e dal ripristino, che tocca solo Archivia e Chat. La scorciatoia ⌥H resta registrata come predefinita per la voce Nascondi del menu del puntino, e il tasto già scelto dall'utente resta attivo. Costo: l'utente non può più cambiare il tasto Nascondi, né vederlo nelle impostazioni.

### Remove field, reset hide key too

Il campo Mostra/nascondi puntino esce dalla finestra delle impostazioni, ma il ripristino continua a riportare la scorciatoia del puntino al valore predefinito ⌥H. Così un tasto cambiato per errore si può annullare senza un campo visibile. Costo: il ripristino tocca una scorciatoia che nelle impostazioni non si vede, e il requisito dice che il ripristino riguarda solo i campi mostrati.

## Where in the code

Axi/Impostazioni/ImpostazioniView.swift:49 (campo Mostra/nascondi puntino) e :50-52 (ripristino); Axi/Impostazioni/Scorciatoie.swift:13 e :55-57
