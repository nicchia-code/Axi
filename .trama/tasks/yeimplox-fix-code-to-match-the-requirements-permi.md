---
column: done
technical: true
refs:
  - requirements/ui#permessi
drift: t7hbem7s
proposal: null
agent: false
created: 2026-10-19T03:02:16.444Z
finished: 2026-10-19T03:14:34.243Z
---
# Fix code to match the Requirements: Permission row texts differ

## What happens

La spiegazione di Accessibility dice solo che serve a leggere il testo delle finestre scelte, senza dire che serve anche ai tasti Spotlight e Dettatura. La nota su Firefox dice solo che non ne ha bisogno, senza dire che gli basta Accessibility.

## What should happen

La spiegazione di Accessibility dice che serve a leggere le finestre e a usare i tasti Spotlight e Dettatura. La nota su Firefox dice «Firefox non ne ha bisogno: gli basta Accessibility.» / «Firefox doesn't need it: Accessibility is enough.».

## Chosen option

**Use Requirement wording now**

Cambiare subito i due testi delle righe del benvenuto con quelli del Requirement, in entrambe le lingue, così il benvenuto è conforme anche prima della finestra dei permessi. Costa: si tocca il benvenuto prima che lo faccia il lavoro sulle righe condivise, che poi andrà ritoccato.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift, PermissionsStep (riga 81, spiegazione di Accessibility) e BrowserAutomationRow (riga 178, nota su Firefox)
