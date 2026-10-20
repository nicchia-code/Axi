---
column: done
technical: true
refs:
  - requirements/ui#impostazioni
drift: 2b90c10g
proposal: null
agent: false
created: 2026-10-18T18:45:27.770Z
finished: 2026-10-18T19:22:53.227Z
---
# Fix code to match the Requirements: Modello predefinito di OMP

## What happens

Quando l'utente non ha scelto un modello, la finestra mostra come selezionato il primo modello dell'elenco di OMP. Il modello che OMP usa davvero per le sessioni non viene letto da Axi, quindi la selezione mostrata può non essere quella in uso.

## What should happen

Il modello preselezionato è quello predefinito di OMP, come dice il Requisito della finestra.

## Chosen option

**Leggere il modello predefinito di OMP**

Dopo l'avvio, Axi chiede a OMP il modello della sessione e lo preseleziona quando l'utente non ne ha scelto uno. La finestra segue così il modello reale di OMP. Costo: una richiesta in più all'avvio, e la preselezione compare solo quando la connessione è pronta.

## Where in the code

Axi/Impostazioni/ImpostazioniModel.swift (modelloSelezionato, righe 36-45); Packages/AxiOMP/Sources/AxiOMP/OMPConnection.swift (start: nessuna richiesta get_state, quindi il modello della sessione non viene letto)
