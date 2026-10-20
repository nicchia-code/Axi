---
column: done
technical: false
refs:
  - attivita
  - tempo.NUVOLETTA_SCADUTA
  - utente.CLIC_NUVOLETTA
  - requirements/ui#attivita
drift: null
proposal: dlfoxco3
agent: false
created: 2026-10-20T07:37:30.232Z
finished: 2026-10-20T07:45:26.586Z
---
# Nuvolette di archiviazione

Attività racconta ogni archiviazione dalla richiesta all'esito, come dice la Machine `attivita`.

- Da Nessuna o da Esito, `utente.CHIEDE_ARCHIVIAZIONE` porta in In ricerca: subito il personaggio è nei tre puntini e compare la nuvoletta «Sto archiviando» / «Archiving» con tre puntini animati, senza nome; dall'Esito la nuvoletta dell'esito lascia il posto a questa.
- In In ricerca: `coda-archiviazione.PROSSIMO_DOCUMENTO` porta in In corso/Avvio e la nuvoletta aggiunge il nome d'origine («Sto archiviando “X”» / «Archiving “X”») senza chiudersi e riaprirsi; se l'utente l'aveva chiusa durante la ricerca porta in In corso/Senza nuvoletta. Il clic chiude la nuvoletta e il personaggio resta nei tre puntini. `lettura-schermo.NESSUN_DOCUMENTO` porta in Esito con il motivo del rifiuto, oppure resta in In ricerca con una nuvoletta del rifiuto se un'altra richiesta aspetta ancora la sua ricerca. `mini-chat.NON_DISPONIBILE` sostituisce la nuvoletta con l'avviso che la chat ha bisogno di OMP.
- Da Nessuna o da Esito, un file rilasciato o un documento individuato (`coda-archiviazione.PROSSIMO_DOCUMENTO`) porta in In corso/Avvio con il nome d'origine già presente.
- In corso/Avvio: la nuvoletta resta finché non la sostituisce un esito, un rifiuto o un avviso, oppure finché l'utente non ci fa clic (→ Senza nuvoletta); non scade e non ha timer.
- In corso: con altri documenti in coda, `archiviazione.ARCHIVIATO` e `archiviazione.NON_ARCHIVIATO` portano in Nuvoletta di passaggio con l'esito del documento concluso; con la coda vuota portano in Esito. Rifiuti (`lettura-schermo.NESSUN_DOCUMENTO`) e avvisi (`mini-chat.NON_DISPONIBILE`) durante il lavoro portano in Nuvoletta di passaggio.
- Nuvoletta di passaggio: `tempo.NUVOLETTA_SCADUTA` (5 s, sospesi mentre il puntatore è sopra) o `utente.CLIC_NUVOLETTA` riportano in Avvio con «Sto archiviando “Y”» del documento in lavorazione; il clic su un esito archiviato o già presente apre anche la copia del vault.
- Esito: come oggi, più `utente.CHIEDE_ARCHIVIAZIONE` → In ricerca.
- Testi degli esiti con il nome d'origine: «Ho archiviato “X”» / «Archived “X”» seguito da titolo, tag, allegati non presi e riga sulla data; «“X” è già nel vault.» / «“X” is already in the vault.»; «Non ho archiviato “X”» / «Didn't archive “X”» seguito dal motivo. I rifiuti della ricerca a schermo restano senza nome. Nome tra virgolette tipografiche, accorciato nel mezzo con «…» se non sta in una riga.
- Con la chat aperta tutte le nuvolette, compresa quella di avvio, compaiono in sovrimpressione in cima alla chat.
- I tre puntini animati della nuvoletta di avvio, posizione, vetro e coda della nuvoletta e tutti i testi sono quelli di `requirements/ui#attivita`.
