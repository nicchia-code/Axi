---
technical: false
refs:
  - benvenuto
  - requirements/ui#benvenuto
  - requirements/tech#benvenuto
---
# Permessi chiesti nel benvenuto

Quando il Task è concluso, il passo Permessi del benvenuto usa le stesse righe dei permessi della finestra dei permessi (le righe condivise costruite dal Task sulla Machine `permessi`), più la riga che mostra se OMP è stato trovato: la riga OMP resta solo qui, non nella finestra dei permessi. Lo stato dei permessi si legge e si chiede come per la finestra dei permessi.

Il passo spiega e chiede Accessibility, Registrazione schermo e Automazione dei browser. La spiegazione della riga Accessibility dice che serve a leggere lo schermo e anche a ricevere i tasti Spotlight e Dettatura. L'Automazione riguarda solo Safari e Chrome: per ciascuno dei due che è installato la riga mostra se è già concessa oppure, se il browser è chiuso, che va aperto per verificarlo («Apri Safari per verificare.», e l'analogo per Chrome). La nota su Firefox dice che non ha bisogno dell'Automazione perché gli basta Accessibility. L'utente può ancora proseguire senza tutti i permessi.

Con `utente.CHIEDE_PERMESSO` nel passo Permessi, Axi fa la richiesta di sistema di macOS per quel permesso, che aggiunge Axi all'elenco di Impostazioni di Sistema; se macOS non mostra più la sua richiesta, si apre il pannello giusto di Impostazioni di Sistema. Il pulsante quindi non si limita più ad aprire il pannello.

Il lavoro tocca `Axi/Benvenuto/BenvenutoView.swift` (`PermissionsStep`, `PermissionRow`, `BrowserAutomationRow` sostituiti dalle righe condivise, la riga OMP resta), `Axi/Benvenuto/BenvenutoModel.swift` (azione di richiesta del permesso al posto di solo `openSettings(for:)`) ed eventualmente `Packages/AxiCore/Sources/AxiCore/Benvenuto/BenvenutoFlow.swift`, appoggiandosi alle funzioni di richiesta in `Packages/AxiScreen/Sources/AxiScreen/Permissions.swift` introdotte dal Task su `permessi`.
