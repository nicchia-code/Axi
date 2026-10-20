---
technical: false
refs:
  - attivita
  - requirements/ui#attivita
---
# Rifiuti della lettura nel puntino

Quando il Task è finito, il rifiuto `lettura-schermo.NESSUN_DOCUMENTO` arriva al puntino in ogni stato di `attivita` (oggi `AppDelegate.swift` inoltra da `lettura.esiti` solo `documentoIndividuato` e il rifiuto si perde):
- in Nessuna il puntino passa a Esito e la nuvoletta spiega il motivo del rifiuto;
- in In corso compare una nuvoletta che spiega il rifiuto e il lavoro di archiviazione continua (stato, animazione e numero in coda restano quelli di In corso);
- in Esito la nuvoletta mostra il nuovo rifiuto al posto dell'esito precedente.

La nuvoletta distingue i motivi del rifiuto e usa i testi di `requirements/ui#attivita`, in italiano o in inglese secondo la lingua del sistema: nessun documento («Qui non vedo un documento da archiviare: salvalo prima come file.»), indirizzo non leggibile, manca Accessibility, manca l'Automazione con il browser nominato (Safari o Chrome), errore imprevisto. Il motivo arriva con l'esito della lettura (vedi `NuvolettaVista.swift`, `Attivita.swift`).

Per `archiviazione.NON_ARCHIVIATO` con motivo errore imprevisto, la nuvoletta (in In corso se la coda ha altri documenti e il lavoro continua, in Esito se la coda è vuota, con l'animazione d'errore) mostra «Qualcosa è andato storto: il documento non è stato archiviato.» / «Something went wrong: the document wasn't archived.» invece di «Indexing failed».

Valgono il resto di `requirements/ui#attivita`: nuvoletta accanto al puntino dal lato con più spazio, anche col puntino nascosto, visibile 5 secondi o finché il puntatore ci resta sopra; frasi brevi con l'indicazione di cosa fare.
