---
column: done
technical: true
refs:
  - requirements/tech#impostazioni
drift: u87yduer
proposal: null
agent: false
created: 2026-10-19T03:02:16.452Z
finished: 2026-10-19T11:29:58.183Z
---
# Fix code to match the Requirements: Chat shortcut defaults to F4

## What happens

Il valore predefinito della scorciatoia Chat è F4, il tasto Spotlight, e non ⌥Spazio. Anche il ripristino dei valori predefiniti riporta la chat su F4.

## What should happen

I valori predefiniti delle scorciatoie sono Archivia ⌥A e Chat ⌥Spazio, e il ripristino riporta a questi valori.

## Chosen option

**Default Chat back to Option-Space**

La scorciatoia Chat torna ⌥Spazio come valore predefinito, come chiede il Requirement delle impostazioni. F4 resta registrabile nel campo Chat. La voce Chat del menu del puntino mostrerà ⌥Spazio, quindi la scelta di F4 fatta per il menu va annullata. Costo: il tasto Spotlight, sulle tastiere Apple, non apre la chat finché non è assegnato ad Axi, e chi usava F4 deve rifare la scelta in una nuova installazione.

## Where in the code

Axi/Impostazioni/Scorciatoie.swift:11 (static let chat, default F4) e :55-57 (ripristinaPredefinite)
