---
technical: false
refs:
  - benvenuto/Permessi
  - requirements/tech#benvenuto
  - requirements/ui#benvenuto
---
# Automazione solo Safari e Chrome

Nel passo dei permessi del Benvenuto l'Automazione riguarda solo Safari (`com.apple.Safari`) e Chrome (`com.google.Chrome`): Brave ed Edge non compaiono più nell'elenco dei browser (`Permissions.swift`).

Lo stato di Automazione si legge con `AEDeterminePermissionToAutomateTarget` per ciascuno dei due browser, ma solo se è installato (non solo se è in esecuzione, come oggi fa `automationPermitted`); un browser non installato non viene interrogato né mostrato. Nessun altro modo di leggere i permessi, come chiede `requirements/tech#benvenuto`.

La riga Automazione (`BenvenutoView.swift`, `BenvenutoModel.swift`) mostra uno stato separato (concesso o no) per Safari e per Chrome, solo per quelli installati, e la nota «Firefox non ne ha bisogno.» / «Firefox doesn't need it.»; la riga mantiene spiegazione in una frase, pulsante verso il pannello giusto di Impostazioni di Sistema e aggiornamento automatico dello stato, come chiede `requirements/ui#benvenuto`.
