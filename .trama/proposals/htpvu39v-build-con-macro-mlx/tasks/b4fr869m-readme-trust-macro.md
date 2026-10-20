---
technical: true
refs:
  - requirements/tech#General
---
# Macro MLX nel README

Quando il Task è fatto vale la regola dei Requirements tech (General) sulla macro `MLXHuggingFaceMacros` di `mlx-swift-lm`:

- La sezione "Build locally" del README dice che, alla prima build in Xcode, la macro `MLXHuggingFaceMacros` va approvata una volta con Trust & Enable, e che da riga di comando `xcodebuild` richiede `-skipMacroValidation`, altrimenti la build fallisce in `ComputeTargetDependencyGraph`.
- Il comando `xcodebuild` del README e quello della CI (`.github/workflows/ci.yml`) passano `-skipMacroValidation`; oggi lo fanno già, e restano così.
- `xcodebuild -project Axi.xcodeproj -scheme Axi -destination 'platform=macOS,arch=arm64' -skipMacroValidation CODE_SIGNING_ALLOWED=NO build` termina con `BUILD SUCCEEDED`.

Nessun cambio al codice di `AxiEmbedding` né alle sue dipendenze.
