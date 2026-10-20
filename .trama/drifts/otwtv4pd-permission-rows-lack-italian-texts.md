---
status: resolved
resolution: dismissed
refs:
  - requirements/ui#permessi
proposal: null
task: p5jq46pu
origin: null
critical: false
option: 1
note: null
resolvedBy: hrfxsylt
created: 2026-10-19T08:15:04.884Z
---
# Permission rows lack Italian texts

## What happens

In Italian the permission rows show English texts. The Allow button, the explanations of Accessibility, Screen Recording and Browser Automation, the closed-browser line and the Firefox note have no Italian translation in the app, so the rows read «Allow» and «Open Safari to check.» instead of the Italian texts of the Requirement.

## What should happen

In Italian each permission row shows the Requirement's Italian text: «Concedi» on the button, «Apri Safari per verificare.» for a closed browser, «Firefox non ne ha bisogno: gli basta Accessibility.» for the Firefox note, and the Italian explanation of Accessibility.

## Fix options

### Add the Italian texts now

Add the Italian translation of each text of the permission rows to the app's translations: the button, the explanations, the closed-browser line with the browser name, and the Firefox note. The English keys stay, so the view code does not change. Costs: a short edit to one translation file, and the same texts must be carried into the shared rows when they replace these two rows.

### Translate when shared rows land

Leave the texts untranslated until the shared permission rows replace the welcome rows, then translate them once in the shared view. Costs: Italian users see English rows for the whole Run, and the Requirement stays unmet until that Task is done.

### Translate and guard with a test

Add the Italian translations now and add a test that fails when a permission row text has no Italian value. Costs: a new test in the test target, and the test must be updated whenever the texts of the rows change.

## Where in the code

Axi/Localizable.xcstrings: entries Allow, Accessibility, Screen Recording, Browser Automation, the three Lets Axi read texts, Open %@ to check. and Firefox doesn't need it (no Italian value); Axi/Benvenuto/BenvenutoView.swift:79-91, 155, 174, 184
