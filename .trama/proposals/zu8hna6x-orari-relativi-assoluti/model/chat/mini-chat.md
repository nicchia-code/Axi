# Mini-chat

La piccola chat che scende dal puntino nella barra dei menu. Resta aperta mentre l'utente usa le altre app, finché non la chiude.

## States

### Chiusa (initial)
- `utente.APRE_CHAT` → Aperta: se OMP è pronto; la chat scende dal puntino e Axi legge lo schermo.
- `utente.APRE_CHAT` → Chiusa: se OMP non è pronto; la chat non si apre e il puntino spiega perché.

### Aperta
Mostra l'ultima conversazione, o una vuota se non ce ne sono.
- `utente.CHIUDE_CHAT` → Chiusa: la conversazione resta salvata; una risposta in corso viene interrotta.

#### In preparazione (initial)
La chat aspetta il contesto dello schermo.
- `lettura-schermo.CONTESTO_LETTO` → Pronta: il contesto (app e documento a schermo) compare nella chat come elemento che l'utente può togliere, e accompagna le domande finché resta.
- `lettura-schermo.LETTURA_FALLITA` → Pronta: la chat dice che non ha potuto leggere lo schermo e risponde solo sul vault; se è mancato un permesso, lo nomina e offre di aprire la finestra dei permessi.

#### Pronta
- `utente.INVIA_DOMANDA` → In risposta
- `utente.RIMUOVE_CONTESTO` → Pronta: il contesto dello schermo non accompagna più le domande.
- `utente.NUOVA_CONVERSAZIONE` → Pronta: inizia una conversazione vuota; quella precedente resta salvata.
- `utente.APRE_ELENCO_CONVERSAZIONI` → Elenco delle conversazioni
- `utente.APRE_DOCUMENTO_CITATO` → Pronta: Axi apre la copia del vault nell'app predefinita, alla pagina citata quando possibile.

#### In risposta
OMP cerca nel vault, legge le pagine che gli servono e scrive la risposta man mano, citando i documenti usati. La domanda e la risposta entrano nella conversazione salvata.
OMP conosce la data e l'ora della domanda, il momento in cui è stato letto lo schermo e le date dei documenti che trova (archiviazione, documento o ricezione, date citate), e può cercare nel vault anche per queste date. Rende assoluti gli orari relativi che incontra: quelli del testo a schermo rispetto al momento della lettura, quelli di un documento rispetto alla sua data di ricezione o del documento. Nella risposta una data che nella fonte era relativa è scritta in forma assoluta, con la forma relativa tra parentesi («lunedì 20 ottobre alle 15:00 (domani)»).
- `omp.RISPOSTA_COMPLETATA` → Pronta
- `omp.RISPOSTA_FALLITA` → Pronta: la chat mostra l'errore e permette di inviare di nuovo la domanda.
- `omp.TERMINATO` → Pronta: la chat dice che OMP si è fermato.
- `utente.INTERROMPE_RISPOSTA` → Pronta: la risposta resta come scritta fino a quel momento.
- `omp.ELIMINAZIONE_RICHIESTA` → Conferma dell'eliminazione
- `utente.APRE_DOCUMENTO_CITATO` → In risposta: Axi apre la copia del vault del documento citato.

#### Conferma dell'eliminazione
La chat mostra il documento da eliminare, con gli allegati collegati che sparirebbero con lui, e chiede conferma.
- `utente.CONFERMA_ELIMINAZIONE` → In risposta: il documento viene eliminato e OMP lo sa.
- `utente.ANNULLA_ELIMINAZIONE` → In risposta: nulla viene eliminato e OMP sa che l'utente ha rifiutato.

#### Elenco delle conversazioni
Le conversazioni salvate, dalla più recente.
- `utente.RIAPRE_CONVERSAZIONE` → Pronta: la conversazione scelta torna con tutti i suoi messaggi.
- `utente.ELIMINA_CONVERSAZIONE` → Elenco delle conversazioni: la conversazione sparisce.
- `utente.CHIUDE_ELENCO_CONVERSAZIONI` → Pronta

## Events

### APERTA
Emesso quando la chat si apre.

### CHIUSA
Emesso quando la chat si chiude.

### NON_DISPONIBILE
Emesso quando l'utente chiede la chat ma OMP non è pronto.
