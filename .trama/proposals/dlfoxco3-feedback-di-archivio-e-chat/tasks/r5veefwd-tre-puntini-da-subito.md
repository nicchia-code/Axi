---
refs:
  - puntino
  - requirements/ui#puntino
---
# Tre puntini da subito

Il personaggio, e la sua icona nella barra dei menu quando il puntino è nascosto, si trasforma nei tre puntini mentre la chat risponde e mentre Axi archivia, da quando l'utente chiede l'archiviazione o rilascia dei file fino all'ultimo esito (`attivita/In ricerca` e `attivita/In corso`), senza aspettare la generazione dei metadati o un altro passo dell'archiviazione.

- Durante un'archiviazione il personaggio non mostra più l'attesa (respiro): l'attesa resta solo mentre l'utente interagisce con il puntino (menu aperto, chat aperta, file trascinati sopra).
- Il segnale di un esito ha la precedenza sui tre puntini; finito il segnale, se l'archiviazione continua con altri documenti, il personaggio torna nei tre puntini, altrimenti all'aspetto del momento.
- Lo scaricamento del PDF di una pagina web mostra gli stessi tre puntini di ogni archiviazione.
- Trasformazione, ciclo e "Riduci movimento" restano come descritti in `requirements/ui#puntino`.
