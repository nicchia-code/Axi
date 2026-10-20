---
status: approved
base:
  chat/mini-chat.md: e66124f021722ac6045c18c5f34cd22f0c4f93b1c7e1297fb4b0145919f88ece
  requirements/rules/ai.md: a351ace4966440521f01f5d4765c149c00542e6141adc5aed84e4d995930ac50
  requirements/tech/documenti.md: 3a2907ac6536dccaf7b2599b3b4a921122b2f6655e838303aaa30a525cec013b
  requirements/tech/fondamenta.md: ea196d773b12a59f83aeafa5dd5d8f795076584b8d7c8ea234f452c234fa51cf
  requirements/ui/chat.md: 325b5142d2616aa3f8a36ba222169823bcc7eba8a6027c221c65e408dc6aa840
delete: []
request: 2026-10-19T18-34-58
created: 2026-10-19T16:39:24.365Z
label: Risposta doppia
---
# Risposta doppia in chat

La chat mostra spesso la risposta due volte, incollata a se stessa senza separatore (per esempio il link di una riunione Teams seguito subito da «Link della riunione…» e dalla risposta ripetuta), e la salva così. Causa: OMP scrive la risposta, chiama cite_documents come gli chiedono le istruzioni, e poi riscrive la risposta in un nuovo messaggio; Axi incolla il testo di tutti i messaggi di OMP nella stessa bolla.

Decisioni:
- Quando OMP scrive più messaggi nella stessa risposta, la risposta è solo l'ultimo messaggio che contiene testo; il testo intermedio sparisce.
- La bolla riparte dal nuovo messaggio al suo primo testo, non al suo inizio: niente bolla vuota durante gli strumenti, e un ultimo messaggio fatto solo di una chiamata a strumento non svuota la risposta.
- OMP dichiara i documenti citati prima di scrivere la risposta, che è la sua ultima azione.
- Le risposte già salvate con il testo doppio restano come sono.
- Gli unici errori segnalati sono il doppione e il link rovinato dal testo incollato.
- Correzione di fatto: l'elenco degli strumenti host in requirements/tech#connessione-omp include cite_documents, già presente nel codice.

## Already present
- `requirements/tech#connessione-omp` — `Packages/AxiOMP/Sources/AxiOMP/OMPHostTools.swift` (lo strumento host `cite_documents` è già offerto a OMP; il resto della sezione è invariato)
