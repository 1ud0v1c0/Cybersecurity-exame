#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# - Rendi la cartella /var/log leggibile solo da root
# - Configura un utente per poter fare cat dei logs ma non essere amministratore 
#   (va configurato sudoers in modo opportuno)
# - Trova tutti i processi che hanno un file descriptor aperto dentro la 
#   cartella /var/log (il comando lsof tornerà comodo)
# ==============================================================================

# ==============================================================================
# GESTIONE E HARDENING DELLA DIRECTORY /var/log
# ==============================================================================

# Definiamo l'utente autorizzato a visualizzare i log
TARGET_USER="studente"

# File di configurazione dedicato per sudoers
SUDOERS_FILE="/etc/sudoers.d/cat_logs"


# ------------------------------------------------------------------------------
# 1. Rendi la cartella /var/log leggibile solo da root
# ------------------------------------------------------------------------------
echo "[+] Impostazione permessi restrittivi su /var/log (solo root)..."

# 0700 (rwx------) consente solo a root di leggere, scrivere ed entrare nella cartella
sudo chmod 0700 /var/log


# ------------------------------------------------------------------------------
# 2. Configura sudo affinché l'utente possa fare solo 'cat' dei file di log
# ------------------------------------------------------------------------------
echo "[+] Configurazione sudoers per consentire a $TARGET_USER di usare 'cat' sui log..."

# Permette all'utente di eseguire esclusivamente il comando 'cat' sui file dentro /var/log/
echo "$TARGET_USER ALL=(ALL) /bin/cat /var/log/*, !/bin/cat /var/log/*..*" | sudo tee "$SUDOERS_FILE"

# Imposta i permessi di sicurezza obbligatori per i file dentro sudoers.d (0440)
sudo chmod 0440 "$SUDOERS_FILE"

# Controlla che la sintassi di sudoers sia valida
sudo visudo -c


# ------------------------------------------------------------------------------
# 3. Trova tutti i processi con un file descriptor aperto in /var/log
# ------------------------------------------------------------------------------
echo "[+] Ricerca processi con descrittori aperti in /var/log..."

# Assicura che lo strumento lsof sia presente
sudo apt update -y && sudo apt install -y lsof

# +D cerca ricorsivamente tutti i file aperti all'interno di quella directory
sudo lsof +D /var/log

# ==============================================================================
# COME VERIFICARE SE HA FUNZIONATO:
# 1. Verifica i permessi della cartella (dovresti vedere drwx------ e root come proprietario):
#    ls -ld /var/log
# 2. Cambia utente passando a studente (se non esiste, crealo prima con sudo adduser studente):
#    su - studente
# 3. Prova ad entrare nella cartella o a vederne il contenuto normalmente (Permesso negato):
#    ls /var/log
#    cd /var/log
# 4. Prova a leggere un file di log autorizzato (Questo DEVE funzionare):
#    sudo cat /var/log/dpkg.log
# 5. Prova a eseguire un comando NON autorizzato o a fare directory traversal (Questo DEVE fallire):
#    sudo tail /var/log/dpkg.log
#    sudo cat /var/log/../etc/shadow
# ==============================================================================
