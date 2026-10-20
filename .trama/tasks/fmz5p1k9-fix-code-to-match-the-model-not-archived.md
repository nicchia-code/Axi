---
column: done
technical: false
refs:
  - attivita/Esito
  - requirements/ui#attivita
drift: lijtpftg
proposal: null
agent: false
created: 2026-10-19T13:21:35.718Z
finished: 2026-10-19T13:44:56.629Z
---
# Fix code to match the Model: Not-archived caption above reason

## What happens

Per un documento non archiviato la nuvoletta mostra prima la scritta «Non archiviato» e sotto il motivo. Il Requirement chiede che mostri il motivo in una frase, senza intestazione: è la stessa regola già applicata alle nuvolette dei rifiuti di lettura.

## What should happen

Per un documento non archiviato la nuvoletta mostra solo il motivo, in una frase, nella lingua di sistema.

## Chosen option

**Togliere l'intestazione**

Si elimina la scritta «Non archiviato» e la nuvoletta mostra soltanto la frase del motivo, come per i rifiuti di lettura. Il testo dei motivi resta quello attuale. Costo: chi guarda la nuvoletta non vede più a colpo d'occhio che il documento non è stato archiviato, a meno che la frase del motivo non lo dica da sola.

## Where in the code

Axi/Puntino/NuvolettaVista.swift: contenuto, caso nonArchiviato (riga 73 con la scritta prima della frase del motivo)
