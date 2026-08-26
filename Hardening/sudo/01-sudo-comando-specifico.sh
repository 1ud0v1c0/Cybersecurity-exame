#!/bin/bash

# Definiamo l'utente a cui applicare la regola (cambialo con il nome utente target)
TARGET_USER="studente"

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