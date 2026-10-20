---
status: rejected
base:
  companion/permessi.md: new
  companion/benvenuto.md: 7fb72f9a394a84a602b9549495c8c01b3c2f6d5e163e66c704a69d1c1fd0987c
  companion/impostazioni.md: 53613a75d4e83be75df5ce30f7bf23e9ca1627b6dfbe1e006b44b573d0954962
  companion/feature.md: ddd2eee6a097cf5c9dc36665a26b0086d34ecb7678a4a364d24cc9909143861d
  chat/mini-chat.md: 362f60041177a49926f7e8f5448bcebee1917a811f584427e584591859b8c1be
  visione/lettura-schermo.md: ae677869b93938ea9f63bf166925d03243ee98d3c33a505cae2a68841fc5fc64
  actors/utente.md: 93f9af8c745f1a99142e0f754eeebbe21fbea4a319fe8d2f8b47552a1c7005b2
  requirements/ui/companion.md: a6191456748df531f73b43fc196a23678dea84aefb043d47da4c4f87f686a6e2
  requirements/ui/chat.md: fd0496019d7c41765ca0254518c3a7c362cebdb2c8fa80fb900fe8bdd9b291ab
  requirements/tech/fondamenta.md: 742d6cc3bb8e608c184534a02f3d85d803a98ef8f0dbd2ac936c7f757ddac9ce
delete: []
request: 2026-10-19T00-11-33
created: 2026-10-18T22:24:25.319Z
label: Permessi a ogni avvio
---
# Permessi a ogni avvio

Axi controlla i permessi di macOS solo nel benvenuto: una volta completato, un permesso tolto (anche da una ricompilazione non firmata) fa smettere Axi di leggere lo schermo senza dirlo. Questa Proposal aggiunge un controllo a ogni avvio, un modo per chiedere davvero i permessi a macOS e una firma stabile delle build di sviluppo.

Decisioni dell'intervista:
- A ogni avvio, se il benvenuto è completato e manca un permesso, si apre una finestra dei permessi (solo permessi, senza scaricamento del modello e senza riga OMP).
- Contano Accessibility, Registrazione schermo e l'Automazione di Safari e Chrome installati; con il browser chiuso l'Automazione è sconosciuta e non conta come mancante.
- Firefox non ha bisogno dell'Automazione: la nota lo spiega in modo esplicito («gli basta Accessibility»).
- Il controllo avviene solo all'avvio; mentre Axi è aperto valgono i rifiuti già previsti.
- Il pulsante di ogni permesso fa la richiesta di sistema di macOS e, se macOS non la mostra più, apre il pannello giusto di Impostazioni di Sistema.
- Chiudere la finestra senza concedere tutto: Axi continua limitato e la finestra ricompare al prossimo avvio.
- Quando tutti i permessi risultano concessi la finestra dice «Tutto pronto» e si chiude da sola.
- Registrazione schermo appena concessa: la finestra e le Impostazioni offrono «Riapri Axi».
- Le Impostazioni hanno una sezione Permessi con le stesse righe.
- La chat, se non legge lo schermo per un permesso mancante, lo nomina e offre di aprire la finestra dei permessi.
- Testi della finestra e della chat come proposti nell'intervista.
- Build di sviluppo firmate Apple Development con il team indicato nel progetto Xcode; la CI resta senza firma.
- I crash registrati vengono dall'archiviazione delle pagine web, non dai permessi: restano fuori da questa Proposal.
- Tasti Spotlight e Dettatura (Proposal approvata nel frattempo): finché il tap esiste Axi rilegge Accessibility e, se manca, toglie il tap e restituisce i tasti a macOS, senza aprire finestre.

Assunzioni da verificare:
- Anche i pulsanti del passo Permessi del benvenuto chiedono a macOS come la nuova finestra, e le righe sono le stesse ovunque (comprese «Apri Safari per verificare» e la nuova nota su Firefox).
- «Riapri Axi» compare per Registrazione schermo dopo che l'utente l'ha chiesta da quella finestra o dalle Impostazioni, finché Axi non viene riaperto.
- Etichette non discusse: pulsante «Concedi» / «Allow», «Fine» / «Done», «Riapri Axi» / «Reopen Axi» con la frase «Registrazione schermo vale dopo aver riaperto Axi.». In chat, con entrambi i permessi mancanti, il testo li nomina tutti e due; il testo per la sola Accessibility mancante è tolto, perché in quel caso la chat legge lo schermo con il riconoscimento del testo e non fallisce.
- La nota delle Impostazioni sui tasti Spotlight e Dettatura senza Accessibility usa anch'essa il pulsante «Concedi», che chiede il permesso a macOS invece di aprire solo il pannello.

## Already present
- `impostazioni/Chiuse/utente.APRE_IMPOSTAZIONI` — `Axi/Impostazioni/ImpostazioniController.swift`, aperto dalla voce Impostazioni del menu del puntino
