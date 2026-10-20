---
description: Use when building the mini-chat, its messages, citations, conversation list or deletion confirmation.
---
# Mini-chat

## mini-chat
- Con il puntino visibile la chat è un pannello accanto al personaggio, dal lato con più spazio, interamente sullo schermo: si apre dal personaggio con un'animazione e vi si richiude con l'animazione inversa.
- Con il puntino nascosto la chat è un pannello ancorato sotto l'icona della barra dei menu, sullo schermo attivo: scende dall'icona con un'animazione e vi risale con l'animazione inversa quando si chiude. Se la barra dei menu è nascosta (per esempio in un'app a schermo intero) la chat si apre comunque in alto sullo schermo attivo, sotto il punto dell'icona, sopra l'app a schermo intero.
- Quando il puntino si nasconde o riappare con la chat aperta, la chat resta aperta con la sua conversazione e si sposta con un'animazione sotto l'icona della barra o accanto al personaggio.
- Dimensione iniziale circa 380 × 520 pt, ridimensionabile; resta interamente visibile sullo schermo, anche quando la si ridimensiona.
- Resta aperta quando l'utente fa clic su un'altra app; si chiude con il pulsante Chiudi, con Esc, con la scorciatoia o il tasto della chat, o con un clic sul personaggio o sulla sua icona nella barra.
- In alto: titolo della conversazione e pulsanti Nuova conversazione, Conversazioni e Chiudi.
- Il contesto dello schermo compare sopra il campo di testo come etichetta con icona dell'app e titolo del documento o della finestra, con una ✕ per toglierlo.
- Le risposte arrivano man mano e sono formattate in Markdown.
- Quando OMP ricomincia a scrivere nella stessa risposta, la bolla sostituisce il suo testo con il nuovo, senza svuotarsi prima dell'arrivo del nuovo testo; le etichette dei documenti citati restano.
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
