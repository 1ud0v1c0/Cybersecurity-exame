#!/bin/bash

# ==============================================================================
# IPTABLES: SSH SOLO DA 1.2.3.4 - WEBSERVER (80, 443) APERTO A TUTTI
# ==============================================================================

# Definiamo l'IP autorizzato per SSH
ALLOWED_IP="1.2.3.4"

echo "[+] 1. Reset delle regole esistenti..."
sudo iptables -F
sudo iptables -X

echo "[+] 2. Impostazione policy di default a DROP per INPUT..."
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

echo "[+] 3. Abilitazione Loopback e connessioni già stabilite..."
# Permette il traffico interno
sudo iptables -A INPUT -i lo -j ACCEPT
# Mantiene vive le connessioni attive/risposte
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "[+] 4. Apertura SSH (porta 22) SOLO dall'IP $ALLOWED_IP..."
# -s $ALLOWED_IP : limita l'accettazione solo ai pacchetti che provengono da questo IP
sudo iptables -A INPUT -p tcp -s "$ALLOWED_IP" --dport 22 -j ACCEPT

echo "[+] 5. Apertura porte Webserver (80 HTTP, 443 HTTPS) per TUTTI..."
# -m multiport --dports 80,443 : permette di specificare più porte TCP contemporaneamente
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

echo ""
echo "[+] Regole applicate con successo:"
sudo iptables -L -v -n