---
status: resolved
resolution: fix-code
refs:
  - puntino
proposal: null
task: 59ntkip7
origin: q4tprplx
critical: false
option: 1
note: null
resolvedBy: hrfxsylt
created: 2026-10-19T08:23:40.211Z
---
# Menu bar item missing

## What happens

The activity is shown only by the dot on screen. The dot can never be hidden: its menu has no entry for it, and nothing moves it to the hidden state. So there is no icon in the menu bar, and the bubble never appears under one, nor when the menu bar is hidden by a full screen app.

## What should happen

The activity is shown by the dot in the menu bar when the dot is hidden, and its bubble appears under that icon, above a full screen app when the bar is hidden. This needs the hidden state of the dot and the menu bar item that the dot becomes while hidden, which another Task builds.

## Fix options

### Build the hidden dot first

Finish the Task that makes the dot hideable and adds its menu bar item, then implement this Task on top of it. This Task waits; nothing else changes, and the activity is shown in the menu bar as the Model says.

### Add the menu bar item here

Build the hidden state and its menu bar item inside this Task, with the activity on top. This Task grows to cover work of another Task, so that Task must then be checked against it to avoid building the same thing twice.

## Where in the code

Axi/Puntino/PuntinoController.swift (no transition to the hidden state; visibility follows only the dot states), Packages/AxiCore/Sources/AxiCore/Puntino/VoceMenu.swift (four items, none hides the dot), Packages/AxiCore/Sources/AxiCore/Puntino/StatoPuntino.swift (dopo has no hidden transition); no NSStatusItem in Axi/ or Packages/.
