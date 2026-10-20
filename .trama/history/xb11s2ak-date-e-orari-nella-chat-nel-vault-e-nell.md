---
created: 2026-10-19T06:58:33.387Z
updated: 2026-10-19T17:29:57.654Z
summary: Date assolute nel vault con offset, data e ora della chat, momento della lettura schermo, coda con orari di lettura, ricerca nel vault con filtri per data.
tasks:
  - 1zz5k1wg
  - ae98geiv
  - kpc4824h
  - miy6juw6
  - ocxw4k7p
  - hnsdbgg4
---
# Date e orari nella chat, nel vault e nella coda

- kpc4824h: date assolute salvate con l'offset del Mac (instant) o come giorno senza ora (day), migrazione v3-absolute-dates.
- 1zz5k1wg: la chat riceve data e ora del Mac al momento della domanda e le passa a OMP.
- ae98geiv: ogni lettura dello schermo conserva il suo momento, con il fuso orario.
- miy6juw6: la coda conserva il momento di ogni lettura. Gap aperto: ArchivingService non passa il momento ad ArchivingPipeline.archive; è registrato come Drift fylcg2yw (D6).
- ocxw4k7p: la ricerca nel vault applica i filtri per data (ricerca per giorno, con fuso del Mac).
