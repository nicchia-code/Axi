---
column: done
technical: false
refs:
  - documento/Nel vault/utente.CONFERMA_ELIMINAZIONE
  - requirements/tech#documento
drift: qabkcq4m
proposal: null
agent: false
created: 2026-10-18T18:45:27.740Z
finished: 2026-10-18T19:01:28.326Z
---
# Fix code to match the Model: Copia rimossa fuori transazione

## What happens

Quando l'utente conferma un'eliminazione, le righe del documento (testo, indice, vettori, tag non più usati e collegamenti) spariscono in un'unica operazione, ma la copia del file nel vault viene cancellata solo dopo che quell'operazione è riuscita. Se la cancellazione del file fallisce, il documento è già fuori dal vault mentre il file resta sul disco, e l'utente riceve un errore.

## What should happen

Il Requirement tecnico dice che l'eliminazione cancella copia, testo, vettori, tag non più usati e collegamenti in un'unica transazione: la copia è compresa. Oggi la copia sta fuori dalla transazione, quindi un fallimento può lasciare un file orfano, o una cancellazione solo parziale, senza che il vault se ne accorga.

## Chosen option

**Spostare la copia dentro l'operazione**

La copia viene spostata in una cartella di scarto del vault dentro la stessa operazione. Se le righe vengono eliminate, la cartella di scarto viene svuotata; se l'operazione fallisce, la copia torna al suo posto. La copia sparisce così insieme al resto e un fallimento non lascia file orfani. Costa: una cartella di scarto da gestire e una pulizia da fare anche al riavvio dell'app, se si chiude a metà.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Vault/VaultStore.swift: confirmDeletion, dove la rimozione delle copie avviene dopo il commit della transazione; removeCopies.
