# Attività

Ciò che il puntino comunica con le sue animazioni e le sue nuvolette: se sta cercando o archiviando un documento e come è andata. Procede in parallelo al menu e alla chat del puntino; lo mostra il personaggio sullo schermo, o la sua icona nella barra dei menu quando il puntino è nascosto. La nuvoletta compare accanto al personaggio, o sotto l'icona della barra quando il puntino è nascosto, oppure in cima alla chat se la chat è aperta.

## States

### Nessuna (initial)
Il puntino non ha lavoro né esiti da mostrare: è fermo, e si anima solo mentre l'utente interagisce con lui.
- `utente.CHIEDE_ARCHIVIAZIONE` → In ricerca
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → In corso: una nuvoletta di avvio dice che Axi sta archiviando il documento, con il nome con cui l'utente lo riconosce.
- `lettura-schermo.NESSUN_DOCUMENTO` → Esito: la nuvoletta spiega il motivo del rifiuto: che a schermo non c'è un documento archiviabile e che va prima salvato come file, che l'indirizzo della pagina web non si riesce a leggere, quale permesso manca, oppure che c'è stato un errore imprevisto.
- `mini-chat.NON_DISPONIBILE` → Esito: la nuvoletta spiega che la chat ha bisogno di OMP e che OMP non è pronto.

### In ricerca
Axi cerca a schermo il documento da archiviare: dal momento della richiesta il puntino mostra che sta lavorando, anche quando la ricerca aspetta che finisca un'altra lettura dello schermo.
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → In corso: una nuvoletta di avvio dice che Axi sta archiviando il documento, con il nome con cui l'utente lo riconosce.
- `lettura-schermo.NESSUN_DOCUMENTO` → Esito: la nuvoletta spiega il motivo del rifiuto, come quando il puntino non ha lavoro.
- `lettura-schermo.NESSUN_DOCUMENTO` → In ricerca: se un'altra richiesta di archiviazione aspetta ancora la sua ricerca; una nuvoletta spiega il rifiuto e il puntino continua a mostrare che lavora.
- `mini-chat.NON_DISPONIBILE` → In ricerca: una nuvoletta spiega che la chat ha bisogno di OMP.

### In corso
Il puntino mostra che sta lavorando e accanto quanti documenti aspettano in coda. La nuvoletta di avvio compare solo quando il puntino comincia a lavorare: i documenti che seguono nella stessa serie non ne hanno una.
- `archiviazione.ARCHIVIATO` → In corso: se in coda ci sono altri documenti; una nuvoletta mostra l'esito e il lavoro continua.
- `archiviazione.ARCHIVIATO` → Esito: se la coda è vuota.
- `archiviazione.NON_ARCHIVIATO` → In corso: se in coda ci sono altri documenti; una nuvoletta mostra il motivo e il lavoro continua.
- `archiviazione.NON_ARCHIVIATO` → Esito: se la coda è vuota.
- `lettura-schermo.NESSUN_DOCUMENTO` → In corso: una nuvoletta spiega il rifiuto e il lavoro continua.
- `mini-chat.NON_DISPONIBILE` → In corso: una nuvoletta spiega che la chat ha bisogno di OMP.
- `tempo.NUVOLETTA_SCADUTA` → In corso: la nuvoletta sparisce e il lavoro continua.
- `utente.CLIC_NUVOLETTA` → In corso: se è la nuvoletta di avvio, sparisce e il lavoro continua.

### Esito
Il puntino anima il successo o l'errore e una nuvoletta racconta l'ultimo esito: per un documento archiviato il titolo e i tag, gli allegati di un'email che non è stato possibile prendere e, se la data di ricezione di un'email è rimasta sconosciuta, che è stata archiviata senza; per un documento non archiviato il motivo, compreso il documento già presente nel vault.
- `tempo.NUVOLETTA_SCADUTA` → Nessuna: la nuvoletta sparisce.
- `utente.CLIC_NUVOLETTA` → Nessuna: se l'esito era un documento archiviato o già presente, Axi apre la sua copia del vault nell'app predefinita.
- `utente.CHIEDE_ARCHIVIAZIONE` → In ricerca
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → In corso: una nuvoletta di avvio dice che Axi sta archiviando il documento, con il nome con cui l'utente lo riconosce.
- `lettura-schermo.NESSUN_DOCUMENTO` → Esito: la nuvoletta mostra il nuovo rifiuto.
- `mini-chat.NON_DISPONIBILE` → Esito: la nuvoletta spiega che la chat ha bisogno di OMP.
