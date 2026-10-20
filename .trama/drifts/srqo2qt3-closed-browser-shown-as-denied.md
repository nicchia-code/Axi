---
status: resolved
resolution: fix-code
refs:
  - requirements/tech#permessi
  - requirements/ui#permessi
proposal: null
task: mvp5tiya
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:40:45.532Z
---
# Closed browser shown as denied

## What happens

Quando Safari o Chrome è installato ma chiuso, la sua riga di Automazione mostra «non concesso», come un permesso negato. La lettura dell'Automazione dà solo sì o no, e il browser chiuso dà no: il caso «sconosciuto» non esiste.

## What should happen

Un browser chiuso ha l'Automazione sconosciuta: non conta come mancante e la riga dice «Apri Safari per verificare.» (o Chrome), senza pulsante. Risultano mancanti solo il permesso negato o quello non ancora chiesto.

## Fix options

### Four-state reading

Far restituire all'Automazione uno dei quattro stati (concessa, negata, non ancora chiesta, sconosciuta) invece di un sì o no. Il browser chiuso diventa sconosciuto: la riga mostra «Apri Safari per verificare.» senza pulsante e non conta come mancante. Costa: cambia il tipo di ritorno, e chi lo legge (il benvenuto e la finestra dei permessi) va aggiornato insieme. È il modo che segue il Requirement senza eccezioni.

### Check running state apart

Lasciare la lettura com'è e decidere a parte, nella vista, se il browser è in esecuzione. Se è chiuso, la riga mostra «Apri Safari per verificare.» senza leggere l'Automazione. Costa: lo stato di un browser ha due fonti, e la lettura resta un sì o no che non distingue il caso sconosciuto dal negato, quindi la regola del Requirement vale solo nella vista.

## Where in the code

Packages/AxiScreen/Sources/AxiScreen/Permissions.swift, automationPermitted (righe 44-52); Axi/Benvenuto/BenvenutoView.swift, BrowserAutomationRow (righe 160-185)
