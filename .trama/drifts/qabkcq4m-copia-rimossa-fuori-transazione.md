---
status: resolved
resolution: fix-code
refs:
  - documento/Nel vault/utente.CONFERMA_ELIMINAZIONE
  - requirements/tech#documento
proposal: null
task: y8m6q0yo
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:40:56.070Z
---
# Copia rimossa fuori transazione

## What happens

Quando l'utente conferma un'eliminazione, le righe del documento (testo, indice, vettori, tag non più usati e collegamenti) spariscono in un'unica operazione, ma la copia del file nel vault viene cancellata solo dopo che quell'operazione è riuscita. Se la cancellazione del file fallisce, il documento è già fuori dal vault mentre il file resta sul disco, e l'utente riceve un errore.

## What should happen

Il Requirement tecnico dice che l'eliminazione cancella copia, testo, vettori, tag non più usati e collegamenti in un'unica transazione: la copia è compresa. Oggi la copia sta fuori dalla transazione, quindi un fallimento può lasciare un file orfano, o una cancellazione solo parziale, senza che il vault se ne accorga.

## Fix options

### Spostare la copia dentro l'operazione

La copia viene spostata in una cartella di scarto del vault dentro la stessa operazione. Se le righe vengono eliminate, la cartella di scarto viene svuotata; se l'operazione fallisce, la copia torna al suo posto. La copia sparisce così insieme al resto e un fallimento non lascia file orfani. Costa: una cartella di scarto da gestire e una pulizia da fare anche al riavvio dell'app, se si chiude a metà.

### Tenere la copia nel database

La copia del file viene conservata nel database del vault, e la sua rimozione fa parte della stessa transazione che elimina testo, indice e collegamenti. Nessun file esce dal vault e non esistono più file orfani. Costa: il database cresce con i file, la cartella delle copie cambia ruolo, e serve una migrazione che sposti le copie già archiviate.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Vault/VaultStore.swift: confirmDeletion, dove la rimozione delle copie avviene dopo il commit della transazione; removeCopies.
