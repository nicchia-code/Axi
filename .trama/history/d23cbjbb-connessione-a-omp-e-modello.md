---
created: 2026-10-18T19:26:54.261Z
updated: 2026-10-18T21:30:48.497Z
summary: Avvio e cambio percorso di OMP, finestra di errore al processo morto, modello predefinito letto da OMP.
tasks:
  - et3wyh1m
  - ok5ey515
  - p9fwwcey
  - wcgxm16j
  - ospwms1t
  - g9vgjc3m
  - vsetr4hm
---
# Connessione a OMP e modello

Implementati i Task et3wyh1m (Cambio percorso con OMP pronto: riavvio solo dallo stato Non disponibile, invio solo se il percorso cambia), ok5ey515 (Processo morto durante l'avvio: regola di sorveglianza e di riavvio di OMPConnection), p9fwwcey (Modello predefinito di OMP: lettura di provider e id del modello da get_state, usato come scelta predefinita se l'utente non ne sceglie uno). Test: AxiOMP 42 test verdi.
