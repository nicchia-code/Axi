---
column: done
technical: false
refs:
  - archiviazione/Acquisizione
  - archiviazione.ACQUISIZIONE_FALLITA
  - archiviazione.NON_ARCHIVIATO
  - requirements/rules#archiviazione/Acquisizione
  - requirements/tech#archiviazione
  - requirements/data#documento
  - requirements/quality#archiviazione
drift: null
proposal: axxxv89o
agent: false
created: 2026-10-19T16:49:18.317Z
finished: 2026-10-19T18:24:19.100Z
---
# Scaricamento PDF delle pagine web

Quando Axi acquisisce una pagina web (indirizzo `http` o `https`), prima di caricarla nel `WKWebView` non visibile guarda che cosa c'è al suo indirizzo, con una richiesta `URLSession` in una sessione effimera (`URLSessionConfiguration.ephemeral`, senza cookie del browser) che segue i reindirizzamenti. Questo controllo avviene prima di usare il testo letto a schermo: un PDF si archivia anche quando a schermo non si legge testo, quindi il controllo precede il rifiuto per testo visibile vuoto.

- L'indirizzo porta a un PDF se i primi byte ricevuti cominciano con `%PDF`, qualunque sia il tipo dichiarato dal server. L'indirizzo dice di essere un PDF se il suo percorso finisce in `.pdf`, senza distinzione tra maiuscole e minuscole.
- Se è un PDF, lo scaricamento continua su un file temporaneo e il documento entra come un file PDF: tipo PDF, copia originale del file scaricato nel vault, testo estratto come per ogni PDF (PDFKit, con OCR quando serve), impronta SHA-256 calcolata sui byte scaricati, origine data dal browser e dall'indirizzo della pagina. Il nome originale è quello suggerito dal server (`Content-Disposition`, tramite `URLResponse.suggestedFilename`) se c'è, altrimenti l'ultima parte del percorso dell'indirizzo; se manca anche quella, il dominio dell'indirizzo con l'estensione `.pdf`. Il PDF scaricato non si confronta con il testo letto a schermo.
- Se la risposta non è un PDF, la richiesta si annulla subito.
- Limiti: un indirizzo che non dice di essere un PDF aspetta al massimo 15 secondi i primi byte. Lo scaricamento di un PDF ha 120 secondi in tutto dall'inizio della richiesta; oltre, è non riuscito. Un PDF oltre 200 MB (1 MB = 1.000.000 byte) è troppo grande: lo scaricamento non comincia se il server dichiara una dimensione oltre il massimo, e si annulla appena i byte ricevuti lo superano, anche quando il server non la dichiara. Il file temporaneo si elimina in ogni caso di fallimento.
- Indirizzo che dice di essere un PDF: se i primi byte non arrivano in tempo, la richiesta fallisce, il server risponde con un errore, la risposta non è un PDF (per esempio una pagina di accesso) o lo scaricamento supera i 120 secondi, l'acquisizione finisce in `ACQUISIZIONE_FALLITA` con motivo "PDF non scaricato"; se il PDF è troppo grande, con motivo "PDF troppo grande". Nel vault non entra nulla, si torna in Inattiva e `NON_ARCHIVIATO` porta il motivo distinto; l'esito suggerisce di scaricare il PDF e trascinarlo sul puntino.
- Indirizzo che non dice di essere un PDF: se i primi byte non arrivano entro 15 secondi, la richiesta fallisce, il server risponde con un errore o la risposta non è un PDF, la pagina procede come oggi con il `WKWebView`, `createPDF` e il confronto con il testo letto a schermo (o il ripiego a solo testo e indirizzo).
- Lo scaricamento sta dietro un protocollo, con un'implementazione di prova per i test: i test non usano la rete e coprono i casi PDF scaricato, risposta non PDF, tempo scaduto, errore, troppo grande (dichiarato e ricevuto), per indirizzi che dicono e non dicono di essere un PDF.
- Ogni scaricamento non riuscito si registra nel log di sistema con il passo, il motivo, la causa (tempo scaduto, errore di rete o del server, risposta che non è un PDF, troppo grande) e l'origine del documento, senza testo del documento e con al più il dominio dell'indirizzo.

Codice da toccare: `Packages/AxiCore` — `Archive/ArchivingPipeline.swift` (`acquireWebPage`, riusando la strada di `acquireFile` per il PDF scaricato e la scrittura in staging) e `ArchiveSources.swift` (accanto a `WebPageRenderer`, il protocollo dello scaricamento e la sua implementazione con `URLSession`).
