---
refs:
  - attivita/In corso
  - requirements/ui#attivita
---
# Tre puntini nell'archiviazione

Quando il Task è finito, durante un'archiviazione (`attivita/In corso`) il puntino mostra l'attesa (si gonfia e si sgonfia, il contorno ondeggia) e passa ai tre puntini mentre il documento è in `archiviazione/Generazione dei metadati`, cioè mentre l'AI ne genera titolo, riassunto, tag e date; quando quel passo finisce il puntino torna all'attesa, o all'aspetto del momento se il lavoro è finito.

- I tre puntini hanno la precedenza sull'attesa; il segnale di un esito (`archiviazione.ARCHIVIATO`, `archiviazione.NON_ARCHIVIATO`) ha la precedenza sui tre puntini.
- Il piccolo numero dei documenti in coda resta alla destra del personaggio anche durante i tre puntini, e nella barra dei menu l'elemento si allarga per contenerlo come oggi.
- A riposo (`attivita/Nessuna`) il puntino è fermo, nell'aspetto fermo del disegno vettoriale.
- Successo, errore e documento già presente restano: rimbalzo con spunta, scossa con tinta rossa, lampo; finito il segnale il personaggio torna ai suoi colori.
