---
technical: false
refs:
  - archiviazione/Acquisizione
  - requirements/tech#archiviazione
  - requirements/rules#archiviazione/Acquisizione
---
# PDF della pagina web stabile

Quando il Task è finito, archiviare una pagina web (con qualsiasi browser) non chiude più Axi. In `archiviazione/Acquisizione` la pagina viene riaperta dal suo indirizzo in un `WKWebView` non visibile e salvata come PDF; se il PDF non si riesce a creare (la pagina non si carica, il suo caricamento si interrompe o richiede troppo tempo) o non corrisponde a ciò che l'utente legge, Axi conserva solo il testo letto a schermo e l'indirizzo e lo dice nell'esito.

Secondo `requirements/tech#archiviazione`:
- la finestra nascosta che ospita il `WKWebView` ha `isReleasedWhenClosed = false`, vive finché il PDF non è pronto e viene liberata una sola volta (oggi `WebPageRenderer.renderPDF` in `Packages/AxiCore/Sources/AxiCore/Archive/ArchiveSources.swift` la chiude con `defer { window.close() }` causando un doppio rilascio e il crash EXC_BAD_ACCESS);
- un unico limite di 45 secondi copre caricamento e creazione del PDF (oggi copre solo il caricamento e `webView.pdf` non ha limite);
- dopo la fine del caricamento si aspetta 1 secondo prima di creare il PDF;
- se il processo della pagina si interrompe (`webViewWebContentProcessDidTerminate`) il PDF fallisce subito;
- in ogni caso di fallimento la pagina entra solo come testo (indirizzo e testo letto a schermo), con l'esito che lo dice.

Secondo `requirements/rules#archiviazione/Acquisizione`, la pagina corrisponde se almeno l'80% delle parole del testo della pagina si trova nel testo del PDF, dove il testo della pagina è solo quello dell'area della pagina (`AXWebArea`), senza schede, barra degli indirizzi, segnalibri e barre degli strumenti del browser; è lo stesso testo che si conserva quando la pagina entra senza PDF. Il confronto è in `WebPageMatch` (`ArchiveFingerprint.swift`); il testo oggi raccolto da `VisibleTextReader` comprende l'interfaccia del browser e va ristretto all'area della pagina per il documento web.

Ogni PDF non creato o scartato perché non corrisponde si registra nel log `os.Logger` (subsystem `Axi`, categoria `archiviazione`) come chiede `requirements/quality#archiviazione` (registrazione coperta dal Task sull'errore imprevisto).
