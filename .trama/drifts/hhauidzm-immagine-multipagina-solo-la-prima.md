---
status: resolved
resolution: fix-code
refs:
  - archiviazione/Estrazione del testo
  - requirements/tech#archiviazione
proposal: null
task: 59zgashk
origin: null
critical: false
option: 1
note: null
resolvedBy: 4p713jb5
created: 2026-10-18T19:56:58.221Z
---
# Immagine multipagina: solo la prima

## What happens

Un file immagine con più pagine (TIFF multipagina) viene letto solo dal primo fotogramma: il testo delle pagine successive non viene estratto, né indicizzato, e il documento risulta archiviato con una sola pagina. Il modello dice invece che l'estrazione riguarda tutte le pagine e che il testo si conserva pagina per pagina.

## What should happen

Ogni pagina dell'immagine è riconosciuta e conservata come pagina del documento, con il suo numero.

## Fix options

### Riconoscere ogni fotogramma come pagina

Il file multipagina viene letto fotogramma per fotogramma e ogni pagina è riconosciuta (sul Mac o con Azure, come per le altre pagine senza testo); la copia conservata resta il file originale.

### Passare dal PDF costruito dall'immagine

Il file multipagina viene convertito in un PDF temporaneo e le pagine passano dal percorso PDF già esistente; la copia conservata resta il file originale, e il PDF temporaneo non viene conservato.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/TextExtractor.swift:47-51 (ramo delle immagini: CGImageSourceCreateImageAtIndex con indice 0 e una sola DocumentPage)
