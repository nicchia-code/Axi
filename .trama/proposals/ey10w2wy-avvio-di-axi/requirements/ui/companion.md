---
description: Use when building the dot, its menu, its animations and bubbles, the welcome window or the settings window.
---
# Puntino, benvenuto e impostazioni

## General
- Interfaccia in italiano e inglese: segue la lingua di macOS, inglese per ogni altra lingua.
- Stile di macOS 26: materiali Liquid Glass per menu, nuvolette e finestre.
- Le animazioni sono una parte centrale dell'esperienza: fluide, curate, mai a scatti. Con "Riduci movimento" attivo diventano dissolvenze semplici.
- Axi è un'app accessoria: nessuna icona nel Dock e nessuna voce nel selettore ⌘Tab.

## puntino
- Cerchio di circa 18 pt nel colore d'accento di macOS, con un leggero alone.
- Sta sopra tutte le finestre, su ogni Spazio e sulle app a schermo intero, senza rubare il fuoco all'app in primo piano.
- Si trascina ovunque, anche tra schermi; la posizione si salva e si ripristina all'avvio. Se lo schermo dove era non c'è più, compare in basso a destra sullo schermo principale.
- Quando l'utente ci trascina sopra dei file, il puntino si ingrandisce e cambia aspetto per mostrare che può riceverli.
- Nascondere e mostrare il puntino avviene con un'animazione di dissolvenza e scala.

## puntino/Menu aperto
- Le azioni compaiono a raggiera attorno al puntino, con icona ed etichetta: Archivia, Chat, Impostazioni…, Nascondi, Esci.
- Ogni azione mostra la sua scorciatoia: Archivia ⌥A, Chat F4 (oppure ⌥Spazio se F4 non è disponibile), Nascondi ⌥H.

## attivita
- A riposo il puntino "respira" lentamente (leggera variazione di scala e luminosità).
- Durante un'archiviazione il puntino anima il lavoro (rotazione o pulsazione dell'alone) e mostra un piccolo numero con i documenti in coda, quando ce ne sono.
- Successo: breve rimbalzo con un segno di spunta. Errore: breve scossa orizzontale e colore rosso di sistema. Documento già presente: un lampo nel colore d'accento senza scossa.
- La nuvoletta compare accanto al puntino, dal lato con più spazio. Per un documento archiviato mostra titolo, tag e l'elenco degli allegati non presi con l'indicazione di trascinarli o aprirli; per un documento non archiviato mostra il motivo in una frase.
- La nuvoletta resta 5 secondi, o finché il puntatore ci resta sopra, ed è cliccabile.

## benvenuto
- Finestra centrata, a passi, con indicatore del passo corrente.
- Passo dei permessi: per Accessibility, Registrazione schermo e Automazione una riga con spiegazione in una frase, stato (concesso o no) e pulsante che apre il pannello giusto di Impostazioni di Sistema; lo stato si aggiorna da solo. Una riga mostra se OMP è stato trovato.
- Passo del modello: barra di avanzamento con dimensione scaricata e totale; in caso di errore il messaggio e il pulsante Riprova.

## impostazioni
- Finestra standard delle impostazioni di macOS con le sezioni: Modello AI, Scorciatoie, Azure Document Intelligence, OMP.
- Modello AI: elenco dei modelli disponibili in OMP, con quello predefinito di OMP preselezionato.
- Scorciatoie: un campo registrabile per Archivia, Chat e Mostra/nascondi puntino, con ripristino dei valori predefiniti.
- Azure Document Intelligence: endpoint e chiave, un pulsante Prova connessione e l'indicazione che, se configurato, viene usato per le pagine senza testo e per lo schermo.
- OMP: percorso, stato della connessione e motivo quando non è disponibile.
