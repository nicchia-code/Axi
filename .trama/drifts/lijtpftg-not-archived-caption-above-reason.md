---
status: resolved
resolution: fix-code
refs:
  - attivita/Esito
  - requirements/ui#attivita
proposal: null
task: fmz5p1k9
origin: null
critical: false
option: 1
note: null
resolvedBy: lqzwxev6
created: 2026-10-19T12:43:31.995Z
---
# Not-archived caption above reason

## What happens

Per un documento non archiviato la nuvoletta mostra prima la scritta «Non archiviato» e sotto il motivo. Il Requirement chiede che mostri il motivo in una frase, senza intestazione: è la stessa regola già applicata alle nuvolette dei rifiuti di lettura.

## What should happen

Per un documento non archiviato la nuvoletta mostra solo il motivo, in una frase, nella lingua di sistema.

## Fix options

### Togliere l'intestazione

Si elimina la scritta «Non archiviato» e la nuvoletta mostra soltanto la frase del motivo, come per i rifiuti di lettura. Il testo dei motivi resta quello attuale. Costo: chi guarda la nuvoletta non vede più a colpo d'occhio che il documento non è stato archiviato, a meno che la frase del motivo non lo dica da sola.

### Unire l'intestazione al motivo

La scritta «Non archiviato» diventa parte della stessa frase, per esempio con i due punti prima del motivo, così la nuvoletta resta una sola frase e dice anche che il documento non è stato archiviato. Costo: il testo dei motivi va riscritto in italiano e in inglese, e le frasi diventano più lunghe.

## Where in the code

Axi/Puntino/NuvolettaVista.swift: contenuto, caso nonArchiviato (riga 73 con la scritta prima della frase del motivo)
