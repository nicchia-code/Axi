# Puntino

Il personaggio animato che rappresenta Axi: dove si trova, se si vede, se ha il menu aperto o se la chat è aperta da lui. Quando è visibile sta sopra le finestre, dove l'utente l'ha lasciato; quando l'utente lo nasconde, Axi resta come icona nella barra dei menu di macOS. All'avvio il puntino torna com'era all'uscita: visibile dove stava, oppure nascosto nella barra dei menu. Mentre l'AI pensa, cioè mentre la chat sta rispondendo o mentre Axi genera i metadati di un documento, il personaggio si trasforma in tre puntini di sospensione e, finito, torna sé stesso. Quello che il puntino sta facendo (archiviazioni in corso, esiti) è descritto da Attività.

## States

### Visibile (initial)
Il personaggio sta sopra tutte le finestre, su ogni Spazio e anche sulle app a schermo intero, dove l'utente l'ha lasciato l'ultima volta. Nella barra dei menu Axi non c'è.

#### A riposo (initial)
L'utente può trascinare il personaggio ovunque, anche su un altro schermo; la posizione viene ricordata. Rilasciare file sul personaggio li manda in archiviazione.
- `utente.CLIC_PUNTINO` → Menu aperto
- `mini-chat.APERTA` → Chat aperta: la chat è stata aperta con la scorciatoia o con il tasto Spotlight.
- `utente.ALTERNA_PUNTINO` → Nascosto: il personaggio svanisce e Axi compare nella barra dei menu.

#### Menu aperto
Attorno al personaggio compaiono le azioni Archivia, Chat, Impostazioni, Nascondi ed Esci. Aprire il menu non porta Axi in primo piano. Esci chiude Axi.
- `utente.CHIEDE_ARCHIVIAZIONE` → A riposo: l'archiviazione riguarda l'app che era in primo piano quando il menu si è aperto.
- `mini-chat.APERTA` → Chat aperta
- `utente.APRE_IMPOSTAZIONI` → A riposo
- `utente.CHIUDE_MENU` → A riposo
- `utente.ALTERNA_PUNTINO` → Nascosto: il menu si chiude, il personaggio svanisce e Axi compare nella barra dei menu.

#### Chat aperta
La mini-chat è aperta accanto al personaggio, dal lato con più spazio. Un clic sul personaggio chiude la chat invece di aprire il menu.
- `mini-chat.CHIUSA` → A riposo: la chat si richiude nel personaggio.
- `utente.ALTERNA_PUNTINO` → Chat sotto la barra: il personaggio svanisce, Axi compare nella barra dei menu e la chat, ancora aperta con la sua conversazione, si sposta sotto l'icona della barra.

### Nascosto
Il personaggio non si vede: Axi è un'icona nella barra dei menu, nel posto scelto dall'utente. Le scorciatoie e i tasti continuano a funzionare.

#### Nella barra (initial)
Rilasciare file sull'icona li manda in archiviazione.
- `utente.CLIC_PUNTINO` → Menu della barra
- `mini-chat.APERTA` → Chat sotto la barra: la chat è stata aperta con la scorciatoia o con il tasto Spotlight.
- `utente.ALTERNA_PUNTINO` → Visibile: il personaggio riappare dove era e l'icona lascia la barra dei menu.

#### Menu della barra
Sotto l'icona si apre il menu con le azioni Mostra, Archivia, Chat, Impostazioni ed Esci. Aprire il menu non porta Axi in primo piano. Esci chiude Axi.
- `utente.ALTERNA_PUNTINO` → Visibile: l'utente ha scelto Mostra; il personaggio riappare dove era e l'icona lascia la barra dei menu.
- `utente.CHIEDE_ARCHIVIAZIONE` → Nella barra: l'archiviazione riguarda l'app che era in primo piano quando il menu si è aperto.
- `mini-chat.APERTA` → Chat sotto la barra
- `utente.APRE_IMPOSTAZIONI` → Nella barra
- `utente.CHIUDE_MENU` → Nella barra

#### Chat sotto la barra
La mini-chat è scesa dall'icona della barra e resta ancorata sotto di lei. Un clic sull'icona chiude la chat invece di aprire il menu.
- `mini-chat.CHIUSA` → Nella barra: la chat risale nell'icona.
- `utente.ALTERNA_PUNTINO` → Chat aperta: il personaggio riappare dove era, l'icona lascia la barra dei menu e la chat, ancora aperta con la sua conversazione, si sposta accanto al personaggio.
