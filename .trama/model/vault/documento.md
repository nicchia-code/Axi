# Documento

Un documento nel vault, dalla sua archiviazione alla sua eventuale eliminazione. Nasce quando l'archiviazione emette `archiviazione.ARCHIVIATO`; un'email e ciascuno dei suoi allegati sono documenti distinti e collegati.

## States

### Nel vault (initial)
Il documento si ritrova cercando in chat e si apre dalla sua copia nel vault.
- `omp.TAG_CAMBIATI` → Nel vault: i tag cambiano come l'utente ha chiesto in chat; i tag nuovi entrano nel vocabolario del vault.
- `utente.CONFERMA_ELIMINAZIONE` → Eliminato: se è il documento di cui la chat ha chiesto conferma; spariscono copia, testo, metadati e indice. Eliminare un'email elimina anche i suoi allegati; eliminare un allegato lo scollega dall'email.

### Eliminato (final)
