---
technical: false
refs:
  - lettura-schermo.NESSUN_DOCUMENTO
  - requirements/quality#lettura-schermo
---
# Motivi del rifiuto lettura

`NESSUN_DOCUMENTO` porta con sé il motivo, distinto per ogni caso (oggi `ScreenReader.swift` produce `nessunDocumento` senza motivo):
- «nessun documento»: in primo piano non c'è né un file, né un'email di Outlook, né una pagina web;
- «indirizzo non leggibile»: in primo piano c'è una pagina web ma il suo indirizzo non si legge né dall'area della pagina, né dalla barra degli indirizzi, né (per Safari e Chrome) dall'Automazione;
- permesso mancante, nominato: manca Accessibility, oppure per una pagina di Safari o Chrome serve l'Automazione e manca il suo permesso;
- «errore imprevisto»: la ricerca si interrompe per un errore non previsto; Axi resta aperto e la lettura torna «Inattiva».

Nessun errore durante la lettura dello schermo chiude Axi. Ogni rifiuto e ogni fallimento della lettura si registra con `os.Logger` (subsystem `Axi`, categoria `lettura-schermo`) con il passo, il motivo e l'app di origine, senza testo letto a schermo e senza indirizzi completi (al più il dominio).

Rispetta `requirements/quality#lettura-schermo`.
