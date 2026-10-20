---
status: approved
base:
  visione/lettura-schermo.md: 8c9e676a35b3f756a5d863d47fcab0fc11cae3292170d405c83a6fd2d4230c18
  requirements/tech/documenti.md: a6e5bb2d029da910ef9718bc9ef2b2320a43e7c8fbbcdc9e905b65dae3cbb898
delete: []
request: 2026-10-19T19-57-51
created: 2026-10-19T18:02:41.139Z
label: Cartelle
---
# Cartelle non archiviabili

Lo sviluppatore segnala che l'archiviazione dei PDF dà ancora «The document cannot be read», mentre la chat contestuale funziona. Dal log di sistema i tentativi falliscono nel passo di acquisizione con origine Safari: un PDF aperto nel browser viene trattato come pagina web senza testo, perché il Task «Scaricamento PDF delle pagine web» (Proposal axxxv89o, già approvata) è ancora da fare. Il Model descrive già il comportamento voluto: questa Proposal non lo cambia, e la correzione dei PDF nel browser è quel Task.

Nello stesso log c'è un tentativo fallito con Terminal in primo piano: la sua finestra indica come documento una cartella, che Axi prova ad archiviare come un file. Questa Proposal stabilisce che una cartella non è un documento archiviabile.

Decisioni prese con lo sviluppatore:
- PDF aperti in Safari, Chrome o Firefox: si scaricano dall'indirizzo come già approvato; nessun cambio al Model, si esegue il Task in todo.
- Pagina web (non PDF) di cui Accessibility non dà il testo: resta com'è, con l'esito «documento illeggibile».
- Un'app in primo piano che mostra una cartella invece di un file (per esempio Terminal con la sua cartella corrente, o un browser su un indirizzo file:// di una cartella): nessun documento, come nel Finder; la nuvoletta dice che a schermo non c'è un documento archiviabile.

Assunzioni da verificare:
- Che la finestra di Terminal indichi la sua cartella corrente come documento è una deduzione dal log, non verificata a schermo.

## Already present
- `lettura-schermo/Inattiva/utente.CHIEDE_ARCHIVIAZIONE` — Packages/AxiScreen/Sources/AxiScreen/ScreenReader.swift:196-197 (`.archiving` → `searchDocument`)
