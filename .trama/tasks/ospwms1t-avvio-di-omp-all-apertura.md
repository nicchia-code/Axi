---
column: done
technical: false
refs:
  - connessione-omp
  - connessione-omp/Avvio
  - omp
  - requirements/tech#connessione-omp
drift: null
proposal: null
agent: false
created: 2026-10-18T18:41:11.308Z
finished: 2026-10-18T20:17:25.448Z
---
# Avvio di OMP all'apertura

Quando Axi parte, la connessione a OMP viene avviata: usa il percorso indicato nelle impostazioni, oppure cerca OMP sul Mac se il percorso non è indicato, e usa il modello scelto nelle impostazioni. Quando OMP è pronto la connessione passa a Pronta; se non si trova o non si avvia passa a Non disponibile e le impostazioni e il benvenuto lo mostrano con il motivo. Le uscite di OMP arrivano all'archiviazione e alla chat. Il modello scelto nelle impostazioni si applica a entrambi i processi anche quando OMP è già pronto. Il percorso cambiato nelle impostazioni, quando OMP è Non disponibile, riporta la connessione in Avvio.
