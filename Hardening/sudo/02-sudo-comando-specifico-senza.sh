#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# Configura sudo affinchè un utente possa eseguire solo un comando specifico 
# ma senza un parametro (e.s: si puo eseguire nmap ma non nmap -p)
# Nota: si possono mettere espressioni regolari nel file sudoers
# ==============================================================================

# Definiamo l'utente target
TARGET_USER="utente_test"

# ==============================================================================
# Se non hai un utente target, creane uno per effettuare dei test (es. utente_test):
#    sudo adduser utente_test
# ==============================================================================

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

# ==============================================================================
# COME VERIFICARE SE HA FUNZIONATO:
# 1. Cambia utente passando al target:
#    su - utente_test
# 2. Verifica i comandi consentiti:
#    sudo -l
# 3. Prova ad eseguire il comando consentito senza l'opzione bloccata:
#    sudo nmap localhost
# 4. Prova ad eseguire il comando usando l'opzione vietata (dovrebbe fallire):
#    sudo nmap -p 80 localhost
# ==============================================================================