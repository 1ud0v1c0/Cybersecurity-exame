#!/bin/bash

# ==============================================================================
# SCRIPT PER IMPOSTARE UNA PASSWORD SU GRUB
# ==============================================================================

# Definiamo utente e password desiderati per GRUB
GRUB_USER="admin"
GRUB_PASS="PasswordSicura123!"

# File personalizzato di GRUB dove inserire le direttive
GRUB_CUSTOM_FILE="/etc/grub.d/40_custom"

echo "[+] Generazione dell'hash PBKDF2 per la password di GRUB..."
# grub-mkpasswd-pbkdf2 chiede la password due volte in input; 
# usiamo printf per passarla in automatico ed estraiamo l'hash generato
GRUB_HASH=$(printf "$GRUB_PASS\n$GRUB_PASS\n" | grub-mkpasswd-pbkdf2 | awk '/PBKDF2 hash of your password is/ {print $NF}')

echo "[+] Scrittura della configurazione in $GRUB_CUSTOM_FILE..."
# Scriviamo le direttive:
# - set superusers: definisce l'utente autorizzato a modificare i parametri di boot
# - password_pbkdf2: associa l'utente all'hash della password generata
echo "#!/bin/sh
exec tail -n +3 \$0
set superusers=\"$GRUB_USER\"
password_pbkdf2 $GRUB_USER $GRUB_HASH" | sudo tee "$GRUB_CUSTOM_FILE"

# Rendiamo il file eseguibile (richiesto dai file dentro /etc/grub.d/)
sudo chmod +x "$GRUB_CUSTOM_FILE"

echo "[+] Aggiornamento della configurazione di GRUB..."
# Applica le modifiche rigenerando il file /boot/grub/grub.cfg
sudo update-grub

echo "[+] Password impostata con successo per l'utente GRUB: $GRUB_USER"