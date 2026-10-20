---
refs:
  - "vault"
  - "archiviazione"
  - "requirements/tech#archiviazione"
  - "requirements/tech#archiviazione/Indicizzazione"
  - "requirements/rules#archiviazione/Acquisizione"
  - "requirements/rules#archiviazione/Controllo dei duplicati"
  - "requirements/rules#archiviazione/Generazione dei metadati"
  - "requirements/rules#archiviazione/Indicizzazione"
  - "requirements/data#General"
  - "requirements/data#documento"
  - "specs#data"
---
# Archiviazione nel vault

Il vault e il lavoro che vi porta un documento: copia, duplicati, testo, metadati dell'AI e indice.

Quando il Task è fatto:
- il vault esiste in `~/Library/Application Support/Axi/` con le copie dei documenti e un database SQLite (GRDB, FTS5, sqlite-vec) che conserva per ogni documento tutti i dati elencati nei Requirements, con migrazioni;
- da Inattiva, `coda-archiviazione.PROSSIMO_DOCUMENTO` porta a In lavorazione/Acquisizione se OMP è pronto e il benvenuto è completato; altrimenti resta in Inattiva ed emette `NON_ARCHIVIATO` con il motivo;
- in Acquisizione Axi copia il file; per un'email di Outlook crea il documento dell'email e prova a prendere gli allegati con Accessibility, ognuno come documento collegato, annotando per nome quelli non presi; per una pagina web genera il PDF riaprendo l'indirizzo e, se non corrisponde al testo visibile secondo la soglia delle regole, conserva solo testo e indirizzo e lo annota per l'esito; un file che risulta allegato di un'email a schermo in Outlook o nel vault viene collegato a quell'email; poi `ACQUISITO` porta a Controllo dei duplicati, `ACQUISIZIONE_FALLITA` a Inattiva con `NON_ARCHIVIATO`;
- in Controllo dei duplicati, un'impronta già nel vault produce `GIA_PRESENTE` e il ritorno in Inattiva con `NON_ARCHIVIATO` che indica il documento esistente; altrimenti `CONTENUTO_NUOVO` porta a Estrazione del testo;
- in Estrazione del testo Axi estrae il testo pagina per pagina da PDF, DOCX, DOC, RTF, EML, immagini e pagine web, riconoscendo le pagine senza testo con Azure Document Intelligence se configurato, altrimenti con Vision; `TESTO_ESTRATTO` porta a Generazione dei metadati, `ESTRAZIONE_FALLITA` a Inattiva con `NON_ARCHIVIATO`;
- in Generazione dei metadati Axi chiede a OMP titolo, riassunto, tag, data del documento e lingua, inviando il documento intero o a sezioni secondo la soglia del 50% del contesto del modello, con il vocabolario dei tag esistenti e la lingua dell'interfaccia; `omp.METADATI_GENERATI` porta a Indicizzazione, `omp.METADATI_FALLITI` a Inattiva con `NON_ARCHIVIATO`;
- in Indicizzazione il testo si divide in brani, ogni brano entra nell'indice a testo pieno e riceve il suo vettore dal componente di embedding verificato; `INDICIZZATO` porta a Inattiva con `ARCHIVIATO` (titolo, tag, allegati non presi), `INDICIZZAZIONE_FALLITA` a Inattiva con `NON_ARCHIVIATO`;
- `omp.TERMINATO` durante In lavorazione riporta in Inattiva con `NON_ARCHIVIATO`;
- ogni archiviazione è atomica: dopo un `NON_ARCHIVIATO` nel vault non resta nulla di quel documento;
- estrazione, impronte, corrispondenza delle pagine web, suddivisione in brani e flusso con OMP finto sono coperti da test con i documenti d'esempio.
