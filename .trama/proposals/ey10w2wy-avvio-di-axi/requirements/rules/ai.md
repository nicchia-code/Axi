---
description: Use when implementing duplicate detection, web page matching, document size limits for the AI, tagging, chunking or the archive queue.
---
# Regole di archiviazione e AI

## coda-archiviazione
- La coda è in ordine di arrivo; più file rilasciati insieme entrano nell'ordine in cui il Finder li consegna.

## archiviazione/Acquisizione
- Una pagina web corrisponde a ciò che si vede a schermo se almeno l'80% delle parole del testo visibile si trova nel testo del PDF.
- Un file aperto è un allegato di un'email se il suo nome coincide con quello di un allegato dell'email a schermo in Outlook o di un'email nel vault e il file viene dalla cartella in cui Outlook apre gli allegati.

## archiviazione/Controllo dei duplicati
- L'impronta è lo SHA-256 dei byte della copia. Per un'email è quella del testo normalizzato di mittente, data, oggetto e corpo; per una pagina web senza PDF quella di indirizzo e testo.

## archiviazione/Generazione dei metadati
- Un documento si invia intero se il suo testo occupa al massimo il 50% della finestra di contesto del modello scelto; altrimenti si invia a sezioni di pagine consecutive che rispettano lo stesso limite, si ottiene un riassunto per sezione e i metadati si ricavano dai riassunti.
- Da 1 a 5 tag per documento. All'AI si passa il vocabolario dei tag del vault: deve preferire tag esistenti e crearne di nuovi solo se nessuno è adatto. Tag in minuscolo, al singolare.
- Riassunto di al massimo 3 frasi; riassunto e tag nella lingua dell'interfaccia.

## archiviazione/Indicizzazione
- Il testo si divide in brani di circa 500 token che non attraversano le pagine, con sovrapposizione di circa 50 token; ogni brano conosce documento e pagina.

## mini-chat
- Ogni risposta cita i documenti e le pagine da cui prende le informazioni; senza fonti nel vault lo dice.
- Un documento si passa intero all'AI se sta nel 50% della finestra di contesto del modello; altrimenti l'AI riceve i brani pertinenti e può sempre chiedere il testo di qualsiasi pagina.
- La ricerca restituisce al massimo 20 brani per chiamata.
