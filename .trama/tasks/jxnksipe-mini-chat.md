---
column: done
technical: false
refs:
  - chat
  - mini-chat
  - requirements/ui#mini-chat
  - requirements/ui#mini-chat/Conferma dell'eliminazione
  - requirements/ui#mini-chat/Elenco delle conversazioni
  - requirements/tech#mini-chat
  - requirements/rules#mini-chat
  - requirements/data#mini-chat
drift: null
proposal: ey10w2wy
agent: false
created: 2026-10-18T17:25:07.412Z
finished: 2026-10-18T18:01:31.129Z
---
# Mini-chat

La piccola chat in cui si espande il puntino, con ricerca nel vault, citazioni e conversazioni salvate.

Quando il Task è fatto:
- da Chiusa, `utente.APRE_CHAT` con OMP pronto porta ad Aperta/In preparazione ed emette `APERTA`; con OMP non pronto resta Chiusa ed emette `NON_DISPONIBILE`;
- in In preparazione, `lettura-schermo.CONTESTO_LETTO` porta a Pronta con il contesto dello schermo visibile come etichetta rimovibile; `lettura-schermo.LETTURA_FALLITA` porta a Pronta con l'avviso che lo schermo non è stato letto;
- la chat apre l'ultima conversazione, o una vuota se non ce ne sono;
- in Pronta: `utente.INVIA_DOMANDA` porta a In risposta; `utente.RIMUOVE_CONTESTO` toglie il contesto; `utente.NUOVA_CONVERSAZIONE` inizia una conversazione vuota; `utente.APRE_ELENCO_CONVERSAZIONI` porta a Elenco delle conversazioni; `utente.APRE_DOCUMENTO_CITATO` apre la copia del vault nell'app predefinita, alla pagina citata quando possibile;
- in In risposta OMP usa gli strumenti `search_vault` (ricerca ibrida per parole e significato, con filtri) e `read_document_page`; la risposta arriva in streaming, cita documenti e pagine, e domanda e risposta entrano nella conversazione salvata; il contesto dello schermo accompagna la domanda finché non viene tolto;
- da In risposta: `omp.RISPOSTA_COMPLETATA` porta a Pronta; `omp.RISPOSTA_FALLITA` e `omp.TERMINATO` portano a Pronta con l'errore e la possibilità di riprovare; `utente.INTERROMPE_RISPOSTA` ferma la risposta lasciando il testo già scritto; `omp.ELIMINAZIONE_RICHIESTA` porta a Conferma dell'eliminazione; `utente.APRE_DOCUMENTO_CITATO` apre il documento senza interrompere;
- in Conferma dell'eliminazione la scheda mostra il documento e gli allegati che spariranno; `utente.CONFERMA_ELIMINAZIONE` e `utente.ANNULLA_ELIMINAZIONE` tornano a In risposta, e OMP riceve l'esito dello strumento `request_document_deletion`;
- in Elenco delle conversazioni: `utente.RIAPRE_CONVERSAZIONE` riporta a Pronta con la conversazione scelta e la sua sessione OMP; `utente.ELIMINA_CONVERSAZIONE` la elimina; `utente.CHIUDE_ELENCO_CONVERSAZIONI` torna a Pronta;
- da Aperta, `utente.CHIUDE_CHAT` e `utente.ALTERNA_PUNTINO` portano a Chiusa, interrompendo una risposta in corso, ed emettono `CHIUSA`;
- i documenti si passano interi all'AI entro il 50% del contesto del modello, altrimenti per brani, e la ricerca restituisce al massimo 20 brani;
- ricerca ibrida, strumenti e salvataggio delle conversazioni sono coperti da test.
