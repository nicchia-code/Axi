# Coda di archiviazione

I documenti che aspettano di essere archiviati. Le archiviazioni avvengono una alla volta, nell'ordine in cui l'utente le ha chieste.

## States

### Vuota (initial)
- `lettura-schermo.DOCUMENTO_INDIVIDUATO` → Vuota: se nessuna archiviazione è in corso, il documento passa subito all'archiviazione.
- `lettura-schermo.DOCUMENTO_INDIVIDUATO` → Con documenti in attesa: se un'archiviazione è in corso, il documento aspetta il suo turno.
- `utente.RILASCIA_FILE` → Vuota: se nessuna archiviazione è in corso e il file rilasciato è uno solo, passa subito all'archiviazione.
- `utente.RILASCIA_FILE` → Con documenti in attesa: se un'archiviazione è in corso o i file rilasciati sono più di uno; il primo file passa all'archiviazione se nessuna è in corso, gli altri aspettano nell'ordine.

### Con documenti in attesa
- `lettura-schermo.DOCUMENTO_INDIVIDUATO` → Con documenti in attesa: il documento si aggiunge in fondo alla coda.
- `utente.RILASCIA_FILE` → Con documenti in attesa: i file si aggiungono in fondo alla coda.
- `archiviazione.ARCHIVIATO` → Con documenti in attesa: il primo documento in coda passa all'archiviazione e ne restano altri.
- `archiviazione.ARCHIVIATO` → Vuota: passa all'archiviazione l'ultimo documento in coda.
- `archiviazione.NON_ARCHIVIATO` → Con documenti in attesa: il primo documento in coda passa all'archiviazione e ne restano altri.
- `archiviazione.NON_ARCHIVIATO` → Vuota: passa all'archiviazione l'ultimo documento in coda.

## Events

### PROSSIMO_DOCUMENTO
Emesso quando un documento passa dalla coda all'archiviazione.
