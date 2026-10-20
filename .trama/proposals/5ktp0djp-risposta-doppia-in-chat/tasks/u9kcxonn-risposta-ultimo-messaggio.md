---
refs:
  - mini-chat/In risposta
  - mini-chat/Pronta/utente.INVIA_DOMANDA
  - mini-chat/Conferma dell'eliminazione/utente.CONFERMA_ELIMINAZIONE
  - mini-chat/Conferma dell'eliminazione/utente.ANNULLA_ELIMINAZIONE
  - requirements/rules#mini-chat
  - requirements/tech#mini-chat
  - requirements/ui#mini-chat
---
# Risposta senza doppioni

Quando il Task è finito, in `mini-chat/In risposta`:

- OMP può scrivere in più riprese nella stessa risposta, per esempio prima e dopo aver usato uno strumento: la risposta è solo l'ultima ripresa che contiene testo. Quando OMP ricomincia a scrivere, la chat riparte dal nuovo testo e quello precedente sparisce; finché il nuovo testo non arriva, resta quello precedente. Un messaggio di OMP senza testo (solo chiamate a strumenti) non cambia la risposta.
- La risposta salvata nella conversazione è quella che la chat mostra alla fine, anche con `utente.INTERROMPE_RISPOSTA` (la risposta resta come scritta fino a quel momento), `omp.RISPOSTA_FALLITA` e `omp.TERMINATO`.
- La bolla sostituisce il suo testo con quello nuovo senza svuotarsi prima che arrivi; le etichette dei documenti citati restano.
- Le istruzioni a OMP e la descrizione dello strumento `cite_documents` chiedono di dichiarare i documenti e le pagine citati prima di scrivere la risposta, e di non scrivere nulla dopo la risposta; senza fonti nel vault la risposta lo dice senza citare.
- Lo streaming distingue i messaggi dell'assistente di OMP tramite gli eventi di inizio e fine messaggio del protocollo RPC: il primo `text_delta` di un nuovo messaggio sostituisce il testo mostrato invece di accodarsi.
- Le risposte già salvate con il testo doppio restano come sono: nessuna migrazione.

Un test copre una risposta con testo, chiamata a `cite_documents` e di nuovo testo, e verifica che la conversazione salvata contenga una sola volta la risposta; un altro copre un ultimo messaggio fatto solo di una chiamata a strumento, che non svuota la risposta.
