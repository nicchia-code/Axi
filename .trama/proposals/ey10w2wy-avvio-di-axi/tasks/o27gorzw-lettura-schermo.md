---
refs:
  - "visione"
  - "lettura-schermo"
  - "requirements/tech#lettura-schermo"
  - "specs#cloud"
---
# Lettura dello schermo

La lettura, su richiesta, di ciò che l'utente ha a schermo, per archiviare e per la chat.

Quando il Task è fatto:
- la lettura riguarda sempre l'app che era in primo piano nel momento della richiesta, prima che Axi prendesse il fuoco; una richiesta che arriva durante un'altra lettura viene servita appena quella finisce;
- da Inattiva, `utente.CHIEDE_ARCHIVIAZIONE` porta a Ricerca del documento: con Accessibility Axi individua il file aperto (Anteprima, Word, Pages, Acrobat e simili), l'email aperta o selezionata nel nuovo Outlook con mittente, destinatari, oggetto, data, corpo e nomi degli allegati, o la pagina web aperta in Safari, Chrome o Firefox con il suo indirizzo e il testo visibile; emette `DOCUMENTO_INDIVIDUATO` con questi dati, oppure `NESSUN_DOCUMENTO` se non c'è nulla di archiviabile o manca il permesso, tornando in Inattiva;
- da Inattiva, `utente.APRE_CHAT` porta a Lettura del contesto/Accessibilità: Axi legge app, finestra, documento e testo visibile; se ci riesce emette `CONTESTO_LETTO`, altrimenti `TESTO_NON_ACCESSIBILE` e passa a Riconoscimento del testo;
- in Riconoscimento del testo Axi cattura la finestra e ne riconosce il testo con Azure Document Intelligence se configurato, altrimenti con Vision sul Mac; emette `CONTESTO_LETTO`, o `LETTURA_FALLITA` se manca il permesso di registrazione dello schermo o il riconoscimento non riesce;
- il client di Azure Document Intelligence (modello `prebuilt-read`) è condiviso con l'estrazione del testo dell'archiviazione e usa endpoint e chiave delle impostazioni;
- Axi non legge mai lo schermo senza una richiesta dell'utente;
- le parti che non richiedono permessi (interpretazione dei risultati di Accessibility, scelta del documento, client Azure) sono testate con dati d'esempio.
