---
column: done
technical: true
refs:
  - requirements/tech#General
drift: null
proposal: htpvu39v
agent: false
created: 2026-10-19T02:47:50.555Z
finished: 2026-10-19T02:48:33.578Z
---
# Macro MLX nel README

Quando il Task è fatto vale la regola dei Requirements tech (General) sulla macro `MLXHuggingFaceMacros` di `mlx-swift-lm`:

- La sezione "Build locally" del README dice che, alla prima build in Xcode, la macro `MLXHuggingFaceMacros` va approvata una volta con Trust & Enable, e che da riga di comando `xcodebuild` richiede `-skipMacroValidation`, altrimenti la build fallisce in `ComputeTargetDependencyGraph`.
- Il comando `xcodebuild` del README e quello della CI (`.github/workflows/ci.yml`) passano `-skipMacroValidation`; oggi lo fanno già, e restano così.
- `xcodebuild -project Axi.xcodeproj -scheme Axi -destination 'platform=macOS,arch=arm64' -skipMacroValidation CODE_SIGNING_ALLOWED=NO build` termina con `BUILD SUCCEEDED`.

Nessun cambio al codice di `AxiEmbedding` né alle sue dipendenze.
