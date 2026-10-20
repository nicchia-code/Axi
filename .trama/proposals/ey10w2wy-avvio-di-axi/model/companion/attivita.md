# Attività

Ciò che il puntino comunica con le sue animazioni e le sue nuvolette: se sta archiviando e come è andata. Procede in parallelo alla posizione e alla visibilità del puntino; anche quando il puntino è nascosto, la nuvoletta con l'esito compare nella sua posizione.

## States

### Nessuna (initial)
Il puntino respira piano.
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → In corso
- `lettura-schermo.NESSUN_DOCUMENTO` → Esito: la nuvoletta spiega che a schermo non c'è un documento archiviabile e che va prima salvato come file, oppure che manca il permesso per leggere lo schermo.
- `mini-chat.NON_DISPONIBILE` → Esito: la nuvoletta spiega che la chat ha bisogno di OMP e che OMP non è pronto.

### In corso
Il puntino anima il lavoro e mostra quanti documenti aspettano in coda.
- `archiviazione.ARCHIVIATO` → In corso: se in coda ci sono altri documenti; una nuvoletta mostra l'esito e il lavoro continua.
- `archiviazione.ARCHIVIATO` → Esito: se la coda è vuota.
- `archiviazione.NON_ARCHIVIATO` → In corso: se in coda ci sono altri documenti; una nuvoletta mostra il motivo e il lavoro continua.
- `archiviazione.NON_ARCHIVIATO` → Esito: se la coda è vuota.
- `lettura-schermo.NESSUN_DOCUMENTO` → In corso: una nuvoletta spiega il rifiuto e il lavoro continua.
- `mini-chat.NON_DISPONIBILE` → In corso: una nuvoletta spiega che la chat ha bisogno di OMP.

### Esito
Il puntino anima il successo o l'errore e una nuvoletta racconta l'ultimo esito: per un documento archiviato il titolo e i tag, e gli allegati di un'email che non è stato possibile prendere; per un documento non archiviato il motivo, compreso il documento già presente nel vault.
- `tempo.NUVOLETTA_SCADUTA` → Nessuna: la nuvoletta sparisce.
- `utente.CLIC_NUVOLETTA` → Nessuna: se l'esito era un documento archiviato o già presente, Axi apre la sua copia del vault nell'app predefinita.
- `coda-archiviazione.PROSSIMO_DOCUMENTO` → In corso
- `lettura-schermo.NESSUN_DOCUMENTO` → Esito: la nuvoletta mostra il nuovo rifiuto.
- `mini-chat.NON_DISPONIBILE` → Esito: la nuvoletta spiega che la chat ha bisogno di OMP.
