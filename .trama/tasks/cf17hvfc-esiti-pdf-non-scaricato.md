---
column: done
technical: false
refs:
  - attivita/In corso/archiviazione.NON_ARCHIVIATO
  - requirements/ui#attivita
drift: null
proposal: axxxv89o
agent: false
created: 2026-10-19T16:49:18.317Z
finished: 2026-10-19T17:24:42.529Z
---
# Esiti del PDF non scaricato

Quando `archiviazione.NON_ARCHIVIATO` arriva con uno dei due nuovi motivi (il PDF di una pagina web non scaricato, oppure troppo grande), la nuvoletta dell'attività mostra il testo che distingue i due casi, in italiano o in inglese secondo la lingua del sistema, esattamente così:

- Non scaricato: «Non sono riuscito a scaricare questo PDF: scaricalo tu e trascinalo sul puntino.» / «I couldn't download this PDF: download it and drop it on the dot.»
- Troppo grande: «Questo PDF supera i 200 MB: scaricalo tu e trascinalo sul puntino.» / «This PDF is over 200 MB: download it and drop it on the dot.»

Per il resto vale quello che già succede con ogni `NON_ARCHIVIATO`: se in coda ci sono altri documenti, da In corso la nuvoletta mostra il motivo e il lavoro continua; se la coda è vuota, l'attività va in Esito.

Mentre Axi scarica il PDF di una pagina web, il puntino non cambia aspetto: mostra la stessa attesa di ogni archiviazione, senza un nuovo stato visivo.

Codice: in `Axi/Puntino/NuvolettaVista.swift`, `MotivoNonArchiviato.testo` associa i due nuovi motivi (aggiunti a `MotivoNonArchiviato` dalla parte di acquisizione) ai due testi inglesi; in `Axi/Localizable.xcstrings` vanno aggiunte entrambe le chiavi con le traduzioni it/en sopra.
