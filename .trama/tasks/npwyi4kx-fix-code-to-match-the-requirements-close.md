---
column: done
technical: true
refs:
  - requirements/ui#permessi
drift: lcp70806
proposal: null
agent: false
created: 2026-10-19T06:07:34.211Z
finished: 2026-10-19T06:12:39.098Z
---
# Fix code to match the Requirements: Closed browser hint says verify

## What happens

Quando Safari o Chrome è installato ma chiuso, la sua riga di Automazione dice in inglese «Open Safari to verify.» (o Chrome). In italiano il testo è «Apri Safari per verificare.», come il Requirement.

## What should happen

La riga di un browser chiuso dice in inglese «Open Safari to check.» (o Chrome), come il Requirement, senza pulsante; il testo italiano resta «Apri Safari per verificare.».

## Chosen option

**Use the Requirement's English**

Cambiare la sola frase inglese del browser chiuso in «Open %@ to check.», lasciando invariato il testo italiano. È una modifica di una parola, così la riga resta conforme anche prima che le righe condivise della finestra dei permessi sostituiscano il benvenuto. Costa: si tocca il benvenuto prima del lavoro sulle righe condivise, che poi andrà ritoccato.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift, BrowserAutomationRow (riga 174, la frase per il browser chiuso)
