---
technical: false
refs:
  - impostazioni
  - requirements/ui#impostazioni
  - requirements/tech#impostazioni
---
# Permessi nelle impostazioni

Quando il Task è fatto, la finestra delle impostazioni (`Axi/Impostazioni/ImpostazioniView.swift`, `ImpostazioniController.swift`) ha, dopo Modello AI, Scorciatoie, Azure Document Intelligence e OMP, una nuova sezione Permessi. Nello stato Aperte la sezione mostra lo stato dei permessi di macOS con le stesse righe della finestra dei permessi (le righe condivise con `Axi/Benvenuto/BenvenutoView.swift`, non una copia), aggiornato da solo mentre la finestra è aperta.

- `utente.CHIEDE_PERMESSO` → Aperte: Axi fa la richiesta di sistema di macOS per quel permesso, che aggiunge Axi all'elenco di Impostazioni di Sistema; se macOS non mostra più la sua richiesta, si apre il pannello giusto di Impostazioni di Sistema. Se il permesso è Registrazione schermo, la sezione Permessi mostra il pulsante «Riapri Axi».
- `utente.RIAPRE_AXI` → Chiuse: Axi si chiude e si riapre.

Nella sezione Scorciatoie, la nota che compare con l'interruttore «Usa i tasti Spotlight e Dettatura» attivo e senza permesso Accessibility («Per usare questi tasti serve il permesso Accessibility.» / «These keys need the Accessibility permission.») ha ora il pulsante «Concedi» / «Allow», che chiede il permesso a macOS come le righe dei permessi invece di aprire soltanto Impostazioni di Sistema; la nota sparisce da sola quando il permesso arriva.

I tasti Spotlight e Dettatura restano ad Axi solo finché Accessibility è concessa. Finché il `CGEventTap` esiste, Axi rilegge `AXIsProcessTrusted` ogni secondo; appena Accessibility manca rimuove il tap e restituisce i tasti a macOS, così togliere il permesso con Axi aperto non blocca l'input del sistema; quando il permesso torna, il tap si ricrea senza riavviare Axi. Per questo non si apre nessuna finestra. Questa sorveglianza si costruisce sul tap introdotto dalla Proposal `uswpa2t4` (i cui Task creano il tap, l'interruttore e la nota): questo Task aggiunge solo la rilettura del permesso e la rimozione/ricreazione del tap, accanto al codice del tap (`Axi/Impostazioni/Scorciatoie.swift` o dove quei Task lo collocano). La lettura e la richiesta dei permessi passano da `Packages/AxiScreen/Sources/AxiScreen/Permissions.swift`.

Devono valere i Requirement `requirements/ui#impostazioni` (sezione Permessi, pulsante «Riapri Axi», nota con «Concedi») e `requirements/tech#impostazioni` (tap solo con interruttore attivo e Accessibility concessa, rilettura ogni secondo, nessuna finestra).
