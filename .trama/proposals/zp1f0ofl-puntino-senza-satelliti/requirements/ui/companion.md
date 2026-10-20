---
description: Use when building the dot character (on screen or in the menu bar), its menus, its animations and bubbles, the welcome, permissions or settings window.
---
# Puntino, benvenuto e impostazioni

## General
- Interfaccia in italiano e inglese: segue la lingua di macOS, inglese per ogni altra lingua.
- Stile di macOS 26: materiali Liquid Glass per menu, nuvolette e finestre.
- Le animazioni sono una parte centrale dell'esperienza: fluide, curate, mai a scatti. Con "Riduci movimento" attivo diventano dissolvenze semplici.
- Axi è un'app accessoria: nessuna icona nel Dock e nessuna voce nel selettore ⌘Tab; vive nel puntino sullo schermo e, quando il puntino è nascosto, nella barra dei menu.

## puntino
- Il puntino è il personaggio di Axi disegnato in vettoriale, in uno stile liscio e fluido (non pixel art): una pallina blu dal contorno tondo e leggermente irregolare, un poco schiacciata, con l'ombra in basso a sinistra, un riflesso in alto a destra e due occhi azzurri, senza satelliti né altre forme attorno. È sempre nei suoi colori, sullo schermo e nella barra dei menu (non segue l'aspetto chiaro o scuro).
- Colori: corpo `#1777F7`, ombra `#135EEA`, riflesso `#33C9F9`, occhi `#68EDF6`, con passaggi sfumati tra corpo, ombra e riflesso. Il disegno è nitido a ogni dimensione; nella barra dei menu è lo stesso disegno rimpicciolito.
- Ha tre aspetti: fermo, attesa e tre puntini.
  - Fermo, l'aspetto predefinito: il personaggio non si muove.
  - Attesa: il corpo si gonfia e si sgonfia mentre il contorno ondeggia piano come una goccia; il movimento è continuo, senza scatti, in un ciclo di circa 2,2 s.
  - Tre puntini di sospensione, mentre l'AI pensa (la chat è in `mini-chat/In risposta` o un documento è in `archiviazione/Generazione dei metadati`): in circa 0,4 s il corpo si allunga e si separa in tre gocce uguali in fila, sfumate come il corpo (ombra, luce e riflesso), e gli occhi spariscono. Le gocce si alzano e si gonfiano un poco una dopo l'altra, a onda, in un ciclo di circa 2,2 s. Quando l'AI ha finito, in circa 0,4 s le gocce si riuniscono nel personaggio. I tre puntini restano dentro il riquadro del personaggio. Le altre richieste all'AI (per esempio la data di ricezione di un'email) non mostrano i tre puntini.
- A riposo si vede l'aspetto fermo. L'attesa si vede mentre l'utente interagisce con il puntino (menu aperto, chat aperta, file trascinati sopra) e durante un'archiviazione (vedi `attivita`). I tre puntini hanno la precedenza sull'attesa; il segnale di un esito ha la precedenza su entrambi e, finito, il puntino torna all'aspetto del momento.
- Con "Riduci movimento" attivo attesa, trasformazione e tre puntini restano gli stessi a metà velocità (ciclo di circa 4,4 s, trasformazione di circa 0,8 s) invece di diventare dissolvenze.
- Clic con la chat chiusa: si apre il menu. Clic con la chat aperta: la chat si chiude e il menu non si apre.
- Quando l'utente ci trascina sopra dei file, il puntino si evidenzia per mostrare che può riceverli.

## puntino/Visibile
- Personaggio alto circa 32 pt, sopra tutte le finestre, su ogni Spazio e sulle app a schermo intero, senza rubare il fuoco all'app in primo piano.
- Si trascina ovunque, anche tra schermi; la posizione si ritrova al prossimo avvio. Senza una posizione salvata, o se lo schermo dove era non c'è più, compare in basso a destra sullo schermo principale.
- Nascondere e mostrare il personaggio avviene sul posto con un'animazione di dissolvenza e scala.

## puntino/Menu aperto
- Le azioni compaiono a raggiera attorno al personaggio, con icona ed etichetta: Archivia, Chat, Impostazioni…, Nascondi, Esci, distribuite in modo uniforme. Esc e il clic altrove lo chiudono.
- Ogni azione mostra la sua scorciatoia: Archivia ⌥A, Chat ⌥Spazio, Nascondi ⌥H, o quelle registrate dall'utente.
- Quando i tasti Spotlight e Dettatura sono assegnati ad Axi e il permesso Accessibility è concesso, Archivia mostra al posto della scorciatoia il simbolo del microfono e Chat il simbolo della lente, come sui tasti.

## puntino/Nascosto
- Elemento della barra dei menu con il personaggio nei suoi colori, alto come le altre icone della barra (circa 18 pt); si evidenzia come le altre icone quando il suo menu è aperto.
- C'è solo mentre il puntino è nascosto. L'utente lo sposta nella barra con ⌘-trascina; il posto scelto si ritrova la volta successiva.
- Mostra gli stessi aspetti e le stesse animazioni del personaggio sullo schermo.

## puntino/Menu della barra
- Menu nativo di macOS sotto l'icona, con icona ed etichetta per ogni azione: Mostra, un separatore, poi Archivia, Chat, Impostazioni…, Esci. Esc e il clic altrove lo chiudono.
- Ogni azione mostra la sua scorciatoia come nel menu a raggiera: Mostra ⌥H, Archivia ⌥A, Chat ⌥Spazio, o quelle registrate dall'utente, con i simboli del microfono e della lente quando i tasti Spotlight e Dettatura sono assegnati ad Axi e il permesso Accessibility è concesso.

## attivita
- A riposo il puntino è fermo: si vede l'aspetto fermo.
- Durante un'archiviazione il puntino mostra l'attesa, e i tre puntini mentre l'AI genera i metadati del documento (vedi `puntino`); quando ci sono documenti in coda un piccolo numero compare alla destra del personaggio, e nella barra dei menu l'elemento si allarga per contenerlo.
- Successo: breve rimbalzo del personaggio con un piccolo segno di spunta. Errore: breve scossa orizzontale con il personaggio tinto del rosso di sistema. Documento già presente: un breve lampo del personaggio senza scossa. Finito il segnale il personaggio torna ai suoi colori.
- Con il puntino visibile la nuvoletta compare accanto al personaggio, dal lato con più spazio, interamente sullo schermo. Con il puntino nascosto compare sotto l'icona della barra, allineata a lei e interamente sullo schermo; se la barra dei menu è nascosta (per esempio in un'app a schermo intero) compare comunque in alto sullo schermo attivo, sotto il punto dell'icona, sopra l'app a schermo intero. Se la chat è aperta compare in sovrimpressione in cima alla chat. Per un documento archiviato mostra titolo, tag e l'elenco degli allegati non presi con l'indicazione di trascinarli o aprirli; per un documento non archiviato mostra il motivo in una frase.
- Per un'email archiviata senza data di ricezione la nuvoletta aggiunge, sotto titolo e tag, la riga «Non ho capito quando è arrivata: l'ho archiviata senza data di ricezione.» / «I couldn't tell when it arrived: archived without a received date.»
- Testi dei rifiuti e dell'errore imprevisto (italiano / inglese):
  - Nessun documento: «Qui non vedo un documento da archiviare: salvalo prima come file.» / «I don't see a document to archive here: save it as a file first.»
  - Indirizzo non leggibile: «Non riesco a leggere l'indirizzo di questa pagina.» / «I can't read this page's address.»
  - Manca Accessibility: «Per leggere lo schermo serve il permesso Accessibility.» / «Reading the screen needs the Accessibility permission.»
  - Manca l'Automazione: «Per leggere questa pagina serve il permesso di Automazione per Safari.» (o Chrome) / «Reading this page needs the Automation permission for Safari.» (or Chrome)
  - Manca l'Automazione per il Finder: «Per leggere la selezione del Finder serve il permesso di Automazione per il Finder.» / «Reading the Finder selection needs the Automation permission for Finder.»
  - Errore imprevisto: «Qualcosa è andato storto: il documento non è stato archiviato.» / «Something went wrong: the document wasn't archived.»
- La nuvoletta resta 5 secondi, o finché il puntatore ci resta sopra, ed è cliccabile.

## benvenuto
- Finestra centrata, a passi, con indicatore del passo corrente.
- Passo dei permessi: le stesse righe dei permessi della finestra dei permessi (vedi `permessi`), più una riga che mostra se OMP è stato trovato.
- Passo del modello: barra di avanzamento con dimensione scaricata e totale; in caso di errore il messaggio e il pulsante Riprova.

## permessi
- Finestra centrata, non ridimensionabile, titolo «Permessi di Axi» / «Axi permissions».
- Introduzione: «Ad Axi mancano alcuni permessi: senza, non può leggere lo schermo.» / «Axi is missing some permissions: without them it can't read the screen.»
- Righe dei permessi (le stesse nel benvenuto e nelle impostazioni): per Accessibility, Registrazione schermo e Automazione una riga con spiegazione in una frase, stato (concesso o no) e pulsante «Concedi» / «Allow», mostrato solo quando il permesso manca; lo stato si aggiorna da solo.
- La spiegazione della riga Accessibility dice che serve a leggere le finestre e a usare i tasti Spotlight e Dettatura.
- La riga Automazione mostra uno stato separato per il Finder, sempre, e per Safari e per Chrome, solo per quelli installati; per un browser chiuso lo stato è «Apri Safari per verificare.» (o Chrome) / «Open Safari to check.» (or Chrome), senza pulsante. Sotto, la nota: «Firefox non ne ha bisogno: gli basta Accessibility.» / «Firefox doesn't need it: Accessibility is enough.»
- Nella finestra dei permessi e nel benvenuto, dopo che l'utente ha chiesto Registrazione schermo, la sua riga mostra «Registrazione schermo vale dopo aver riaperto Axi.» / «Screen Recording takes effect after reopening Axi.» e il pulsante «Riapri Axi» / «Reopen Axi», finché Axi non viene riaperto.
- Pulsante «Fine» / «Done» in basso a destra, che chiude la finestra.
- Quando tutti i permessi risultano concessi, la finestra mostra «Tutto pronto.» / «All set.» con un segno di spunta e si chiude da sola dopo 2 secondi.

## impostazioni
- Finestra standard delle impostazioni di macOS con le sezioni: Generale, Modello AI, Scorciatoie, Azure Document Intelligence, OMP, Permessi.
- Generale: un interruttore «Apri Axi al login» / «Open Axi at login» che mostra lo stato reale dell'avvio al login.
- Modello AI: elenco dei modelli disponibili in OMP, con quello predefinito di OMP preselezionato.
- Scorciatoie: un campo registrabile per Archivia, Chat e Nascondi/Mostra il puntino, con ripristino dei valori predefiniti; il ripristino non tocca l'interruttore dei tasti.
- Scorciatoie: un interruttore «Usa i tasti Spotlight e Dettatura» / «Use the Spotlight and Dictation keys», attivo al primo avvio, con sotto una riga: «🔍 apre la chat, 🎤 archivia. Spotlight e la Dettatura da tastiera non partono.» / «🔍 opens the chat, 🎤 archives. Spotlight and keyboard Dictation won't start.»
- Scorciatoie: con l'interruttore attivo e senza permesso Accessibility, sotto l'interruttore compare «Per usare questi tasti serve il permesso Accessibility.» / «These keys need the Accessibility permission.» con il pulsante «Concedi» / «Allow», che chiede il permesso come le righe dei permessi; la nota sparisce da sola quando il permesso arriva.
- Azure Document Intelligence: endpoint e chiave, un pulsante Prova connessione e l'indicazione che, se configurato, viene usato per le pagine senza testo e per lo schermo.
- OMP: percorso, stato della connessione e motivo quando non è disponibile.
- Permessi: le righe dei permessi della finestra dei permessi, con il pulsante «Riapri Axi» dopo che l'utente ha chiesto Registrazione schermo.
