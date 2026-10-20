---
technical: true
refs:
  - "specs#languages"
  - "specs#frameworks"
  - "specs#deployment"
  - "specs#notes"
  - "requirements/tech#General"
  - "requirements/ui#General"
---
# Scheletro del progetto

Creare il progetto Xcode di Axi e i suoi pacchetti Swift locali, pronti per ospitare le funzioni.

Quando il Task è fatto:
- esiste `Axi.xcodeproj` con il target dell'app per macOS 26, Swift 6 con strict concurrency, App Sandbox disattivata, Hardened Runtime attivo e `LSUIElement` attivo;
- esistono i pacchetti locali `AxiCore`, `AxiScreen`, `AxiOMP` e `AxiEmbedding`, collegati all'app, ciascuno con un target di test Swift Testing che passa;
- le dipendenze delle Specs (GRDB.swift, sqlite-vec, KeyboardShortcuts, MLX Swift) sono dichiarate nei pacchetti che le useranno e il progetto compila;
- c'è un String Catalog con italiano e inglese, e la lingua dell'interfaccia segue quella di macOS;
- l'app si avvia senza icona nel Dock e senza finestre, pronta ad accogliere il puntino;
- c'è una cartella di fixture per i test con un PDF con testo, un PDF scansionato, un DOCX, un'email e una pagina HTML d'esempio;
- `xcodebuild build test` funziona da riga di comando, senza firma.
