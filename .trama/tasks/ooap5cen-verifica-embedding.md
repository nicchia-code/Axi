---
column: done
technical: true
refs:
  - requirements/tech#archiviazione/Indicizzazione
drift: null
proposal: ey10w2wy
agent: false
created: 2026-10-18T17:25:07.412Z
finished: 2026-10-18T17:40:09.975Z
---
# Verifica embedding su MLX

Verificare che EmbeddingGemma 2 (variante solo testo) giri correttamente con MLX Swift dentro l'app, e ottimizzarlo, prima di costruire l'indicizzazione.

Quando il Task è fatto:
- nel pacchetto `AxiEmbedding` c'è un componente che carica il modello dalla cartella dati di Axi e trasforma testi in vettori;
- un test confronta i vettori di alcune frasi in italiano e inglese con quelli di riferimento del modello (per esempio prodotti con sentence-transformers e salvati nelle fixture) e verifica che la similarità tra frasi affini superi quella tra frasi non correlate;
- sono misurati e annotati nel README del pacchetto: tempo per brano su Apple Silicon, memoria usata, dimensione dei vettori scelta (con troncamento Matryoshka se conviene) e quantizzazione scelta;
- se EmbeddingGemma 2 non gira bene su MLX Swift, il componente usa un altro modello di embedding supportato da MLX con buona qualità multilingue, e la scelta e il motivo sono annotati nel README del pacchetto e segnalati allo sviluppatore, perché le Specs vanno aggiornate.
