---
status: resolved
resolution: fix-code
refs:
  - requirements/tech#lettura-schermo
  - lettura-schermo/Ricerca del documento
proposal: null
task: c65bcede
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:00:58.282Z
---
# Automation asked before address bar

## What happens

In Safari e Chrome, quando l'area della pagina non espone l'indirizzo, Axi chiede l'indirizzo al browser tramite l'Automazione anche se la barra degli indirizzi lo mostra già. La barra degli indirizzi viene letta solo quando l'Automazione non dà un indirizzo.

## What should happen

Axi legge l'indirizzo prima dall'area della pagina, poi dalla barra degli indirizzi, e usa l'Automazione solo quando Accessibility non basta, così non interroga il browser quando non serve.

## Fix options

### Leggere la barra prima dell'Automazione

Nella lettura della finestra, prima di chiedere l'indirizzo al browser, cercare il campo dell'indirizzo con le stesse regole della ricerca del documento, e chiamare l'Automazione solo se il campo manca o è vuoto. Il cambiamento tocca un solo punto. Le regole del campo vanno spostate in un punto condiviso, perché oggi stanno nella ricerca del documento. Safari e Chrome restano coperti dall'Automazione come prima.

### Spostare l'Automazione nella ricerca

Lasciare la lettura della finestra senza Automazione e chiederla alla ricerca del documento solo quando dalla pagina e dalla barra degli indirizzi non esce un indirizzo. La ricerca diventa asincrona e riceve l'Automazione come parametro. La parte che oggi non ha effetti collaterali ne acquista uno, e i suoi test vanno adattati al nuovo ordine.

## Where in the code

Packages/AxiScreen/Sources/AxiScreen/LiveAdapters.swift:24-28, in LiveAccessibilityReader.snapshot(of:), chiama BrowserTabAutomation prima della barra degli indirizzi; Packages/AxiScreen/Sources/AxiScreen/DocumentFinder.swift:80-86, dove BrowserAddress legge la barra degli indirizzi solo dopo
