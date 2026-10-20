---
column: done
technical: false
refs:
  - permessi/Aperta/utente.CHIEDE_PERMESSO
  - requirements/ui#permessi
drift: gg56rqu6
proposal: null
agent: false
created: 2026-10-19T03:02:16.440Z
finished: 2026-10-19T03:11:46.487Z
---
# Fix code to match the Model: Buttons only open Settings

## What happens

Il pulsante «Open Settings» accanto a ogni permesso apre sempre il pannello di Impostazioni di Sistema e non chiede nulla a macOS. Il pulsante resta visibile anche quando il permesso è già concesso.

## What should happen

Il pulsante «Concedi» / «Allow» compare solo quando il permesso manca e chiede il permesso a macOS: Axi fa la richiesta di sistema e, se macOS non la mostra più, apre il pannello giusto di Impostazioni di Sistema.

## Chosen option

**Request first, then pane**

Aggiungere alla lettura dei permessi le richieste di sistema (Accessibility, Registrazione schermo, Automazione fuori dal thread principale) e far chiamare al modello prima la richiesta, poi il pannello solo se macOS non mostra più la sua. Le righe mostrano il pulsante solo quando il permesso manca. Costa: codice nuovo che agisce su macOS, da provare su un macOS reale come chiede il Requirement.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift, PermissionRow (righe 137-158) e pulsante di BrowserAutomationRow (riga 181); Packages/AxiScreen/Sources/AxiScreen/Permissions.swift, openSettings (righe 54-58)
