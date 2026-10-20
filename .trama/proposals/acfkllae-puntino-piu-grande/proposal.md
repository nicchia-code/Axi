---
status: approved
base:
  requirements/ui/companion.md: ff859bc00323469d149f1c2b3c27d786cda88d4c1bad58d848cd08377be20625
  requirements/tech/fondamenta.md: d6cf88d78f0950e0369d308b622ace3247a9bd3bb1536e425dcdabb221c79cff
  requirements/data/vault.md: 4168f20c1262d2f88fe184af56ed58344f19cd0fa0bd357e4e67c4c5c4f76106
delete: []
request: 2026-10-19T22-43-05
created: 2026-10-19T20:48:19.045Z
label: Puntino più grande
---
# Puntino più grande

Il personaggio sullo schermo è troppo piccolo e nella barra dei menu i suoi colori stonano con le altre icone: la richiesta chiede un puntino 1,5 volte più grande e, nella barra, il colore delle icone di sistema.

Decisioni:
- Sullo schermo cresce di 1,5x tutto il personaggio (circa 48 pt invece di 32), con spunta, contatore, rimbalzo e scossa.
- La posizione salvata non si corregge: il riquadro più grande cresce dall'angolo in basso a sinistra, quindi una volta il personaggio sembra spostarsi un poco in alto a destra.
- Il menu a raggiera resta della misura di oggi.
- Nella barra l'icona resta di circa 18 pt.
- Nella barra il personaggio è una sagoma nel colore delle icone di sistema, con gli occhi trasparenti; ombra e riflesso spariscono.
- Nella barra restano le stesse animazioni, in un solo colore.
- Nella barra tutti i segnali sono nel colore delle icone: spunta monocroma, errore solo con la scossa, lampo e velo del trascinamento come variazioni di opacità.
- Nella barra il contatore della coda è un cerchio nel colore delle icone con il numero trasparente.
- Tecnica: immagine template (NSImage con isTemplate) ridisegnata a ogni fotogramma, così macOS gestisce colore, evidenziazione e attenuazione.
- Design/puntino.svg riceve la posa ferma monocroma per la barra.

## Already present
- `requirements/ui#puntino/Menu aperto` — Axi/Puntino/MenuRadialeVista.swift: cerchi delle azioni di 44 pt su un raggio di 100 pt, indipendenti dalla misura del personaggio
