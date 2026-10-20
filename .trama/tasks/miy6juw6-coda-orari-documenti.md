---
column: done
technical: false
refs:
  - coda-archiviazione/Con documenti in attesa/archiviazione.ARCHIVIATO
  - coda-archiviazione/Vuota/lettura-schermo.DOCUMENTO_INDIVIDUATO
  - coda-archiviazione/Con documenti in attesa/lettura-schermo.DOCUMENTO_INDIVIDUATO
drift: null
proposal: zu8hna6x
agent: false
created: 2026-10-19T06:32:37.717Z
finished: 2026-10-19T06:37:34.646Z
---
# Coda con orari di lettura

`lettura-schermo.DOCUMENTO_INDIVIDUATO` ora porta con sé il momento della lettura e, per un'email di Outlook, la data di ricezione così come è mostrata. La coda di archiviazione deve conservarli insieme a ciascun documento, così che l'archiviazione li riceva e li usi.

In Vuota, su `lettura-schermo.DOCUMENTO_INDIVIDUATO`: se nessuna archiviazione è in corso e il documento individuato è uno solo, passa subito all'archiviazione con il suo momento della lettura e, se è un'email di Outlook, con la data di ricezione così come è mostrata. Se un'archiviazione è in corso o i file selezionati nel Finder sono più di uno, si va in Con documenti in attesa: il primo passa all'archiviazione se nessuna è in corso, gli altri aspettano nell'ordine, ognuno con il momento della lettura portato dall'evento.

In Con documenti in attesa, su `lettura-schermo.DOCUMENTO_INDIVIDUATO`: il documento, o i file selezionati nel Finder, si aggiungono in fondo alla coda conservando il momento della lettura e, per un'email di Outlook, la data di ricezione così come è mostrata. Quando un documento in attesa passa all'archiviazione, questi dati arrivano invariati: non vengono ricalcolati né sostituiti con il momento in cui il documento esce dalla coda.

Su `archiviazione.ARCHIVIATO` in Con documenti in attesa, il primo documento in coda passa all'archiviazione e ne restano altri, come oggi. L'evento ora dice anche, per un'email, se la sua data di ricezione è rimasta sconosciuta; la coda non lo interpreta né lo modifica, e l'informazione resta disponibile invariata a chi ascolta l'esito.
