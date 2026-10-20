---
status: approved
base:
  requirements/ui/companion.md: 4b7fd406199eefd18522733be5185fad1a532dfaf1e04a1bc507db05398ae170
  requirements/tech/fondamenta.md: c493e6a948f0b47aa10f87b8ac7e624dbede80d21d33dc6d71bc02964b7edf3c
  companion/puntino.md: d8a364e5d3efbee9a5a2186229305ff43a27bad2f116f903b6d9d2ef7b9fb23c
delete: []
request: 2026-10-19T15-03-40
created: 2026-10-19T13:15:16.772Z
label: Puntino SVG
---
# Puntino vettoriale

Il personaggio oggi è una PNG 55×55 e una GIF di 17 fotogrammi in pixel art; nella GIF i fotogrammi 8–11 hanno lo sfondo nero e l'interno trasparente, quindi il puntino lampeggia in un quadrato nero. Lo sviluppatore vuole il puntino riprodotto in SVG, in uno stile fluido completamente diverso, e un nuovo aspetto: tre puntini di sospensione mentre l'AI pensa.

Decisioni:
- Un file SVG nel repository è il disegno di riferimento; l'app ridisegna le stesse forme in codice (SwiftUI) e le anima.
- Stile liscio e fluido, non più pixel art, con la palette della GIF (corpo, ombra, riflesso, occhi).
- Contorno tondo e leggermente irregolare, fermo a riposo.
- Attesa: il corpo si gonfia e si sgonfia e il contorno ondeggia; animazione continua, ciclo di circa 2,2 s come la GIF.
- Con "Riduci movimento" tutte le animazioni del personaggio restano uguali a metà velocità.
- Nella barra dei menu lo stesso disegno rimpicciolito, satelliti compresi.
- I segnali degli esiti (rimbalzo e spunta, scossa rossa, lampo) restano come sono, applicati alla forma vettoriale.
- `puntino.png` e `puntino-attesa.gif` si eliminano, con il codice che li decodifica.
- Tre puntini quando l'AI pensa: chat in risposta e generazione dei metadati di un documento.
- Trasformazione: il corpo si divide in tre gocce uguali in fila, i satelliti vengono riassorbiti, gli occhi spariscono; al ritorno le gocce si riuniscono. Circa 0,4 s all'andata e al ritorno.
- I tre puntini si alzano e si gonfiano a onda, uno dopo l'altro, nel ciclo di circa 2,2 s.
- I tre puntini vincono sul gonfiarsi; il segnale di un esito vince su entrambi.

Assunzioni (non chieste):
- I tre puntini restano nel riquadro del personaggio, così pannello, contatore della coda, nuvolette e chat non si spostano.
- Il file SVG di riferimento contiene sia il personaggio fermo sia la posa dei tre puntini, con le parti come forme separate e con nome.
- Nella barra dei menu si vedono anche i tre puntini, come già chiede "stessi aspetti e stesse animazioni".
