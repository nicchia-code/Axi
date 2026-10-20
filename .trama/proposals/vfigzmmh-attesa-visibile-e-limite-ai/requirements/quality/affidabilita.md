---
description: Use when handling errors, failures or diagnostics while reading the screen or archiving.
---
# Affidabilità

## lettura-schermo
- Nessun errore durante la lettura dello schermo chiude Axi: un errore non previsto nella ricerca del documento diventa un rifiuto con motivo «errore imprevisto».
- Ogni rifiuto e ogni fallimento della lettura si registra nel log di sistema con il passo, il motivo e l'app di origine; senza testo letto a schermo e senza indirizzi completi delle pagine (al più il dominio).
- Ogni ricerca del documento da archiviare registra nel log di sistema quando comincia e, alla fine, quanto è durata e il suo esito (documento individuato o rifiuto), con l'app di origine; con le stesse esclusioni dei rifiuti.

## archiviazione
- Nessun errore durante l'archiviazione chiude Axi: un errore non previsto diventa un documento non archiviato con motivo «errore imprevisto», e nel vault non resta nulla di esso.
- Ogni fallimento di un passo dell'archiviazione, compreso un PDF di pagina web non creato o scartato perché non corrisponde, e un PDF di pagina web non scaricato con la sua causa (tempo scaduto, errore di rete o del server, risposta che non è un PDF, troppo grande), si registra nel log di sistema con il passo, il motivo e l'origine del documento; senza testo del documento e senza indirizzi completi delle pagine (al più il dominio).
- Ogni passo dell'archiviazione (acquisizione, compresi lo scaricamento o la creazione del PDF di una pagina web e la richiesta della data di ricezione di un'email; controllo dei duplicati; estrazione del testo; generazione dei metadati, con ciascuna richiesta all'AI; indicizzazione) registra nel log di sistema quando comincia e, alla fine, quanto è durato e il suo esito, con l'origine del documento; con le stesse esclusioni dei fallimenti. Una richiesta all'AI scaduta si registra come fallimento della generazione dei metadati con motivo «tempo scaduto».
- Un errore non previsto non si racconta come uno dei motivi previsti (per esempio «indicizzazione non riuscita»).
