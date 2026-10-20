---
refs:
  - "connessione-omp"
  - "omp"
  - "requirements/tech#connessione-omp"
  - "requirements/quality#General"
---
# Connessione a OMP

Il collegamento di Axi con OMP in modalità RPC e gli strumenti host che OMP usa sul vault.

Quando il Task è fatto:
- all'avvio di Axi la connessione è in Avvio: Axi avvia `omp --mode rpc` dal percorso delle impostazioni o cercandolo sul Mac, negozia il protocollo v2 e, alla ricezione di ready, produce `omp.PRONTO` e va in Pronta; se OMP non si trova o non parte produce `omp.NON_AVVIABILE` e va in Non disponibile, con il motivo leggibile da impostazioni e benvenuto;
- da Pronta, `omp.TERMINATO` riporta in Avvio una volta; se OMP si ferma di nuovo entro 30 secondi dal riavvio la connessione va in Non disponibile;
- da Non disponibile, `utente.CAMBIA_PERCORSO_OMP` riporta in Avvio con il nuovo percorso;
- il client RPC (pacchetto `AxiOMP`) invia prompt, riceve la risposta in streaming, interrompe una risposta, imposta il modello scelto, elenca i modelli, gestisce sessioni persistenti per conversazione e risponde alle chiamate degli strumenti host `search_vault`, `read_document_page`, `set_document_tags` e `request_document_deletion`, delegandole a interfacce implementate dai Task del vault e della chat;
- un processo OMP serve l'archiviazione e uno la chat;
- le risposte di OMP diventano gli Events `omp.METADATI_GENERATI` / `omp.METADATI_FALLITI` per l'archiviazione, `omp.RISPOSTA_COMPLETATA` / `omp.RISPOSTA_FALLITA` per la chat, `omp.TAG_CAMBIATI` e `omp.ELIMINAZIONE_RICHIESTA` dalle chiamate degli strumenti;
- OMP non riceve strumenti di file system, shell o rete; i log non contengono testo dei documenti né delle conversazioni;
- il client è testato con un finto processo OMP che parla il protocollo.
