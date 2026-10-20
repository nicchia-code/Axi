---
column: done
technical: true
refs:
  - requirements/ui#mini-chat
drift: p3i03by5
proposal: null
agent: false
created: 2026-10-18T19:43:27.162Z
finished: 2026-10-18T20:25:15.444Z
---
# Fix code to match the Requirements: Markdown solo in linea

## What happens

Le risposte di Axi appaiono come testo con solo il grassetto, il corsivo, i collegamenti e il codice in linea. Elenchi puntati e numerati, titoli e blocchi di codice arrivano come simboli grezzi (per esempio trattini o cancelletti), così la risposta non è formattata in Markdown.

## What should happen

Le risposte arrivano man mano e sono formattate in Markdown: elenchi, titoli e blocchi di codice devono apparire come tali nella conversazione.

## Chosen option

**Interpretare tutto il Markdown**

Lo schermo mostra ogni risposta interpretando l'intera sintassi Markdown, con elenchi, titoli e blocchi di codice resi come tali. Costa un po' di lavoro di impaginazione dei blocchi nella bolla e richiede di verificare che il testo selezionabile resti utilizzabile.

## Where in the code

Axi/MiniChat/MiniChatView.swift: MessageBubble, funzione attributed (interpretedSyntax inlineOnlyPreservingWhitespace)
