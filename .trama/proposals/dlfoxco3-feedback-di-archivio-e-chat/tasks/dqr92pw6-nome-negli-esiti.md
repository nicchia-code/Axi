---
refs:
  - archiviazione.ARCHIVIATO
  - archiviazione.NON_ARCHIVIATO
  - "archiviazione/Inattiva/coda-archiviazione.PROSSIMO_DOCUMENTO"
---
# Nome negli esiti

Gli esiti dell'archiviazione portano il nome d'origine del documento ricevuto con `coda-archiviazione.PROSSIMO_DOCUMENTO`:

- `archiviazione.ARCHIVIATO`: nome d'origine, titolo, tag, allegati non presi e, per un'email, se la data di ricezione è rimasta sconosciuta.
- `archiviazione.NON_ARCHIVIATO`: nome d'origine e motivo, per ogni motivo, compresi già presente, OMP non pronto o fermato, benvenuto non completato ed errore imprevisto.
