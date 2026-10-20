---
status: resolved
resolution: fix-code
refs:
  - requirements/tech#impostazioni
proposal: null
task: l4inxzp9
origin: cd1yhhvc
critical: false
option: 2
note: null
resolvedBy: 0zmrvfhb
created: 2026-10-19T12:17:30.534Z
---
# Tasti Apple non intercettati

## What happens

Axi non intercetta il tasto Spotlight (lente) né quello della Dettatura (microfono): nel codice non c'è nessun event tap né interruttore per questi tasti, e il segnale che mandano non è registrato nel codice. Il tasto dell'interruttore resta assente; la chiusura precedente dice che i tasti già funzionano, ma il codice non lo mostra.

## What should happen

I Requirements chiedono che, con i tasti assegnati ad Axi, la lente apra o chiuda la chat e il microfono archivi, senza far partire Spotlight né la Dettatura, e che il segnale esatto sia verificato su una tastiera Apple reale e documentato nel codice. Il segnale non è dato e non si può verificare senza una tastiera reale, quindi il Task non si può completare come scritto.

## Fix options

### Verifica il segnale su tastiera reale

Lo sviluppatore, o chi ha una tastiera Apple, preme una volta lente e microfono mentre una cattura temporanea, fuori da Axi, registra il segnale; poi Axi intercetta i due tasti con quel segnale e lo documenta nel codice. Costi: serve la cattura, e il segnale vale solo per le tastiere provate.

### Scrivi ora dal segnale pubblico, verifica dopo

Il tap viene scritto dal segnale che le tabelle pubbliche dei tasti danno per questi due tasti, con la nota che non è ancora verificato; il Task resta in doing finché lo sviluppatore non lo conferma su una tastiera reale. Costi: se il segnale è sbagliato, i tasti non rispondono finché non si corregge, e il codice contiene un segnale non verificato per un po'.

## Where in the code

Axi/Impostazioni/Scorciatoie.swift (solo i due nomi KeyboardShortcuts Archivia e Chat, nessun event tap); Axi/AppDelegate.swift (tastiAssegnati fissato a false, nessun tap registrato)
