#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# Creare uno unit file di Systemd per permettere una shell aperta a tutti sulla 
# rete (netcat in modalità listen con il processo /bin/bash) e provare a 
# connettersi dalla propria macchina usando netcat
# ==============================================================================

# Definiamo il percorso del file di servizio
SERVICE_FILE="/etc/systemd/system/shell.service"

# 1. Installiamo ncat (supporta direttamente il flag -e)
sudo apt update
sudo apt install -y ncat

# 2. Creiamo lo unit file Systemd usando la variabile
# - -l 4444      : ascolta sulla porta 4444
# - -k           : resta attivo anche se il client si disconnette
# - -e /bin/bash : collega la porta direttamente alla bash di root
echo '[Unit]
Description=Simple Root Shell

[Service]
ExecStart=/usr/bin/ncat -l 4444 -k -e /bin/bash
Restart=always

[Install]
WantedBy=multi-user.target' | sudo tee "$SERVICE_FILE"

# 3. Ricarichiamo systemd e avviamo il servizio
sudo systemctl daemon-reload
sudo systemctl enable --now shell.service

# PER TESTARLO
# ip -a per vedere ip della macchina
# nc <IP_MACHINE> 4444 per connettersi

