#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# Imposta Iptables affinchè sia permesso l'accesso alla macchina solo via SSH 
# (TCP port 22) e ad un webserver (TCP port 80 e 443)
# ==============================================================================

# ==============================================================================
# IPTABLES: ACCESSO CONSENTITO SOLO A SSH (PORTA 22) E WEBSERVER (80, 443)
# ==============================================================================

echo "[+] 1. Reset delle regole esistenti..."
sudo iptables -F
sudo iptables -X

echo "[+] 2. Impostazione policy di default..."
# Blocca tutto il traffico in entrata non esplicitamente consentito
sudo iptables -P INPUT DROP
# Blocca l'inoltro di pacchetti
sudo iptables -P FORWARD DROP
# Consente il traffico in uscita generato dalla macchina
sudo iptables -P OUTPUT ACCEPT

echo "[+] 3. Abilitazione Loopback e sessioni attive..."
# Consente la comunicazione interna tra i servizi locali (127.0.0.1)
sudo iptables -A INPUT -i lo -j ACCEPT
# Mantiene attive le connessioni già stabilite e correlate
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "[+] 4. Apertura delle porte per SSH (22) e Webserver (80, 443)..."
# Usiamo il modulo 'multiport' per raggruppare tutte le porte richieste in un'unica riga
sudo iptables -A INPUT -p tcp -m multiport --dports 22,80,443 -j ACCEPT

echo ""
echo "[+] Configurazione completata con successo. Regole attive:"
# Mostra la tabella finale con le porte e le policy applicate
sudo iptables -L -v -n