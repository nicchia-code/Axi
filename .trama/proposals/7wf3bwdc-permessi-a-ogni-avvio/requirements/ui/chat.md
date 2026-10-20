---
description: Use when building the mini-chat, its messages, citations, conversation list or deletion confirmation.
---
# Mini-chat

## mini-chat
- La chat nasce dal puntino con un'animazione di espansione e torna puntino con l'animazione inversa, nella stessa posizione.
- Dimensione iniziale circa 380 × 520 pt, ridimensionabile; si apre verso il centro dello schermo per restare interamente visibile.
- In alto: titolo della conversazione e pulsanti Nuova conversazione, Conversazioni e Chiudi.
- Il contesto dello schermo compare sopra il campo di testo come etichetta con icona dell'app e titolo del documento o della finestra, con una ✕ per toglierlo.
- Le risposte arrivano man mano e sono formattate in Markdown.
- Ogni documento citato è un'etichetta cliccabile con titolo e pagina.
- Durante una risposta il pulsante di invio diventa Stop.
- Gli errori compaiono come messaggio nella conversazione, con il pulsante Riprova quando ha senso.

## mini-chat/In preparazione
- Quando la lettura dello schermo fallisce per un permesso mancante, il messaggio nella conversazione lo nomina (italiano / inglese). Se manca solo Accessibility la lettura non fallisce, perché passa al riconoscimento del testo:
  - Manca Registrazione schermo: «Non ho potuto leggere lo schermo: manca il permesso Registrazione schermo. Rispondo solo sul vault.» / «I couldn't read the screen: the Screen Recording permission is missing. I'll answer from the vault only.»
  - Mancano entrambi: «Non ho potuto leggere lo schermo: mancano i permessi Accessibility e Registrazione schermo. Rispondo solo sul vault.» / «I couldn't read the screen: the Accessibility and Screen Recording permissions are missing. I'll answer from the vault only.»
- Sotto il messaggio, il pulsante «Apri i permessi» / «Open permissions» apre la finestra dei permessi.

## mini-chat/Conferma dell'eliminazione
- Una scheda nella conversazione mostra titolo, tipo, data di archiviazione e allegati collegati che spariranno, con i pulsanti Elimina (stile distruttivo) e Annulla.

## mini-chat/Elenco delle conversazioni
- Elenco dalla più recente, con titolo e data dell'ultimo messaggio; ogni riga ha un'azione per eliminarla.
- Il titolo di una conversazione è la sua prima domanda, accorciata.
