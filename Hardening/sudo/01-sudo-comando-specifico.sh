#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# Configura sudo affinchè un utente possa eseguire solo un comando specifico (e.s: nmap)
# ==============================================================================

# Definiamo l'utente a cui applicare la regola (cambialo con il nome utente target)
TARGET_USER="utente_test"

# ==============================================================================
# Se non hai un utente target, creane uno per effettuare dei test (es. utente_test):
#    sudo adduser utente_test
# ==============================================================================

# Creiamo la regola:
# Sintassi: <UTENTE> <HOST>=(<RUN_AS>) <COMANDO_ASSOLUTO>
# L'utente specificato potrà eseguire SOLO /usr/bin/nmap con qualsiasi parametro
REGOLA="$TARGET_USER ALL=(ALL) /usr/bin/nmap"

# Scriviamo la regola in un file dedicato dentro /etc/sudoers.d/
echo "$REGOLA" | sudo tee /etc/sudoers.d/nmap_only

# È fondamentale impostare i permessi a 0440 (sola lettura per root)
# altrimenti sudo ignorerà il file per motivi di sicurezza
sudo chmod 0440 /etc/sudoers.d/nmap_only

# Verifica sintattica del file sudoers per accertarsi che non ci siano errori
sudo visudo -c

# ==============================================================================
# COME VERIFICARE SE HA FUNZIONATO:
# 1. Cambia utente passando al target:
#    su - utente_test
# 2. Verifica i comandi consentiti (ti verrà chiesta la password di studente se configurata, o fallirà se richiede password e non la si ha. sudo -l listerà le regole):
#    sudo -l
# 3. Prova ad eseguire il comando consentito:
#    sudo nmap localhost
# 4. Prova ad eseguire un comando NON consentito (dovrebbe dare errore):
#    sudo ls /root
# ==============================================================================