#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# - Cercare se esiste un qualche file all'interno della home di un utente che 
#   sia scrivibile da tutti gli utenti
# - Cercare se esiste una cartella all'interno della home di un utente che sia 
#   scrivibile da tutti gli utenti
# ==============================================================================

# ==============================================================================
# RICERCA DI FILE E DIRECTORY WORLD-WRITABLE NELLA HOME DI UN UTENTE
# ==============================================================================

# Definiamo l'utente target di cui analizzare la home directory
TARGET_USER="studente"

# Ricaviamo dinamicamente il percorso assoluto della home dell'utente
# (es. /home/studente)
TARGET_HOME=$(eval echo "~$TARGET_USER")

echo "=== SCANSIONE HOME DIRECTORY: $TARGET_HOME ==="
echo ""

# ------------------------------------------------------------------------------
# 1. Ricerca dei FILE scrivibili da tutti
# ------------------------------------------------------------------------------
echo "[+] Ricerca FILE scrivibili da tutti (world-writable):"

# Spiegazione parametri:
# - "$TARGET_HOME" : limita la ricerca alla cartella home dell'utente
# - "-type f"      : cerca solo file regolari
# - "-perm -0002"  : filtra i file che hanno il bit di scrittura per gli 'others' attivo
# - "-ls"          : stampa l'output dettagliato con permessi, proprietario e path
# - "2>/dev/null"  : sopprime eventuali messaggi di errore su file non leggibili
find "$TARGET_HOME" -type f -perm -0002 -ls 2>/dev/null

echo ""

# ------------------------------------------------------------------------------
# 2. Ricerca delle CARTELLE scrivibili da tutti
# ------------------------------------------------------------------------------
echo "[+] Ricerca CARTELLE scrivibili da tutti (world-writable):"

# - "-type d"      : cerca specificamente le directory
find "$TARGET_HOME" -type d -perm -0002 -ls 2>/dev/null