---
status: resolved
resolution: fix-code
refs:
  - permessi/Aperta/utente.CHIEDE_PERMESSO
  - requirements/ui#permessi
proposal: null
task: 3vxuf1to
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:40:45.542Z
---
# Buttons only open Settings

## What happens

Il pulsante «Open Settings» accanto a ogni permesso apre sempre il pannello di Impostazioni di Sistema e non chiede nulla a macOS. Il pulsante resta visibile anche quando il permesso è già concesso.

## What should happen

Il pulsante «Concedi» / «Allow» compare solo quando il permesso manca e chiede il permesso a macOS: Axi fa la richiesta di sistema e, se macOS non la mostra più, apre il pannello giusto di Impostazioni di Sistema.

## Fix options

### Request first, then pane

Aggiungere alla lettura dei permessi le richieste di sistema (Accessibility, Registrazione schermo, Automazione fuori dal thread principale) e far chiamare al modello prima la richiesta, poi il pannello solo se macOS non mostra più la sua. Le righe mostrano il pulsante solo quando il permesso manca. Costa: codice nuovo che agisce su macOS, da provare su un macOS reale come chiede il Requirement.

### Request behind same button

Lasciare l'etichetta «Open Settings» e la sua visibilità com'è, e far fare alla stessa azione la richiesta di sistema prima del pannello. Costa: l'etichetta resta diversa dal Requirement e il pulsante resta anche con il permesso concesso, finché la finestra dei permessi non sostituisce le righe.

## Where in the code

Axi/Benvenuto/BenvenutoView.swift, PermissionRow (righe 137-158) e pulsante di BrowserAutomationRow (riga 181); Packages/AxiScreen/Sources/AxiScreen/Permissions.swift, openSettings (righe 54-58)
