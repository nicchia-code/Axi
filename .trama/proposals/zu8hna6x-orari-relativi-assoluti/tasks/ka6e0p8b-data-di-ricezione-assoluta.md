---
refs:
  - archiviazione/Acquisizione
  - archiviazione/Controllo dei duplicati
  - archiviazione.ARCHIVIATO
  - requirements/rules#archiviazione/Acquisizione
  - requirements/rules#archiviazione/Controllo dei duplicati
  - requirements/tech#archiviazione
---
# Data di ricezione assoluta

In archiviazione/Acquisizione, un'email di Outlook diventa un documento con mittente, destinatari, oggetto, data di ricezione e testo. La data di ricezione è quella mostrata a schermo, anche relativa («2 ore fa», «ieri alle 14:30»): Axi la conserva com'era scritta e chiede a OMP di renderla assoluta rispetto al momento in cui ha letto lo schermo.

Quando il Task è fatto vale quanto segue.

- La data di ricezione si chiede a OMP con una richiesta a parte, durante l'acquisizione e prima del controllo dei duplicati. A OMP si passano il testo della data mostrato a schermo, il momento della lettura dello schermo e il fuso del Mac, così come arrivano con il documento individuato.
- La risposta è JSON validato: un istante ISO 8601 con offset, oppure nullo. Se OMP non sa interpretare il testo, se la risposta non è valida o è nulla, o se la richiesta fallisce o OMP non risponde, la data di ricezione resta sconosciuta e l'archiviazione prosegue: nessuno la inventa e l'archiviazione non fallisce per questo.
- L'ora di archiviazione non si usa mai come data di ricezione di riserva. Oggi `emailWork` in `ArchivingPipeline.swift` fa `EmailDate.parse(sentAtText) ?? now()`: questa riserva va tolta. Il testo mostrato da Outlook si conserva accanto alla data di ricezione assoluta, che può mancare.
- In archiviazione/Controllo dei duplicati l'impronta di un'email è lo SHA-256 del testo normalizzato di mittente, giorno di ricezione assoluto (nel fuso del Mac), oggetto e corpo; se la data di ricezione è sconosciuta, quella di mittente, oggetto e corpo. Così la stessa email riarchiviata più tardi, quando Outlook la mostra con un'altra forma relativa, viene riconosciuta come già presente (`GIA_PRESENTE`). L'impronta non usa più il testo della data com'era mostrato (oggi `Fingerprint.email` in `ArchiveFingerprint.swift`). Le altre impronte restano come sono: i byte della copia per un file, indirizzo e testo per una pagina web senza PDF.
- L'evento archiviazione.ARCHIVIATO, emesso quando un documento entra nel vault, porta il suo titolo, i tag, gli eventuali allegati non presi e, per un'email, se la sua data di ricezione è rimasta sconosciuta, così che l'esito lo possa dire.
- Ogni archiviazione resta atomica per file e database: in caso di fallimento non resta nulla nel vault.
