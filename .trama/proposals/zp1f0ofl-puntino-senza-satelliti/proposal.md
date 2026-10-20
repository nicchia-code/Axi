---
status: approved
base:
  requirements/ui/companion.md: 9a7fafd98b15092dae496dd8e52d1950762c783351c96cafd566a9589f6c1e3b
  requirements/tech/fondamenta.md: fdd63934342007e2a6649b6da3e2e4138ee4e977cc0a21428ceceb2d1ddc5ccf
delete: []
request: 2026-10-19T16-02-39
created: 2026-10-19T14:08:03.744Z
label: Puntino senza satelliti
---
# Puntino senza satelliti

La richiesta chiede che, mentre l'AI lavora, il puntino diventi tre puntini di sospensione con effetto onda, e che i satelliti spariscano dal personaggio. I tre puntini a onda sono già descritti dal Model e dai Requirements, ma nel codice la chat in risposta non li attiva: li si vede solo nel breve passo dei metadati.

Decisioni:
- I tre puntini compaiono mentre la chat è in `mini-chat/In risposta` e mentre un documento è in `archiviazione/Generazione dei metadati`; le altre richieste all'AI (per esempio la data di ricezione di un'email) mostrano l'attesa.
- L'onda resta quella attuale: le gocce si alzano e si gonfiano una dopo l'altra in un ciclo di circa 2,2 s.
- I tre puntini restano gocce sfumate come il corpo (ombra, luce, riflesso), senza occhi.
- I satelliti spariscono ovunque: sullo schermo, nella barra dei menu e nel disegno di riferimento `Design/puntino.svg`; la trasformazione in tre puntini non ha più satelliti da riassorbire.
