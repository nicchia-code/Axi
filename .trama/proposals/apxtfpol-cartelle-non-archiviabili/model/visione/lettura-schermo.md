# Lettura dello schermo

Una lettura di ciò che c'è a schermo, fatta nel momento in cui l'utente chiede un'archiviazione o la chat, e riferita all'app che era in primo piano al momento della richiesta, prima che Axi prendesse il fuoco. Per un'archiviazione, se in quel momento in primo piano c'è Axi stesso (per esempio le sue impostazioni), la lettura riguarda l'ultima altra app che è stata in primo piano, se è ancora aperta. Una richiesta che arriva mentre è in corso un'altra lettura viene servita appena quella finisce. Ogni lettura annota il momento in cui è stata fatta, perché gli orari relativi a schermo («2 ore fa», «domani») si possano rendere assoluti.

## States

### Inattiva (initial)
- `utente.CHIEDE_ARCHIVIAZIONE` → Ricerca del documento
- `utente.APRE_CHAT` → Lettura del contesto

### Ricerca del documento
Con Accessibility Axi cerca in primo piano un documento archiviabile: il file aperto in un'app come Anteprima, Word, Pages o Acrobat; i file selezionati nel Finder, anche sulla Scrivania, ciascuno come documento a sé e senza le cartelle; l'email aperta o selezionata in Outlook, con i suoi allegati; la pagina web aperta in Safari, Chrome o Firefox, con il suo indirizzo, che può essere anche quella di un PDF mostrato dal browser. Di una pagina web Axi legge prima l'area della pagina, con il suo indirizzo e il suo testo, e solo se lì manca l'indirizzo lo legge dalla barra degli indirizzi; Safari e Chrome, quando Accessibility non basta, gli danno l'indirizzo anche tramite l'Automazione, Firefox no. Se l'indirizzo è quello di un file sul Mac, qualunque sia il suo formato, il browser lo sta solo mostrando: Axi lo tratta come un file aperto in qualsiasi altra app, non come una pagina web. Allo stesso modo il Finder, quando Accessibility non basta, gli dà la selezione tramite l'Automazione. Una cartella non è mai un documento: se un'app in primo piano, per esempio Terminal con la sua cartella di lavoro, o un browser con l'indirizzo di una cartella del Mac, indica una cartella invece di un file, Axi non la tratta come un file aperto.
- `DOCUMENTO_INDIVIDUATO` → Inattiva
- `NESSUN_DOCUMENTO` → Inattiva: in primo piano non c'è né un file aperto, né un file selezionato nel Finder, né un'email di Outlook, né una pagina web; oppure l'app in primo piano indica una cartella invece di un file; oppure in primo piano c'è Axi e non c'è un'altra app usata prima o è stata chiusa; il motivo è «nessun documento».
- `NESSUN_DOCUMENTO` → Inattiva: in primo piano c'è una pagina web ma il suo indirizzo non si riesce a leggere; il motivo è «indirizzo non leggibile».
- `NESSUN_DOCUMENTO` → Inattiva: manca il permesso Accessibility, oppure per una pagina di Safari o Chrome o per la selezione del Finder serve l'Automazione e manca il suo permesso; il motivo è il permesso mancante, nominato.
- `NESSUN_DOCUMENTO` → Inattiva: la ricerca si interrompe per un errore non previsto; Axi resta aperto e il motivo è «errore imprevisto».

### Lettura del contesto

#### Accessibilità (initial)
Axi legge con Accessibility l'app, la finestra, il documento e il testo visibile.
- `CONTESTO_LETTO` → Inattiva: Accessibility ha dato il testo visibile.
- `TESTO_NON_ACCESSIBILE` → Riconoscimento del testo: l'app non espone il testo visibile, oppure manca il permesso Accessibility.

#### Riconoscimento del testo
Axi cattura la finestra e ne riconosce il testo: con Azure Document Intelligence se è configurato, altrimenti sul Mac.
- `CONTESTO_LETTO` → Inattiva
- `LETTURA_FALLITA` → Inattiva: manca il permesso Registrazione schermo, e il motivo nomina i permessi mancanti (anche Accessibility, se manca anch'esso); oppure il riconoscimento non è riuscito.

## Events

### DOCUMENTO_INDIVIDUATO
Emesso quando la ricerca trova un documento archiviabile; porta con sé di quale documento si tratta, da dove viene e il momento della lettura; per un'email di Outlook anche la data di ricezione così come è mostrata; per una selezione del Finder porta tutti i file selezionati, nell'ordine della selezione.

### NESSUN_DOCUMENTO
Emesso quando la ricerca non trova un documento archiviabile; porta con sé il motivo: nessun documento, indirizzo non leggibile, permesso mancante (quale) o errore imprevisto.

### CONTESTO_LETTO
Emesso quando il contesto per la chat è pronto: app, finestra, documento se c'è, testo visibile e momento della lettura.

### TESTO_NON_ACCESSIBILE
Emesso quando Accessibility non dà il testo visibile della finestra.

### LETTURA_FALLITA
Emesso quando non è stato possibile leggere il testo visibile in nessun modo; porta con sé il motivo: i permessi mancanti (quali) o il riconoscimento non riuscito.
