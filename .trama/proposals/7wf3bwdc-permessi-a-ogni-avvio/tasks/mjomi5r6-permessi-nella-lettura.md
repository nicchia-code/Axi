---
technical: false
refs:
  - lettura-schermo/Accessibilità/lettura-schermo.TESTO_NON_ACCESSIBILE
  - lettura-schermo/Riconoscimento del testo/lettura-schermo.LETTURA_FALLITA
  - lettura-schermo.LETTURA_FALLITA
---
# Motivo della lettura fallita

Quando il Task è concluso, la lettura del contesto per la chat si comporta così.

In Accessibilità, `TESTO_NON_ACCESSIBILE` porta al Riconoscimento del testo sia quando l'app non espone il testo visibile, sia quando manca il permesso Accessibility: senza Accessibility Axi non si ferma, ma cattura la finestra e ne riconosce il testo (con Azure Document Intelligence se è configurato, altrimenti sul Mac).

In Riconoscimento del testo, `LETTURA_FALLITA` porta a Inattiva quando manca il permesso Registrazione schermo, e in quel caso il motivo nomina i permessi mancanti: Registrazione schermo, più Accessibility se manca anch'esso; oppure quando il riconoscimento non è riuscito.

L'evento `LETTURA_FALLITA` porta con sé il motivo: i permessi mancanti (quali, uno o entrambi) oppure il riconoscimento non riuscito, così che chi lo riceve (la mini-chat) possa distinguere i casi e nominare i permessi.

Dove va il lavoro: `Packages/AxiScreen/Sources/AxiScreen/ScreenReader.swift` (`readContext` già salta l'istantanea AX senza Accessibility e passa all'OCR; `recognizeOnScreen` oggi restituisce solo `.screenRecordingPermissionMissing` e deve dire anche se manca Accessibility, leggendo i permessi da `Permissions.swift`), e `Packages/AxiCore/Sources/AxiCore/LetturaSchermo/LetturaSchermo.swift` / `LetturaSchermoService.swift`, dove `EsitoLetturaSchermo` e il fallimento devono esprimere il motivo: insieme dei permessi mancanti oppure riconoscimento non riuscito.
