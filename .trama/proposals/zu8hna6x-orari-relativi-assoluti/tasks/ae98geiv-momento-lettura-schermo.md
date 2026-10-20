---
refs:
  - lettura-schermo
  - lettura-schermo.DOCUMENTO_INDIVIDUATO
  - lettura-schermo.CONTESTO_LETTO
  - lettura-schermo/Ricerca del documento/lettura-schermo.DOCUMENTO_INDIVIDUATO
  - lettura-schermo/Accessibilità/lettura-schermo.CONTESTO_LETTO
  - lettura-schermo/Riconoscimento del testo/lettura-schermo.CONTESTO_LETTO
  - requirements/tech#lettura-schermo
---

# Momento della lettura schermo

Quando la Task è fatta, ogni lettura di `lettura-schermo` annota il momento in cui è stata fatta, perché gli orari relativi a schermo («2 ore fa», «domani») si possano rendere assoluti. La lettura registra il proprio istante e il fuso del Mac (`TimeZone.current`) e li passa con il documento individuato e con il contesto per la chat.

- In Ricerca del documento, quando la ricerca trova un documento archiviabile, `DOCUMENTO_INDIVIDUATO` porta con sé, oltre a quale documento è e da dove viene, il momento della lettura. Per un'email di Outlook porta anche la data di ricezione così come è mostrata (il testo letto via Accessibility, senza interpretarlo); per una selezione del Finder porta tutti i file selezionati, nell'ordine della selezione, con lo stesso momento della lettura.
- In Lettura del contesto, `CONTESTO_LETTO` porta app, finestra, documento se c'è, testo visibile e momento della lettura, sia quando lo emette Accessibilità (Accessibility ha dato il testo visibile) sia quando lo emette Riconoscimento del testo (cattura con ScreenCaptureKit e riconoscimento con Vision o Azure Document Intelligence). `ScreenContext` deve quindi includere istante e fuso della lettura, valorizzati al momento della lettura e non all'invio della domanda.
- Il resto del comportamento della Machine resta come descritto nel Model e nei requisiti tecnici di `lettura-schermo` (app in primo piano memorizzata al momento della richiesta, Automazione solo per Safari, Chrome e Finder, log `os.Logger` subsystem `Axi` categoria `lettura-schermo`).
