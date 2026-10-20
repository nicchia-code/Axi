---
status: resolved
resolution: fix-code
refs:
  - archiviazione/Acquisizione
proposal: null
task: xwuyeuc0
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:41:23.741Z
---
# Cartella Outlook per il collegamento

## What happens

Un file già presente nel vault come allegato, o con il nome di un allegato di un'email nel vault, viene collegato a quell'email anche quando non arriva dalla cartella in cui Outlook apre gli allegati.

## What should happen

Un file è allegato di un'email solo se ha il nome di un allegato dell'email e viene dalla cartella in cui Outlook apre gli allegati: la condizione di cartella vale anche per le email già nel vault.

## Fix options

### Applicare la condizione di cartella anche al ramo del vault

Il file collegato a un'email del vault deve venire dalla cartella degli allegati di Outlook, come già accade per l'email a schermo. Un file con lo stesso nome, copiato altrove, resta un documento a sé. Costo: poche righe e un test in più.

### Lasciare il comportamento e aggiornare la regola

Il collegamento per nome vale anche fuori dalla cartella di Outlook. Un file scaricato altrove con lo stesso nome finirebbe sotto l'email. Costo: la regola del Requirement va riscritta e il rischio di collegamenti sbagliati resta.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift:148-149
