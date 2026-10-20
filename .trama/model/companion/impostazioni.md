# Impostazioni

La finestra delle impostazioni: avvio di Axi al login, modello AI, scorciatoie, Azure Document Intelligence, percorso di OMP e permessi di macOS. L'avvio al login si attiva da solo quando il benvenuto è completato e l'utente può spegnerlo qui. Tra le scorciatoie l'utente sceglie se assegnare ad Axi i tasti Spotlight e Dettatura: assegnati, il tasto Spotlight apre e chiude la chat e il tasto Dettatura archivia, e macOS non apre più Spotlight né avvia la Dettatura da quei tasti; non assegnati, tornano a macOS. I tasti restano ad Axi solo finché Accessibility è concessa: se il permesso viene tolto mentre Axi è aperto, tornano subito a macOS, e tornano ad Axi quando il permesso torna. Ogni cambiamento vale subito.

## States

### Chiuse (initial)
- `utente.APRE_IMPOSTAZIONI` → Aperte

### Aperte
Mostra anche lo stato dei permessi di macOS, come la finestra dei permessi, aggiornato da solo.
- `utente.CHIUDE_IMPOSTAZIONI` → Chiuse
- `utente.APRE_IMPOSTAZIONI` → Aperte: la finestra già aperta torna in primo piano.
- `utente.CHIEDE_PERMESSO` → Aperte: Axi fa la richiesta di sistema di macOS per quel permesso, che aggiunge Axi all'elenco di Impostazioni di Sistema; se macOS non mostra più la sua richiesta, si apre il pannello giusto di Impostazioni di Sistema. Se il permesso è Registrazione schermo, le impostazioni offrono di riaprire Axi.
- `utente.RIAPRE_AXI` → Chiuse: Axi si chiude e si riapre.
