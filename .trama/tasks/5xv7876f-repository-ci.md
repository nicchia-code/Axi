---
column: done
technical: true
refs:
  - specs#repository
  - specs#ci
  - specs#testing
drift: null
proposal: ey10w2wy
agent: false
created: 2026-10-18T17:25:07.412Z
finished: 2026-10-18T17:28:27.624Z
---
# Repository e CI

Preparare il repository pubblico su GitHub e la CI.

Quando il Task è fatto:
- il repository git locale ha un `.gitignore` per Xcode e Swift, il file `LICENSE` con il testo di AGPL-3.0 e un `README.md` in inglese che descrive Axi, i requisiti (macOS 26, Apple Silicon, OMP installato), come compilarlo in locale, e che l'uso è libero mentre le aziende interessate a una licenza commerciale contattano l'autore;
- un workflow di GitHub Actions esegue build e test con `xcodebuild` su un runner macOS con un Xcode che supporta macOS 26, a ogni push e pull request, senza firma;
- i test girano senza OMP, rete né permessi di sistema;
- il remoto GitHub pubblico viene creato e collegato solo se lo sviluppatore lo chiede durante il Task; altrimenti il README spiega come pubblicarlo.
