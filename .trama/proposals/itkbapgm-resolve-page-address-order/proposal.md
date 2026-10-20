---
status: approved
kind: resolution
nonBlocking: true
drifts:
  - drift: p632kwvt
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-19T18:13:35.726Z
---
# Resolve page address order

Risolve la Drift p632kwvt («Page address read order»), trovata dalla scansione di fine Run su lettura-schermo. Per una pagina web Axi legge l'indirizzo dalla finestra prima che dall'area della pagina; il requisito tech#lettura-schermo dice l'opposto. Decisione raccomandata: opzione 1, leggere prima l'area della pagina. La Drift non blocca nessun Task.
