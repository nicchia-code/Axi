---
status: approved
base:
  visione/lettura-schermo.md: bfbc82c73ad0ba993574a342729ff89a22f430578eb7134c4482119024cae06f
  companion/attivita.md: df4b9f5d3ff49abbf83a6498723c5bffdc0883111913942380756383bf68f455
  vault/archiviazione.md: 80d84338090754c4c0b73daa4b663421214682c6dc504ad6af9d5a3e21f1b885
  companion/benvenuto.md: b5e138fdfca7a61bdf8a688ece43def9e7e774279d5be6300fc697115dd55abc
  requirements/quality/affidabilita.md: new
  requirements/tech/documenti.md: fc8862a248ec0c8e01d0c28ee668d3e06d0d5c4ae40adba67216fbd7017af023
  requirements/tech/fondamenta.md: 40e39ad213d48efac1f00e88c891d18883d0d4b456754f847061f3fe4af44dc0
  requirements/rules/ai.md: 4088de96b7bd21d4c59bee7636422a0893b1df6cf707393dcf6c18f1f4061b17
  requirements/ui/companion.md: d5f86f390e51f2ab0589e0601ad8bbfe3b1ca11b38a5f65cd58a53d92d5d170e
  vault/coda-archiviazione.md: 271616f47d246bc32f91f6d134dafde1cecc9398bb22ecb940e3df746de5c385
delete: []
request: 2026-10-18T23-41-03
created: 2026-10-18T21:52:50.864Z
label: Pagine web senza crash
---
# Pagine web senza crash

Chiedendo di archiviare una pagina web Axi si chiude (crash report del 18 ottobre: la finestra nascosta che crea il PDF della pagina viene rilasciata due volte, con qualsiasi browser), e con Firefox spesso non succede nulla: il rifiuto «nessun documento» non arriva mai al puntino e l'indirizzo della pagina si legge in modo fragile.

Decisioni:
- Un errore imprevisto durante l'archiviazione non chiude Axi: il documento non viene archiviato, nel vault non resta nulla e la nuvoletta dice «errore imprevisto»; il crash della finestra nascosta si corregge.
- Una pagina web di cui non si legge l'indirizzo viene rifiutata con un motivo preciso.
- La nuvoletta di «nessun documento» distingue i motivi: nessun documento, indirizzo non leggibile, permesso mancante (nominato).
- Se Axi si chiude durante un'archiviazione, la coda si perde, come oggi.
- Browser supportati: Safari, Chrome e Firefox; l'Automazione serve solo a Safari e Chrome.
- Testi delle nuvolette: frasi brevi con l'indicazione di cosa fare.
- La regola dell'80% confronta il PDF con il solo testo della pagina, senza l'interfaccia del browser.
- Firefox: Axi attiva la sua Accessibility completa, legge prima l'area della pagina (indirizzo e testo), poi la barra degli indirizzi; limiti a profondità 40 e 5.000 elementi.
- PDF della pagina: un solo limite di 45 s per caricamento e PDF, 1 s di attesa dopo il caricamento, interruzione del processo della pagina come fallimento immediato (la pagina entra solo come testo).
- Rifiuti e fallimenti di lettura e archiviazione nel log di sistema (os.Logger), senza testo né indirizzi completi.
- Benvenuto: la riga Automazione mostra lo stato per Safari e Chrome, se installati, e dice che Firefox non ne ha bisogno.

Assunzione: un errore imprevisto durante la ricerca del documento non chiude Axi e diventa un rifiuto «errore imprevisto» della lettura, come per l'archiviazione.

## Already present
- `coda-archiviazione` — `Packages/AxiCore/Sources/AxiCore/Archive/ArchivingService.swift`: la coda (`ArchiveQueue`, riga 19) vive solo in memoria nell'actor `ArchivingService`, e lo staging non confermato non lascia nulla nel vault; ogni esito `.notArchived` fa partire il documento successivo (`finish(_:)`, righe 116-130).
