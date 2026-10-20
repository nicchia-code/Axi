---
description: Use when reading the screen, acquiring documents, extracting text, indexing, searching or deleting in the vault.
---
# Schermo, documenti e ricerca

## lettura-schermo
- L'app in primo piano si memorizza nel momento della richiesta (clic sul puntino o scorciatoia), prima che Axi prenda il fuoco, e la lettura riguarda quella.
- Accessibility (`AXUIElement`) per app, finestra principale, `AXDocument` (file aperto), indirizzo della pagina nei browser (Safari, Chrome, Firefox) e testo visibile.
- Outlook (nuovo Outlook per Mac): lettura via Accessibility del messaggio aperto o selezionato (mittente, destinatari, oggetto, data, corpo, nomi degli allegati). Nessun AppleScript, che il nuovo Outlook non supporta.
- Automazione (Apple Events) solo dove Accessibility non basta, per browser che la offrono.
- Cattura della finestra con ScreenCaptureKit; riconoscimento del testo con Vision in italiano e inglese, oppure con Azure Document Intelligence (modello `prebuilt-read`) se configurato.

## archiviazione
- Testo: PDFKit per i PDF; `NSAttributedString` per DOCX, DOC, RTF; parser per EML; Vision o Azure Document Intelligence per immagini e pagine PDF senza testo. Il testo si conserva pagina per pagina.
- Allegati di Outlook: tentativo via Accessibility (azioni di salvataggio dell'allegato); quelli non riusciti si registrano come mancanti, con il nome.
- Pagine web: caricamento dell'indirizzo in un `WKWebView` non visibile e `createPDF` della pagina intera; confronto del testo del PDF con il testo letto a schermo secondo le regole di corrispondenza.
- Metadati: una richiesta a OMP con risposta in JSON validato (titolo, riassunto, tag, data del documento, lingua); una risposta non valida conta come fallimento.
- Ogni archiviazione scrive file e database in modo atomico: in caso di fallimento non resta nulla nel vault.

## archiviazione/Indicizzazione
- Database SQLite (tramite GRDB) con FTS5 per il testo e sqlite-vec per i vettori.
- Embedding con EmbeddingGemma 2 nella variante solo testo, eseguito con MLX Swift dentro l'app; prima di costruire l'indicizzazione si verifica che il modello giri correttamente su MLX e lo si ottimizza (quantizzazione, dimensione dei vettori, lotti). Se non gira bene, si usa un altro modello di embedding supportato da MLX, scelto in base alla qualità multilingue.

## mini-chat
- Ricerca ibrida per lo strumento `search_vault`: risultati FTS5 (BM25) e per similarità dei vettori, fusi con Reciprocal Rank Fusion, filtrabili per tag, tipo, origine e date; ogni risultato porta documento, pagina e brano.
- `read_document_page` restituisce il testo di una pagina di un documento del vault.
- `set_document_tags` e `request_document_deletion` agiscono solo su documenti esistenti; l'eliminazione aspetta la conferma dell'utente prima di toccare il vault.
- Aprire un documento citato usa `NSWorkspace` sulla copia del vault; per i PDF l'apertura alla pagina citata avviene quando l'app predefinita lo permette.

## documento
- L'eliminazione cancella copia, testo, vettori, tag non più usati e collegamenti in un'unica transazione.
