---
description: Use when building the dot character (on screen or in the menu bar), its radial menu, its animations, its queue count or its bubbles.
---
# Puntino

## General
- Interfaccia in italiano e inglese: segue la lingua di macOS, inglese per ogni altra lingua.
- Stile di macOS 26: materiali Liquid Glass per menu, nuvolette e finestre.
- Le animazioni sono una parte centrale dell'esperienza: fluide, curate, mai a scatti. Con "Riduci movimento" attivo diventano dissolvenze semplici.
- Axi è un'app accessoria: nessuna icona nel Dock e nessuna voce nel selettore ⌘Tab; vive nel puntino sullo schermo e, quando il puntino è nascosto, nella barra dei menu.

## puntino
- Il puntino è il personaggio di Axi disegnato in vettoriale, fatto solo di cerchi ed ellissi a bordi netti e colori piatti, senza sfocature né contorni irregolari, nello stesso linguaggio visivo della chat: un corpo ellittico un poco schiacciato, una mezzaluna d'ombra in basso a sinistra, un riflesso ellittico in alto a destra e due occhi ellittici, senza satelliti né altre forme attorno.
- Colori dal tema di macOS: il corpo è nel colore accento scelto dall'utente in Impostazioni di Sistema, come le bolle dell'utente in chat; l'ombra è una tinta più scura dell'accento, il riflesso una tinta più chiara, gli occhi una tinta molto chiara. Con accento grafite il puntino è grigio; con accento multicolore è blu, come lo fa macOS.
- Segue l'aspetto chiaro o scuro: i toni derivano dalla variante dell'accento che macOS usa per l'aspetto corrente, in scuro un poco più luminosi. Un cambio di accento o di aspetto mentre Axi è aperto vale subito, senza riavviare.
- Il disegno è nitido a ogni dimensione; nella barra dei menu è lo stesso disegno rimpicciolito.
- Ha tre aspetti: fermo, attesa e tre puntini. In ogni fotogramma di ogni aspetto e di ogni passaggio le forme restano cerchi ed ellissi perfetti.
  - Fermo, l'aspetto predefinito: il personaggio non si muove.
  - Attesa: il corpo respira, cioè l'ellisse si gonfia e si sgonfia restando un'ellisse, con ombra, riflesso e occhi che la seguono; il movimento è continuo, senza scatti, in un ciclo di circa 2,2 s.
  - Tre puntini di sospensione, mentre l'AI pensa (la chat è in `mini-chat/In risposta` o un documento è in `archiviazione/Generazione dei metadati`): in circa 0,4 s il corpo si restringe nel cerchio centrale mentre due cerchi uguali scivolano fuori a sinistra e a destra, e gli occhi spariscono. I tre puntini sono cerchi pieni nel colore accento, senza ombra né riflesso, come l'indicatore di scrittura delle chat. Si alzano e si gonfiano un poco uno dopo l'altro, a onda, in un ciclo di circa 2,2 s. Quando l'AI ha finito, in circa 0,4 s i due cerchi laterali rientrano in quello centrale, che torna il corpo con ombra, riflesso e occhi. I tre puntini restano dentro il riquadro del personaggio. Le altre richieste all'AI (per esempio la data di ricezione di un'email) non mostrano i tre puntini.
- A riposo si vede l'aspetto fermo. L'attesa si vede mentre l'utente interagisce con il puntino (menu aperto, chat aperta, file trascinati sopra), mentre Axi cerca a schermo il documento da archiviare e durante un'archiviazione (vedi `attivita`). I tre puntini hanno la precedenza sull'attesa; il segnale di un esito ha la precedenza su entrambi e, finito, il puntino torna all'aspetto del momento.
- Con "Riduci movimento" attivo attesa, trasformazione e tre puntini restano gli stessi a metà velocità (ciclo di circa 4,4 s, trasformazione di circa 0,8 s) invece di diventare dissolvenze.
- Clic con la chat chiusa: si apre il menu. Clic con la chat aperta: la chat si chiude e il menu non si apre.
- Quando l'utente ci trascina sopra dei file, il puntino si ingrandisce un poco e si vela del colore accento per mostrare che può riceverli.

## puntino/Visibile
- Personaggio alto circa 32 pt, sopra tutte le finestre, su ogni Spazio e sulle app a schermo intero, senza rubare il fuoco all'app in primo piano.
- Si trascina ovunque, anche tra schermi; la posizione si ritrova al prossimo avvio. Senza una posizione salvata, o se lo schermo dove era non c'è più, compare in basso a destra sullo schermo principale.
- Nascondere e mostrare il personaggio avviene sul posto con un'animazione di dissolvenza e scala.

## puntino/Menu aperto
- Le azioni compaiono a raggiera attorno al personaggio, ognuna come un cerchio di vetro con l'icona, con etichetta e scorciatoia sotto: Archivia, Chat, Impostazioni…, Nascondi, Esci, distribuite in modo uniforme. Esc e il clic altrove lo chiudono.
- Al passaggio del puntatore il cerchio di vetro di un'azione si tinge di un velo del colore accento, leggero come le bolle dell'utente in chat, e la sua icona prende il colore accento; uscito il puntatore torna com'era.
- Ogni azione mostra la sua scorciatoia: Archivia ⌥A, Chat ⌥Spazio, Nascondi ⌥H, o quelle registrate dall'utente.
- Quando i tasti Spotlight e Dettatura sono assegnati ad Axi e il permesso Accessibility è concesso, Archivia mostra al posto della scorciatoia il simbolo del microfono e Chat il simbolo della lente, come sui tasti.

## puntino/Nascosto
- Elemento della barra dei menu con il personaggio nei colori del tema, alto come le altre icone della barra (circa 18 pt); i suoi toni seguono l'aspetto chiaro o scuro della barra dei menu, che può differire da quello del sistema. Si evidenzia come le altre icone quando il suo menu è aperto.
- C'è solo mentre il puntino è nascosto. L'utente lo sposta nella barra con ⌘-trascina; il posto scelto si ritrova la volta successiva.
- Mostra gli stessi aspetti e le stesse animazioni del personaggio sullo schermo, tranne l'attesa, che nella barra è più marcata perché si noti a 18 pt: il corpo si gonfia di circa il 10% della sua altezza (quasi 2 pt), restando dentro il riquadro dell'icona. Ciclo e rallentamento con "Riduci movimento" sono quelli dello schermo; i tre puntini sono uguali allo schermo.

## puntino/Menu della barra
- Menu nativo di macOS sotto l'icona, con icona ed etichetta per ogni azione: Mostra, un separatore, poi Archivia, Chat, Impostazioni…, Esci. Esc e il clic altrove lo chiudono.
- Ogni azione mostra la sua scorciatoia come nel menu a raggiera: Mostra ⌥H, Archivia ⌥A, Chat ⌥Spazio, o quelle registrate dall'utente, con i simboli del microfono e della lente quando i tasti Spotlight e Dettatura sono assegnati ad Axi e il permesso Accessibility è concesso.

## attivita
- A riposo il puntino è fermo: si vede l'aspetto fermo.
- Dal momento in cui l'utente chiede l'archiviazione (Archivia nei menu, la scorciatoia o il tasto Dettatura) il puntino mostra l'attesa, anche mentre Axi cerca il documento a schermo o aspetta che finisca un'altra lettura dello schermo.
- Durante un'archiviazione il puntino mostra l'attesa, e i tre puntini mentre l'AI genera i metadati del documento (vedi `puntino`); quando ci sono documenti in coda il loro numero compare alla destra del personaggio, in bianco dentro un piccolo cerchio nel colore accento (una capsula da due cifre in su), e nella barra dei menu l'elemento si allarga per contenerlo.
- Nuvoletta di avvio, quando il puntino comincia ad archiviare (non per i documenti che seguono nella stessa serie): «Archivio “nome”…» / «Archiving “name”…», dove il nome è quello dell'origine come lo vede l'utente: il nome del file, l'oggetto dell'email o il titolo della pagina web. Non anima il personaggio con un segnale di esito. Un esito che arriva prima che sparisca la sostituisce; il clic la chiude.
- Successo: breve rimbalzo del personaggio con una piccola spunta verde di sistema. Errore: breve scossa orizzontale con il personaggio tinto del rosso di sistema. Documento già presente: un breve lampo del personaggio in una tinta chiara del colore accento, senza scossa. Finito il segnale il personaggio torna ai colori del tema.
- Con il puntino visibile la nuvoletta compare accanto al personaggio, dal lato con più spazio, interamente sullo schermo. Con il puntino nascosto compare sotto l'icona della barra, allineata a lei e interamente sullo schermo; se la barra dei menu è nascosta (per esempio in un'app a schermo intero) compare comunque in alto sullo schermo attivo, sotto il punto dell'icona, sopra l'app a schermo intero. Se la chat è aperta compare in sovrimpressione in cima alla chat. Per un documento archiviato mostra titolo, tag e l'elenco degli allegati non presi con l'indicazione di trascinarli o aprirli; per un documento non archiviato mostra il motivo in una frase.
- La nuvoletta è di vetro, con angoli arrotondati di circa 12 pt come le bolle della chat. Accanto al personaggio o sotto l'icona della barra ha una coda di due cerchietti di vetro, il più piccolo vicino al personaggio o all'icona, come la nuvoletta di un fumetto; in sovrimpressione sulla chat non ha coda.
- Per un'email archiviata senza data di ricezione la nuvoletta aggiunge, sotto titolo e tag, la riga «Non ho capito quando è arrivata: l'ho archiviata senza data di ricezione.» / «I couldn't tell when it arrived: archived without a received date.»
- Testi dei rifiuti e dell'errore imprevisto (italiano / inglese):
  - Nessun documento: «Qui non vedo un documento da archiviare: salvalo prima come file.» / «I don't see a document to archive here: save it as a file first.»
  - Indirizzo non leggibile: «Non riesco a leggere l'indirizzo di questa pagina.» / «I can't read this page's address.»
  - Manca Accessibility: «Per leggere lo schermo serve il permesso Accessibility.» / «Reading the screen needs the Accessibility permission.»
  - Manca l'Automazione: «Per leggere questa pagina serve il permesso di Automazione per Safari.» (o Chrome) / «Reading this page needs the Automation permission for Safari.» (or Chrome)
  - Manca l'Automazione per il Finder: «Per leggere la selezione del Finder serve il permesso di Automazione per il Finder.» / «Reading the Finder selection needs the Automation permission for Finder.»
  - Errore imprevisto: «Qualcosa è andato storto: il documento non è stato archiviato.» / «Something went wrong: the document wasn't archived.»
- Testi di un PDF di pagina web non archiviato (italiano / inglese):
  - Non scaricato: «Non sono riuscito a scaricare questo PDF: scaricalo tu e trascinalo sul puntino.» / «I couldn't download this PDF: download it and drop it on the dot.»
  - Troppo grande: «Questo PDF supera i 200 MB: scaricalo tu e trascinalo sul puntino.» / «This PDF is over 200 MB: download it and drop it on the dot.»
- Testo di un documento non archiviato perché l'AI non ha risposto in tempo (italiano / inglese): «L'AI non ha risposto in tempo: riprova tra poco.» / «The AI didn't answer in time: try again shortly.»
- Lo scaricamento del PDF di una pagina web non cambia l'aspetto del puntino: mostra la stessa attesa di ogni archiviazione.
- La nuvoletta resta 5 secondi, o finché il puntatore ci resta sopra, ed è cliccabile.
