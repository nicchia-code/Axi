---
description: Use when building the menu bar dot, its menu, its animations and bubbles, the welcome, permissions or settings window.
---
# Puntino, benvenuto e impostazioni

## General
- Interfaccia in italiano e inglese: segue la lingua di macOS, inglese per ogni altra lingua.
- Stile di macOS 26: materiali Liquid Glass per menu, nuvolette e finestre.
- Le animazioni sono una parte centrale dell'esperienza: fluide, curate, mai a scatti. Con "Riduci movimento" attivo diventano dissolvenze semplici.
- Axi è un'app accessoria: nessuna icona nel Dock e nessuna voce nel selettore ⌘Tab; vive nella barra dei menu.

## puntino
- Elemento della barra dei menu con un puntino monocromo pieno, in stile icona di sistema: segue l'aspetto chiaro o scuro della barra e si evidenzia come le altre icone quando il suo menu è aperto.
- L'utente lo sposta nella barra con ⌘-trascina; il posto scelto si ritrova al prossimo avvio.
- Clic con la chat chiusa: si apre il menu. Clic con la chat aperta: la chat si chiude e il menu non si apre.
- Quando l'utente ci trascina sopra dei file, il puntino si evidenzia per mostrare che può riceverli.

## puntino/Menu aperto
- Menu nativo di macOS sotto il puntino, con icona ed etichetta per ogni azione: Archivia, Chat, Impostazioni…, Esci. Esc e il clic altrove lo chiudono.
- Ogni azione mostra la sua scorciatoia: Archivia ⌥A, Chat ⌥Spazio, o quelle registrate dall'utente.
- Quando i tasti Spotlight e Dettatura sono assegnati ad Axi e il permesso Accessibility è concesso, Archivia mostra al posto della scorciatoia il simbolo del microfono e Chat il simbolo della lente, come sui tasti.

## attivita
- A riposo il puntino è fermo.
- Durante un'archiviazione il puntino diventa tre puntini che balzano uno dopo l'altro; quando ci sono documenti in coda un piccolo numero compare alla destra dei puntini e l'elemento della barra si allarga per contenerlo.
- Successo: breve rimbalzo con un segno di spunta. Errore: breve scossa orizzontale e colore rosso di sistema. Documento già presente: un breve lampo senza scossa. Finito il segnale il puntino torna monocromo.
- La nuvoletta compare sotto il puntino, allineata a lui e interamente sullo schermo; se la chat è aperta compare in sovrimpressione in cima alla chat. Se la barra dei menu è nascosta (per esempio in un'app a schermo intero) compare comunque in alto sullo schermo attivo, sotto il punto del puntino, sopra l'app a schermo intero. Per un documento archiviato mostra titolo, tag e l'elenco degli allegati non presi con l'indicazione di trascinarli o aprirli; per un documento non archiviato mostra il motivo in una frase.
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
- Nella finestra dei permessi, dopo che l'utente ha chiesto Registrazione schermo, la sua riga mostra «Registrazione schermo vale dopo aver riaperto Axi.» / «Screen Recording takes effect after reopening Axi.» e il pulsante «Riapri Axi» / «Reopen Axi», finché Axi non viene riaperto.
- Pulsante «Fine» / «Done» in basso a destra, che chiude la finestra.
- Quando tutti i permessi risultano concessi, la finestra mostra «Tutto pronto.» / «All set.» con un segno di spunta e si chiude da sola dopo 2 secondi.

## impostazioni
- Finestra standard delle impostazioni di macOS con le sezioni: Generale, Modello AI, Scorciatoie, Azure Document Intelligence, OMP, Permessi.
- Generale: un interruttore «Apri Axi al login» / «Open Axi at login» che mostra lo stato reale dell'avvio al login.
- Modello AI: elenco dei modelli disponibili in OMP, con quello predefinito di OMP preselezionato.
- Scorciatoie: un campo registrabile per Archivia e Chat, con ripristino dei valori predefiniti; il ripristino non tocca l'interruttore dei tasti.
- Scorciatoie: un interruttore «Usa i tasti Spotlight e Dettatura» / «Use the Spotlight and Dictation keys», attivo al primo avvio, con sotto una riga: «🔍 apre la chat, 🎤 archivia. Spotlight e la Dettatura da tastiera non partono.» / «🔍 opens the chat, 🎤 archives. Spotlight and keyboard Dictation won't start.»
- Scorciatoie: con l'interruttore attivo e senza permesso Accessibility, sotto l'interruttore compare «Per usare questi tasti serve il permesso Accessibility.» / «These keys need the Accessibility permission.» con il pulsante «Concedi» / «Allow», che chiede il permesso come le righe dei permessi; la nota sparisce da sola quando il permesso arriva.
- Azure Document Intelligence: endpoint e chiave, un pulsante Prova connessione e l'indicazione che, se configurato, viene usato per le pagine senza testo e per lo schermo.
- OMP: percorso, stato della connessione e motivo quando non è disponibile.
- Permessi: le righe dei permessi della finestra dei permessi, con il pulsante «Riapri Axi» dopo che l'utente ha chiesto Registrazione schermo.
