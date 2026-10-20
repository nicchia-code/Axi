---
description: Use when storing or reading vault documents, their metadata, conversations, settings or the dot's place in the menu bar.
---
# Vault, conversazioni e impostazioni

## General
- Tutti i dati stanno in `~/Library/Application Support/Axi/`: le copie dei documenti, il database del vault, il modello di embedding e le sessioni OMP delle conversazioni.
- Le date rese assolute si interpretano nel fuso orario del Mac al momento della lettura o dell'archiviazione e si conservano come istante con il suo offset; una data senza ora si conserva come giorno, senza ora inventata.

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
- per un'email: mittente, destinatari, oggetto, data di ricezione assoluta (può mancare) e, se veniva da Outlook, la data così come era mostrata a schermo, gli allegati collegati e i nomi degli allegati non presi;
- le date citate, al massimo 20, ciascuna con data (con l'ora se il testo la dice), di cosa si tratta e le parole originali del testo; la data manca solo per una data relativa di un'email con data di ricezione sconosciuta;
- per un allegato: l'email a cui è collegato.
- I tag sono un vocabolario condiviso del vault: un tag esiste una volta sola e può stare su molti documenti.

## mini-chat
- Ogni conversazione conserva titolo, data di creazione e dell'ultimo messaggio, la sessione OMP e i messaggi.
- Ogni messaggio conserva autore (utente o Axi), testo, data, il contesto dello schermo usato se c'era con il momento della sua lettura, e i documenti citati con la pagina.

## impostazioni
- Si conservano modello AI scelto, scorciatoie, se i tasti Spotlight e Dettatura sono assegnati ad Axi (sì se mai scelto), endpoint di Azure Document Intelligence (la chiave sta nel Keychain), percorso di OMP e se l'avvio al login è già stato attivato dopo il benvenuto, così una scelta dell'utente non viene sovrascritta.

## puntino
- Si conserva il posto del puntino nella barra dei menu scelto dall'utente (lo conserva macOS con il nome di salvataggio dell'elemento).

## benvenuto
- Si conserva se il benvenuto è completato.
