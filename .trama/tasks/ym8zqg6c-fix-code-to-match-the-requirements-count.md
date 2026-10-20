---
column: done
technical: true
refs:
  - requirements/ui#attivita
drift: 3qymrk87
proposal: null
agent: false
created: 2026-10-19T19:03:11.035Z
finished: 2026-10-19T19:14:55.583Z
unchanged: "Checked Axi/Puntino/PuntinoVista.swift:157-165 (contatore): white Text on Color.accentColor background in a Capsule, offset 22, sizes scaled by fattoreContatore. Matches requirements/ui#attivita (white count inside an accent-colour circle or capsule). No red fill remains on the counter; the only .red is the error tint of the character (line 140). Nothing changed."
---
# Fix code to match the Requirements: Counter capsule is red

## What happens

The queue count on the dot is white on a red capsule, not on the accent colour.

## What should happen

The queue count is white inside a small circle or capsule in the accent colour, as the requirement says.

## Chosen option

**Use the accent colour**

Change the capsule background from the fixed red to the accent colour, keeping the white number and the size rules. This matches the requirement and keeps the counter readable on both light and dark menu bars. The change is local to the counter view and does not affect the dot's states or the bubble.

## Where in the code

Axi/Puntino/PuntinoVista.swift:158
