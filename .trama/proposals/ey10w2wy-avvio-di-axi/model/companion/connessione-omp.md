# Connessione OMP

Il collegamento tra Axi e OMP. Axi avvia OMP quando parte e lo usa per archiviare e per la chat; quando la connessione non è pronta, archiviazione e chat non sono disponibili.

## States

### Avvio (initial)
Axi avvia OMP con il percorso indicato nelle impostazioni, o cercandolo sul Mac se non è indicato.
- `omp.PRONTO` → Pronta
- `omp.NON_AVVIABILE` → Non disponibile

### Pronta
- `omp.TERMINATO` → Avvio: Axi riavvia OMP, una volta sola; se OMP si era già fermato subito dopo il riavvio precedente, la connessione diventa non disponibile.
- `omp.TERMINATO` → Non disponibile: se OMP si è fermato subito dopo un riavvio.

### Non disponibile
Le impostazioni e il benvenuto mostrano che OMP non è disponibile e perché.
- `utente.CAMBIA_PERCORSO_OMP` → Avvio: Axi riprova con il nuovo percorso.
