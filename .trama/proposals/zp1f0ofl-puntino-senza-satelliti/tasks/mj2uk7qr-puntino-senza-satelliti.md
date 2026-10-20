---
technical: false
refs:
  - puntino
  - requirements/ui#puntino
  - requirements/tech#puntino
---
# Puntino senza satelliti

Quando il Task è finito valgono queste condizioni.

- Il personaggio non ha più satelliti in nessun aspetto e in nessuna dimensione: né sullo schermo, né nell'icona della barra dei menu, né durante la trasformazione in tre puntini e il ritorno al personaggio. Resta la pallina blu con ombra, riflesso e due occhi azzurri.
- Il disegno di riferimento `Design/puntino.svg` non contiene più i satelliti; la posa ferma e la posa dei tre puntini hanno corpo, ombra, riflesso e occhi come forme separate e con nome (`id`), e il disegno in codice ridisegna le stesse forme.
- Mentre la chat è in `mini-chat/In risposta` il personaggio si trasforma nei tre puntini di sospensione, come già fa mentre un documento è in `archiviazione/Generazione dei metadati`: in circa 0,4 s il corpo si separa in tre gocce sfumate come il corpo e gli occhi spariscono; le gocce si alzano e si gonfiano una dopo l'altra, a onda, in un ciclo di circa 2,2 s (a metà velocità con "Riduci movimento"); quando la risposta è completata, fallita, interrotta, OMP si ferma o la chat si chiude, in circa 0,4 s le gocce si riuniscono nel personaggio. Vale sia col puntino visibile (chat aperta accanto al personaggio) sia col puntino nascosto (chat sotto l'icona della barra, che mostra gli stessi aspetti).
- I tre puntini hanno la precedenza sull'attesa della chat aperta; il segnale di un esito ha la precedenza su entrambi e, finito, il puntino torna all'aspetto del momento.
- Le altre richieste all'AI (per esempio la data di ricezione di un'email durante l'acquisizione) continuano a mostrare l'attesa, non i tre puntini.
- I test del disegno verificano l'assenza dei satelliti in ogni aspetto, al posto della loro presenza a riposo e del loro riassorbimento.
