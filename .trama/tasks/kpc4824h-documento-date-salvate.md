---
column: done
technical: false
refs:
  - documento
  - requirements/data#documento
  - requirements/data#General
drift: null
proposal: zu8hna6x
agent: false
created: 2026-10-19T06:32:37.717Z
finished: 2026-10-19T06:40:05.829Z
---
# Date assolute nel vault

Quando il Task è fatto, il vault conserva per ogni `documento` le date rese assolute come dice il Model:

- Per un'email la data di ricezione assoluta può mancare: `email_details.sent_at` diventa nullable e non si riempie più con la data di archiviazione quando la data non si capisce. Se l'email veniva da Outlook, si conserva anche la data così come era mostrata a schermo, in testo, accanto alla data assoluta.
- Ogni documento conserva le date citate nel suo contenuto, al massimo 20. Ciascuna ha la data (con l'ora solo se il testo la dice), di cosa si tratta e le parole originali del testo; la data manca solo per una data relativa di un'email con data di ricezione sconosciuta. Le date citate si cancellano insieme al documento.
- Regola generale: le date rese assolute si interpretano nel fuso orario del Mac al momento della lettura o dell'archiviazione e si conservano come istante con il suo offset; una data senza ora si conserva come giorno, senza ora inventata. Vale per la data di ricezione dell'email, per la data del documento e per le date citate.
- Una migrazione del database (`VaultSchema.swift`) porta i vault esistenti al nuovo schema senza perdere documenti: `sent_at` nullable, la colonna per la data mostrata da Outlook, la tabella delle date citate. I dati già salvati restano leggibili.

Il `documento` come Machine non cambia: cambia solo ciò che il vault conserva per lui.
