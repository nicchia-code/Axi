---
column: done
technical: false
refs:
  - archiviazione/In lavorazione/archiviazione.ERRORE_IMPREVISTO
  - archiviazione.ERRORE_IMPREVISTO
  - archiviazione.NON_ARCHIVIATO
  - requirements/quality#archiviazione
drift: null
proposal: dbk7lcfl
agent: false
created: 2026-10-18T21:57:37.720Z
finished: 2026-10-18T22:07:56.004Z
---
# Errore imprevisto in archiviazione

Quando il Task è finito, se un passo dell'archiviazione si interrompe per un errore non previsto da nessun altro esito, si emette `ERRORE_IMPREVISTO` e da In lavorazione si torna in Inattiva: Axi resta aperto, il documento non viene archiviato, nel vault non resta nulla di esso (scrittura atomica, `requirements/tech#archiviazione`) e si emette `NON_ARCHIVIATO` con il nuovo motivo «errore imprevisto», accanto a quelli già previsti (già presente, OMP non pronto o fermato, benvenuto non completato, documento illeggibile, testo assente, AI o indicizzazione non riuscite). La coda passa poi al documento successivo come per ogni altro mancato archivio.

Secondo `requirements/quality#archiviazione`:
- nessun errore durante l'archiviazione chiude Axi;
- un errore non previsto non si racconta come uno dei motivi previsti: oggi `ArchivingPipeline.swift` (righe ~60-62 e ~439-445) trasforma ogni errore inatteso in «indicizzazione non riuscita», e va invece distinto come «errore imprevisto»; gli errori della creazione del PDF di pagina web non vanno più persi in silenzio (righe ~187-192);
- ogni fallimento di un passo dell'archiviazione, compresi il PDF di pagina web non creato o scartato perché non corrisponde e l'errore imprevisto, si registra con `os.Logger` (subsystem `Axi`, categoria `archiviazione`) indicando passo, motivo e origine del documento, senza testo del documento e senza indirizzi completi delle pagine (al più il dominio).

Il motivo «errore imprevisto» va aggiunto all'esito non archiviato in `AxiCore` così che il puntino lo mostri con il testo già definito nei requirement del companion.
