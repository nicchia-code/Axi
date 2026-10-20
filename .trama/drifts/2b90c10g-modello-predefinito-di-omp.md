---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#impostazioni
proposal: null
task: p9fwwcey
origin: null
critical: false
option: 1
note: null
resolvedBy: 2j8ba76j
created: 2026-10-18T18:41:50.399Z
---
# Modello predefinito di OMP

## What happens

Quando l'utente non ha scelto un modello, la finestra mostra come selezionato il primo modello dell'elenco di OMP. Il modello che OMP usa davvero per le sessioni non viene letto da Axi, quindi la selezione mostrata può non essere quella in uso.

## What should happen

Il modello preselezionato è quello predefinito di OMP, come dice il Requisito della finestra.

## Fix options

### Leggere il modello predefinito di OMP

Dopo l'avvio, Axi chiede a OMP il modello della sessione e lo preseleziona quando l'utente non ne ha scelto uno. La finestra segue così il modello reale di OMP. Costo: una richiesta in più all'avvio, e la preselezione compare solo quando la connessione è pronta.

### Mostrare il predefinito come voce esplicita

Nel menu dei modelli compare la voce Predefinito di OMP con il nome del modello che OMP userebbe. La scelta nulla resta, ma diventa visibile. Costo: un elemento in più nell'elenco e un significato nuovo per la scelta vuota, da spiegare nella finestra.

## Where in the code

Axi/Impostazioni/ImpostazioniModel.swift (modelloSelezionato, righe 36-45); Packages/AxiOMP/Sources/AxiOMP/OMPConnection.swift (start: nessuna richiesta get_state, quindi il modello della sessione non viene letto)
