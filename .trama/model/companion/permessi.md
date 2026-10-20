# Permessi

La finestra dei permessi. A ogni avvio, quando il benvenuto è già completato, Axi controlla i permessi di macOS che gli servono e, se ne manca qualcuno, apre questa finestra per chiederli. Contano come mancanti Accessibility, Registrazione schermo e l'Automazione di Safari e di Chrome, per ciascuno dei due che è installato, quando macOS la dice negata o non ancora chiesta; se il browser è chiuso la sua Automazione è sconosciuta e non conta come mancante. Firefox non ha bisogno dell'Automazione: gli basta Accessibility. La finestra mostra anche l'Automazione del Finder, con il suo stato e il pulsante per chiederla, ma la sua mancanza non conta: al Finder serve solo quando Accessibility non dà la selezione. Mentre Axi è aperto la finestra non ricompare da sola: un permesso tolto si scopre al prossimo avvio, oppure quando una lettura dello schermo lo trova mancante; solo i tasti Spotlight e Dettatura tornano subito a macOS se Accessibility viene tolta.

## States

### Controllo (initial)
All'avvio Axi legge lo stato dei permessi.
- `PERMESSI_CONCESSI` → Chiusa
- `PERMESSI_MANCANTI` → Chiusa: il benvenuto non è ancora completato; i permessi li chiede il benvenuto.
- `PERMESSI_MANCANTI` → Aperta: il benvenuto è completato.

### Aperta
Spiega che ad Axi mancano alcuni permessi e mostra per ciascuno se è concesso, con un pulsante per chiederlo; lo stato si aggiorna da solo. Quando l'utente ha chiesto Registrazione schermo, che macOS applica solo alla riapertura dell'app, la finestra offre di riaprire Axi.
- `utente.CHIEDE_PERMESSO` → Aperta: Axi fa la richiesta di sistema di macOS per quel permesso, che aggiunge Axi all'elenco di Impostazioni di Sistema; se macOS non mostra più la sua richiesta, si apre il pannello giusto di Impostazioni di Sistema.
- `PERMESSI_CONCESSI` → Chiusa: tutti i permessi risultano concessi e nessuno aspetta la riapertura di Axi; la finestra dice che è tutto pronto e si chiude da sola dopo un paio di secondi.
- `utente.RIAPRE_AXI` → Controllo: Axi si chiude e si riapre, e il controllo si ripete.
- `utente.CHIUDE_PERMESSI` → Chiusa: Axi continua con le funzioni che i permessi concessi permettono; se al prossimo avvio manca ancora qualcosa, la finestra ricompare.
- `utente.APRE_PERMESSI` → Aperta: la finestra già aperta torna in primo piano.

### Chiusa
- `utente.APRE_PERMESSI` → Aperta

## Events

### PERMESSI_CONCESSI
Emesso quando tutti i permessi che contano risultano concessi: all'avvio, oppure mentre la finestra è aperta.

### PERMESSI_MANCANTI
Emesso dal controllo all'avvio quando almeno un permesso che conta manca; porta con sé quali.
