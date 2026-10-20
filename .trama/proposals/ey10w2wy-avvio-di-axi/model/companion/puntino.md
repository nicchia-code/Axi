# Puntino

Il puntino animato che rappresenta Axi sullo schermo: dove si trova, se si vede, se ha il menu aperto o se si è espanso nella chat. Quello che il puntino sta facendo (archiviazioni in corso, esiti) è descritto da Attività.

## States

### Visibile (initial)
Il puntino sta sopra tutte le finestre, su ogni Spazio e anche sulle app a schermo intero, dove l'utente l'ha lasciato l'ultima volta.
- `utente.ALTERNA_PUNTINO` → Nascosto: anche il menu si chiude.

#### A riposo (initial)
L'utente può trascinare il puntino ovunque, anche su un altro schermo; la posizione viene ricordata. Rilasciare file sul puntino li manda in archiviazione.
- `utente.CLIC_PUNTINO` → Menu aperto
- `mini-chat.APERTA` → Espanso in chat: la chat è stata aperta con la scorciatoia.

#### Menu aperto
Attorno al puntino compaiono le azioni Archivia, Chat, Impostazioni, Nascondi ed Esci. Esci chiude Axi.
- `utente.CHIEDE_ARCHIVIAZIONE` → A riposo: l'archiviazione riguarda l'app che era in primo piano prima del clic sul puntino.
- `mini-chat.APERTA` → Espanso in chat
- `utente.APRE_IMPOSTAZIONI` → A riposo
- `utente.CHIUDE_MENU` → A riposo

#### Espanso in chat
Il puntino si è trasformato nella mini-chat, ancorata alla sua posizione.
- `mini-chat.CHIUSA` → A riposo: la chat torna puntino nella stessa posizione.

### Nascosto
Il puntino non si vede, ma le scorciatoie continuano a funzionare.
- `utente.ALTERNA_PUNTINO` → Visibile: riappare dove era.
- `mini-chat.APERTA` → Espanso in chat: aprire la chat con la scorciatoia fa riapparire il puntino espanso.
