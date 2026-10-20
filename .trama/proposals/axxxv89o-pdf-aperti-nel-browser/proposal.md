---
status: approved
base:
  visione/lettura-schermo.md: e99e6005c3b96eab0edca11a2db4701f7bae0683bba13957fd433be805f48e45
  vault/archiviazione.md: fdc2f8e6e6e0e5a5a49d85a1425d9149b2da8629223670cc98c685ea2f6f4254
  requirements/tech/documenti.md: 799689b1f5ab1e0295e574b72c72c1e076df27c463de0af826018ff9845dfc4f
  requirements/rules/ai.md: a39bc8687c5ba64f4265ecb7c0439047bbf180c3e5a61b8e8447d30a51d9385f
  requirements/data/vault.md: 9b9dc8e22b8fb29432fcb5534a6657d1df7437ba206bc16989b13ec3de646c0a
  requirements/ui/companion.md: 13a93f5641d0b3693e04399f41267fc79bdd54ed7ace9d66d9ec37807e0c3c1c
  requirements/quality/affidabilita.md: c2ffaa8ae03807509f485572b26469f1029c4db33ca355faad81f941554443b3
delete: []
request: 2026-10-19T18-36-41
created: 2026-10-19T16:44:42.076Z
label: PDF nel browser
---
# PDF aperti nel browser

Un PDF aperto in Safari, Chrome o Firefox oggi viene trattato come una pagina web: il visualizzatore PDF del browser non espone testo ad Accessibility, il testo a schermo è vuoto e l'acquisizione fallisce con «Il documento non si può leggere» prima ancora di riaprire l'indirizzo; anche con testo, Axi conserverebbe una stampa del visualizzatore invece del file originale.

Decisioni prese con lo sviluppatore:
- Il PDF si riconosce dal contenuto dell'indirizzo (firma %PDF), non solo dall'estensione .pdf.
- Lo scaricamento è una richiesta a parte con URLSession (sessione effimera, senza cookie del browser), prima del caricamento come pagina web; se non è un PDF si interrompe e si procede come pagina web.
- Il PDF scaricato entra come documento PDF: copia originale, testo come ogni PDF, impronta dei byte, origine browser e indirizzo.
- Nessun confronto con il testo letto a schermo.
- Se lo scaricamento non riesce non si archivia nulla: esito dedicato che suggerisce di scaricarlo e trascinarlo sul puntino; un esito a parte per il PDF troppo grande.
- Un indirizzo che finisce in .pdf ma non restituisce un PDF (per esempio una pagina di login) è uno scaricamento non riuscito.
- Limiti: 15 secondi per i primi byte (per un indirizzo senza .pdf, poi si procede come pagina web), 120 secondi per lo scaricamento intero, massimo 200 MB.
- Nome originale: quello indicato dal server, altrimenti l'ultima parte dell'indirizzo.
- Durante lo scaricamento il puntino mostra la solita attesa.
- Un file locale aperto nel browser (indirizzo file://), di qualunque formato, si archivia come un file aperto in un'altra app.

Assunzioni da verificare:
- 200 MB si intendono come 200.000.000 byte.
- Se il server non suggerisce un nome e l'indirizzo non ha un ultimo pezzo di percorso, il nome originale è il dominio con l'estensione .pdf.
- I 120 secondi contano dall'inizio della richiesta; per un indirizzo .pdf non vale il limite di 15 secondi per i primi byte.

## Already present
- `lettura-schermo/Inattiva/utente.CHIEDE_ARCHIVIAZIONE` — Packages/AxiScreen/Sources/AxiScreen/ScreenReader.swift:196-197 (`.archiving` → `searchDocument`)
- `coda-archiviazione/Con documenti in attesa/archiviazione.NON_ARCHIVIATO` — Packages/AxiCore/Sources/AxiCore/Archive/ArchiveQueue.swift:50-52 e ArchivingService.swift:134-140 (la coda prosegue con qualunque motivo)
