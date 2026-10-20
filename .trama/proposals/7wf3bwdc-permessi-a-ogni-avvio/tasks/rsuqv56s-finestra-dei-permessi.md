---
technical: false
refs:
  - companion
  - permessi
  - utente.CHIEDE_PERMESSO
  - utente.RIAPRE_AXI
  - utente.APRE_PERMESSI
  - utente.CHIUDE_PERMESSI
  - requirements/tech#permessi
  - requirements/ui#permessi
---
# Finestra dei permessi

Quando il Task è fatto, a ogni avvio Axi controlla i permessi di macOS e, se ne manca qualcuno, apre la finestra dei permessi, come descrive la Machine `permessi`.

**Controllo all'avvio.** In `Axi/AppDelegate.swift` (`applicationDidFinishLaunching`), dopo l'avvio del puntino e senza bloccare il resto di Axi, si leggono i permessi. Il controllo vale solo se il benvenuto è completato (`BenvenutoStore.isCompleted()`): se non lo è, i permessi li chiede il benvenuto e la finestra resta chiusa. Contano come mancanti Accessibility, Registrazione schermo e l'Automazione di Safari (`com.apple.Safari`) e di Chrome (`com.google.Chrome`), ciascuno solo se installato, quando macOS la dice negata (`errAEEventNotPermitted`) o non ancora chiesta (`errAEEventWouldRequireUserConsent`). Un browser chiuso (`procNotFound`) ha Automazione sconosciuta e non conta come mancante. Firefox e altri browser non contano. Se tutto è concesso la finestra resta chiusa. Mentre Axi è aperto la finestra non ricompare da sola.

**`Permissions`.** `Packages/AxiScreen/Sources/AxiScreen/Permissions.swift` va esteso: l'Automazione restituisce uno dei quattro stati (concessa, negata, non ancora chiesta, sconosciuta) invece di un `Bool`, e si aggiungono le richieste: Accessibility con `AXIsProcessTrustedWithOptions` e `kAXTrustedCheckOptionPrompt`, Registrazione schermo con `CGRequestScreenCaptureAccess`, Automazione con `AEDeterminePermissionToAutomateTarget` chiedendo all'utente, fuori dal main thread perché aspetta la risposta. Se macOS non mostra la sua richiesta (permesso già negato), si apre il pannello giusto di Impostazioni di Sistema (`Privacy_Accessibility`, `Privacy_ScreenCapture`, `Privacy_Automation`), riusando `openSettings(for:)`. Il comportamento va verificato su un macOS 26 reale, anche dopo una ricompilazione.

**La finestra.** Una nuova finestra (accanto a `Axi/Benvenuto/` e `Axi/Impostazioni/`) centrata, non ridimensionabile, titolo «Permessi di Axi» / «Axi permissions», con l'introduzione «Ad Axi mancano alcuni permessi: senza, non può leggere lo schermo.» / «Axi is missing some permissions: without them it can't read the screen.». Mentre è aperta lo stato si rilegge ogni secondo; a finestra chiusa non si rilegge.

**Righe condivise.** Le righe dei permessi devono essere un'unica vista condivisa, usata dalla finestra dei permessi, dal benvenuto (al posto di `PermissionRow` e `BrowserAutomationRow` in `Axi/Benvenuto/BenvenutoView.swift`) e dalle impostazioni. Per Accessibility, Registrazione schermo e Automazione: spiegazione in una frase, stato (concesso o no) e pulsante «Concedi» / «Allow» solo quando il permesso manca. La spiegazione di Accessibility dice che serve a leggere le finestre e a usare i tasti Spotlight e Dettatura. La riga Automazione mostra uno stato separato per Safari e Chrome, solo se installati; per un browser chiuso mostra «Apri Safari per verificare.» (o Chrome) / «Open Safari to check.», senza pulsante; sotto, la nota «Firefox non ne ha bisogno: gli basta Accessibility.» / «Firefox doesn't need it: Accessibility is enough.».

**Chiedere (`utente.CHIEDE_PERMESSO`).** Il pulsante fa la richiesta di sistema di macOS per quel permesso, che aggiunge Axi all'elenco di Impostazioni di Sistema, con il ripiego sul pannello come sopra; la finestra resta aperta.

**Riapri Axi (`utente.RIAPRE_AXI`).** Dopo che l'utente ha chiesto Registrazione schermo, nella finestra dei permessi la sua riga mostra «Registrazione schermo vale dopo aver riaperto Axi.» / «Screen Recording takes effect after reopening Axi.» e il pulsante «Riapri Axi» / «Reopen Axi», finché Axi non viene riaperto. Riaprire avvia una nuova istanza dal bundle dell'app con `NSWorkspace` e poi chiude quella corrente; al nuovo avvio il controllo si ripete.

**Chiusura automatica.** Quando tutti i permessi risultano concessi e nessuno aspetta la riapertura di Axi, la finestra mostra «Tutto pronto.» / «All set.» con un segno di spunta e si chiude da sola dopo 2 secondi.

**Chiudere (`utente.CHIUDE_PERMESSI`).** Il pulsante «Fine» / «Done» in basso a destra (o la chiusura della finestra) la chiude; Axi continua con le funzioni che i permessi concessi permettono, e se al prossimo avvio manca ancora qualcosa la finestra ricompare.

**Riaprire dalla chat (`utente.APRE_PERMESSI`).** Il controller della finestra espone un modo per aprirla da fuori: se è chiusa si apre, se è già aperta torna in primo piano. Il pulsante nella chat che lo usa è di un altro Task.
