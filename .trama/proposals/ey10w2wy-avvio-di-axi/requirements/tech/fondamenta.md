---
description: Use when setting up the project, build, CI and repository, the OMP connection, shortcuts or settings storage.
---
# Fondamenta e OMP

## General
- Swift 6 con strict concurrency, SwiftUI per le viste e AppKit dove serve (finestre fluttuanti, eventi globali, Accessibility).
- Deployment target macOS 26; solo Apple Silicon, perché gli embedding girano con MLX.
- Progetto Xcode `Axi.xcodeproj` con l'app e pacchetti Swift locali per i moduli: `AxiCore` (vault, ricerca, regole), `AxiScreen` (Accessibility, cattura e riconoscimento del testo), `AxiOMP` (client RPC di OMP e strumenti host), `AxiEmbedding` (modello di embedding su MLX). La logica sta nei pacchetti, testabile senza interfaccia.
- App Sandbox disattivata (serve per Accessibility su altre app e per avviare OMP); Hardened Runtime attivo, così la firma Developer ID e la notarizzazione future non richiedono modifiche al progetto. Per ora la build è locale e non firmata.
- `LSUIElement` attivo: app accessoria senza Dock.
- Testi dell'interfaccia in un String Catalog con italiano e inglese.
- Codice, commenti, messaggi di commit, README e documentazione del progetto in inglese.
- Test con Swift Testing nei pacchetti: unitari e di integrazione su vault, estrazione, duplicati e ricerca, con documenti d'esempio in una cartella di fixture del repository (PDF con testo, PDF scansionato, DOCX, email, pagina HTML). I test non richiedono OMP, rete o permessi: OMP e Azure sono sostituiti da implementazioni di prova dietro protocolli.
- Repository pubblico su GitHub con licenza AGPL-3.0; il README dice che l'uso è libero e che le aziende interessate a una licenza commerciale devono contattare l'autore.
- GitHub Actions: a ogni push e pull request, build e test su runner macOS con Xcode che supporta macOS 26.

## connessione-omp
- Axi avvia `omp --mode rpc` come processo figlio e parla con lui in JSON per riga su stdin/stdout, negoziando il protocollo v2; stderr va nei log, mai nel parser.
- Il percorso di OMP è quello delle impostazioni; se manca, Axi lo cerca nel `PATH` della shell di login dell'utente e in `~/.bun/bin` e `/opt/homebrew/bin`.
- Un processo OMP per l'archiviazione e uno per la chat, così una risposta in chat non blocca un'archiviazione.
- OMP riceve solo gli strumenti host di Axi (`search_vault`, `read_document_page`, `set_document_tags`, `request_document_deletion`), nessuno strumento di file system, shell o rete.
- Il modello scelto nelle impostazioni si applica a ogni sessione; l'elenco dei modelli viene da OMP.
- Ogni conversazione della chat ha la sua sessione OMP persistente, conservata nella cartella dati di Axi; riaprire una conversazione riprende la sua sessione.
- Dopo un'uscita inattesa Axi riavvia OMP una volta; una seconda uscita entro 30 secondi dal riavvio rende la connessione non disponibile.

## impostazioni
- Preferenze in `UserDefaults`; la chiave di Azure Document Intelligence nel Keychain, mai in chiaro su disco.
- Scorciatoie globali registrabili con la libreria KeyboardShortcuts. Valori predefiniti: Archivia ⌥A, Mostra/nascondi ⌥H, Chat F4 (il tasto Spotlight delle tastiere Apple) se Axi riesce a intercettarlo senza che si apra Spotlight, altrimenti ⌥Spazio.

## benvenuto
- Il modello di embedding si scarica da Hugging Face nella cartella dati di Axi, con ripresa dello scaricamento interrotto e verifica dell'integrità dei file.
- Lo stato dei permessi si legge con `AXIsProcessTrusted`, `CGPreflightScreenCaptureAccess` e lo stato di Automazione per i browser.
