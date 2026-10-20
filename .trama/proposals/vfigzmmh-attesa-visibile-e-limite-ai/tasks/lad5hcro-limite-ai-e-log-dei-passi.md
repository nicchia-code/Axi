---
refs:
  - archiviazione/Generazione dei metadati
  - archiviazione.NON_ARCHIVIATO
  - tempo.ATTESA_METADATI_SCADUTA
  - requirements/rules#archiviazione/Generazione dei metadati
  - requirements/tech#archiviazione
  - requirements/quality#archiviazione
---
# Limite AI e log dei passi

Ogni richiesta all'AI per i metadati (quella dell'intero documento oppure, per un documento diviso in sezioni, quella di ciascuna sezione e quella finale) ha un limite di 60 secondi dal suo invio; i tentativi che OMP ripete da sé restano dentro questo limite. Allo scadere (`tempo.ATTESA_METADATI_SCADUTA`) Axi interrompe il turno di OMP con il comando `abort` (`OMPClient.abort()` in `Packages/AxiOMP/Sources/AxiOMP/OMPClient.swift`; oggi `prompt` è inviato con `timeout: nil`), il documento non viene archiviato, nel vault non resta nulla e `NON_ARCHIVIATO` riporta il nuovo motivo «AI che non ha risposto in tempo», distinto da `aiNonRisponde` (risposta non valida). Il limite passa da un orologio sostituibile, così i test non aspettano 60 secondi. Probabili punti nel codice: `Packages/AxiCore/Sources/AxiCore/Archive/ArchivingPipeline.swift` (`describe` e l'enum dei motivi verso la riga 760) e `MetadataGenerator`.

Ogni passo dell'archiviazione — acquisizione (compresi lo scaricamento o la creazione del PDF di una pagina web e la richiesta della data di ricezione di una email), controllo dei duplicati, estrazione del testo, generazione dei metadati con ciascuna richiesta all'AI, indicizzazione — registra nel log quando inizia e, alla fine, la durata e l'esito, con l'origine del documento e le stesse esclusioni dei fallimenti: nessun testo del documento, degli indirizzi al più il dominio. Una richiesta all'AI scaduta è registrata come fallimento della generazione dei metadati con motivo «tempo scaduto». Logger: `os.Logger`, subsystem `Axi`, category `archiviazione`.
