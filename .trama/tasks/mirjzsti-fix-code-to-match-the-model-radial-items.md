---
column: done
technical: false
refs:
  - puntino/Menu aperto
  - requirements/ui#puntino/Menu aperto
drift: vupx1sr2
proposal: null
agent: false
created: 2026-10-19T20:34:27.718Z
finished: 2026-10-19T20:36:11.700Z
unchanged: "Checked Axi/Puntino/MenuRadialeVista.swift, VoceMenuVista (lines 40-77): onHover sets sopra; the icon uses Color.accentColor when sopra, and the glass circle uses .regular.tint(Color.accentColor.opacity(0.18)) when sopra, animated with easeOut 0.2 (off under Reduce Motion). This matches What should happen and the Requirement, so no change was needed."
---
# Fix code to match the Model: Radial items lack hover highlight

## What happens

Passando il puntatore su una voce del menu radiale il suo cerchio e la sua icona non cambiano: l'utente non vede quale azione sta per scegliere.

## What should happen

Al passaggio del puntatore il cerchio di vetro della voce si tinge di un velo del colore dell'accento e la sua icona prende lo stesso colore.

## Chosen option

**Highlight circle and icon on hover**

Ogni voce del menu radiale rileva il passaggio del puntatore e applica il velo dell'accento al cerchio di vetro, portando l'icona allo stesso colore. Il costo è una modifica alla sola vista della voce, senza cambiare posizioni, testi o scorciatoie delle azioni.

## Where in the code

Axi/Puntino/MenuRadialeVista.swift, vista della singola voce `VoceMenuVista` (intorno alle righe 40-65).
