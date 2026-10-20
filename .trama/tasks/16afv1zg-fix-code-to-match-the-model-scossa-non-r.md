---
column: done
technical: false
refs:
  - attivita
  - requirements/ui#attivita
drift: z976h3y6
proposal: null
agent: false
created: 2026-10-18T19:43:27.170Z
finished: 2026-10-18T21:28:10.257Z
---
# Fix code to match the Model: Scossa non ripetuta

## What happens

Un errore arriva mentre la nuvoletta mostra già lo stesso esito (per esempio due documenti rifiutati di seguito per lo stesso motivo): la nuvoletta non cambia valore e il puntino non scuote. La scossa parte solo quando la nuvoletta cambia, perché la vista osserva `nuvoletta` e `Nuvoletta` è Equatable.

## What should happen

Requisito: «Errore: breve scossa orizzontale e colore rosso di sistema». Ogni errore deve scuotere il puntino, anche se ripete l'esito precedente.

## Chosen option

**Contatore degli esiti**

Attivita tiene un numero progressivo che cresce a ogni esito e la vista scuote su ogni incremento: la scossa non dipende più dal valore della nuvoletta, e il Modello resta invariato.

## Where in the code

Axi/Puntino/PuntinoVista.swift: .onChange(of: modello.attivita.nuvoletta) (righe 59-60); Packages/AxiCore/Sources/AxiCore/Attivita/Attivita.swift: mostra e concludi (righe 135-147).
