#!/bin/bash

# ==============================================================================
# SCRIPT PER LA RICERCA DI ESEGUIBILI CON BIT SUID E SGID ATTIVI
# ==============================================================================

echo "=== RICERCA ESEGUIBILI CON SUID ATTIVO ==="
# Spiegazione del comando:
# - '/'           : Cerca a partire dalla radice del filesystem
# - '-type f'     : Limita la ricerca solo ai file regolari (esclude directory, link, ecc.)
# - '-perm -4000' : Filtra i file che hanno almeno il bit SUID (4000 in notazione ottale)
# - '-exec ls -la {} +' : Mostra i dettagli dei file trovati (permessi, proprietario, path)
# - '2>/dev/null' : Nasconde gli errori di 'Permission denied' sulle cartelle non accessibili
sudo find / -type f -perm -4000 -exec ls -la {} + 2>/dev/null

echo ""
echo "=== RICERCA ESEGUIBILI CON SGID ATTIVO ==="
# Spiegazione del comando:
# - '-perm -2000' : Filtra i file che hanno almeno il bit SGID (2000 in notazione ottale)
# Il resto dei parametri ha la stessa funzione del comando precedente.
sudo find / -type f -perm -2000 -exec ls -la {} + 2>/dev/null