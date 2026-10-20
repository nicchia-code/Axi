---
column: done
technical: false
refs:
  - attivita/Nessuna/lettura-schermo.NESSUN_DOCUMENTO
  - attivita/In corso/lettura-schermo.NESSUN_DOCUMENTO
  - attivita/Esito/lettura-schermo.NESSUN_DOCUMENTO
  - requirements/ui#attivita
drift: nwxhjdoj
proposal: null
agent: false
created: 2026-10-19T06:07:34.199Z
finished: 2026-10-19T08:33:52.834Z
---
# Fix code to match the Model: Rejection wording differs

## What happens

When a search finds no document, the bubble shows a headline and an explanation that are not the sentences the Requirement gives. No document reads «No document to archive» with «Save the document as a file first, then try again.»; an unreadable address reads «The page address cannot be read» with «Axi cannot read the address of this web page.»; a missing Accessibility permission reads «Accessibility permission is missing» with a longer explanation; an unexpected error reads «Something went wrong» with «The search stopped unexpectedly. Try again.». The Italian texts are translations of these English texts, not the Requirement's sentences.

## What should happen

For each reason the bubble shows the Italian or English sentence that the Requirement gives for it, in the language of the system: no document to archive, the page address cannot be read, the Accessibility or Automation permission that is missing, or something went wrong and the document was not archived.

## Chosen option

**Show only the Requirement sentence**

Show the Requirement's sentence as the only text of each reason, in Italian or English as the system language, and drop the separate headline and explanation. The Italian and English versions of each sentence replace the current texts in the string catalogue. Costs: the bubble loses its bold headline, so each reason reads as one plain sentence, as the Requirement asks.

## Where in the code

Axi/Puntino/NuvolettaVista.swift, extension NoDocumentReason (titolo and testo); Axi/Localizable.xcstrings, the Italian values of these strings
