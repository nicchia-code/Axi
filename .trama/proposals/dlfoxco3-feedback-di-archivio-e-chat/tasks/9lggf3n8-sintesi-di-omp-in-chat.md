---
refs:
  - mini-chat/In risposta
  - mini-chat/Elenco delle conversazioni/utente.RIAPRE_CONVERSAZIONE
  - requirements/ui#mini-chat/In risposta
  - requirements/tech#mini-chat
  - requirements/data#mini-chat
  - "mini-chat/Pronta/utente.INVIA_DOMANDA"
  - "mini-chat/Conferma dell'eliminazione/utente.CONFERMA_ELIMINAZIONE"
  - "mini-chat/Conferma dell'eliminazione/utente.ANNULLA_ELIMINAZIONE"
---
# Sintesi di OMP in chat

Mentre la chat è in In risposta, la bolla della risposta mostra in cima una sintesi di ciò che OMP sta facendo.

- Appena la domanda è inviata compaiono tre puntini animati nella bolla di Axi, sostituiti dal primo passo o dal primo testo.
- I passi compaiono uno per riga, man mano: ricerche nel vault con le parole cercate, pagine lette e di quale documento, documenti citati, tag cambiati, eliminazione chiesta, nuovi tentativi di OMP quando il provider non risponde (con tentativo e massimo) e riassunto della conversazione; il passo in corso finisce con i tre puntini animati. Le fonti sono gli eventi RPC di `requirements/tech#mini-chat`.
- Sotto i passi, quando il modello ragiona, una riga in corsivo con l'ultima frase del ragionamento, così come il modello la scrive, aggiornata man mano; il ragionamento oscurato non si mostra.
- All'avvio della sessione OMP della chat Axi imposta il livello di ragionamento `low` se il modello lo offre; le richieste dell'archiviazione non cambiano livello.
- Quando la risposta finisce (`omp.RISPOSTA_COMPLETATA`, `omp.RISPOSTA_FALLITA`, `omp.TERMINATO`, `utente.INTERROMPE_RISPOSTA`), la sintesi si richiude in una riga («Ha cercato N volte e letto M pagine» e varianti) che un clic apre e richiude; senza passi né ragionamento la riga non c'è.
- La sintesi non si salva: chiusa la chat, o riaprendo una conversazione (`utente.RIAPRE_CONVERSAZIONE`), restano solo le risposte.
- Testi, stile e posizione sono quelli di `requirements/ui#mini-chat/In risposta`.
