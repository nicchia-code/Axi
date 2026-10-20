---
column: done
technical: false
refs:
  - lettura-schermo/Inattiva/utente.CHIEDE_ARCHIVIAZIONE
  - lettura-schermo/Ricerca del documento
  - requirements/tech#lettura-schermo
drift: null
proposal: dbk7lcfl
agent: false
created: 2026-10-18T21:57:37.720Z
finished: 2026-10-19T03:09:14.918Z
---
# Pagine web anche da Firefox

Quando l'utente chiede un'archiviazione, la lettura passa a «Ricerca del documento» per l'app che era in primo piano prima che Axi prendesse il fuoco; una richiesta che arriva durante un'altra lettura viene servita appena quella finisce.

Nella ricerca Axi trova come documento archiviabile il file aperto (Anteprima, Word, Pages, Acrobat…), l'email di Outlook aperta o selezionata con i suoi allegati, e la pagina web aperta in Safari, Chrome **o Firefox** con il suo indirizzo. Per una pagina web Axi cerca prima l'area della pagina (`AXWebArea`) a qualunque profondità e ne legge l'indirizzo (`AXURL`, poi `AXDocument`) e il testo; solo se lì manca l'indirizzo lo legge dalla barra degli indirizzi (oggi `BrowserAddress.pageURL` in `DocumentFinder.swift`). Il percorso dell'albero si ferma a profondità 40 e 5.000 elementi (oggi 25 e 3.000 in `LiveAdapters.swift`). Il testo della pagina usato poi per la regola dell'80% è quello dell'area della pagina, senza l'interfaccia del browser (oggi `VisibleTextReader.swift` raccoglie tutta la finestra).

Per Firefox, prima della lettura Axi imposta `AXEnhancedUserInterface` sull'elemento dell'app e al termine della lettura, anche quando fallisce, ripristina il valore precedente. L'Automazione (Apple Events) si usa solo per Safari e Chrome e solo quando Accessibility non basta; per Firefox mai (`BrowserTabAutomation` in `LiveAdapters.swift`). Il comportamento si verifica su un Firefox reale: con una pagina aperta in Firefox la ricerca emette `DOCUMENTO_INDIVIDUATO` con l'indirizzo della pagina.

Rispetta `requirements/tech#lettura-schermo`.
