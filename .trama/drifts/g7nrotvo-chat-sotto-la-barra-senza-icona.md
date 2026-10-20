---
status: resolved
resolution: fix-code
refs:
  - puntino/Chat sotto la barra
proposal: null
task: k4z4mqo9
origin: iiq4aamf
critical: false
option: 1
note: null
resolvedBy: 7ln2nfjv
created: 2026-10-19T07:04:21.820Z
---
# Chat sotto la barra senza icona

## What happens

Con il puntino nascosto la chat non si apre sotto l'icona della barra dei menu: il codice non ha l'icona della barra e il puntino nascosto non è mai raggiunto, quindi la chat non ha un punto a cui ancorarsi.

## What should happen

Il Model dice che con il puntino nella barra dei menu (Nella barra) la chat si apre sotto l'icona della barra, e con la barra nascosta in alto sullo schermo attivo, sotto il punto dell'icona.

## Fix options

### Costruire prima l'icona della barra

La chat sotto la barra si implementa insieme all'icona nella barra dei menu, che introduce lo stato Nella barra. Il posizionamento della chat accanto al personaggio resta com'è.

### Rimandare la chat col puntino nascosto

Finché l'icona non c'è, con il puntino nascosto la chat si apre accanto al personaggio, come col puntino visibile. Il Model va aggiornato per dire questo caso.

## Where in the code

Packages/AxiCore/Sources/AxiCore/Puntino/StatoPuntino.swift (StatoPuntino: nascosto, dopoChat); Axi/AppDelegate.swift (riceveChat e finestraChat, ancorata al puntino)
