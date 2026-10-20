---
status: approved
base:
  companion/attivita.md: d582a46f35466dabd96639013a8a1ea1a355d3af98cafda36b53ffb7ade14d1d
  companion/puntino.md: d28a69dd385031a4ab1c848af814d94f69b6ef539c7cac09e6b3075904638ad1
  actors/tempo.md: b5fee1ed3e227e00859925a90e1bd7779bca6d7725a8d588448b34fc44558950
  actors/utente.md: f6679726bd7e6733c23b9146758e1cdeb6080d2772ee386071a679353084074e
  visione/lettura-schermo.md: 0fb113cae31040c254b886bb1f7bcbb12236cf4dfbf22b786703b4fb55569607
  vault/archiviazione.md: f38a2a010eecfd9ef5e6cb0a5b241f54a6db7ec156acafc64edfc1e142eadccc
  vault/coda-archiviazione.md: 44fd74d1089e6f9770bda7e19d6a3d3b1359e32f117f543ed3ae73bb824a6506
  chat/mini-chat.md: b4ee64ec55e84f2ff6a162b57fdd4f40939e48067028a81a2fe03fe4b8c98a11
  actors/omp.md: 9557a3dc580aaa7662a5df02c57c6f007c31f2670ce3fd7bcca5626ac10440d5
  requirements/ui/companion.md: df3568879e6fe77019dadd0c2ef6261d76474ed67619a7d6564e62377943f7b0
  requirements/ui/attivita.md: new
  requirements/ui/chat.md: 870d27682ba288b407959ee4833145bd8f6ae07a15e295a4d679162ba8dd2dd4
  requirements/tech/documenti.md: 2dbb3ca4a01405fc4b22b255f34f5d9723cca5533c1937f9ac61ff7b2295fa44
  requirements/data/vault.md: 4168f20c1262d2f88fe184af56ed58344f19cd0fa0bd357e4e67c4c5c4f76106
delete: []
request: 2026-10-20T08-33-58
created: 2026-10-20T07:25:38.923Z
label: Feedback archivio e chat
---
# Feedback di archivio e chat

Richiesta scritta: i feedback all'utente sono pessimi. Archiviando, Axi deve dire subito che sta lavorando e su cosa, e dire alla fine che il documento è archiviato; in chat deve far vedere cosa sta facendo OMP mentre risponde.

Decisioni:
- Archivio: la nuvoletta «Sto archiviando…» compare subito alla richiesta, senza nome; il nome si aggiunge appena il documento è individuato (un file rilasciato lo ha già). Un rifiuto della ricerca la sostituisce.
- X è il nome d'origine: nome del file, oggetto dell'email, titolo della pagina web; se mancano, il dominio o «email senza oggetto». Per le pagine web Axi legge ora anche il titolo.
- Tre puntini da subito sia nel personaggio (o nell'icona della barra), dalla richiesta all'ultimo esito, sia animati nella nuvoletta dopo il testo.
- La nuvoletta di avvio resta fino all'esito, senza scadenza; un clic la nasconde e il lavoro continua.
- Con più documenti la nuvoletta segue ogni documento: «Sto archiviando “X”», poi il suo esito per i suoi secondi, poi «Sto archiviando “Y”». Il clic nasconde solo la nuvoletta del documento in corso; per il successivo torna.
- Esito archiviato: «Ho archiviato “X”» con lo stesso X dell'avvio, poi titolo AI, tag, allegati non presi e riga sulla data come oggi.
- Anche gli esiti negativi nominano X: «“X” è già nel vault.», «Non ho archiviato “X”» con il motivo; i rifiuti della ricerca a schermo restano senza nome.
- Esiti: 5 s o finché il puntatore è sopra, come oggi.
- Con la chat aperta anche la nuvoletta di avvio compare in sovrimpressione in cima alla chat.
- Chat: la sintesi mostra i passi scritti da Axi a partire dagli strumenti usati da OMP, i nuovi tentativi e il riassunto della conversazione, e sotto l'ultima frase del ragionamento del modello, dal vivo, senza traduzione.
- Chat: Axi imposta il ragionamento `low` per la sessione della chat quando il modello lo offre.
- Chat: appena inviata la domanda, tre puntini animati nella bolla; la sintesi sta in cima alla bolla, sopra il testo.
- Chat: a risposta finita la sintesi si richiude in una riga riapribile; non si salva nelle conversazioni.

Scelte mie, da verificare:
- I testi esatti in italiano e inglese delle nuvolette, dei passi e della riga richiusa (in `requirements/ui#attivita` e `requirements/ui#mini-chat/In risposta`).
- Il nome del file si mostra con l'estensione; un nome troppo lungo si accorcia nel mezzo con «…».
- Se l'utente chiude la nuvoletta durante la ricerca a schermo, non ricompare quando il documento viene individuato.
- In una serie, dopo una nuvoletta di passaggio (esito, rifiuto o avviso) torna la nuvoletta di avvio del documento in lavorazione, anche se l'utente aveva chiuso la precedente.
- Durante un'archiviazione il personaggio non mostra più il respiro dell'attesa: solo i tre puntini.
- Il titolo di una pagina web viene da `AXTitle` dell'area della pagina, altrimenti dal titolo della finestra.
- Durante la risposta tutti i passi restano elencati; l'ultima frase del ragionamento è quella in corso di scrittura; il ragionamento oscurato dal provider non si mostra.
- La sezione `attivita` dei Requirement `ui` passa in un nuovo fragment `attivita`, perché `companion` avrebbe superato i 12 KB.
