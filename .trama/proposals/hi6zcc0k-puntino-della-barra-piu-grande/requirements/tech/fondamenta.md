---
description: Use for project setup, build, signing, CI, repository, menu bar item, launch at login, OMP connection, shortcuts, settings storage, macOS permissions.
---
# Fondamenta e OMP

## General
- Swift 6 con strict concurrency, SwiftUI per le viste e AppKit dove serve (pannello del puntino, elemento della barra dei menu, pannelli fluttuanti, eventi globali, Accessibility).
- Deployment target macOS 26; solo Apple Silicon, perché gli embedding girano con MLX.
- Progetto Xcode `Axi.xcodeproj` con l'app e pacchetti Swift locali per i moduli: `AxiCore` (vault, ricerca, regole), `AxiScreen` (Accessibility, cattura e riconoscimento del testo), `AxiOMP` (client RPC di OMP e strumenti host), `AxiEmbedding` (modello di embedding su MLX). La logica sta nei pacchetti, testabile senza interfaccia.
- App Sandbox disattivata (serve per Accessibility su altre app e per avviare OMP); Hardened Runtime attivo, così la firma Developer ID e la notarizzazione future non richiedono modifiche al progetto.
- Le build di sviluppo sono firmate con firma automatica e un certificato Apple Development del team indicato nel progetto Xcode (`DEVELOPMENT_TEAM`), così macOS riconosce Axi tra una build e l'altra e i permessi concessi restano validi. La CI compila e testa senza firma. Il README spiega che per compilare con firma serve un Apple ID del team in Xcode.
- `AxiEmbedding` usa il prodotto `MLXHuggingFace` di `mlx-swift-lm`, che porta la macro di terze parti `MLXHuggingFaceMacros`. Ogni build da riga di comando, dello sviluppatore, degli agenti e della CI, passa `-skipMacroValidation` a `xcodebuild`; senza il flag la build fallisce in `ComputeTargetDependencyGraph`. In Xcode la macro si approva una volta con Trust & Enable. Il README spiega entrambe le cose nella sezione sulla build locale.
- `LSUIElement` attivo: app accessoria senza Dock.
- Testi dell'interfaccia in un String Catalog con italiano e inglese.
- Codice, commenti, messaggi di commit, README e documentazione del progetto in inglese.
- Test con Swift Testing nei pacchetti: unitari e di integrazione su vault, estrazione, duplicati e ricerca, con documenti d'esempio in una cartella di fixture del repository (PDF con testo, PDF scansionato, DOCX, email, pagina HTML). I test non richiedono OMP, rete o permessi: OMP e Azure sono sostituiti da implementazioni di prova dietro protocolli.
- Repository pubblico su GitHub con licenza AGPL-3.0; il README dice che l'uso è libero e che le aziende interessate a una licenza commerciale devono contattare l'autore.
- GitHub Actions: a ogni push e pull request, build e test su runner macOS con Xcode che supporta macOS 26.

## puntino
- Disegno del personaggio: il file `Design/puntino.svg` nel repository, fuori dal bundle dell'app, è il disegno di riferimento; contiene la posa ferma e la posa dei tre puntini, ciascuna in variante chiara e scura con l'accento blu predefinito di macOS come colori d'esempio, e la posa ferma monocroma della barra dei menu (la sagoma del corpo in un solo colore con gli occhi ritagliati, senza ombra né riflesso), fatte solo di `<circle>` ed `<ellipse>` (la mezzaluna d'ombra è un'ellisse ritagliata da un'altra), senza `<path>` liberi né filtri di sfocatura, con corpo, ombra, riflesso e occhi come forme separate e con nome (`id`), e nessun satellite. L'app ridisegna le stesse forme in codice con SwiftUI (`Canvas`, `Path(ellipseIn:)`, `Circle`, `Ellipse`) e le anima; un cambiamento del disegno tocca il file e il codice insieme.
- Animazioni guidate dal tempo con `TimelineView(.animation)`, continue e senza fotogrammi: il respiro, la trasformazione in tre puntini e l'onda si ottengono interpolando centri e raggi di cerchi ed ellissi, mai deformando un contorno libero. Con "Riduci movimento" le durate raddoppiano.
- Colori del personaggio sullo schermo: nessun colore fisso né asset di colore; il corpo è `Color.accentColor` (cioè `NSColor.controlAccentColor`) risolto nell'aspetto effettivo della vista che lo disegna, e ombra, riflesso e occhi sono tinte dello stesso accento ottenute mescolandolo con nero o bianco (`NSColor.blended(withFraction:of:)` o equivalente). Nessun aspetto forzato: il pannello del personaggio prende l'aspetto del sistema. Sullo schermo il disegno non è template; i segnali degli esiti (tinta rossa, lampo nella tinta chiara dell'accento, velo d'accento del trascinamento) riempiono le stesse forme vettoriali dell'aspetto del momento.
- Icona della barra dei menu: il pulsante dell'elemento mostra un'`NSImage` template (`isTemplate = true`) alta circa 22,5 pt (il 25% in più delle icone di sistema di circa 18 pt), ridisegnata a ogni fotogramma dalle stesse forme vettoriali e con la stessa temporizzazione delle animazioni sullo schermo, in un solo colore opaco su fondo trasparente: occhi, numero del contatore e segno della spunta sono ritagliati e restano trasparenti; lampo e velo del trascinamento sono variazioni di opacità. Colore, evidenziazione con il menu aperto e attenuazione sugli schermi inattivi li dà macOS; nel pulsante non c'è una vista nei colori del tema.
- Nell'icona della barra le ampiezze di rimbalzo e scossa, la misura del contatore (cerchio, numero e distanza dal personaggio) e la larghezza dell'elemento derivano da un'unica misura dell'immagine, mai da valori fissi in punti ripetuti altrove; la larghezza dell'elemento contiene l'immagine intera, con e senza contatore.
- `puntino.png` e `puntino-attesa.gif` escono dal target `Axi`, dal progetto Xcode e dal repository, insieme al codice che li decodifica con ImageIO.
- Puntino visibile: `NSPanel` senza bordi e non attivante (`nonactivatingPanel`), che non diventa mai key, a livello sopra le finestre normali, con `canJoinAllSpaces` e `fullScreenAuxiliary`; si trascina con `performDrag`; dopo ogni spostamento si salvano posizione e schermo.
- Il menu a raggiera è un pannello fluttuante centrato sul personaggio, entro l'area visibile dello schermo, con monitor di clic ed Esc per chiuderlo; all'apertura si memorizza l'app in primo piano, prima di qualsiasi azione.
- Puntino nascosto: `NSStatusItem` creato quando il puntino si nasconde e rimosso quando riappare, sempre con lo stesso `autosaveName`, così macOS ricorda il posto scelto dall'utente con ⌘-trascina. Il menu è un `NSMenu` nativo; all'apertura del menu (`menuWillOpen`) si memorizza l'app in primo piano, prima di qualsiasi azione. Il pulsante dell'elemento mostra l'immagine template descritta sopra, con le animazioni del personaggio.
- Il personaggio e il pulsante dell'elemento della barra accettano il rilascio di file (URL di file).
- Chat e nuvolette sono pannelli che non attivano Axi e restano visibili su ogni Spazio e sopra le app a schermo intero. Col puntino visibile si posizionano rispetto al riquadro del personaggio, dal lato con più spazio; col puntino nascosto sotto il riquadro del pulsante sullo schermo dove si trova, e con la barra nascosta nello stesso punto in alto sullo schermo attivo.

## connessione-omp
- Axi avvia `omp --mode rpc` come processo figlio e parla con lui in JSON per riga su stdin/stdout, negoziando il protocollo v2; stderr va nei log, mai nel parser.
- Il percorso di OMP è quello delle impostazioni; se manca, Axi lo cerca nel `PATH` della shell di login dell'utente e in `~/.bun/bin` e `/opt/homebrew/bin`.
- Un processo OMP per l'archiviazione e uno per la chat, così una risposta in chat non blocca un'archiviazione.
- OMP riceve solo gli strumenti host di Axi (`search_vault`, `read_document_page`, `set_document_tags`, `request_document_deletion`, `cite_documents`), nessuno strumento di file system, shell o rete.
- Il modello scelto nelle impostazioni si applica a ogni sessione; l'elenco dei modelli viene da OMP.
- Ogni conversazione della chat ha la sua sessione OMP persistente, conservata nella cartella dati di Axi; riaprire una conversazione riprende la sua sessione.
- Dopo un'uscita inattesa Axi riavvia OMP una volta; una seconda uscita entro 30 secondi dal riavvio rende la connessione non disponibile.

## impostazioni
- Preferenze in `UserDefaults`; la chiave di Azure Document Intelligence nel Keychain, mai in chiaro su disco.
- Scorciatoie globali registrabili con la libreria KeyboardShortcuts. Valori predefiniti: Archivia ⌥A, Chat ⌥Spazio, Nascondi/Mostra il puntino ⌥H.
- Tasti Spotlight (lente, sopra F4) e Dettatura (microfono, sopra F5) delle tastiere Apple: non arrivano come F4 e F5 e KeyboardShortcuts non li gestisce, quindi si intercettano con un `CGEventTap` di sessione attivo (non in solo ascolto), che consuma l'evento di quei due tasti così che macOS non apra Spotlight né avvii la Dettatura. Il segnale esatto che mandano (codice del tasto o evento di sistema) si verifica su una tastiera Apple reale.
- Il tasto Spotlight produce `utente.APRE_CHAT` se la chat è chiusa e `utente.CHIUDE_CHAT` se è aperta; il tasto Dettatura produce `utente.CHIEDE_ARCHIVIAZIONE`. Un'azione per pressione, al rilascio, ignorando la ripetizione del tasto tenuto premuto; come per le scorciatoie, l'app in primo piano si memorizza al momento della pressione.
- Il tap esiste solo con l'interruttore attivo e il permesso Accessibility concesso (`AXIsProcessTrusted`): spegnere l'interruttore lo rimuove e restituisce i tasti a macOS; quando il permesso arriva il tap si crea senza riavviare Axi; se macOS disattiva il tap (timeout o input dell'utente) Axi lo riattiva.
- Finché il tap esiste, Axi rilegge `AXIsProcessTrusted` ogni secondo; appena Accessibility manca rimuove il tap e restituisce i tasti a macOS, così togliere il permesso con Axi aperto non blocca l'input del sistema. Quando il permesso torna, il tap si ricrea come sopra. Nessuna finestra si apre per questo.
- Avvio al login con `SMAppService.mainApp`: si registra una sola volta, al completamento del benvenuto; se poi l'utente lo spegne (nelle impostazioni o in Impostazioni di Sistema) Axi non lo riaccende. L'interruttore delle impostazioni legge e scrive lo stato di `SMAppService`.

## benvenuto
- Il modello di embedding si scarica da Hugging Face nella cartella dati di Axi, con ripresa dello scaricamento interrotto e verifica dell'integrità dei file.
- Lo stato dei permessi si legge e si chiede come per la finestra dei permessi (vedi `permessi`).

## permessi
- Il controllo all'avvio avviene dopo l'avvio del puntino, solo se il benvenuto è completato, e non blocca l'avvio del resto di Axi.
- Lo stato si legge con `AXIsProcessTrusted`, `CGPreflightScreenCaptureAccess` e, per il Finder (`com.apple.finder`), sempre, e per Safari (`com.apple.Safari`) e Chrome (`com.google.Chrome`), ciascuno solo se installato, `AEDeterminePermissionToAutomateTarget` senza chiedere all'utente: `noErr` è concessa, `errAEEventNotPermitted` è negata, `errAEEventWouldRequireUserConsent` è non ancora chiesta, `procNotFound` (browser chiuso) è sconosciuta. Nessun altro browser. L'Automazione del Finder si legge allo stesso modo e si mostra nelle righe, ma non conta per il controllo all'avvio.
- Chiedere un permesso: Accessibility con `AXIsProcessTrustedWithOptions` e `kAXTrustedCheckOptionPrompt`; Registrazione schermo con `CGRequestScreenCaptureAccess`; Automazione con `AEDeterminePermissionToAutomateTarget` con richiesta all'utente, fuori dal main thread perché aspetta la risposta. Se macOS non mostra la sua richiesta (il permesso era già stato negato), si apre il pannello giusto di Impostazioni di Sistema (`x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`, `Privacy_ScreenCapture`, `Privacy_Automation`). Il comportamento si verifica su un macOS 26 reale, anche dopo una ricompilazione.
- Con la finestra dei permessi o le impostazioni aperte, lo stato si rilegge ogni secondo; a finestra chiusa non si rilegge, salvo Accessibility finché esiste il tap dei tasti Spotlight e Dettatura (vedi `impostazioni`).
- Riaprire Axi avvia una nuova istanza dal bundle dell'app con `NSWorkspace` e poi chiude quella corrente.
