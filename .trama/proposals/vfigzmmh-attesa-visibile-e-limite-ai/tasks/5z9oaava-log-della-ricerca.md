---
refs:
  - lettura-schermo/Ricerca del documento
  - requirements/quality#lettura-schermo
---
# Log della ricerca

Ogni ricerca del documento da archiviare registra nel log di sistema quando comincia e, alla fine, quanto è durata e il suo esito: documento individuato oppure rifiuto con il suo motivo, sempre con l'app di origine. Come per i rifiuti, il log non contiene testo letto a schermo né indirizzi completi delle pagine (al più il dominio).

Oggi `ScreenReader.log` in `Packages/AxiScreen/Sources/AxiScreen/ScreenReader.swift` (categoria `lettura-schermo`) registra solo i rifiuti: va aggiunta la registrazione di inizio, durata ed esito di ogni ricerca. Il comportamento della ricerca in sé non cambia.
