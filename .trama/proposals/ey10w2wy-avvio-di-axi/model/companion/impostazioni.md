# Impostazioni

La finestra delle impostazioni: modello AI, scorciatoie, Azure Document Intelligence e percorso di OMP. Ogni cambiamento vale subito.

## States

### Chiuse (initial)
- `utente.APRE_IMPOSTAZIONI` → Aperte

### Aperte
- `utente.CHIUDE_IMPOSTAZIONI` → Chiuse
- `utente.APRE_IMPOSTAZIONI` → Aperte: la finestra già aperta torna in primo piano.
