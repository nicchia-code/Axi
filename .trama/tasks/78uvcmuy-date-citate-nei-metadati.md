---
column: done
technical: false
refs:
  - archiviazione/Generazione dei metadati
  - archiviazione/Estrazione del testo/archiviazione.TESTO_ESTRATTO
  - omp.METADATI_GENERATI
  - requirements/rules#archiviazione/Generazione dei metadati
drift: null
proposal: zu8hna6x
agent: false
created: 2026-10-19T06:32:37.717Z
finished: 2026-10-19T10:43:44.838Z
---
# Date citate nei metadati

Dopo archiviazione.TESTO_ESTRATTO, in archiviazione/Generazione dei metadati Axi chiede a OMP titolo, riassunto, tag, data del documento, lingua e le date citate. L'evento omp.METADATI_GENERATI porta tutti questi metadati, date citate comprese, e porta a Indicizzazione come oggi.

Quando il Task è fatto vale quanto segue.

- Le date citate sono gli eventi, le scadenze e gli appuntamenti di cui parla il documento, scritti in forma relativa o assoluta; i riferimenti storici («fondata nel 1990») non entrano. Ciascuna diventa una data assoluta, con l'ora solo quando il testo la dice (altrimenti resta un giorno), insieme a ciò di cui si tratta e alle parole originali del testo.
- Al massimo 20 date citate per documento, nell'ordine in cui compaiono nel testo. Un documento inviato a sezioni unisce le date di tutte le sezioni, senza doppioni, fino al limite.
- Riferimento per le date relative del contenuto: la data di ricezione per un'email; per gli altri documenti la data del documento se il testo la dice, altrimenti il momento dell'archiviazione. Il riferimento si passa all'AI nella richiesta, con il fuso del Mac (oggi `MetadataPrompts.instructions` in `ArchiveMetadata.swift` non dà alcun riferimento).
- In un'email la cui data di ricezione è rimasta sconosciuta non si passa nessun riferimento: le sue date relative entrano senza data, solo con ciò di cui si tratta e le parole originali; le date assolute del testo entrano comunque. Il riassunto scrive in forma assoluta solo le date che si possono risolvere.
- Un'espressione ambigua o vaga («venerdì») diventa la data più probabile e conserva le parole originali accanto, per verificarla.
- Anche il riassunto scrive le date in forma assoluta. Restano invariati gli altri vincoli: riassunto di al massimo 3 frasi, da 1 a 5 tag che preferiscono il vocabolario del vault, riassunto e tag nella lingua dell'interfaccia, invio intero entro il 50% della finestra di contesto del modello, altrimenti a sezioni.
- La risposta di OMP è JSON validato con le date citate: ogni data citata ha la data in ISO 8601 (con ora e offset se il testo dice l'ora, altrimenti solo il giorno), la descrizione e le parole originali. Una data citata non valida si scarta e le altre restano; una risposta non valida nel suo insieme conta come fallimento (omp.METADATI_FALLITI).
- Le date citate prodotte arrivano al vault con il documento archiviato, nella stessa scrittura atomica degli altri metadati.
