---
column: done
technical: false
refs:
  - attivita/Nessuna/lettura-schermo.NESSUN_DOCUMENTO
  - attivita/In corso/lettura-schermo.NESSUN_DOCUMENTO
  - attivita/Esito/lettura-schermo.NESSUN_DOCUMENTO
  - requirements/ui#attivita
drift: 8vquicg4
proposal: null
agent: false
created: 2026-10-19T06:07:34.206Z
finished: 2026-10-19T08:34:29.493Z
unchanged: "Checked ScreenReader.searchDocument: a missing Automation for Safari or Chrome yields browserAutomationMissing(browser:) with the browser's name, and NuvolettaVista renders it as 'Reading this page needs the Automation permission for %@.' (it/en in Localizable.xcstrings). Existing tests archivingWithUnreadableChromeAddressNamesChromeWithoutAutomation and the Safari counterpart cover it. The described behaviour does not occur."
---
# Fix code to match the Model: Browser permission not named

## What happens

When Automation is missing for a web page in Safari or Chrome, the bubble says that the Automation permission is missing and that Axi may control the browser. It does not name the browser whose permission is missing.

## What should happen

The bubble names the browser whose Automation permission is missing, Safari or Chrome, as the Requirement's sentence does: «Per leggere questa pagina serve il permesso di Automazione per Safari.» (or Chrome), and «Reading this page needs the Automation permission for Safari.» (or Chrome).

## Chosen option

**Carry the browser in the reason**

Carry the browser that was being read in the no-document reason for a missing Automation permission, and name it in the bubble as the Requirement's sentence does. Costs: the reason gains a value, the search passes the browser along, and the Safari and Chrome wording is added in both languages in the string catalogue.

## Where in the code

Packages/AxiScreen/Sources/AxiScreen/ScreenReader.swift:194-195 (the browser permission reason is made without the browser); Axi/Puntino/NuvolettaVista.swift:111-112 and 131-132
