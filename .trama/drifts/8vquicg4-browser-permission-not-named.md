---
status: resolved
resolution: dismissed
refs:
  - attivita/Nessuna/lettura-schermo.NESSUN_DOCUMENTO
  - attivita/In corso/lettura-schermo.NESSUN_DOCUMENTO
  - attivita/Esito/lettura-schermo.NESSUN_DOCUMENTO
  - requirements/ui#attivita
proposal: null
task: 8s4h14m7
origin: null
critical: false
option: 1
note: null
resolvedBy: ccydv3zq
created: 2026-10-19T03:31:38.184Z
---
# Browser permission not named

## What happens

When Automation is missing for a web page in Safari or Chrome, the bubble says that the Automation permission is missing and that Axi may control the browser. It does not name the browser whose permission is missing.

## What should happen

The bubble names the browser whose Automation permission is missing, Safari or Chrome, as the Requirement's sentence does: «Per leggere questa pagina serve il permesso di Automazione per Safari.» (or Chrome), and «Reading this page needs the Automation permission for Safari.» (or Chrome).

## Fix options

### Carry the browser in the reason

Carry the browser that was being read in the no-document reason for a missing Automation permission, and name it in the bubble as the Requirement's sentence does. Costs: the reason gains a value, the search passes the browser along, and the Safari and Chrome wording is added in both languages in the string catalogue.

### Read the browser when shown

Keep the reason as it is and let the bubble name the browser of the page read when it is shown, taken from the app in front at that moment. Costs: the bubble looks at the front application again, so it could name a different browser if the user switches apps while the bubble is on screen.

## Where in the code

Packages/AxiScreen/Sources/AxiScreen/ScreenReader.swift:194-195 (the browser permission reason is made without the browser); Axi/Puntino/NuvolettaVista.swift:111-112 and 131-132
