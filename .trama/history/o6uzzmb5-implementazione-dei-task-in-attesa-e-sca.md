---
created: 2026-10-19T12:07:07.955Z
updated: 2026-10-19T12:07:07.955Z
summary: Chiusi 16 Task in Done (15 con codice, T6 per decisione); build dell'app e tutti i pacchetti passano; scan finale con sette Drift.
tasks:
  - 7h37jac3
  - cdgdz0pl
  - xg5s8onj
  - xfy80y60
  - 78uvcmuy
  - ka6e0p8b
  - ku0v3mjn
  - ot54yl20
  - 0zl20zkr
  - djtzpkmc
  - kfrtpzdx
  - 5vbr6qpl
  - czjivj7o
  - kcz7yekn
  - cx60n9cs
  - 3crdhl7i
---
# Implementazione dei Task in attesa e scan finale

Run di implementazione di tutti i Task in attesa: 16 Task chiusi in Done (15 con modifiche al codice, T6 per decisione dello sviluppatore). Chiusi senza modifiche (T2, T4, T24, T50) non citati.

## Task
- T19 Remove code of puntino/Nascosto: rimossi stato, flag e transizioni nascosto.
- T22 Remove code of puntino/Visibile: rimossi solo commenti residui.
- T12 Permessi chiesti nel benvenuto: il passo permessi usa le righe condivise di PermessiModel; rimossi PermissionRow, BrowserAutomationRow e la richiesta locale del benvenuto.
- T13 Finestra dei permessi: finestra con righe e modello; PermessiMachineTests 5/5.
- T18 Finder nei permessi e login: Controllo all'avvio con EventoPermessi; benvenuto incompleto va a Chiuse (scelta di implementazione, da confermare).
- T6 Shared permission rows missing: chiuso Done per decisione dello sviluppatore, coperto dal lavoro di T12.
- T39 Chat shortcut defaults to F4: ora ⌥Space. Nessun test aggiunto.
- T8 Shortcut stores app at release: Archivia e Chat memorizzano l'app alla pressione e agiscono al rilascio. Nessun test aggiunto.
- T46 Welcome stays after completion: rimossa la scritta "All set".
- T41 Dot click leaves chat open: verificato con PuntinoTests 6/6; nessun test di routing dell'app.
- T42 Archive shortcut leaves menu open: 14 test passano; target app non compilato in quel momento.
- T1 Unreadable latest conversation opens empty: 28/28 nel pacchetto temporaneo; AxiTests non collegato al target.
- T30 Idle flash between queued documents: 17 test passano.
- T32 Date citate nei metadati: 21 test passano.
- T35 Data di ricezione assoluta: 81 test passano.
- T47 Failed recognition reported as empty: 33 test passano.

## Verifica
- Build dell'app: passa dopo aver aggiunto LaunchAtLogin.swift al target Axi in Axi.xcodeproj (mancava, il build falliva).
- Pacchetti: AxiCore 188, AxiScreen 49, AxiOMP 50, AxiEmbedding 6, AxiVectors 1; tutti passano.
- Non verificato a runtime: welcome, finestra dei permessi, scorciatoie ⌥A e ⌥Space, T46, T41.

## Scan finale
Scan dei Machine cambiati (attivita, archiviazione, permessi, benvenuto, impostazioni, coda-archiviazione): nessun Task, sette Drift.
- Ricevuta su tutti i documenti non email (o6bhm2cd, iar3mpgv): duplicati tra archiviazione e attivita.
- Ricevuta fallita non registrata (mjcboxgk).
- Benvenuto: riapri Axi non nel Model (my92oper).
- Permessi: richiesta con finestra chiusa (try9r9us), riavvio con finestra chiusa (sfuczyyb), Allow solo per il Finder (3ulnuyom).

Puntino, companion e mini-chat esclusi dallo scan: Model in revisione (puntino.md non allineato alla Proposal cd9nbto9).
