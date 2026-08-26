#!/bin/bash

# ==============================================================================
# IPTABLES: BLOCCO TRAFFICO IN USCITA (NO NAVIGAZIONE) + WEBSERVER (80, 443) ATTIVO
# ==============================================================================

echo "[+] 1. Reset delle regole..."
sudo iptables -F
sudo iptables -X

echo "[+] 2. Impostazione policy restrittive (DROP sia in INPUT che in OUTPUT)..."
# Blocca tutto il traffico in entrata non esplicitamente autorizzato
sudo iptables -P INPUT DROP
# Blocca l'inoltro pacchetti
sudo iptables -P FORWARD DROP
# Blocca tutto il traffico generato dalla macchina verso l'esterno (impedisce la navigazione)
sudo iptables -P OUTPUT DROP

echo "[+] 3. Abilitazione Loopback (interno alla macchina)..."
# Permette le comunicazioni interne (127.0.0.1) sia in ingresso che in uscita
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

echo "[+] 4. Gestione dello stato delle connessioni..."
# Permette alla macchina di inviare i pacchetti di RISPOSTA ai client del webserver
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Permette il traffico correlato in ingresso
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "[+] 5. Apertura porte del Webserver in ingresso (80 HTTP, 443 HTTPS)..."
# Permette ai client esterni di avviare connessioni verso il webserver
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

echo ""
echo "[+] Configurazione completata. Regole attive:"
sudo iptables -L -v -n