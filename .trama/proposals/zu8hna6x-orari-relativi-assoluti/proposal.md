---
status: approved
base:
  vault/archiviazione.md: 3943e867189fa7486bdc6e1451c444a74c4f829c6c77042c21dc3bf2ba4f1fa4
  actors/omp.md: 458aaf489fa4ea1a9760ef5b9277019ae230f5aadd81ceaa7368b80944ed36d2
  visione/lettura-schermo.md: 0dd0715217f4b30d57caab1ff4b6830ab6471679a64d5b6bf0f20ad11fc99f9b
  chat/mini-chat.md: 32503c48d6276b1e4afc53c43c87e2cafb9cf9ca4c3c4c4e3c2666e5d6cb0538
  companion/attivita.md: 54ffef29ed7682ed2d62c32e1efbd4c9a401c78da7d195edc4a91a83ad1b3e5a
  requirements/data/vault.md: 228f3ea0b1827130b54643d3eb031d2e4cd196cc11dfe100c166b62e14efe590
  requirements/rules/ai.md: e063076ac281ef74a72190525e4af1ef074e5b35e47560f9dc253be38b8f3e83
  requirements/tech/documenti.md: 1ccea2114f75d3e381f408e8ff41bf6974fa699f3aa1439eed32e436806e1b3f
  requirements/ui/companion.md: 2d24aef40fe8d733dd2058208bd87554ddc1180b256d33a3fc9a0e943e3cc4c1
delete: []
request: 2026-10-19T08-15-07
created: 2026-10-19T06:26:55.085Z
label: Date assolute
---
# Orari relativi assoluti

Quando Axi incontra orari relativi («2 ore fa», «domani alle 15:00») deve sempre provare a renderli assoluti: in archiviazione (data di ricezione delle email, date citate nei documenti) e in chat.

Decisioni:
- Ambito: archiviazione e chat.
- Data di ricezione di un'email di Outlook: la risolve OMP con una richiesta a parte durante l'acquisizione, rispetto al momento della lettura dello schermo; si conserva anche il testo mostrato da Outlook.
- Se non si riesce a risolverla (o OMP non risponde): l'email entra senza data di ricezione, l'archiviazione prosegue e la nuvoletta lo dice con una riga in più. Nessuna data inventata (oggi diventa l'ora di archiviazione).
- Date citate: nuovo metadato, elenco di eventi, scadenze e appuntamenti (in forma relativa o assoluta, esclusi i riferimenti storici), ciascuno con data e ora assolute, di cosa si tratta e le parole originali; massimo 20 per documento; anche il riassunto usa date assolute.
- Riferimento per le date relative del contenuto: per un'email la data di ricezione; per gli altri documenti la data del documento se il testo la dice, altrimenti il momento dell'archiviazione.
- Email con data di ricezione sconosciuta: le sue date relative non si risolvono ed entrano solo con le parole originali; le date assolute del testo entrano comunque.
- Espressioni ambigue: si registra l'interpretazione più probabile, con le parole originali accanto.
- Impronta di un'email: con la data di ricezione assoluta al giorno; senza la data quando questa è sconosciuta.
- Chat: OMP conosce data e ora correnti; il testo a schermo si risolve rispetto al momento della lettura; le date si scrivono assolute con la forma relativa tra parentesi («lunedì 20 ottobre alle 15:00 (domani)»).
- Ricerca della chat: filtri per data di archiviazione, data del documento o di ricezione, date citate; i risultati portano queste date.
- Fuso orario: quello del Mac al momento della lettura, conservato con l'offset; una data senza ora resta un giorno.
