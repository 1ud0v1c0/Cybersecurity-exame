#!/bin/bash

# Definiamo il percorso del file di configurazione
CONF_FILE="/etc/security/pwquality.conf"

# 1. Installiamo il modulo PAM pwquality
sudo apt update
sudo apt install -y libpam-pwquality

# 2. Scriviamo le regole richieste nel file di configurazione:
# - minlen = 8    : lunghezza minima 8 caratteri
# - ucredit = -1  : almeno 1 lettera MAIUSCOLA richiesta (il valore negativo indica obbligo)
# - lcredit = -1  : almeno 1 lettera MINUSCOLA richiesta
# - ocredit = -1  : almeno 1 SIMBOLO/carattere speciale richiesto (other)
# - enforce_for_root : applica i controlli anche se la password viene cambiata da root
echo 'minlen = 8
ucredit = -1
lcredit = -1
ocredit = -1
enforce_for_root' | sudo tee "$CONF_FILE"