---
status: approved
kind: setup
base:
  system.md: 33959dfb17e62dd716ae43f9fb0caf774ce2f3b1e6ff4b359f573335157d6d0f
  actors/utente.md: new
  actors/omp.md: new
  actors/tempo.md: new
  companion/feature.md: new
  companion/puntino.md: new
  companion/attivita.md: new
  companion/benvenuto.md: new
  companion/impostazioni.md: new
  companion/connessione-omp.md: new
  visione/feature.md: new
  visione/lettura-schermo.md: new
  vault/feature.md: new
  vault/coda-archiviazione.md: new
  vault/archiviazione.md: new
  vault/documento.md: new
  chat/feature.md: new
  chat/mini-chat.md: new
  specs.yaml: new
  requirements/ui/companion.md: new
  requirements/ui/chat.md: new
  requirements/tech/fondamenta.md: new
  requirements/tech/documenti.md: new
  requirements/data/vault.md: new
  requirements/rules/ai.md: new
  requirements/quality/privacy.md: new
delete: []
request: 2026-10-18T18-47-17
created: 2026-10-18T17:18:22.737Z
label: Avvio Axi
---
# Avvio di Axi

Prima Proposal di Axi: un companion solo per Mac che, quando richiesto, guarda cosa c'è a schermo, archivia documenti in un vault ottimizzato per la ricerca e risponde in una mini-chat sui documenti archiviati, usando l'AI tramite OMP in locale. Definisce il Model iniziale, i Requirements, le Specs e i Task che costruiscono il progetto.

## Decisioni dell'intervista

- Attivazione: clic sul puntino con menu di azioni e scorciatoie globali (predefinite e modificabili).
- Scorciatoie predefinite: F4 per la chat se intercettabile, altrimenti ⌥Spazio; ⌥A per archiviare; ⌥H per mostrare/nascondere il puntino.
- Visione dello schermo: serve da contesto per archivio e chat; prima Accessibility, poi screenshot con riconoscimento del testo (Azure Document Intelligence se configurato, altrimenti OCR locale), attenzione ai documenti multipagina.
- Fonti da archiviare: file aperto in primo piano, email di Outlook (con allegati), pagina web (Safari, Chrome, Firefox, via Accessibility; automazione solo dove serve), file trascinati sul puntino. Apple Mail esclusa.
- Outlook: lettura tramite Accessibility; allegati via Accessibility, altrimenti trascinandoli o aprendoli e attivando Axi; email e allegati diventano documenti collegati; allegati mancanti segnalati nell'esito; un allegato aperto e archiviato da solo si collega all'email se riconoscibile.
- Documento senza file: Axi rifiuta e spiega di salvarlo prima come file.
- Pagine web: PDF ottenuto riaprendo l'indirizzo, più testo e indirizzo; se il PDF non corrisponde a ciò che è a schermo, si archiviano testo e indirizzo senza PDF, dicendolo.
- Vault: copia del documento, nei dati privati dell'app; duplicati riconosciuti dall'impronta del contenuto e segnalati.
- Tag e riassunto: generati dall'AI in automatico, riusando i tag esistenti, nella lingua dell'interfaccia; correggibili chiedendo in chat.
- Ricerca: testo pieno, tag, metadati e semantica, svolta dall'agente OMP tramite strumenti di Axi; embedding con EmbeddingGemma 2 su MLX Swift (da verificare e ottimizzare; se non va, altro modello su MLX), scaricato nel benvenuto.
- Metadati: origine, dati email, date, riassunto e tag, tipo, pagine e lingua.
- Archiviazione dipendente dall'AI: senza OMP fallisce e avvisa. Richieste multiple in coda, una alla volta.
- Chat: il puntino si espande in mini-chat; risponde su tutto il vault con citazioni; include il contesto dello schermo in modo visibile e rimovibile; conversazioni salvate e riapribili da un elenco nella mini-chat; cliccare un documento citato apre la copia del vault.
- Nessuna finestra Vault: gestione (tag, eliminazione definitiva con conferma) solo chiedendo in chat.
- Documenti grandi: interi fino al 50% del contesto del modello, oltre a sezioni; l'AI può sempre chiedere il dettaglio di una pagina. Tutto ciò che è stato archiviato può essere inviato all'AI.
- Modello AI scelto nelle impostazioni tra quelli di OMP. Integrazione con `omp --mode rpc` dall'app Swift.
- Puntino: piccolo, colore d'accento, animazioni curate; sempre sopra, su ogni Spazio e in schermo intero, nascondibile; si posiziona ovunque e ricorda la posizione. Esito con animazione e nuvoletta.
- Impostazioni dal menu del puntino. Permessi guidati da un benvenuto al primo avvio. Interfaccia in italiano e inglese.
- Tecnologia: Swift con SwiftUI e AppKit, macOS 26 Tahoe minimo, tutto locale, nessun cloud proprio né file di infrastruttura.
- Distribuzione: per ora solo build locale; firma e notarizzazione previste più avanti.
- Repository GitHub pubblico, licenza AGPL-3.0 (uso libero, le aziende contattano l'autore); test unitari e di integrazione con Swift Testing, CI su GitHub Actions.

## Assunzioni da verificare

- Senza OMP pronto anche la chat non si apre: il puntino mostra l'errore e lo spiega, come per l'archiviazione.
- Se OMP termina mentre è pronto, Axi lo riavvia una volta; se non riparte resta non disponibile finché non si cambia il percorso nelle impostazioni.
- La chat ha un comando per interrompere una risposta; chiudere la chat durante una risposta la interrompe.
- Eliminare un'email dal vault elimina anche i suoi allegati; la conferma mostra tutto ciò che sparisce.
- Mentre il puntino è nascosto le scorciatoie funzionano e l'esito compare comunque in una nuvoletta; nascondere il puntino chiude la chat.
- Una lettura dello schermo chiesta mentre ne è in corso un'altra parte appena la prima finisce.
- La nuvoletta dell'esito resta 5 secondi (o finché il puntatore è sopra), poi sparisce.
- Archiviare richiede anche il modello di ricerca scaricato nel benvenuto.
- Axi è un'app accessoria, senza icona nel Dock né voce in ⌘Tab.
- Solo Apple Silicon, come conseguenza di MLX.
- OMP riceve solo gli strumenti di Axi, nessuno strumento di file system, shell o rete; un processo OMP per l'archiviazione e uno per la chat; una sessione OMP per conversazione.
- Valori iniziali scelti da me, da confermare con l'uso: puntino di circa 18 pt, chat di circa 380 × 520 pt, da 1 a 5 tag per documento, riassunto di al massimo 3 frasi, brani di circa 500 token, al massimo 20 brani per ricerca, soglia dell'80% per la corrispondenza tra PDF di una pagina web e schermo, riavvio di OMP considerato fallito se si ferma entro 30 secondi.
- Tecnologie scelte da me (segnate nelle Specs): ScreenCaptureKit, Vision, PDFKit, WebKit, GRDB.swift, SQLite con FTS5 e sqlite-vec, KeyboardShortcuts.
- Creare il remoto GitHub pubblico avviene solo se lo chiedi durante il Task del repository.
