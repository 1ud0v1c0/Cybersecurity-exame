#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# Imposta Iptables affinchè sia permesso l'accesso alla macchina solo via SSH 
# (TCP port 22)
# ==============================================================================

# ==============================================================================
# CONFIGURAZIONE IPTABLES: ACCESSO CONSENTITO SOLO VIA SSH (PORTA 22 TCP)
# ==============================================================================

echo "[+] 1. Reset di tutte le regole e catene preesistenti..."
# -F : svuota (flush) tutte le regole
# -X : cancella eventuali catene personalizzate create in precedenza
sudo iptables -F
sudo iptables -X

echo "[+] 2. Impostazione delle policy di default..."
# Blocca tutto il traffico in ingresso non esplicitamente autorizzato
sudo iptables -P INPUT DROP
# Blocca l'inoltro di pacchetti (non siamo un router)
sudo iptables -P FORWARD DROP
# Consente alla macchina di generare traffico verso l'esterno
sudo iptables -P OUTPUT ACCEPT

echo "[+] 3. Abilitazione del traffico locale (loopback)..."
# Indispensabile per la comunicazione tra processi interni sulla macchina (127.0.0.1)
sudo iptables -A INPUT -i lo -j ACCEPT

echo "[+] 4. Mantenimento delle sessioni già attive e risposte..."
# Consente i pacchetti appartenenti a connessioni già stabilite o correlate
# (evita che lo script ti disconnetta dalla sessione SSH corrente)
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "[+] 5. Apertura della porta TCP 22 (SSH)..."
# -A INPUT     : aggiunge la regola alla catena di ingresso
# -p tcp       : protocollo TCP
# --dport 22   : porta di destinazione 22
# -j ACCEPT    : accetta il pacchetto
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

echo ""
echo "[+] Configurazione completata. Regole attive:"
# Mostra la tabella delle regole attive numerate e dettagliate
sudo iptables -L -v -n