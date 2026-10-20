---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#permessi
proposal: null
task: npwyi4kx
origin: null
critical: false
option: 1
note: null
resolvedBy: ccydv3zq
created: 2026-10-19T03:31:50.794Z
---
# Closed browser hint says verify

## What happens

Quando Safari o Chrome è installato ma chiuso, la sua riga di Automazione dice in inglese «Open Safari to verify.» (o Chrome). In italiano il testo è «Apri Safari per verificare.», come il Requirement.

## What should happen

La riga di un browser chiuso dice in inglese «Open Safari to check.» (o Chrome), come il Requirement, senza pulsante; il testo italiano resta «Apri Safari per verificare.».

## Fix options

### Use the Requirement's English

Cambiare la sola frase inglese del browser chiuso in «Open %@ to check.», lasciando invariato il testo italiano. È una modifica di una parola, così la riga resta conforme anche prima che le righe condivise della finestra dei permessi sostituiscano il benvenuto. Costa: si tocca il benvenuto prima del lavoro sulle righe condivise, che poi andrà ritoccato.

### Change it with shared rows

Lasciare il testo attuale e allinearlo al Requirement quando la vista condivisa delle righe sostituirà la riga di Automazione nel benvenuto e nella finestra dei permessi, così il testo si cambia una sola volta. Costa: per tutto il Run la riga inglese dice «to verify» invece di «to check», in difformità con il Requirement.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift, BrowserAutomationRow (riga 174, la frase per il browser chiuso)
