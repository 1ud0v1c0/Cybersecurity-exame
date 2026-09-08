#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# Installare e configurare un modulo PAM per richiedere caratteristiche minime 
# alla password (min 8 caratteri, maiuscole, minuscole e simboli)
# ==============================================================================

# Definiamo il percorso del file di configurazione
CONF_FILE="/etc/security/pwquality.conf"

# 1. Installiamo il modulo PAM pwquality
sudo apt update
sudo apt install -y libpam-pwquality

# 2. Scriviamo le regole richieste nel file di configurazione:
# - minlen = 8    : lunghezza minima 8 caratteri
# - ucredit = -1  : almeno 1 lettera MAIUSCOLA richiesta (il valore negativo indica obbligo)
# - lcredit = -1  : almeno 1 lettera MINUSCOLA richiesta
# - ocredit = -1  : almeno 1 SIMBOLO/carattere speciale richiesto (other)
# - enforce_for_root : applica i controlli anche se la password viene cambiata da root
echo 'minlen = 8
ucredit = -1
lcredit = -1
ocredit = -1
enforce_for_root' | sudo tee "$CONF_FILE"

# ==============================================================================
# COME VERIFICARE SE HA FUNZIONATO:
# 1. Prova a cambiare la password dell'utente corrente (o di un utente di test):
#    passwd
# 2. Inserisci prima la tua password attuale.
# 3. Prova a inserire una nuova password "debole" (es: "ciao" oppure "password123").
#    Il sistema dovrebbe rifiutarla dicendo ad esempio "BAD PASSWORD: The password is shorter than 8 characters" 
#    oppure "BAD PASSWORD: The password contains less than 1 uppercase letters".
# 4. Inserisci una password che rispetti tutti i criteri (es: "Cyb3rS3c!").
#    Il sistema dovrebbe accettarla.
# ==============================================================================