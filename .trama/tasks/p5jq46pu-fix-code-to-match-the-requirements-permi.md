---
column: done
technical: true
refs:
  - requirements/ui#permessi
drift: otwtv4pd
proposal: null
agent: false
created: 2026-10-19T10:35:03.018Z
finished: 2026-10-19T10:52:02.363Z
unchanged: "Checked the shared permission rows (Axi/Permessi/PermessiRighe.swift) and the catalog Axi/Localizable.xcstrings: every text of the rows has a translated Italian value that matches the Requirement (Concedi; Apri %@ per verificare.; Firefox non ne ha bisogno: gli basta Accessibility.; the Accessibility explanation; Registrazione schermo, Riapri Axi, Automazione dei browser, Concesso/Non concesso). The rows use these keys, so Italian is shown. No code change needed."
---
# Fix code to match the Requirements: Permission rows lack Italian texts

## What happens

In Italian the permission rows show English texts. The Allow button, the explanations of Accessibility, Screen Recording and Browser Automation, the closed-browser line and the Firefox note have no Italian translation in the app, so the rows read «Allow» and «Open Safari to check.» instead of the Italian texts of the Requirement.

## What should happen

In Italian each permission row shows the Requirement's Italian text: «Concedi» on the button, «Apri Safari per verificare.» for a closed browser, «Firefox non ne ha bisogno: gli basta Accessibility.» for the Firefox note, and the Italian explanation of Accessibility.

## Chosen option

**Add the Italian texts now**

Add the Italian translation of each text of the permission rows to the app's translations: the button, the explanations, the closed-browser line with the browser name, and the Firefox note. The English keys stay, so the view code does not change. Costs: a short edit to one translation file, and the same texts must be carried into the shared rows when they replace these two rows.

## Where in the code

Axi/Localizable.xcstrings: entries Allow, Accessibility, Screen Recording, Browser Automation, the three Lets Axi read texts, Open %@ to check. and Firefox doesn't need it (no Italian value); Axi/Benvenuto/BenvenutoView.swift:79-91, 155, 174, 184
