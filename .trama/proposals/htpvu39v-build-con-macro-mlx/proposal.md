---
status: approved
base:
  requirements/tech/fondamenta.md: 77a13efe419339dc2354d43d7530dcc8b0d530f688134cc26550f8f9a6d88e89
delete: []
request: 2026-10-19T00-52-01
created: 2026-10-19T02:45:47.698Z
label: Build macro MLX
---
# Build con macro MLX

La build di Axi fallisce in ComputeTargetDependencyGraph: AxiEmbedding usa il prodotto MLXHuggingFace di mlx-swift-lm, che porta la macro MLXHuggingFaceMacros, e Xcode e xcodebuild rifiutano le macro di terze parti non approvate. Con -skipMacroValidation la build riesce.

Decisioni:
- Si tiene la macro di mlx-swift-lm; nessun cambio al codice di AxiEmbedding.
- Ogni build da riga di comando (sviluppatore, agenti, CI) passa -skipMacroValidation; in Xcode la macro si approva una volta con Trust & Enable.
- La regola entra nei Requirements tech (General), così chi lancia xcodebuild la trova.

Assunzioni:
- Il README, nella sezione sulla build locale, spiega anche il passo Trust & Enable in Xcode, oltre al flag già presente nel comando da riga di comando.
