---
refs:
  - "coda-archiviazione"
  - "requirements/rules#coda-archiviazione"
---
# Coda di archiviazione

La coda che fa archiviare i documenti uno alla volta, nell'ordine di richiesta.

Quando il Task è fatto:
- da Vuota, `lettura-schermo.DOCUMENTO_INDIVIDUATO` resta in Vuota ed emette `PROSSIMO_DOCUMENTO` se nessuna archiviazione è in corso; se un'archiviazione è in corso porta a Con documenti in attesa con il documento in coda;
- da Vuota, `utente.RILASCIA_FILE` con un solo file e nessuna archiviazione in corso emette `PROSSIMO_DOCUMENTO` e resta in Vuota; con più file o con un'archiviazione in corso porta a Con documenti in attesa, facendo partire subito il primo file se nessuna archiviazione è in corso;
- in Con documenti in attesa, nuovi documenti e file si aggiungono in fondo;
- in Con documenti in attesa, `archiviazione.ARCHIVIATO` e `archiviazione.NON_ARCHIVIATO` fanno partire il primo documento in coda emettendo `PROSSIMO_DOCUMENTO`, restando in Con documenti in attesa se ne restano altri o tornando in Vuota se era l'ultimo;
- l'ordine è quello di arrivo, e per più file rilasciati insieme quello in cui il Finder li consegna;
- il numero di documenti in attesa è disponibile al puntino;
- le transizioni sono coperte da test.
