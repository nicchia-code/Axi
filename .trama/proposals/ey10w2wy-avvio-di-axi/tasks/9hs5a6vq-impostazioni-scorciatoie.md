---
refs:
  - "impostazioni"
  - "utente"
  - "requirements/ui#impostazioni"
  - "requirements/tech#impostazioni"
  - "requirements/data#impostazioni"
---
# Impostazioni e scorciatoie

La finestra delle impostazioni e le scorciatoie globali con cui l'utente produce i suoi Events senza passare dal puntino.

Quando il Task è fatto:
- `utente.APRE_IMPOSTAZIONI` porta Impostazioni da Chiuse ad Aperte, o riporta in primo piano la finestra già aperta; `utente.CHIUDE_IMPOSTAZIONI` la chiude;
- la finestra ha le sezioni Modello AI (elenco dei modelli di OMP, predefinito di OMP preselezionato), Scorciatoie, Azure Document Intelligence (endpoint, chiave nel Keychain, Prova connessione) e OMP (percorso, stato e motivo); ogni cambiamento vale subito e resta salvato;
- cambiare il percorso di OMP produce `utente.CAMBIA_PERCORSO_OMP`;
- le scorciatoie globali funzionano da qualunque app e sono registrabili: Archivia (⌥A) produce `utente.CHIEDE_ARCHIVIAZIONE`; Chat produce `utente.APRE_CHAT` se la chat è chiusa e `utente.CHIUDE_CHAT` se è aperta; Mostra/nascondi (⌥H) produce `utente.ALTERNA_PUNTINO`;
- la scorciatoia predefinita della chat è F4 se Axi riesce a intercettarla senza aprire Spotlight; altrimenti è ⌥Spazio, e il comportamento scelto è documentato nel codice;
- l'app in primo piano al momento della scorciatoia viene memorizzata per la lettura dello schermo;
- gli altri Events di Utente sono prodotti dalle viste dei rispettivi Task (puntino, chat, benvenuto); questo Task copre l'Actor nel suo insieme e verifica che ogni suo Event abbia una sorgente nell'interfaccia.
