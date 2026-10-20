# Benvenuto

La finestra che accoglie l'utente al primo avvio: guida i permessi di macOS e scarica il modello per la ricerca nel vault. Ricompare a ogni avvio finché non è completato; chiuderla la rimanda al prossimo avvio. Finché il benvenuto non è completato Axi non archivia. Dopo, i permessi mancanti si chiedono nella finestra dei permessi.

## States

### In corso (initial)

#### Permessi (initial)
Spiega e chiede i permessi che servono ad Axi: Accessibility, Registrazione schermo e Automazione dei browser. Accessibility serve a leggere lo schermo e anche a ricevere i tasti Spotlight e Dettatura. L'Automazione serve solo a Safari e Chrome: per ciascuno dei due che è installato mostra se è già concessa, oppure che va aperto per verificarlo se è chiuso, e dice che Firefox non ne ha bisogno perché gli basta Accessibility. Mostra per ogni permesso se è già concesso e se OMP è stato trovato. L'utente può proseguire anche senza tutti i permessi: le funzioni che li richiedono restano limitate finché mancano.
- `utente.CHIEDE_PERMESSO` → Permessi: Axi fa la richiesta di sistema di macOS per quel permesso, che aggiunge Axi all'elenco di Impostazioni di Sistema; se macOS non mostra più la sua richiesta, si apre il pannello giusto di Impostazioni di Sistema.
- `utente.PROSEGUE` → Scaricamento del modello

#### Scaricamento del modello
Axi scarica il modello per la ricerca nel vault e mostra l'avanzamento.
- `MODELLO_SCARICATO` → Completato
- `SCARICAMENTO_FALLITO` → Scaricamento non riuscito

#### Scaricamento non riuscito
Spiega che lo scaricamento non è riuscito.
- `utente.RIPROVA_DOWNLOAD` → Scaricamento del modello

### Completato (final)
Il benvenuto non compare più.

## Events

### MODELLO_SCARICATO
Il modello per la ricerca è sul Mac e funziona.

### SCARICAMENTO_FALLITO
Lo scaricamento del modello si è interrotto o il modello scaricato non funziona.
