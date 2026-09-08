#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# Configura sudo affinchè un utente possa eseguire solo un comando specifico 
# ma senza un parametro (e.s: si puo eseguire nmap ma non nmap -p)
# Nota: si possono mettere espressioni regolari nel file sudoers
# ==============================================================================

# Definiamo l'utente target
TARGET_USER="studente"

# Creiamo la regola:
# 1. Permette /usr/bin/nmap con argomenti generici
# 2. Con '!/usr/bin/nmap *-p*' VIETA qualsiasi comando nmap che contenga l'opzione -p
REGOLA="$TARGET_USER ALL=(ALL) /usr/bin/nmap, !/usr/bin/nmap *-p*"

# Scriviamo la regola nel file di configurazione
echo "$REGOLA" | sudo tee /etc/sudoers.d/nmap_no_param

# Impostiamo i permessi corretti (0440)
sudo chmod 0440 /etc/sudoers.d/nmap_no_param

# Controlliamo la validità del file sudoers
sudo visudo -c