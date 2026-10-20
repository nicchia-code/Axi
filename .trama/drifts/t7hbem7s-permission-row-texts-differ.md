---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#permessi
proposal: null
task: yeimplox
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:40:45.552Z
---
# Permission row texts differ

## What happens

La spiegazione di Accessibility dice solo che serve a leggere il testo delle finestre scelte, senza dire che serve anche ai tasti Spotlight e Dettatura. La nota su Firefox dice solo che non ne ha bisogno, senza dire che gli basta Accessibility.

## What should happen

La spiegazione di Accessibility dice che serve a leggere le finestre e a usare i tasti Spotlight e Dettatura. La nota su Firefox dice «Firefox non ne ha bisogno: gli basta Accessibility.» / «Firefox doesn't need it: Accessibility is enough.».

## Fix options

### Use Requirement wording now

Cambiare subito i due testi delle righe del benvenuto con quelli del Requirement, in entrambe le lingue, così il benvenuto è conforme anche prima della finestra dei permessi. Costa: si tocca il benvenuto prima che lo faccia il lavoro sulle righe condivise, che poi andrà ritoccato.

### Wait for shared rows

Lasciare i testi attuali e allinearli al Requirement quando le righe condivise saranno costruite con la finestra dei permessi, così i testi si cambiano una volta sola. Costa: per tutto il Run il benvenuto mostra testi diversi dal Requirement.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift, PermissionsStep (riga 81, spiegazione di Accessibility) e BrowserAutomationRow (riga 178, nota su Firefox)
