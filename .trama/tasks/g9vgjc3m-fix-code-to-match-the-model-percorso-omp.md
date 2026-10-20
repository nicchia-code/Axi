---
column: done
technical: false
refs:
  - impostazioni
drift: 3kva9nnv
proposal: null
agent: false
created: 2026-10-18T21:21:35.723Z
finished: 2026-10-18T21:29:23.321Z
---
# Fix code to match the Model: Percorso OMP non applicato subito

## What happens

Il percorso di OMP scritto nella finestra viene salvato e fatto valere sulla connessione solo quando l'utente preme Invio o quando lascia il campo. Fino ad allora una modifica non ha effetto. Le chiavi Azure, l'endpoint e il modello AI invece valgono subito, a ogni modifica.

## What should happen

La finestra dice che ogni cambiamento vale subito. Anche il percorso di OMP, appena l'utente lo modifica, deve essere salvato e fatto valere sulla connessione, senza attendere che lasci il campo.

## Chosen option

**Applicare solo i percorsi validi**

Ogni modifica viene salvata subito, ma la connessione a OMP viene riavviata solo quando il percorso scritto indica un programma esistente e eseguibile. I percorsi incompleti non disturbano OMP. Costo: la finestra controlla il file a ogni modifica, e fino a un percorso valido la connessione resta sul percorso precedente.

## Where in the code

Axi/Impostazioni/ImpostazioniView.swift, sezione OMP (campo Percorso: salvataggio a Invio o alla perdita del fuoco); Axi/Impostazioni/ImpostazioniModel.swift, cambiaPercorsoOMP
