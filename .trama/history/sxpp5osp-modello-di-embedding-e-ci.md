---
created: 2026-10-18T19:26:54.318Z
updated: 2026-10-19T02:50:38.048Z
summary: CI con i test, verifica del modello di embedding su MLX e controllo d'integrità dei file scaricati.
tasks:
  - 0e14kvsx
  - 0h9vnn7a
  - 8sim97s0
  - b4fr869m
---
# Modello di embedding e CI

Implementati i Task 0e14kvsx (CI con i test: build e test su runner macOS, README), 0h9vnn7a (Verifica che il modello funzioni: TextEmbedder.verify e BenvenutoModel), 8sim97s0 (Integrità dei file del modello: dimensione e hash dalla lista del repository, SHA-1 dei blob Git per i file non LFS). Test: AxiEmbedding 6 test verdi, AxiCore 145 test verdi.
