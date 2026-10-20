---
description: Use when reading the screen, acquiring documents, extracting text, indexing, searching or deleting in the vault.
---
# Schermo, documenti e ricerca

## lettura-schermo
- L'app in primo piano si memorizza nel momento della richiesta (apertura del menu del puntino, scorciatoia o tasto), prima che Axi prenda il fuoco, e la lettura riguarda quella.
- Axi tiene traccia dell'ultima app diversa da sé che è stata in primo piano (`NSWorkspace.didActivateApplicationNotification`). Per un'archiviazione chiesta mentre in primo piano c'è Axi si usa quella, se è ancora in esecuzione; altrimenti il rifiuto è «nessun documento».
- Accessibility (`AXUIElement`) per app, finestra principale, `AXDocument` (file aperto), indirizzo della pagina nei browser (Safari, Chrome, Firefox) e testo visibile.
- Pagine web: prima si cerca l'area della pagina (`AXWebArea`) e se ne leggono l'indirizzo (`AXURL`, poi `AXDocument`) e il testo; solo se lì manca l'indirizzo lo si legge dalla barra degli indirizzi del browser. Il percorso dell'albero si ferma a profondità 40 e 5.000 elementi.
- Un indirizzo `file://` letto in Safari, Chrome o Firefox dà un file aperto, come l'`AXDocument` delle altre app, e segue la stessa strada dei file; non è una pagina web. Una pagina web ha un indirizzo `http` o `https`.
- Un `AXDocument` (o `AXURL`) di finestra, o un indirizzo `file://` di un browser, che indica una cartella (`URLResourceValues.isDirectory`) non è un file aperto: il rifiuto è «nessun documento», come per le cartelle del Finder. Il controllo avviene nella ricerca del documento, prima che il documento vada in coda.
- Firefox: prima della lettura si attiva la sua Accessibility completa impostando `AXEnhancedUserInterface` sull'elemento dell'app (Firefox non accetta `AXManualAccessibility`); al termine della lettura si ripristina il valore precedente, perché l'attributo disturba il posizionamento delle finestre. Il comportamento si verifica su un Firefox reale.
- Finder: i file selezionati si leggono con Accessibility (elementi selezionati della finestra in primo piano o della Scrivania e il loro URL di file); se Accessibility non dà la selezione, con l'Automazione (Apple Events, `selection` del Finder). Le cartelle si scartano; senza file selezionati il rifiuto è «nessun documento». Il comportamento si verifica su un Finder reale, nelle viste a icone, elenco e colonne e sulla Scrivania.
- Outlook (nuovo Outlook per Mac): lettura via Accessibility del messaggio aperto o selezionato (mittente, destinatari, oggetto, data così come è mostrata, corpo, nomi degli allegati). Nessun AppleScript, che il nuovo Outlook non supporta.
- Ogni lettura registra il proprio istante e il fuso del Mac (`TimeZone.current`) e li passa con il documento individuato e con il contesto per la chat.
- Automazione (Apple Events) solo dove Accessibility non basta, e solo per Safari, Chrome e Finder; Firefox non la offre per l'indirizzo della pagina.
- Log con `os.Logger`, subsystem `Axi`, categoria `lettura-schermo`.
- Cattura della finestra con ScreenCaptureKit; riconoscimento del testo con Vision in italiano e inglese, oppure con Azure Document Intelligence (modello `prebuilt-read`) se configurato.

## archiviazione
- Testo: PDFKit per i PDF; `NSAttributedString` per DOCX, DOC, RTF; parser per EML; Vision o Azure Document Intelligence per immagini e pagine PDF senza testo. Il testo si conserva pagina per pagina; DOCX, DOC e RTF, che non hanno pagine proprie, si conservano come una sola pagina con tutto il testo.
- Allegati di Outlook: tentativo via Accessibility (azioni di salvataggio dell'allegato); quelli non riusciti si registrano come mancanti, con il nome.
- PDF delle pagine web: prima del caricamento nel `WKWebView`, una richiesta all'indirizzo con `URLSession` in una sessione effimera (`URLSessionConfiguration.ephemeral`, senza cookie del browser) che segue i reindirizzamenti. Se i primi byte ricevuti dicono che è un PDF secondo le regole di `archiviazione/Acquisizione`, lo scaricamento continua su un file temporaneo e il PDF entra con tipo PDF, la sua copia originale e il testo estratto come per ogni PDF; altrimenti la richiesta si annulla subito e la pagina procede con il `WKWebView`. I limiti di tempo e di dimensione sono quelli delle stesse regole.
- Lo scaricamento del PDF non comincia se il server dichiara una dimensione oltre il massimo, e si annulla appena i byte ricevuti lo superano, anche quando il server non la dichiara; il file temporaneo si elimina in ogni caso di fallimento.
- Nome originale di un PDF scaricato: il nome suggerito dalla risposta del server (`Content-Disposition`, tramite `URLResponse.suggestedFilename`) se c'è, altrimenti l'ultima parte del percorso dell'indirizzo; se manca anche quella, il dominio dell'indirizzo, con l'estensione `.pdf`.
- Lo scaricamento sta dietro un protocollo: i test usano un'implementazione di prova, senza rete.
- Pagine web che non sono PDF: caricamento dell'indirizzo in un `WKWebView` non visibile e `createPDF` della pagina intera; confronto del testo del PDF con il testo letto a schermo secondo le regole di corrispondenza.
- La finestra nascosta che ospita il `WKWebView` vive finché il PDF non è pronto e viene liberata una sola volta: non si rilascia da sola alla chiusura (`isReleasedWhenClosed = false`).
- Un unico limite di 45 secondi copre caricamento e creazione del PDF; dopo la fine del caricamento si aspetta 1 secondo prima di creare il PDF; se il processo della pagina si interrompe (`webViewWebContentProcessDidTerminate`) il PDF fallisce subito. In ogni caso di fallimento la pagina entra solo come testo.
- Log con `os.Logger`, subsystem `Axi`, categoria `archiviazione`.
- Data di ricezione di un'email di Outlook: una richiesta a OMP a parte, durante l'acquisizione e prima del controllo dei duplicati, con risposta in JSON validato (istante ISO 8601 con offset, oppure nullo); una risposta non valida, nulla o un fallimento della richiesta lasciano la data sconosciuta senza far fallire l'archiviazione. L'ora di archiviazione non si usa mai come data di ricezione di riserva.
- Metadati: una richiesta a OMP con risposta in JSON validato (titolo, riassunto, tag, data del documento, lingua, date citate); nella richiesta ci sono il riferimento per le date relative e il fuso del Mac. Ogni data citata ha data ISO 8601 (con ora e offset se il testo dice l'ora, altrimenti solo giorno), descrizione e parole originali; una data citata non valida si scarta, una risposta non valida conta come fallimento.
- Ogni archiviazione scrive file e database in modo atomico: in caso di fallimento non resta nulla nel vault.

## archiviazione/Indicizzazione
- Database SQLite (tramite GRDB) con FTS5 per il testo e sqlite-vec per i vettori.
- Embedding con EmbeddingGemma 2 nella variante solo testo, eseguito con MLX Swift dentro l'app; prima di costruire l'indicizzazione si verifica che il modello giri correttamente su MLX e lo si ottimizza (quantizzazione, dimensione dei vettori, lotti). Se non gira bene, si usa un altro modello di embedding supportato da MLX, scelto in base alla qualità multilingue.

## mini-chat
- Ricerca ibrida per lo strumento `search_vault`: risultati FTS5 (BM25) e per similarità dei vettori, fusi con Reciprocal Rank Fusion, filtrabili per tag, tipo, origine, data di archiviazione, data del documento o di ricezione e date citate (intervalli nel fuso del Mac); ogni risultato porta documento, pagina e brano, con data di archiviazione, data del documento, data di ricezione di un'email e date citate del documento.
- Domanda alla chat: il messaggio a OMP comincia con data, ora e fuso correnti; il blocco del contesto dello schermo porta il momento della sua lettura.
- Le istruzioni a OMP e la descrizione di `cite_documents` chiedono di chiamare `cite_documents` prima di scrivere la risposta e di non scrivere testo dopo la risposta.
- Lo streaming della risposta distingue i messaggi dell'assistente di OMP (gli eventi di inizio e fine di ogni messaggio del protocollo RPC): il primo `text_delta` di un nuovo messaggio sostituisce il testo mostrato invece di accodarsi; i messaggi senza `text_delta` lasciano il testo com'è. Il testo salvato nella conversazione è quello mostrato alla fine, anche quando la risposta viene interrotta.
- `read_document_page` restituisce il testo di una pagina di un documento del vault.
- `set_document_tags` e `request_document_deletion` agiscono solo su documenti esistenti; l'eliminazione aspetta la conferma dell'utente prima di toccare il vault.
- Aprire un documento citato usa `NSWorkspace` sulla copia del vault; per i PDF l'apertura alla pagina citata avviene quando l'app predefinita lo permette.

## documento
- L'eliminazione cancella copia, testo, vettori, tag non più usati e collegamenti in un'unica transazione.
