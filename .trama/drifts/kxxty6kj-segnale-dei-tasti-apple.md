---
status: resolved
resolution: dismissed
refs:
  - impostazioni
proposal: null
task: e4joe7a7
origin: cd1yhhvc
critical: false
option: 1
note: null
resolvedBy: 7ln2nfjv
created: 2026-10-19T03:10:30.548Z
---
# Segnale dei tasti Apple

## What happens

Axi cannot yet tell the Spotlight key (the lens) and the Dictation key (the microphone) of an Apple keyboard apart from the other keys: the exact signal they send is not known. Without it the keys cannot be taken from macOS, so the Task cannot make them start Axi's Chat or Archive actions, nor stop Spotlight and Dictation from starting.

## What should happen

The Requirements say the exact signal of the two keys must be checked on a real Apple keyboard and recorded in the code, but they do not give the signal, nor who checks it or when. The check cannot be made without a real keyboard, so the Task cannot be finished as written.

## Fix options

### Record the signal on a real keyboard first

The developer, or someone with an Apple keyboard, presses the lens and microphone keys once while a temporary capture runs outside Axi, and sends the observed signal. The interception is then written from it and the Task is finished. Costs: waits for that capture, and the signal is known only for the keyboards tested.

### Use the signal from Apple's published key tables

Intercept the two keys with the signal the public HID usage tables give for them, and document in the code that it is not yet checked on a real keyboard. Costs: the keys may not be recognised on some keyboards, and the Task is marked done before the real check the Requirements ask for.

## Where in the code

Axi/Impostazioni/Scorciatoie.swift (the Chat default and the place where the event tap would be registered); Axi/AppDelegate.swift (the wiring of Scorciatoie)
