---
column: done
technical: false
refs:
  - lettura-schermo/Inattiva
  - lettura-schermo/Lettura del contesto
  - lettura-schermo/Accessibilità
  - lettura-schermo/Riconoscimento del testo
  - lettura-schermo.CONTESTO_LETTO
  - lettura-schermo.TESTO_NON_ACCESSIBILE
  - lettura-schermo.LETTURA_FALLITA
drift: null
proposal: null
agent: false
created: 2026-10-18T18:40:32.024Z
finished: 2026-10-18T19:07:44.352Z
---
# Lettura del contesto in funzione

Quando l'utente apre la chat (utente.APRE_CHAT), Axi legge il contesto dell'app in primo piano memorizzata nel momento della richiesta. La lettura deve partire da Inattiva verso Lettura del contesto, provare prima l'Accessibilità e, se l'app non espone il testo visibile, passare al riconoscimento del testo sullo schermo. Deve emettere lettura-schermo.CONTESTO_LETTO con app, finestra, documento e testo verso la mini-chat, oppure lettura-schermo.LETTURA_FALLITA se il permesso di registrazione manca o il riconoscimento non riesce. Oggi la mini-chat riceve il contesto da un'interfaccia ScreenReading che nessuna parte dell'app implementa, e ScreenReader non viene mai creato.
