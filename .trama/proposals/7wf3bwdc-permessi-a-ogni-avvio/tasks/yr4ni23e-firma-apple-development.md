---
technical: true
refs:
  - requirements/tech#General
---
# Firma Apple Development

Quando il Task è finito, le build di sviluppo di Axi sono firmate con firma automatica e un certificato Apple Development del team indicato nel progetto Xcode, così macOS riconosce Axi tra una build e l'altra e i permessi concessi (Accessibility, Registrazione schermo, Automazione) restano validi dopo una ricompilazione.

In `Axi.xcodeproj/project.pbxproj` resta `CODE_SIGN_STYLE = Automatic` e si imposta `DEVELOPMENT_TEAM` con l'ID del team dello sviluppatore. L'ID non va inventato: lo fornisce lo sviluppatore accedendo a Xcode con il proprio Apple ID del team (Settings › Accounts) e scegliendo il team nel target; se non è disponibile, il Task si ferma e lo chiede. Su questo Mac oggi non c'è ancora un'identità di firma. App Sandbox resta disattivata e Hardened Runtime resta attivo, senza altre modifiche, così la futura firma Developer ID e la notarizzazione non richiedono cambi al progetto.

La CI (`.github/workflows/*.yml`) continua a compilare e testare senza firma (`CODE_SIGNING_ALLOWED=NO`) e non ha bisogno del team né di certificati.

Il README spiega che per compilare con firma serve un Apple ID del team aggiunto in Xcode.

Verifica su un Mac reale: concessi i permessi ad Axi, una ricompilazione e un nuovo avvio li trovano ancora concessi, senza doverli ridare in Impostazioni di Sistema.
