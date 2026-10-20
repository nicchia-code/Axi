---
column: done
technical: false
refs:
  - benvenuto
  - requirements/ui#benvenuto
  - requirements/tech#benvenuto
  - requirements/data#benvenuto
drift: null
proposal: ey10w2wy
agent: false
created: 2026-10-18T17:25:07.412Z
finished: 2026-10-18T17:32:20.850Z
---
# Benvenuto

La finestra di benvenuto che guida i permessi e scarica il modello per la ricerca.

Quando il Task è fatto:
- al primo avvio, e a ogni avvio finché non è completato, compare il benvenuto in Permessi; chiudere la finestra lo rimanda al prossimo avvio;
- Permessi mostra per Accessibility, Registrazione schermo e Automazione dei browser una spiegazione, lo stato aggiornato da solo e un pulsante per il pannello giusto di Impostazioni di Sistema, più lo stato di OMP; `utente.PROSEGUE` porta a Scaricamento del modello anche se mancano permessi;
- Scaricamento del modello scarica il modello di embedding nella cartella dati di Axi con avanzamento, ripresa e verifica dell'integrità; `MODELLO_SCARICATO` porta a Completato, `SCARICAMENTO_FALLITO` a Scaricamento non riuscito;
- in Scaricamento non riuscito il messaggio spiega l'errore e `utente.RIPROVA_DOWNLOAD` riprende lo scaricamento;
- Completato è salvato e il benvenuto non compare più;
- finché il benvenuto non è completato l'archiviazione rifiuta i documenti (vedi il Task dell'archiviazione).
