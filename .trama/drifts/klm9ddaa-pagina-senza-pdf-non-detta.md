---
status: resolved
resolution: fix-code
refs:
  - attivita/Esito
proposal: null
task: 9ryqhktc
origin: null
critical: false
option: 1
note: null
resolvedBy: xedrhjzk
created: 2026-10-18T20:10:09.064Z
---
# Pagina senza PDF non detta

## What happens

Quando una pagina web viene archiviata senza il suo PDF, perché il PDF non corrisponde a ciò che l'utente legge a schermo, la nuvoletta mostra solo titolo e tag, come per ogni documento. Non dice che nel vault ci sono solo il testo letto e l'indirizzo della pagina.

## What should happen

Il Modello dice che, in questo caso, l'esito lo dice: Axi conserva solo il testo letto a schermo e l'indirizzo, e la nuvoletta lo indica. Il requisito sul vault prevede la stessa indicazione per il documento salvato, così chi legge sa che la copia non è il PDF della pagina.

## Fix options

### Una riga nella nuvoletta

Sotto il titolo, la nuvoletta di una pagina senza PDF aggiunge una riga che dice che nel vault ci sono solo il testo letto a schermo e l'indirizzo. La riga compare solo in questo caso e resta per la durata della nuvoletta, come il resto dell'esito.

### Indirizzo con la nota

La nuvoletta mostra l'indirizzo della pagina insieme alla nota che il PDF non è stato salvato, così chi legge capisce subito da dove viene il testo. L'indirizzo può essere lungo e va accorciato, e la nota resta visibile per soli cinque secondi, se nessuno ci passa sopra.

## Where in the code

Axi/Puntino/NuvolettaVista.swift, caso archiviato (il campo pdfNonPresente non è letto); Packages/AxiCore/Sources/AxiCore/Attivita/Attivita.swift, campo pdfNonPresente di DocumentoNelVault
