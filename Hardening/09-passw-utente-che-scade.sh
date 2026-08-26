#!/bin/bash

# ==============================================================================
# CREAZIONE UTENTE CON PASSWORD CHE SCADE OGNI GIORNO
# ==============================================================================

# Definiamo nome utente e password iniziale
NEW_USER="dailyuser"
USER_PASS="PasswordSicura123!"

echo "[+] Creazione dell'utente $NEW_USER..."
# -m : crea la cartella /home/$NEW_USER
# -s : imposta la shell predefinita a /bin/bash
sudo useradd -m -s /bin/bash "$NEW_USER"

echo "[+] Impostazione della password iniziale..."
# chpasswd permette di impostare la password in modo non interattivo (formato utente:password)
echo "$NEW_USER:$USER_PASS" | sudo chpasswd

echo "[+] Impostazione della scadenza password a 1 giorno..."
# Spiegazione di 'chage -M 1':
# -M (maxdays): imposta il numero massimo di giorni tra i cambi di password a 1.
#               Trascorsa una giornata, al login successivo verrà imposto il cambio password.
sudo chage -M 1 "$NEW_USER"

echo ""
echo "[+] Verifica dello stato di invecchiamento della password:"
# Mostra la configurazione attiva (Maximum number of days between password change: 1)
sudo chage -l "$NEW_USER"