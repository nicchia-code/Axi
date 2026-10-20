---
status: resolved
resolution: fix-code
refs:
  - mini-chat/Conferma dell'eliminazione
proposal: null
task: qsqmk2wp
origin: null
critical: false
option: 1
note: null
resolvedBy: 4p713jb5
created: 2026-10-18T19:47:52.437Z
---
# Esito dell'eliminazione per OMP

## What happens

Lo strumento request_document_deletion aspetta la scelta dell'utente, ma il risultato di confirm viene scartato: la risposta a OMP è sempre lo stesso testo (la richiesta è stata inoltrata all'utente). OMP non sa se il documento è stato eliminato o se l'utente ha annullato.

## What should happen

Conferma dell'eliminazione: utente.CONFERMA_ELIMINAZIONE → In risposta: il documento viene eliminato e OMP lo sa. utente.ANNULLA_ELIMINAZIONE → In risposta: nulla viene eliminato e OMP sa che l'utente ha rifiutato.

## Fix options

### Rispondere con l'esito del tool

requestDocumentDeletion restituisce il Bool di confirm e OMPHostTools risponde 'documento eliminato' oppure 'eliminazione rifiutata dall'utente'. Costo: il tipo di ritorno del protocollo OMPVaultHostTools cambia e i test del ponte vanno aggiornati.

### Inviare l'esito a OMP a parte

Quando l'utente risponde, l'esito va a OMP come messaggio nella sessione della conversazione, dopo che il tool ha già risposto. Costo: due canali verso OMP e una risposta al tool che resta generica.

## Where in the code

Axi/MiniChat/ChatTools.swift: OMPVaultTools.requestDocumentDeletion (righe 350-357); Packages/AxiOMP/Sources/AxiOMP/OMPHostTools.swift: case request_document_deletion (righe 130-134)
