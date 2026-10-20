---
column: done
technical: false
refs:
  - coda-archiviazione
  - coda-archiviazione/Vuota
  - coda-archiviazione/Con documenti in attesa
  - utente.RILASCIA_FILE
  - lettura-schermo.DOCUMENTO_INDIVIDUATO
  - coda-archiviazione.PROSSIMO_DOCUMENTO
drift: null
proposal: null
agent: false
created: 2026-10-18T18:40:45.822Z
finished: 2026-10-18T20:14:16.041Z
---
# Collegare la coda all'app

Quando l'utente rilascia file sul puntino, o la ricerca trova un documento archiviabile, quei documenti entrano nella coda di archiviazione e vengono archiviati uno alla volta, nell'ordine di arrivo; ogni archiviazione che parte comunica l'inizio all'attività. Oggi la logica della coda esiste ma l'app non la collega: il punto di composizione dell'app è vuoto, nessuno invia i documenti alla coda e i file rilasciati sul puntino non diventano documenti archiviabili. Fatto quando l'app crea la coda all'avvio, instrada i file rilasciati e i documenti trovati dalla ricerca verso la coda, e l'inizio di ogni archiviazione raggiunge l'attività, senza cambiare gli stati della coda.
