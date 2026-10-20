---
column: done
technical: false
refs:
  - lettura-schermo/Ricerca del documento
  - lettura-schermo.DOCUMENTO_INDIVIDUATO
  - requirements/tech#lettura-schermo
  - lettura-schermo/Inattiva/utente.CHIEDE_ARCHIVIAZIONE
drift: null
proposal: dlfoxco3
agent: false
created: 2026-10-20T07:37:30.232Z
finished: 2026-10-20T07:39:48.816Z
---
# Nome d'origine a schermo

La ricerca del documento a schermo dà a ogni documento individuato il suo nome d'origine, quello con cui l'utente lo riconosce, e `lettura-schermo.DOCUMENTO_INDIVIDUATO` lo porta con sé.

- File aperto o selezionato nel Finder: il nome del file con la sua estensione, per ogni file della selezione.
- Email di Outlook: l'oggetto, che può mancare.
- Pagina web: il titolo della pagina, letto nell'area della pagina (`AXTitle` di `AXWebArea`) e, se manca, dal titolo della finestra del browser; può mancare, e allora le nuvolette useranno il dominio dell'indirizzo.
- Nulla cambia nel modo in cui Axi trova il documento, nei rifiuti e nei loro motivi.
