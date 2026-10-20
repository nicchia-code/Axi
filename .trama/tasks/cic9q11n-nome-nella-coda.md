---
column: done
technical: false
refs:
  - coda-archiviazione.PROSSIMO_DOCUMENTO
  - coda-archiviazione/Vuota/lettura-schermo.DOCUMENTO_INDIVIDUATO
  - coda-archiviazione/Con documenti in attesa/lettura-schermo.DOCUMENTO_INDIVIDUATO
  - coda-archiviazione/Con documenti in attesa/archiviazione.ARCHIVIATO
  - coda-archiviazione/Con documenti in attesa/archiviazione.NON_ARCHIVIATO
drift: null
proposal: dlfoxco3
agent: false
created: 2026-10-20T07:37:30.232Z
finished: 2026-10-20T07:41:22.021Z
---
# Nome nella coda

Ogni documento in coda conserva il suo nome d'origine, sia quello individuato a schermo (`lettura-schermo.DOCUMENTO_INDIVIDUATO`) sia ogni file rilasciato sul puntino (`utente.RILASCIA_FILE`, il nome del file con la sua estensione), e `coda-archiviazione.PROSSIMO_DOCUMENTO` lo porta con sé quando il documento passa all'archiviazione, così che la nuvoletta possa dire «Sto archiviando “X”» per ogni documento, nell'ordine della coda.
