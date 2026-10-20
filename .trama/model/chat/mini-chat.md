# Mini-chat

La piccola chat che si apre accanto al puntino, o sotto la sua icona nella barra dei menu quando il puntino è nascosto. Resta aperta mentre l'utente usa le altre app, finché non la chiude; se il puntino si nasconde o riappare, la chat resta aperta e lo segue.

## States

### Chiusa (initial)
- `utente.APRE_CHAT` → Aperta: se OMP è pronto; la chat si apre dal puntino e Axi legge lo schermo.
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
OMP può scrivere in più riprese nella stessa risposta, per esempio prima e dopo aver usato uno strumento: la risposta è solo l'ultima ripresa che contiene testo. Quando OMP ricomincia a scrivere, la chat riparte dal nuovo testo e quello precedente sparisce; finché il nuovo testo non arriva, resta quello precedente. La risposta salvata è quella che la chat mostra alla fine.
OMP conosce la data e l'ora della domanda, il momento in cui è stato letto lo schermo e le date dei documenti che trova (archiviazione, documento o ricezione, date citate), e può cercare nel vault anche per queste date. Rende assoluti gli orari relativi che incontra: quelli del testo a schermo rispetto al momento della lettura, quelli di un documento rispetto alla sua data di ricezione o del documento. Nella risposta una data che nella fonte era relativa è scritta in forma assoluta, con la forma relativa tra parentesi («lunedì 20 ottobre alle 15:00 (domani)»).
Mentre OMP lavora, la risposta mostra in cima una sintesi di ciò che sta facendo. Appena la domanda è inviata compaiono tre puntini animati, finché non arriva il primo passo o il primo testo. Poi la sintesi elenca i passi man mano che OMP li compie: le ricerche nel vault con le parole cercate, le pagine lette e di quale documento, i documenti citati, i tag cambiati, l'eliminazione chiesta, i nuovi tentativi di OMP quando il provider non risponde e il riassunto della conversazione quando diventa troppo lunga; sotto i passi, quando il modello ragiona, l'ultima frase del suo ragionamento, così come il modello la scrive. Per la chat Axi chiede a OMP un ragionamento breve, se il modello scelto lo permette. Quando la risposta finisce, in qualunque modo, la sintesi si richiude in una riga che riassume i passi e che l'utente può riaprire per rileggere passi e ragionamento. La sintesi non entra nella conversazione salvata: resta solo finché la chat è aperta.
- `omp.RISPOSTA_COMPLETATA` → Pronta: la sintesi si richiude in una riga.
- `omp.RISPOSTA_FALLITA` → Pronta: la sintesi si richiude in una riga; la chat mostra l'errore e permette di inviare di nuovo la domanda.
- `omp.TERMINATO` → Pronta: la sintesi si richiude in una riga; la chat dice che OMP si è fermato.
- `utente.INTERROMPE_RISPOSTA` → Pronta: la sintesi si richiude in una riga; la risposta resta come scritta fino a quel momento.
- `omp.ELIMINAZIONE_RICHIESTA` → Conferma dell'eliminazione
- `utente.APRE_DOCUMENTO_CITATO` → In risposta: Axi apre la copia del vault del documento citato.

#### Conferma dell'eliminazione
La chat mostra il documento da eliminare, con gli allegati collegati che sparirebbero con lui, e chiede conferma.
- `utente.CONFERMA_ELIMINAZIONE` → In risposta: il documento viene eliminato e OMP lo sa.
- `utente.ANNULLA_ELIMINAZIONE` → In risposta: nulla viene eliminato e OMP sa che l'utente ha rifiutato.

#### Elenco delle conversazioni
Le conversazioni salvate, dalla più recente.
- `utente.RIAPRE_CONVERSAZIONE` → Pronta: la conversazione scelta torna con tutti i suoi messaggi, senza le sintesi di ciò che OMP ha fatto.
- `utente.ELIMINA_CONVERSAZIONE` → Elenco delle conversazioni: la conversazione sparisce.
- `utente.CHIUDE_ELENCO_CONVERSAZIONI` → Pronta

## Events

### APERTA
Emesso quando la chat si apre.

### CHIUSA
Emesso quando la chat si chiude.

### NON_DISPONIBILE
Emesso quando l'utente chiede la chat ma OMP non è pronto.
