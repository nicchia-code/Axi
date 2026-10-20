---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#mini-chat
proposal: null
task: k9kq941c
origin: null
critical: false
option: 1
note: null
resolvedBy: stsg18fb
created: 2026-10-18T19:11:16.683Z
---
# Markdown solo in linea

## What happens

Le risposte di Axi appaiono come testo con solo il grassetto, il corsivo, i collegamenti e il codice in linea. Elenchi puntati e numerati, titoli e blocchi di codice arrivano come simboli grezzi (per esempio trattini o cancelletti), così la risposta non è formattata in Markdown.

## What should happen

Le risposte arrivano man mano e sono formattate in Markdown: elenchi, titoli e blocchi di codice devono apparire come tali nella conversazione.

## Fix options

### Interpretare tutto il Markdown

Lo schermo mostra ogni risposta interpretando l'intera sintassi Markdown, con elenchi, titoli e blocchi di codice resi come tali. Costa un po' di lavoro di impaginazione dei blocchi nella bolla e richiede di verificare che il testo selezionabile resti utilizzabile.

### Un blocco alla volta

Ogni risposta viene scomposta in blocchi (paragrafi, elementi di elenco, titoli, codice) e ogni blocco è mostrato con il proprio formato. Il risultato è preciso ma più complesso da mantenere, e lo streaming deve ricomporre i blocchi senza salti visivi mentre la risposta arriva.

## Where in the code

Axi/MiniChat/MiniChatView.swift: MessageBubble, funzione attributed (interpretedSyntax inlineOnlyPreservingWhitespace)
