---
refs:
  - mini-chat/In preparazione/lettura-schermo.CONTESTO_LETTO
  - mini-chat/Pronta/utente.INVIA_DOMANDA
  - mini-chat/In risposta
  - mini-chat/Conferma dell'eliminazione/utente.CONFERMA_ELIMINAZIONE
  - mini-chat/Conferma dell'eliminazione/utente.ANNULLA_ELIMINAZIONE
  - requirements/data#mini-chat
  - requirements/rules#mini-chat
---
# Data e ora alla chat

Quando la Mini-chat riceve `lettura-schermo.CONTESTO_LETTO` in In preparazione, il contesto dello schermo (app e documento a schermo) porta con sé il momento in cui è stato letto, e lo conserva finché accompagna le domande. Oggi `ScreenContext` non ha alcun timestamp di lettura: va aggiunto e valorizzato al momento della lettura, non all'apertura della chat né all'invio.

Con `utente.INVIA_DOMANDA` da Pronta a In risposta, a ogni domanda OMP riceve data, ora e fuso correnti del Mac; se il contesto dello schermo accompagna la domanda, porta il momento della sua lettura. Le istruzioni di OMP dicono che:
- gli orari relativi del testo a schermo si risolvono rispetto al momento della lettura dello schermo, non a quello della domanda;
- gli orari relativi di un documento si risolvono rispetto alla sua data di ricezione o del documento;
- nella risposta una data che nella fonte era relativa si scrive in forma assoluta seguita dalla forma relativa tra parentesi, rispetto al momento della domanda: «lunedì 20 ottobre alle 15:00 (domani)»;
- restano valide le regole esistenti: ogni risposta cita documenti e pagine, e senza fonti nel vault lo dice.

Anche quando la chat torna In risposta da Conferma dell'eliminazione, con `utente.CONFERMA_ELIMINAZIONE` (il documento viene eliminato e OMP lo sa) o con `utente.ANNULLA_ELIMINAZIONE` (nulla viene eliminato e OMP sa che l'utente ha rifiutato), OMP continua a rispondere con lo stesso riferimento di data e ora e con le stesse regole sulle date.

Ogni messaggio salvato della conversazione conserva, oltre ad autore, testo, data e documenti citati con la pagina, il contesto dello schermo usato se c'era insieme al momento della sua lettura.
