---
status: rejected
base:
  companion/attivita.md: d582a46f35466dabd96639013a8a1ea1a355d3af98cafda36b53ffb7ade14d1d
  vault/archiviazione.md: f38a2a010eecfd9ef5e6cb0a5b241f54a6db7ec156acafc64edfc1e142eadccc
  actors/tempo.md: b5fee1ed3e227e00859925a90e1bd7779bca6d7725a8d588448b34fc44558950
  requirements/ui/companion.md: ff859bc00323469d149f1c2b3c27d786cda88d4c1bad58d848cd08377be20625
  requirements/ui/finestre.md: fd0a651ba775c6ca61d01301d07114cd6512fda6b2ee356e59c5cf16bccfc25d
  requirements/rules/ai.md: a7e4a2215440c50b2d8ea3a247bec839877d17a670d7e01cb43eb6719008decd
  requirements/quality/affidabilita.md: 897afe6f6fb473df5fd5359bc5f9817d71ecf4594390aa4cfa6e0f99c9e469ed
  requirements/tech/documenti.md: 2dbb3ca4a01405fc4b22b255f34f5d9723cca5533c1937f9ac61ff7b2295fa44
delete: []
request: 2026-10-19T20-31-20
created: 2026-10-19T18:49:40.536Z
label: Attesa visibile
---
# Attesa visibile e limite AI

Archiviando un PDF da Safari con il puntino nascosto, l'utente non ha visto nulla per oltre due minuti: la richiesta dei metadati a OMP è rimasta appesa (connessione col provider chiusa, nuovo tentativo di OMP) e il documento è entrato nel vault solo dopo 2 minuti e 15 secondi. Nel frattempo l'icona della barra sembrava ferma e non c'era nessuna nuvoletta. Axi deve far capire subito che ha preso la richiesta e non deve aspettare l'AI senza limite.

Decisioni:
- Generazione dei metadati: ogni richiesta all'AI ha un limite di 60 s; scaduto, il documento non viene archiviato e l'esito dice che l'AI non ha risposto in tempo, con un testo proprio.
- Nuvoletta di avvio: quando il puntino comincia a lavorare, una nuvoletta dice «Archivio “nome”…» con il nome dell'origine (nome del file, oggetto dell'email, titolo della pagina); resta 5 secondi come le altre, il clic la chiude.
- Con più documenti in coda la nuvoletta di avvio compare solo per il primo; per gli altri bastano gli esiti e il contatore.
- Il personaggio mostra l'attesa dal momento della richiesta di archiviazione, anche mentre Axi cerca il documento a schermo (nuovo stato `attivita/In ricerca`).
- Nella barra dei menu l'attesa è più marcata: il corpo si gonfia di circa il 10% dell'altezza; i tre puntini restano uguali. L'ondeggiamento del contorno di cui si parlava nell'intervista non c'è più dopo la Proposal j7smnsvx (puntino a ellissi), quindi cambia solo il respiro.
- Il log di sistema registra inizio, durata ed esito di ogni passo dell'archiviazione e della ricerca del documento a schermo.
- La ricerca del documento a schermo non cambia: nessun limite di tempo e nessuno stop anticipato.

Scelte mie, da verificare:
- Il limite è un Event del tempo (`tempo.ATTESA_METADATI_SCADUTA`); allo scadere Axi interrompe il turno di OMP con `abort`, e il limite sta dietro un orologio sostituibile, così i test non aspettano 60 s.
- Con un documento inviato a sezioni il limite vale per ogni richiesta (ogni sezione e la richiesta finale), e i nuovi tentativi interni di OMP restano dentro il limite.
- In `attivita/In corso` una nuvoletta sparisce allo scadere dei suoi secondi, e il clic chiude la nuvoletta di avvio.
- Una richiesta all'AI scaduta si registra nel log come fallimento della generazione dei metadati, con motivo «tempo scaduto».

## Already present
- `archiviazione/Estrazione del testo/archiviazione.TESTO_ESTRATTO` — Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift:57-60, `extract` poi `describe`
- `coda-archiviazione/Con documenti in attesa/archiviazione.NON_ARCHIVIATO` — Packages/AxiCore/Sources/AxiCore/Archive/ArchiveQueue.swift:50-52, `.notArchived` libera la coda e passa al documento successivo
