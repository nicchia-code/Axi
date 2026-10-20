---
description: Use when storing or reading vault documents, their metadata, conversations, settings or the dot's position.
---
# Vault, conversazioni e impostazioni

## General
- Tutti i dati stanno in `~/Library/Application Support/Axi/`: le copie dei documenti, il database del vault, il modello di embedding e le sessioni OMP delle conversazioni.

## documento
Ogni documento conserva:
- identificativo, titolo e tipo (PDF, Word, email, pagina web, immagine, altro);
- la copia del file nel vault e il nome originale; per una pagina web senza PDF, solo testo e indirizzo, con l'indicazione che il PDF manca;
- origine: app da cui viene, percorso originale o indirizzo web;
- impronta del contenuto;
- data del documento (estratta dal contenuto, può mancare) e data di archiviazione;
- numero di pagine e lingua;
- riassunto e tag;
- il testo, pagina per pagina, e i suoi brani indicizzati;
- per un'email: mittente, destinatari, oggetto, data, gli allegati collegati e i nomi degli allegati non presi;
- per un allegato: l'email a cui è collegato.
- I tag sono un vocabolario condiviso del vault: un tag esiste una volta sola e può stare su molti documenti.

## mini-chat
- Ogni conversazione conserva titolo, data di creazione e dell'ultimo messaggio, la sessione OMP e i messaggi.
- Ogni messaggio conserva autore (utente o Axi), testo, data, il contesto dello schermo usato se c'era, e i documenti citati con la pagina.

## impostazioni
- Si conservano modello AI scelto, scorciatoie, endpoint di Azure Document Intelligence (la chiave sta nel Keychain) e percorso di OMP.

## puntino
- Si conservano la posizione del puntino e lo schermo su cui si trova, e se è nascosto.

## benvenuto
- Si conserva se il benvenuto è completato.
