---
column: done
technical: false
refs:
  - attivita/Esito
  - attivita/Nessuna/lettura-schermo.NESSUN_DOCUMENTO
  - attivita/Nessuna/mini-chat.NON_DISPONIBILE
  - attivita/In corso/archiviazione.ARCHIVIATO
  - attivita/In corso/archiviazione.NON_ARCHIVIATO
  - requirements/ui#attivita
drift: null
proposal: zu8hna6x
agent: false
created: 2026-10-19T06:32:37.717Z
finished: 2026-10-19T08:36:09.821Z
---
# Nuvoletta email senza data

Quando la Machine `attivita` entra in Esito, sia da Nessuna (con `lettura-schermo.NESSUN_DOCUMENTO` o `mini-chat.NON_DISPONIBILE`) sia da In corso (con `archiviazione.ARCHIVIATO` o `archiviazione.NON_ARCHIVIATO` quando la coda è vuota), la nuvoletta racconta l'ultimo esito: per un documento archiviato il titolo e i tag, gli allegati di un'email che non è stato possibile prendere e, se la data di ricezione di un'email è rimasta sconosciuta, che è stata archiviata senza; per un documento non archiviato il motivo, compreso il documento già presente nel vault.

A Task finito, per un'email archiviata la cui data di ricezione è rimasta sconosciuta la nuvoletta aggiunge, sotto titolo e tag, la riga «Non ho capito quando è arrivata: l'ho archiviata senza data di ricezione.» in italiano e «I couldn't tell when it arrived: archived without a received date.» in inglese. La riga compare anche quando l'esito è mostrato mentre la coda continua (In corso con `archiviazione.ARCHIVIATO`). Per un'email con data di ricezione nota, per gli altri documenti e per i documenti non archiviati la nuvoletta resta com'è oggi.
