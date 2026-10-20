---
column: done
technical: false
refs:
  - archiviazione
  - requirements/tech#archiviazione
drift: null
proposal: null
agent: false
created: 2026-10-18T18:41:12.536Z
finished: 2026-10-18T20:14:07.060Z
---
# Collegamento dell'archiviazione

Quando l'app è avviata, un solo servizio di archiviazione è costruito con gli adapter reali (AI tramite la sessione di archivio di OMP, embedding tramite TextEmbedder, allegati e pagine web), e i suoi eventi arrivano all'attività del puntino. Un documento trascinato sul puntino entra nel vault solo quando tutti i passi riescono.
