---
status: resolved
resolution: fix-code
refs:
  - benvenuto
proposal: null
task: 3crdhl7i
origin: czjivj7o
critical: false
option: 1
note: null
resolvedBy: hrfxsylt
created: 2026-10-19T08:17:54.406Z
---
# Shared permission rows missing

## What happens

Il passo Permessi del benvenuto disegna ancora le sue righe: Accessibility, Registrazione schermo e Automazione dei browser. Le righe condivise con la finestra dei permessi non esistono ancora, perché quella finestra è un Task ancora da fare. Il passo quindi non può mostrare le stesse righe della finestra. Il Task descrive il Finder fuori dal passo, mentre il Model lo include.

## What should happen

Il Model dice che il passo dei permessi mostra le stesse righe della finestra dei permessi, più la riga OMP, e che spiega anche l'Automazione del Finder. Il Task chiede di riusare le righe condivise, ma queste non sono ancora costruite e il Task non dice se costruirle qui. Senza una decisione il passo non può essere completato come descritto.

## Fix options

### Aspettare la finestra dei permessi

Questo Task resta in doing e riprende dopo il Task della finestra dei permessi, così il benvenuto riusa le sue righe già pronte. Il passo mantiene le sue righe fino ad allora. Costa attendere e lasciare il Finder per il Task dedicato.

### Costruire le righe condivise qui

Le righe della finestra dei permessi vengono costruite ora in un punto comune, e il benvenuto le usa subito. La finestra dei permessi le riusa invece di crearne altre. Costa coordinare i due Task, per evitare di costruire le stesse righe due volte.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift (PermissionsStep, PermissionRow, BrowserAutomationRow); nessuna riga condivisa in Axi/ o Packages/AxiScreen/
