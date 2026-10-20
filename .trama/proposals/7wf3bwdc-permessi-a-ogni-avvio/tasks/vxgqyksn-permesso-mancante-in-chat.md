---
technical: false
refs:
  - mini-chat/In preparazione/lettura-schermo.LETTURA_FALLITA
  - requirements/ui#mini-chat/In preparazione
---
# Permesso mancante nella chat

Quando il Task è concluso, in In preparazione `lettura-schermo.LETTURA_FALLITA` porta a Pronta: la chat dice che non ha potuto leggere lo schermo e risponde solo sul vault; se è mancato un permesso, lo nomina e offre di aprire la finestra dei permessi.

Il messaggio nella conversazione usa il motivo portato da `LETTURA_FALLITA` e ha esattamente questi testi (italiano / inglese); se manca solo Accessibility la lettura non fallisce, perché passa al riconoscimento del testo, quindi non serve un testo per quel caso:
- Manca Registrazione schermo: «Non ho potuto leggere lo schermo: manca il permesso Registrazione schermo. Rispondo solo sul vault.» / «I couldn't read the screen: the Screen Recording permission is missing. I'll answer from the vault only.»
- Mancano entrambi: «Non ho potuto leggere lo schermo: mancano i permessi Accessibility e Registrazione schermo. Rispondo solo sul vault.» / «I couldn't read the screen: the Accessibility and Screen Recording permissions are missing. I'll answer from the vault only.»

Sotto il messaggio, il pulsante «Apri i permessi» / «Open permissions» apre la finestra dei permessi: equivale a `utente.APRE_PERMESSI`, e la finestra è quella costruita dal Task sulla Machine `permessi`. Quando il riconoscimento non è riuscito (nessun permesso mancante) la chat dice soltanto che non ha potuto leggere lo schermo, senza pulsante. In ogni caso la chat passa a Pronta e le domande non sono accompagnate da alcun contesto dello schermo: risponde solo sul vault.

Dove va il lavoro: `Axi/MiniChat/MiniChatController.swift` (oggi trasforma `.letturaFallita` in `LetturaSchermoNonRiuscita` e invia `.screenReadFailed` senza motivo: deve passare i permessi mancanti), `Axi/MiniChat/MiniChatMachine.swift` (`screen = .unreadable` deve conservare il motivo) e `Axi/MiniChat/MiniChatView.swift` (al posto della didascalia grigia «Screen not read», il messaggio con i testi sopra e il pulsante che apre la finestra dei permessi), con le stringhe localizzate in italiano e inglese.
