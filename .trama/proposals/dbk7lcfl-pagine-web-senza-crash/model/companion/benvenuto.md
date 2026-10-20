# Benvenuto

La finestra che accoglie l'utente al primo avvio: guida i permessi di macOS e scarica il modello per la ricerca nel vault. Ricompare a ogni avvio finché non è completato; chiuderla la rimanda al prossimo avvio. Finché il benvenuto non è completato Axi non archivia.

## States

### In corso (initial)

#### Permessi (initial)
Spiega e chiede i permessi che servono ad Axi: Accessibility, Registrazione schermo e Automazione dei browser. L'Automazione serve solo a Safari e Chrome: per ciascuno dei due che è installato mostra se è già concessa, e dice che Firefox non ne ha bisogno. Mostra per ogni permesso se è già concesso e se OMP è stato trovato. L'utente può proseguire anche senza tutti i permessi: le funzioni che li richiedono restano limitate finché mancano.
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
