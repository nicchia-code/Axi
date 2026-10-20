---
name: trama-specs
description: Use when choosing, adding or using the project's languages, frameworks, libraries, data stores, tests, CI, repository, deployment, cloud resources or infrastructure as code.
---
# Project specs

The technologies this project is built, tested and released with, from the developer's Specs. An entry marked as chosen by the agent was picked by the agent itself, not named by the developer.

## Languages

- Swift 6: strict concurrency attiva

## Frameworks and libraries

- SwiftUI: viste dell'app
- AppKit: finestre fluttuanti, eventi globali, integrazione con il sistema
- macOS SDK 26: deployment target macOS 26 Tahoe, solo Apple Silicon
- OMP (omp --mode rpc): agente AI locale, avviato come processo figlio e guidato via RPC JSON (protocollo v2) con strumenti host
- MLX Swift: esecuzione locale del modello di embedding; da verificare e ottimizzare
- EmbeddingGemma 2: modello di embedding (variante solo testo); se non gira bene su MLX si sceglie un altro modello supportato da MLX
- Accessibility API: lettura di app, finestre, documenti e testo visibile
- ScreenCaptureKit (chosen by the agent: API di sistema attuale per catturare una finestra prima del riconoscimento del testo)
- Vision (chosen by the agent: riconoscimento del testo sul Mac, senza dipendenze esterne)
- PDFKit (chosen by the agent: lettura del testo dei PDF inclusa in macOS)
- WebKit (chosen by the agent: WKWebView genera il PDF di una pagina web riaprendone l'indirizzo)
- GRDB.swift (chosen by the agent: accesso a SQLite tipizzato e maturo in Swift, con supporto a FTS5 e alle migrazioni)
- KeyboardShortcuts (chosen by the agent: libreria diffusa per scorciatoie globali registrabili dall'utente in SwiftUI)

## Data and persistence

- SQLite: database del vault in Application Support (chosen by the agent: un file locale, nessun server, ricerca a testo pieno integrata)
- SQLite FTS5: ricerca a testo pieno (chosen by the agent: integrato in SQLite, ranking BM25)
- sqlite-vec: vettori degli embedding per la ricerca semantica (chosen by the agent: tiene vettori e testo nello stesso database locale)
- File system: copie dei documenti, modello e sessioni OMP in ~/Library/Application Support/Axi
- Keychain: chiave di Azure Document Intelligence

## Testing

- Swift Testing: test unitari e di integrazione nei pacchetti, con documenti d'esempio

## CI

- GitHub Actions: build e test su runner macOS a ogni push e pull request

## Repository

- GitHub: repository pubblico, licenza AGPL-3.0

## Deployment

- Build locale: per ora app compilata in locale e non firmata; in seguito firma Developer ID e notarizzazione fuori dal Mac App Store

## Cloud and resources

- Azure AI Document Intelligence: opzionale, configurato dall'utente con endpoint e chiave; nessuna risorsa gestita dal progetto

## Notes

- Solo macOS: nessun supporto a Windows o Linux.
- Nessun backend proprio e nessun file di infrastruttura: tutto gira sul Mac, l'AI passa da OMP.
- Licenza AGPL-3.0: uso libero; le aziende che vogliono una licenza commerciale contattano l'autore.
- App Sandbox disattivata, Hardened Runtime attivo, in vista della notarizzazione.

