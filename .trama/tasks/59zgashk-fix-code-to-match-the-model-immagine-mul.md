---
column: done
technical: false
refs:
  - archiviazione/Estrazione del testo
  - requirements/tech#archiviazione
drift: hhauidzm
proposal: null
agent: false
created: 2026-10-18T20:05:07.497Z
finished: 2026-10-18T20:22:10.299Z
---
# Fix code to match the Model: Immagine multipagina: solo la prima

## What happens

Un file immagine con più pagine (TIFF multipagina) viene letto solo dal primo fotogramma: il testo delle pagine successive non viene estratto, né indicizzato, e il documento risulta archiviato con una sola pagina. Il modello dice invece che l'estrazione riguarda tutte le pagine e che il testo si conserva pagina per pagina.

## What should happen

Ogni pagina dell'immagine è riconosciuta e conservata come pagina del documento, con il suo numero.

## Chosen option

**Riconoscere ogni fotogramma come pagina**

Il file multipagina viene letto fotogramma per fotogramma e ogni pagina è riconosciuta (sul Mac o con Azure, come per le altre pagine senza testo); la copia conservata resta il file originale.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/TextExtractor.swift:47-51 (ramo delle immagini: CGImageSourceCreateImageAtIndex con indice 0 e una sola DocumentPage)
