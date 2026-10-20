# Lettura dello schermo

Una lettura di ciò che c'è a schermo, fatta nel momento in cui l'utente chiede un'archiviazione o la chat, e riferita all'app che era in primo piano prima che Axi prendesse il fuoco. Una richiesta che arriva mentre è in corso un'altra lettura viene servita appena quella finisce.

## States

### Inattiva (initial)
- `utente.CHIEDE_ARCHIVIAZIONE` → Ricerca del documento
- `utente.APRE_CHAT` → Lettura del contesto

### Ricerca del documento
Con Accessibility Axi cerca in primo piano un documento archiviabile: il file aperto in un'app come Anteprima, Word, Pages o Acrobat; l'email aperta o selezionata in Outlook, con i suoi allegati; la pagina web aperta in Safari, Chrome o Firefox, con il suo indirizzo.
- `DOCUMENTO_INDIVIDUATO` → Inattiva
- `NESSUN_DOCUMENTO` → Inattiva: in primo piano non c'è né un file, né un'email di Outlook, né una pagina web, oppure manca il permesso per leggere lo schermo.

### Lettura del contesto

#### Accessibilità (initial)
Axi legge con Accessibility l'app, la finestra, il documento e il testo visibile.
- `CONTESTO_LETTO` → Inattiva: Accessibility ha dato il testo visibile.
- `TESTO_NON_ACCESSIBILE` → Riconoscimento del testo: l'app non espone il testo visibile.

#### Riconoscimento del testo
Axi cattura la finestra e ne riconosce il testo: con Azure Document Intelligence se è configurato, altrimenti sul Mac.
- `CONTESTO_LETTO` → Inattiva
- `LETTURA_FALLITA` → Inattiva: manca il permesso di registrazione dello schermo o il riconoscimento non è riuscito.

## Events

### DOCUMENTO_INDIVIDUATO
Emesso quando la ricerca trova un documento archiviabile; porta con sé di quale documento si tratta e da dove viene.

### NESSUN_DOCUMENTO
Emesso quando la ricerca non trova un documento archiviabile.

### CONTESTO_LETTO
Emesso quando il contesto per la chat è pronto: app, finestra, documento se c'è, e testo visibile.

### TESTO_NON_ACCESSIBILE
Emesso quando Accessibility non dà il testo visibile della finestra.

### LETTURA_FALLITA
Emesso quando non è stato possibile leggere il testo visibile in nessun modo.
