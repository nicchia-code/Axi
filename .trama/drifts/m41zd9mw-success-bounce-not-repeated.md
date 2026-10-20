---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#attivita
proposal: null
task: k9uepath
origin: null
critical: false
option: 1
note: null
resolvedBy: qe7ae4y7
created: 2026-10-18T22:00:43.822Z
---
# Success bounce not repeated

## What happens

Quando un documento viene archiviato subito dopo un altro, il puntino fa il rimbalzo con il segno di spunta solo per il primo successo: per i successi che seguono, il segno resta fermo, perché l'animazione parte solo quando cambia il tipo di esito e non a ogni archiviazione riuscita.

## What should happen

Ogni archiviazione riuscita fa rimbalzare il puntino con il segno di spunta, come ogni errore lo fa scuotere, anche se l'esito precedente era già un successo.

## Fix options

### Rimbalzo a ogni successo

Il rimbalzo del segno di spunta viene legato al contatore degli esiti, come già accade per la scossa dell'errore e per il lampo del documento già presente. Ogni successo fa così rimbalzare il puntino, anche di seguito a un altro successo, senza toccare colore, forma o testi. Costo: una modifica piccola nel modo in cui si attiva l'animazione del segno; nessun effetto sugli altri esiti, che già usano il contatore.

### Ripartire il segno a ogni esito

Quando arriva un nuovo successo il segno di spunta si nasconde per un istante e poi ricompare, così il rimbalzo riparte da zero. Il puntino non cambia colore né forma per tutta la durata della nuvoletta. Costo: un piccolo sfarfallio tra due successi consecutivi, che il requisito non prevede, e una transizione in più da gestire anche quando il movimento è ridotto.

## Where in the code

Axi/Puntino/PuntinoVista.swift:111 (funzione simbolo: il rimbalzo del successo è legato al valore dell'esito, che non cambia tra due successi di fila)
