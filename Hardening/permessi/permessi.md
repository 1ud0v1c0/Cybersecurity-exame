# Guida & Cheat-Sheet Permessi Linux, Bit Speciali e Ricerca (`chmod`, `chown`, `find`)

---

## 1. La Notazione Ottale Completa a 4 Cifre

In ambiente Linux ogni risorsa ha permessi definiti da **4 cifre ottali**:

$$\text{Permessi} = \mathbf{C_1}\text{ (Bit Speciali)} \quad \mathbf{C_2}\text{ (User / Owner)} \quad \mathbf{C_3}\text{ (Group)} \quad \mathbf{C_4}\text{ (Others)}$$

### Calcolo del valore delle cifre base ($C_2, C_3, C_4$)

* **`4`** = Read (`r`) — Lettura file o visualizzazione contenuto directory
* **`2`** = Write (`w`) — Scrittura/modifica file o creazione/eliminazione file in directory
* **`1`** = Execute (`x`) — Esecuzione programma o attraversamento directory (`cd`)
* **`0`** = Nessun permesso (`-`)

---

## 2. I Bit Speciali (Prima Cifra $C_1$)

I bit speciali modificano il contesto di esecuzione del file o il comportamento delle cartelle.

| Valore | Nome | Effetto sui FILE | Effetto sulle DIRECTORY | Come appare in `ls -l` |
| --- | --- | --- | --- | --- |
| **`4`** | **SUID** *(Set User ID)* | Il file viene eseguito con i privilegi del suo **proprietario** (es. `root`), non dell'utente che lo lancia. | Nessun effetto comune. | `-rw**s**r-xr-x` *(nello User)* |
| **`2`** | **SGID** *(Set Group ID)* | Il file viene eseguito con i privilegi del **gruppo** proprietario. | Tutti i nuovi file/cartelle creati all'interno **ereditano il gruppo della cartella madre**. | `-rwxr-**s**r-x` *(nel Group)* |
| **`1`** | **Sticky Bit** | Nessun effetto moderno. | **Solo il proprietario del file** (o root) può rinominare o eliminare il file, anche se la cartella è scrivibile da tutti (es. `/tmp`). | `drwxrwxrwt` *(in fondo)* |
| **`0`** | **Nessuno** | Nessun bit speciale attivo (standard). | Nessun bit speciale attivo. | `-rwxr-xr-x` |

> **Nota su `s`/`S` e `t`/`T` in `ls -l`:**
>
> * Lettera **minuscola** (`s`, `t`): il bit speciale è attivo **insieme** al bit di esecuzione `x`.
> * Lettera **MAIUSCOLA** (`S`, `T`): il bit speciale è attivo, ma **manca** il bit di esecuzione `x` (possibile errore di configurazione).
>
>

---

## 3. Gestione Permessi e Proprietà (`chmod`, `chown`)

### Regola d'oro: File vs Directory

* **File protetto di testo/log:** usa `0600` (`rw-------`) — **non** dare `x`.
* **Cartella protetta:** usa `0700` (`rwx------`) — la `x` è **indispensabile** per entrarci con `cd`.

### Esempi di comandi frequenti

```bash
# Rendi un file leggibile e scrivibile solo da root
sudo chmod 0600 /etc/security/secret.conf

# Rendi una cartella accessibile solo da root
sudo chmod 0700 /var/log/private

# Imposta SUID su un eseguibile
sudo chmod 4755 /usr/local/bin/custom_tool

# Imposta SGID su una directory condivisa (collaborazione di gruppo)
sudo chmod 2775 /srv/shared_folder

# Imposta Sticky Bit su una directory temporanea
sudo chmod 1777 /tmp/sandbox

# Cambia proprietario e gruppo (utente:gruppo)
sudo chown studente:devops /home/studente/progetto.sh

# Modifica ricorsiva su un'intera cartella (-R)
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 0750 /var/www/html

```

---

## 4. Ricerca Avanzata Permessi con `find`

La sintassi del flag `-perm` in `find` ha 3 modalità di match:

1. **`-perm 0755` (Match Esatto):** Cerca file che hanno **esattamente** quei permessi, né più né meno.
2. **`-perm -MODE` (Match Inclusivo / All bits set):** Cerca file che hanno **almeno** tutti i bit specificati attivi (la modalità più usata negli esami di sicurezza).
3. **`-perm /MODE` (Match Any / At least one bit set):** Cerca file che hanno **almeno uno** dei bit indicati attivo.

---

### Pattern di Ricerca Tipici d'Esame

```bash
# 1. Trovare tutti gli eseguibili con SUID attivo
sudo find / -type f -perm -4000 -exec ls -la {} + 2>/dev/null

# 2. Trovare tutti gli eseguibili con SGID attivo
sudo find / -type f -perm -2000 -exec ls -la {} + 2>/dev/null

# 3. Trovare file con SUID O SGID (almeno uno dei due)
sudo find / -type f -perm /6000 -exec ls -la {} + 2>/dev/null

# 4. Trovare FILE World-Writable (scrivibili da 'others' -> bit 0002)
find /home/studente -type f -perm -0002 -ls 2>/dev/null

# 5. Trovare CARTELLE World-Writable
find /home/studente -type d -perm -0002 -ls 2>/dev/null

# 6. Trovare cartelle World-Writable SENZA Sticky Bit (GRAVE RISCHIO DI SICUREZZA)
# Cerca permessi -0002 (scrivibile da tutti) escludendo quelle con Sticky bit (! -perm -1000)
sudo find / -type d -perm -0002 ! -perm -1000 -ls 2>/dev/null

# 7. Trovare file appartenenti a un utente o gruppo specifico
sudo find / -user www-data 2>/dev/null
sudo find / -group docker 2>/dev/null

# 8. Trovare file "orfani" (senza proprietario o gruppo valido sul sistema)
sudo find / \( -nouser -o -nogroup \) -ls 2>/dev/null

```

---

## 5. Cheat-Sheet Riparazione Permessi (Fixing Script)

Se un esercizio richiede di trovare elementi vulnerabili e **correggerne automaticamente i permessi**:

```bash
#!/bin/bash
TARGET_DIR="/home/studente"

# Rimuove il permesso di scrittura per 'others' (world-writable) da tutti i file
find "$TARGET_DIR" -type f -perm -0002 -exec chmod o-w {} +

# Rimuove il permesso di scrittura per 'others' da tutte le cartelle
find "$TARGET_DIR" -type d -perm -0002 -exec chmod o-w {} +

# Rimuove il bit SUID da un eseguibile sospetto
sudo chmod u-s /usr/local/bin/eseguibile_sospetto

```
