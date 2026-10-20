---
column: done
technical: true
refs:
  - requirements/tech#permessi
  - requirements/ui#permessi
drift: srqo2qt3
proposal: null
agent: false
created: 2026-10-19T03:02:16.436Z
finished: 2026-10-19T03:08:54.493Z
---
# Fix code to match the Requirements: Closed browser shown as denied

## What happens

Quando Safari o Chrome è installato ma chiuso, la sua riga di Automazione mostra «non concesso», come un permesso negato. La lettura dell'Automazione dà solo sì o no, e il browser chiuso dà no: il caso «sconosciuto» non esiste.

## What should happen

Un browser chiuso ha l'Automazione sconosciuta: non conta come mancante e la riga dice «Apri Safari per verificare.» (o Chrome), senza pulsante. Risultano mancanti solo il permesso negato o quello non ancora chiesto.

## Chosen option

**Four-state reading**

Far restituire all'Automazione uno dei quattro stati (concessa, negata, non ancora chiesta, sconosciuta) invece di un sì o no. Il browser chiuso diventa sconosciuto: la riga mostra «Apri Safari per verificare.» senza pulsante e non conta come mancante. Costa: cambia il tipo di ritorno, e chi lo legge (il benvenuto e la finestra dei permessi) va aggiornato insieme. È il modo che segue il Requirement senza eccezioni.

## Where in the code

Packages/AxiScreen/Sources/AxiScreen/Permissions.swift, automationPermitted (righe 44-52); Axi/Benvenuto/BenvenutoView.swift, BrowserAutomationRow (righe 160-185)
