#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# Imposta Iptables affinchè sia permesso l'accesso alla macchina solo via SSH 
# (TCP port 22) dall'IP 1.2.3.4 e ad un webserver da qualunque IP 
# (TCP port 80 e 443)
# ==============================================================================

# ==============================================================================
# IPTABLES: SSH SOLO DA 1.2.3.4 - WEBSERVER (80, 443) APERTO A TUTTI
# ==============================================================================

# Definiamo l'IP autorizzato per SSH (all'esame usa l'IP o subnet della traccia, es. 192.168.1.50 o 192.168.1.0/24)
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

# ==============================================================================
# COME VERIFICARE SE HA FUNZIONATO:
#
# 1. Trova l'IP di questa macchina (con 'ip a' o 'hostname -I', es. 192.168.1.100).
#    (Se usi VirtualBox in NAT standard, usa 127.0.0.1 porta 2222).
#
# Da un terminale esterno (es. il tuo Mac o un'altra macchina della rete):
# 2. Prova a fare l'accesso via SSH dal tuo IP. 
#    (ATTENZIONE: Questo DEVE BLOCCARSI! Dato che il tuo IP reale
#    non è 1.2.3.4, la regola di iptables ti taglierà fuori).
#    ssh studente@192.168.1.100   # (sostituisci con l'IP della macchina)
#
# 3. Prova a scansionare le porte 80 o 443. 
#    (Questo DEVE farti passare il firewall, restituendo rapidamente "Connection refused" 
#    se non c'è un webserver acceso, ma non andando in timeout):
#    nc -v -z 192.168.1.100 80
#    nc -v -z 192.168.1.100 443
#
# NOTA BENE: Essendoti appena "chiuso fuori" dal servizio SSH, se questa macchina 
# fosse un server su internet saresti bloccato. Dato che è una macchina virtuale,
# puoi aprirne la finestra direttamente da VirtualBox, loggarti, e digitare 
# 'sudo iptables -F' per sbloccare di nuovo SSH. e poi fare: 
# ' sudo iptables -P INPUT ACCEPT '
# ' sudo iptables -P FORWARD ACCEPT '
# ' sudo iptables -P OUTPUT ACCEPT '
# pochè avevamo chiuso con INPUT DROP
# ==============================================================================