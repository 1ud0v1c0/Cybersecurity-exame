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

# ==============================================================================
# COME VERIFICARE SE HA FUNZIONATO:
#
# DENTRO LA MACCHINA:
# 1. Prova a navigare o pingare un sito esterno (Questo DEVE funzionare, l'uscita è libera):
#    ping 8.8.8.8
#    wget http://google.com
#
# DA FUORI LA MACCHINA (es. dal terminale del tuo Mac o da un'altra macchina):
# (Trova l'IP con 'ip a' o 'hostname -I', es. 192.168.1.100)
# 2. Prova a collegarti in SSH (Questo DEVE funzionare):
#    ssh studente@192.168.1.100 (oppure ssh -p 2222 studente@127.0.0.1 se sei in NAT)
#
# 3. Prova a scansionare le porte 80 o 443 (Queste DEVONO passare il firewall):
#    nc -v -z 192.168.1.100 80
#    nc -v -z 192.168.1.100 443
#
# 4. Prova a scansionare o collegarti a una porta NON autorizzata (es. 21 per FTP, o 8080):
#    nc -v -z 192.168.1.100 21
#    (Questo DEVE fallire e andare in blocco/timeout perché la porta non è nella lista).
# ==============================================================================