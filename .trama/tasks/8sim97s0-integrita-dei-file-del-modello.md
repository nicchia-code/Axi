---
column: done
technical: false
refs:
  - benvenuto/Scaricamento del modello
  - requirements/tech#benvenuto
drift: null
proposal: null
agent: false
created: 2026-10-18T19:10:13.915Z
finished: 2026-10-18T19:19:11.856Z
---
# Integrità dei file del modello

Quando il Task è fatto: ogni file del modello scaricato viene verificato nella sua integrità, non solo nella dimensione. Oggi i file piccoli della configurazione e del tokenizer sono controllati solo per dimensione, mentre i pesi hanno la verifica SHA-256. Un file alterato o incompleto non viene accettato: lo scaricamento finisce in Scaricamento non riuscito con il motivo, e Riprova lo scarica di nuovo.
