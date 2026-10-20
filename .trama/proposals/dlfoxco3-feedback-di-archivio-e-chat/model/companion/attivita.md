# Attività

Ciò che il puntino comunica con le sue animazioni e le sue nuvolette: se sta archiviando, quale documento e come è andata. Procede in parallelo al menu e alla chat del puntino; lo mostra il personaggio sullo schermo, o la sua icona nella barra dei menu quando il puntino è nascosto. La nuvoletta compare accanto al personaggio, o sotto l'icona della barra quando il puntino è nascosto, oppure in cima alla chat se la chat è aperta.

Da quando l'utente chiede un'archiviazione, o rilascia dei file sul puntino, fino all'ultimo esito il personaggio è nei tre puntini, senza aspettare nessun passo dell'archiviazione. Le nuvolette chiamano ogni documento con il suo nome d'origine, quello con cui l'utente lo riconosce: il nome del file, l'oggetto dell'email, il titolo della pagina web.

## States

### Nessuna (initial)
Il puntino non ha lavoro né esiti da mostrare: è fermo, e si anima solo mentre l'utente interagisce con lui.
- `utente.CHIEDE_ARCHIVIAZIONE` → In ricerca
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → In corso
- `lettura-schermo.NESSUN_DOCUMENTO` → Esito: la nuvoletta spiega il motivo del rifiuto: che a schermo non c'è un documento archiviabile e che va prima salvato come file, che l'indirizzo della pagina web non si riesce a leggere, quale permesso manca, oppure che c'è stato un errore imprevisto.
- `mini-chat.NON_DISPONIBILE` → Esito: la nuvoletta spiega che la chat ha bisogno di OMP e che OMP non è pronto.

### In ricerca
Axi cerca a schermo il documento che l'utente ha chiesto di archiviare. Subito il personaggio diventa tre puntini e una nuvoletta dice che Axi sta archiviando, con tre puntini animati, senza ancora il nome del documento.
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → Avvio: il documento è stato individuato e la nuvoletta aggiunge il suo nome d'origine.
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → Senza nuvoletta: se l'utente ha già chiuso la nuvoletta durante la ricerca; il lavoro continua senza nuvoletta.
- `utente.CLIC_NUVOLETTA` → In ricerca: la nuvoletta sparisce e il personaggio resta nei tre puntini.
- `lettura-schermo.NESSUN_DOCUMENTO` → Esito: la nuvoletta lascia il posto al motivo del rifiuto, come quando il puntino non ha lavoro.
- `lettura-schermo.NESSUN_DOCUMENTO` → In ricerca: se un'altra richiesta di archiviazione aspetta ancora la sua ricerca; una nuvoletta spiega il rifiuto per i suoi secondi e il personaggio resta nei tre puntini.
- `mini-chat.NON_DISPONIBILE` → In ricerca: una nuvoletta spiega che la chat ha bisogno di OMP, al posto di quella dell'archiviazione.

### In corso
Axi archivia un documento: il personaggio è nei tre puntini e accanto mostra quanti documenti aspettano in coda.
- `archiviazione.ARCHIVIATO` → Nuvoletta di passaggio: se in coda ci sono altri documenti; la nuvoletta dice che il documento è archiviato, con il suo nome d'origine, e il lavoro continua con il successivo.
- `archiviazione.ARCHIVIATO` → Esito: se la coda è vuota.
- `archiviazione.NON_ARCHIVIATO` → Nuvoletta di passaggio: se in coda ci sono altri documenti; la nuvoletta dice che il documento, con il suo nome d'origine, non è stato archiviato e perché, o che è già nel vault, e il lavoro continua con il successivo.
- `archiviazione.NON_ARCHIVIATO` → Esito: se la coda è vuota.
- `lettura-schermo.NESSUN_DOCUMENTO` → Nuvoletta di passaggio: una nuvoletta spiega il rifiuto di un'altra richiesta e il lavoro continua.
- `mini-chat.NON_DISPONIBILE` → Nuvoletta di passaggio: una nuvoletta spiega che la chat ha bisogno di OMP e il lavoro continua.

#### Avvio (initial)
Una nuvoletta dice che Axi sta archiviando il documento in lavorazione, con il suo nome d'origine e tre puntini animati. Resta finché non arriva il suo esito o finché l'utente non la chiude; non sparisce da sola.
- `utente.CLIC_NUVOLETTA` → Senza nuvoletta: la nuvoletta sparisce e il lavoro continua.

#### Senza nuvoletta
L'utente ha chiuso la nuvoletta del documento in lavorazione: restano i tre puntini e il numero dei documenti in coda. Per il documento successivo le nuvolette tornano.

#### Nuvoletta di passaggio
Il puntino anima l'esito del documento appena concluso, o un rifiuto o un avviso, e la nuvoletta lo racconta mentre il documento successivo è già in lavorazione.
- `tempo.NUVOLETTA_SCADUTA` → Avvio: la nuvoletta lascia il posto a quella del documento in lavorazione.
- `utente.CLIC_NUVOLETTA` → Avvio: se l'esito era un documento archiviato o già presente, Axi apre la sua copia del vault nell'app predefinita; la nuvoletta lascia il posto a quella del documento in lavorazione.

### Esito
Il puntino anima il successo o l'errore e una nuvoletta racconta l'ultimo esito: per un documento archiviato che è stato archiviato, con il suo nome d'origine, poi il titolo e i tag, gli allegati di un'email che non è stato possibile prendere e, se la data di ricezione di un'email è rimasta sconosciuta, che è stata archiviata senza; per un documento non archiviato il suo nome d'origine e il motivo, compreso il documento già presente nel vault.
- `tempo.NUVOLETTA_SCADUTA` → Nessuna: la nuvoletta sparisce.
- `utente.CLIC_NUVOLETTA` → Nessuna: se l'esito era un documento archiviato o già presente, Axi apre la sua copia del vault nell'app predefinita.
- `utente.CHIEDE_ARCHIVIAZIONE` → In ricerca: la nuvoletta dell'esito lascia il posto a quella della nuova archiviazione.
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → In corso
- `lettura-schermo.NESSUN_DOCUMENTO` → Esito: la nuvoletta mostra il nuovo rifiuto.
- `mini-chat.NON_DISPONIBILE` → Esito: la nuvoletta spiega che la chat ha bisogno di OMP.
