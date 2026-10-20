---
column: done
technical: true
refs:
  - requirements/tech#General
drift: null
proposal: null
agent: false
created: 2026-10-18T18:39:10.630Z
finished: 2026-10-18T18:55:11.154Z
---
# CI con i test

La CI esegue build e test a ogni push e pull request, come richiede requirements/tech#General. Oggi il workflow .github/workflows/ci.yml chiama xcodebuild sullo schema Axi con l'azione test, ma lo schema non ha alcun TestAction: i test dei pacchetti AxiCore, AxiScreen, AxiOMP, AxiEmbedding e AxiVectors non girano in CI. Va aggiunta l'esecuzione dei test di ciascun pacchetto. La build inoltre richiede -skipMacroValidation per la macro di mlx-swift-lm, che la CI non passa.
