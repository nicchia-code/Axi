---
description: Use when building the welcome, permissions or settings window.
---
# Benvenuto, permessi e impostazioni

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
