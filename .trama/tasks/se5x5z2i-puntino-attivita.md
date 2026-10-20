---
column: done
technical: false
refs:
  - companion
  - puntino
  - attivita
  - tempo
  - requirements/ui#puntino
  - requirements/ui#puntino/Menu aperto
  - requirements/ui#attivita
  - requirements/data#puntino
drift: null
proposal: ey10w2wy
agent: false
created: 2026-10-18T17:25:07.412Z
finished: 2026-10-18T18:19:22.822Z
---
# Puntino e attività

Il puntino animato di Axi, il suo menu e ciò che comunica con animazioni e nuvolette.

Quando il Task è fatto:
- all'avvio il puntino è Visibile e A riposo, sopra tutte le finestre, su ogni Spazio e sulle app a schermo intero, nella posizione salvata, senza rubare il fuoco all'app in primo piano; si trascina ovunque, anche tra schermi, e la posizione si salva;
- da A riposo, `utente.CLIC_PUNTINO` porta a Menu aperto con le azioni a raggiera Archivia, Chat, Impostazioni…, Nascondi, Esci, ognuna con la sua scorciatoia; `utente.CHIEDE_ARCHIVIAZIONE`, `utente.APRE_IMPOSTAZIONI` e `utente.CHIUDE_MENU` riportano ad A riposo; Esci chiude Axi; l'archiviazione chiesta dal menu riguarda l'app che era in primo piano prima del clic;
- `mini-chat.APERTA` porta il puntino in Espanso in chat da A riposo, da Menu aperto e da Nascosto; `mini-chat.CHIUSA` lo riporta ad A riposo nella stessa posizione;
- `utente.ALTERNA_PUNTINO` passa da Visibile a Nascosto (chiudendo anche il menu) e viceversa, con animazione; mentre è nascosto le scorciatoie funzionano;
- rilasciare file sul puntino produce `utente.RILASCIA_FILE`, con il puntino che mostra di poterli ricevere durante il trascinamento;
- Attività parte da Nessuna (respiro lento); `coda-archiviazione.PROSSIMO_DOCUMENTO` porta a In corso con l'animazione di lavoro e il numero di documenti in coda;
- in In corso, `archiviazione.ARCHIVIATO` e `archiviazione.NON_ARCHIVIATO` mostrano una nuvoletta con l'esito e restano In corso se in coda ci sono altri documenti, altrimenti portano a Esito;
- `lettura-schermo.NESSUN_DOCUMENTO` e `mini-chat.NON_DISPONIBILE` mostrano la nuvoletta con la spiegazione: da Nessuna ed Esito portano a Esito, da In corso restano In corso;
- in Esito il puntino anima successo, errore o documento già presente; la nuvoletta mostra titolo e tag, gli allegati non presi, o il motivo; `tempo.NUVOLETTA_SCADUTA` (5 secondi, sospeso finché il puntatore è sopra la nuvoletta) e `utente.CLIC_NUVOLETTA` riportano a Nessuna, e il clic apre la copia del vault di un documento archiviato o già presente; `coda-archiviazione.PROSSIMO_DOCUMENTO` riporta a In corso;
- anche con il puntino nascosto la nuvoletta compare nella sua posizione;
- tutte le animazioni sono fluide e rispettano "Riduci movimento".
