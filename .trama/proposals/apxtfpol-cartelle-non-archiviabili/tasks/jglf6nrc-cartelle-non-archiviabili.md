---
technical: false
refs:
  - lettura-schermo/Ricerca del documento
  - requirements/tech#lettura-schermo
---
# Cartelle non archiviabili

Nella ricerca del documento una cartella non è mai un documento. Quando la finestra dell'app in primo piano indica come documento (`AXDocument` o `AXURL`) una cartella invece di un file, per esempio Terminal con la sua cartella di lavoro, oppure quando Safari, Chrome o Firefox mostrano un indirizzo `file://` che è una cartella del Mac, la ricerca finisce in `NESSUN_DOCUMENTO` con motivo «nessun documento», come per le cartelle del Finder; la nuvoletta spiega che a schermo non c'è un documento archiviabile. Nulla va in coda e l'archiviazione non parte, quindi l'esito non è più «Il documento non si può leggere».

Un file vero, aperto in un'app o mostrato dal browser con un indirizzo `file://`, continua a essere individuato come oggi. Il controllo usa `URLResourceValues.isDirectory` nella ricerca del documento (`DocumentFinder.find` in `Packages/AxiScreen`), riusando quello già usato per la selezione del Finder. I test di `DocumentFinder` coprono una cartella come `AXDocument` di un'app, una cartella come indirizzo `file://` di un browser e un file vero in entrambi i casi.
