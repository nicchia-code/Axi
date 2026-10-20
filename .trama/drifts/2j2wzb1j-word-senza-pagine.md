---
status: resolved
resolution: proposal
refs:
  - archiviazione/Estrazione del testo
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: stsg18fb
created: 2026-10-18T18:52:07.049Z
---
# Word senza pagine

## What happens

Un documento Word o RTF viene archiviato con tutto il suo testo come se fosse una sola pagina. Il numero di pagina non corrisponde a nulla di reale, e leggere una pagina del documento restituisce tutto il testo insieme.

## What should happen

Il requisito di archiviazione dice che il testo si conserva pagina per pagina, per ogni tipo di file che ha il testo estratto con il sistema del Mac. Senza pagine reali, le citazioni e la lettura di una pagina non puntano al punto giusto del documento.

## Fix options

### Impaginare il testo sul Mac

Il testo di un Word o RTF viene impaginato con una dimensione di pagina fissa, e ogni pagina ottiene il suo numero. Le pagine sono approssimative rispetto a come il documento appare aperto in Word, ma le citazioni e la lettura di una pagina tornano a funzionare.

### Convertire il documento in PDF

Il documento Word o RTF viene convertito in PDF dal sistema, e le pagine sono quelle del PDF ottenuto. Le pagine coincidono con quelle che l'utente vede, ma la conversione richiede più tempo e dipende dal sistema.

### Lasciare una pagina sola

Il documento resta a una sola pagina, come oggi. Non si cambia nulla, ma le citazioni e la lettura di una pagina restano senza un punto preciso nel documento.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/TextExtractor.swift: lettura dei file Word e RTF, con una sola pagina e funzione che estrae il testo
