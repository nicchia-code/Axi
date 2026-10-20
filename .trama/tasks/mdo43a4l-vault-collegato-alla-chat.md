---
column: done
technical: false
refs:
  - documento/Nel vault/omp.TAG_CAMBIATI
  - documento/Nel vault/utente.CONFERMA_ELIMINAZIONE
  - requirements/tech#documento
drift: null
proposal: null
agent: false
created: 2026-10-18T18:40:51.075Z
finished: 2026-10-18T18:59:08.428Z
---
# Vault collegato alla chat

Quando la chat cambia i tag di un documento o l'utente conferma un'eliminazione, il vault deve cambiare davvero. Oggi le operazioni del vault esistono e sono coperte da test, ma nessuna parte dell'app le collega alla chat: gli strumenti della chat non hanno un'implementazione reale sul vault e la chat non è mai costruita con il vault. Quando il Task è fatto: il documento richiesto ha i tag chiesti, i tag nuovi entrano nel vocabolario e quelli non più usati escono; alla conferma il documento sparisce con copia, testo, indice e collegamenti, ed eliminare un'email elimina anche i suoi allegati; senza conferma non si elimina nulla; l'app costruisce il vault una volta e lo passa sia alla chat sia all'archiviazione.
