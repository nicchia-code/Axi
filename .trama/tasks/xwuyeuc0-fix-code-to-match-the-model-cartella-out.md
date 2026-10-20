---
column: done
technical: false
refs:
  - archiviazione/Acquisizione
drift: 1lvde9yf
proposal: null
agent: false
created: 2026-10-18T18:45:27.750Z
finished: 2026-10-18T18:54:28.506Z
---
# Fix code to match the Model: Cartella Outlook per il collegamento

## What happens

Un file già presente nel vault come allegato, o con il nome di un allegato di un'email nel vault, viene collegato a quell'email anche quando non arriva dalla cartella in cui Outlook apre gli allegati.

## What should happen

Un file è allegato di un'email solo se ha il nome di un allegato dell'email e viene dalla cartella in cui Outlook apre gli allegati: la condizione di cartella vale anche per le email già nel vault.

## Chosen option

**Applicare la condizione di cartella anche al ramo del vault**

Il file collegato a un'email del vault deve venire dalla cartella degli allegati di Outlook, come già accade per l'email a schermo. Un file con lo stesso nome, copiato altrove, resta un documento a sé. Costo: poche righe e un test in più.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift:148-149
