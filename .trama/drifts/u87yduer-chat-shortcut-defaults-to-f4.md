---
status: resolved
resolution: fix-code
refs:
  - requirements/tech#impostazioni
proposal: null
task: kcz7yekn
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:41:00.118Z
---
# Chat shortcut defaults to F4

## What happens

Il valore predefinito della scorciatoia Chat è F4, il tasto Spotlight, e non ⌥Spazio. Anche il ripristino dei valori predefiniti riporta la chat su F4.

## What should happen

I valori predefiniti delle scorciatoie sono Archivia ⌥A e Chat ⌥Spazio, e il ripristino riporta a questi valori.

## Fix options

### Default Chat back to Option-Space

La scorciatoia Chat torna ⌥Spazio come valore predefinito, come chiede il Requirement delle impostazioni. F4 resta registrabile nel campo Chat. La voce Chat del menu del puntino mostrerà ⌥Spazio, quindi la scelta di F4 fatta per il menu va annullata. Costo: il tasto Spotlight, sulle tastiere Apple, non apre la chat finché non è assegnato ad Axi, e chi usava F4 deve rifare la scelta in una nuova installazione.

### F4 only when Spotlight keys are Axi's

La scorciatoia Chat predefinita è F4 solo quando i tasti Spotlight e Dettatura sono assegnati ad Axi e il permesso Accessibility è concesso. Altrimenti il predefinito è ⌥Spazio, così F4 non entra in conflitto con un Spotlight che Axi non intercetta. Costo: il valore predefinito dipende da due impostazioni, e la scorciatoia della chat cambia quando l'utente cambia l'interruttore o il permesso.

## Where in the code

Axi/Impostazioni/Scorciatoie.swift:11 (static let chat, default F4) e :55-57 (ripristinaPredefinite)
