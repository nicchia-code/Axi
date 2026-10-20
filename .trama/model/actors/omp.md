# OMP

L'agente AI che gira sullo stesso Mac e che Axi avvia e guida. Usa il modello scelto nelle impostazioni di Axi tra quelli disponibili in OMP, e lavora sul vault solo tramite gli strumenti che Axi gli offre: cercare nei documenti, leggere una pagina, cambiare i tag, chiedere di eliminare un documento.

## Events

### PRONTO
OMP si è avviato e accetta richieste.

### NON_AVVIABILE
OMP non si trova sul Mac o non riesce ad avviarsi.

### TERMINATO
OMP si è fermato mentre era pronto.

### METADATI_GENERATI
OMP ha prodotto per un documento in archiviazione titolo, riassunto, tag, data del documento, lingua e date citate.

### METADATI_FALLITI
OMP non è riuscito a produrre i metadati di un documento in archiviazione.

### RISPOSTA_COMPLETATA
OMP ha finito di rispondere a una domanda della chat.

### RISPOSTA_FALLITA
OMP non è riuscito a rispondere a una domanda della chat.

### ELIMINAZIONE_RICHIESTA
Durante una risposta, OMP chiede di eliminare un documento dal vault perché l'utente lo ha chiesto in chat. Nulla sparisce finché l'utente non conferma.

### TAG_CAMBIATI
Durante una risposta, OMP cambia i tag di un documento del vault come l'utente ha chiesto in chat.
