---
refs:
  - "documento"
  - "requirements/tech#documento"
---
# Documento nel vault

La vita di un documento nel vault: tag correggibili ed eliminazione.

Quando il Task è fatto:
- un documento è Nel vault da quando l'archiviazione emette `archiviazione.ARCHIVIATO`; un'email e ciascuno dei suoi allegati sono documenti distinti e collegati;
- `omp.TAG_CAMBIATI` cambia i tag del documento come chiesto in chat, aggiungendo al vocabolario i tag nuovi e togliendo quelli non più usati;
- `utente.CONFERMA_ELIMINAZIONE` sul documento di cui la chat ha chiesto conferma lo porta a Eliminato: spariscono copia, testo, brani, vettori e collegamenti in un'unica transazione; eliminare un'email elimina anche i suoi allegati, eliminare un allegato lo scollega dall'email;
- senza conferma nessun documento viene eliminato;
- le operazioni sono coperte da test sul database.
