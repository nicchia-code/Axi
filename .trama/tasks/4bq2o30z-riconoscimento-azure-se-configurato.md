---
column: done
technical: false
refs:
  - lettura-schermo/Riconoscimento del testo
  - requirements/tech#lettura-schermo
drift: null
proposal: null
agent: false
created: 2026-10-18T18:40:32.092Z
finished: 2026-10-18T19:09:40.307Z
---
# Riconoscimento Azure se configurato

Il riconoscimento del testo della finestra deve usare Azure Document Intelligence (modello prebuilt-read) quando l'utente lo ha configurato nelle impostazioni, e Vision in italiano e inglese sul Mac altrimenti. Oggi il recognizer Azure esiste nel pacchetto AxiScreen, ma nessun codice sceglie tra Azure e Vision in base alle impostazioni: la scelta richiesta dal Model e dai Requirements non è implementata.
