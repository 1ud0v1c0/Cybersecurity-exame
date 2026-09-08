#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# Imposta Iptables affinchè sia bloccato tutto il traffico Internet sulla 
# macchina (gli utenti non possono navigare) ma sia funzionante il webserver 
# (TCP port 80 e 443)
# ==============================================================================

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

# ==============================================================================
# COME VERIFICARE SE HA FUNZIONATO:
#
# DENTRO LA MACCHINA (Test blocco uscita):
# 1. Prova a navigare o pingare un sito esterno:
#    ping 8.8.8.8
#    wget http://google.com
#    (Questi comandi DEVONO bloccarsi/fallire, perché OUTPUT è su DROP).
#
# DA FUORI LA MACCHINA (es. dal tuo Mac verso l'IP della macchina):
# (Trova l'IP con 'ip a' o 'hostname -I', es. 192.168.1.100)
# 2. Prova a scansionare/collegarti alla porta 80 o 443:
#    nc -v -z 192.168.1.100 80
#    nc -v -z 192.168.1.100 443
#    (Questi DEVONO passare il firewall, mostrando "Connection refused" 
#     o "Succeeded", senza andare in timeout).
#
# 3. Prova a collegarti in SSH:
#    ssh studente@192.168.1.100 (oppure ssh -p 2222 studente@127.0.0.1 se usi NAT)
#    (Questo DEVE bloccarsi! Abbiamo rimosso l'eccezione per la porta 22).
#
# ⚠️ ATTENZIONE: Questo script TI CHIUDERÀ FUORI da SSH se provi a fare un nuovo
# login. Per ripristinare l'accesso, dovrai entrare nella console di VirtualBox e 
# resettare iptables come hai fatto prima (iptables -F e ripristinare le policy ACCEPT).
# ' sudo iptables -P INPUT ACCEPT '
# ' sudo iptables -P FORWARD ACCEPT '
# ' sudo iptables -P OUTPUT ACCEPT '
# ==============================================================================