# Archiviazione

Il lavoro che porta un documento dalla coda al vault: copia, controllo dei duplicati, estrazione del testo, metadati generati dall'AI e indicizzazione. Lavora su un documento alla volta. Un documento entra nel vault solo se tutti i passi riescono; in ogni altro caso nel vault non resta nulla di quel documento.

## States

### Inattiva (initial)
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → In lavorazione: se OMP è pronto e il benvenuto è completato.
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → Inattiva: se OMP non è pronto o il benvenuto non è completato; il documento non viene archiviato e l'esito spiega cosa manca.

### In lavorazione
- `omp.TERMINATO` → Inattiva: il documento non viene archiviato e l'esito spiega che OMP si è fermato.
- `ERRORE_IMPREVISTO` → Inattiva: Axi resta aperto, il documento non viene archiviato, nel vault non resta nulla di esso e l'esito dice che c'è stato un errore imprevisto.

#### Acquisizione (initial)
Axi fa la sua copia del documento:
- un file viene copiato così com'è;
- un'email di Outlook diventa un documento con mittente, destinatari, oggetto, data di ricezione e testo; i suoi allegati vengono presi con Accessibility e diventano documenti collegati all'email; gli allegati che non si riescono a prendere sono annotati per l'esito, e l'utente può aggiungerli trascinandoli sul puntino nella barra dei menu o aprendoli e chiedendo l'archiviazione;
- la data di ricezione di un'email di Outlook è quella mostrata a schermo, anche relativa («2 ore fa», «ieri alle 14:30»): Axi la conserva com'era scritta e chiede a OMP di renderla assoluta rispetto al momento in cui ha letto lo schermo. Se OMP non la capisce o non risponde, l'email prosegue senza data di ricezione, che nessuno inventa, e l'esito lo dice;
- una pagina web viene riaperta dal suo indirizzo e salvata come PDF; se il PDF non si riesce a creare (la pagina non si carica, il suo caricamento si interrompe o richiede troppo tempo) o non corrisponde a ciò che l'utente legge nella pagina (per esempio una pagina dietro login), Axi conserva solo il testo letto a schermo e l'indirizzo, e lo dice nell'esito.
Un file che è un allegato di un'email presente nel vault o ancora a schermo in Outlook viene collegato a quell'email. Un'email a schermo con il corpo vuoto non viene usata: il file viene archiviato da solo, senza email collegata.
- `ACQUISITO` → Controllo dei duplicati
- `ACQUISIZIONE_FALLITA` → Inattiva: il documento non si può leggere o copiare; l'esito spiega perché.

#### Controllo dei duplicati
Axi confronta l'impronta del contenuto con quelle dei documenti nel vault. L'impronta di un'email tiene conto del giorno in cui è stata ricevuta, quando è noto, così che la stessa email riarchiviata più tardi venga riconosciuta.
- `GIA_PRESENTE` → Inattiva: lo stesso contenuto è già nel vault; non viene creata una copia nuova e l'esito indica il documento già presente.
- `CONTENUTO_NUOVO` → Estrazione del testo

#### Estrazione del testo
Axi estrae il testo di tutte le pagine; un documento Word o RTF, che non ha pagine proprie, dà una sola pagina con tutto il suo testo. Le pagine senza testo (scansioni, immagini) vengono riconosciute con Azure Document Intelligence se è configurato, altrimenti sul Mac.
- `TESTO_ESTRATTO` → Generazione dei metadati
- `ESTRAZIONE_FALLITA` → Inattiva: dal documento non si ricava testo; l'esito lo spiega.

#### Generazione dei metadati
Axi chiede a OMP titolo, riassunto, tag, data del documento, lingua e le date citate. I tag riusano quelli già presenti nel vault e ne creano di nuovi solo se nessuno è adatto; riassunto e tag sono nella lingua dell'interfaccia. Un documento grande viene inviato a sezioni.
Le date citate sono gli eventi, le scadenze e gli appuntamenti di cui parla il documento, scritti in forma assoluta o relativa: ciascuna diventa una data assoluta, con l'ora quando il testo la dice, insieme a ciò di cui si tratta e alle parole originali. Le date relative si risolvono rispetto alla data di ricezione per un'email, alla data del documento per gli altri documenti se il testo la dice, altrimenti al momento dell'archiviazione. In un'email la cui data di ricezione è rimasta sconosciuta le date relative non si risolvono: entrano solo con ciò di cui si tratta e le parole originali. Un'espressione ambigua («venerdì») diventa l'interpretazione più probabile, e le parole originali restano accanto per verificarla. Anche il riassunto scrive le date in forma assoluta, quando le può risolvere.
- `omp.METADATI_GENERATI` → Indicizzazione
- `omp.METADATI_FALLITI` → Inattiva: il documento non viene archiviato; l'esito spiega che l'AI non ha risposto.

#### Indicizzazione
Axi rende il documento ricercabile per parole e per significato.
- `INDICIZZATO` → Inattiva: il documento, con i suoi allegati collegati, è nel vault.
- `INDICIZZAZIONE_FALLITA` → Inattiva: il documento non viene archiviato; l'esito lo spiega.

## Events

### ARCHIVIATO
Emesso quando un documento entra nel vault, con il suo titolo, i tag, gli eventuali allegati non presi e, per un'email, se la sua data di ricezione è rimasta sconosciuta.

### NON_ARCHIVIATO
Emesso a ogni ritorno in Inattiva senza un documento archiviato, con il motivo: già presente, OMP non pronto o fermato, benvenuto non completato, documento illeggibile, testo assente, AI o indicizzazione non riuscite, errore imprevisto.

### ERRORE_IMPREVISTO
Emesso quando un passo dell'archiviazione si interrompe per un errore non previsto da nessun altro esito.

### ACQUISITO
Emesso quando la copia del documento è pronta.

### ACQUISIZIONE_FALLITA
Emesso quando il documento non si riesce a leggere o copiare.

### GIA_PRESENTE
Emesso quando il contenuto è già nel vault.

### CONTENUTO_NUOVO
Emesso quando il contenuto non è nel vault.

### TESTO_ESTRATTO
Emesso quando il testo di tutte le pagine è pronto.

### ESTRAZIONE_FALLITA
Emesso quando dal documento non si ricava testo.

### INDICIZZATO
Emesso quando il documento è ricercabile.

### INDICIZZAZIONE_FALLITA
Emesso quando l'indicizzazione non riesce.
