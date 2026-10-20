---
refs:
  - attivita
  - tempo.NUVOLETTA_SCADUTA
  - requirements/ui#attivita
---
# Ricerca e nuvoletta di avvio

Nuovo State `In ricerca` in `attivita`: da `Nessuna` e da `Esito`, `utente.CHIEDE_ARCHIVIAZIONE` porta a `In ricerca`, e il puntino mostra l'attesa fin dal momento della richiesta (anche mentre la ricerca aspetta un'altra lettura dello schermo). Da `In ricerca`: `PROSSIMO_DOCUMENTO` porta a `In corso` con la nuvoletta di avvio; `NESSUN_DOCUMENTO` porta a `Esito` (nuvoletta di rifiuto) oppure resta `In ricerca` se un'altra richiesta di archiviazione aspetta ancora la sua ricerca; `mini-chat.NON_DISPONIBILE` resta `In ricerca` mostrando la nuvoletta.

Nuvoletta di avvio: «Archivio “nome”…» / «Archiving “name”…», dove il nome è il nome del file, l'oggetto dell'email o il titolo della pagina web come l'utente li vede. Compare su `PROSSIMO_DOCUMENTO` solo da `Nessuna`, `In ricerca` ed `Esito`; non per i documenti successivi della stessa serie (già `In corso`). Non mostra alcun segnale di esito sul personaggio; dura 5 s o finché è sotto il puntatore; un esito arrivato prima la sostituisce; un clic la chiude (`attivita/In corso/utente.CLIC_NUVOLETTA`). `tempo.NUVOLETTA_SCADUTA` in `In corso` fa sparire la nuvoletta e il lavoro continua: l'evento ora copre anche la nuvoletta di avvio.

Nuovo testo di esito per un documento non archiviato perché l'AI non ha risposto in tempo: «L'AI non ha risposto in tempo: riprova tra poco.» / «The AI didn't answer in time: try again shortly.». Il motivo è prodotto dalla pipeline di archiviazione (altro Task); qui va solo mostrato il testo, probabilmente in `Axi/Puntino/NuvolettaVista.swift` e `Axi/Localizable.xcstrings`.

Il nome per la nuvoletta di avvio deve arrivare all'attività dall'elemento in coda: probabilmente `Packages/AxiCore/Sources/AxiCore/Attivita/Attivita.swift`, `ArchivingService.swift` (`prossimoDocumento`), `Axi/Puntino/PuntinoController.swift` e `PuntinoVista.swift` (`animato`).
