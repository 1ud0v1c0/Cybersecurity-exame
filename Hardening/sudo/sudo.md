# Guida & Cheat-Sheet Sudo e Sudoers per Esame Pratico (Debian)

---

## 1. Regole d'Oro per la Gestione di Sudo

1. **Mai toccare direttamente `/etc/sudoers`:** Crea sempre file dedicati dentro la directory protetta `/etc/sudoers.d/`.
2. **Permessi obbligatori (`0440`):** I file dentro `/etc/sudoers.d/` devono essere in modalità *sola lettura* per root e gruppo root (`r--r-----`). Se i permessi sono diversi (es. `0644` o `0777`), `sudo` **ignora completamente il file** per ragioni di sicurezza.
3. **Nomi file conformi:** I nomi dei file in `/etc/sudoers.d/` non devono contenere punti (`.`) o terminare con `~` (es. usa `nmap_rule`, **non** `nmap.conf`).
4. **Validazione con `visudo -c`:** Lancia sempre il controllo sintattico a fine script:

```bash
sudo visudo -c

```

---

## 2. Anatomia della Sintassi di una Regola

La struttura generale di una direttiva nel file sudoers è:

$$\mathbf{CHI} \quad \mathbf{DOVE}=(\mathbf{COME}) \quad [\mathbf{TAG:}] \quad \mathbf{COSA}$$

```text
studente    ALL=(ALL:ALL)    NOPASSWD:    /usr/bin/nmap
│           │   │   │        │            │
│           │   │   │        │            └─ Comando/i autorizzati (path assoluto)
│           │   │   │        └─ Opzione tag (es. nessuna password richiesta)
│           │   │   └─ Come quale gruppo eseguire (default: lo stesso dell'utente)
│           │   └─ Come quale utente eseguire (ALL = chiunque, tipicamente root)
│           └─ Su quali host di rete è valida la regola (ALL = ovunque)
└─ Utente (es. studente) o Gruppo (es. %admin)

```

---

## 3. Gestione di Utenti, Gruppi e Password

| Caso d'uso | Sintassi |
| --- | --- |
| **Singolo Utente** | `studente ALL=(ALL) /usr/bin/nmap` |
| **Gruppo di sistema** (prefisso `%`) | `%devops ALL=(ALL) /usr/bin/systemctl` |
| **Senza richiesta di Password** | `studente ALL=(ALL) NOPASSWD: /usr/bin/nmap` |
| **Con richiesta di Password** (default) | `studente ALL=(ALL) PASSWD: /usr/bin/nmap` |
| **Esecuzione come utente specifico** | `studente ALL=(www-data) /usr/bin/php` *(si invoca con: `sudo -u www-data php ...`)* |

---

## 4. Filtraggio Comandi, Argomenti e Parametri Vietati

> **Importante:** Sudo valuta i comandi da sinistra a destra. Per bloccare un parametro, **prima autorizzi il comando generale**, poi **neghi l'eccezione con il punto esclamativo `!**`.

### Tabella dei Pattern Comuni

| Esigenza | Regola Sudoers | Esempio comando consentito | Esempio comando bloccato |
| --- | --- | --- | --- |
| **Solo comando senza argomenti** | `studente ALL=(ALL) /usr/bin/nmap ""` | `sudo nmap` | `sudo nmap 127.0.0.1` |
| **Comando con qualsiasi argomento** | `studente ALL=(ALL) /usr/bin/nmap` | `sudo nmap -sS 1.1.1.1` | `sudo ls` |
| **Comando MA vietato un flag (es. `-p`)** | `studente ALL=(ALL) /usr/bin/nmap, !/usr/bin/nmap *-p*` | `sudo nmap 192.168.1.1` | `sudo nmap -p 80 192.168.1.1`<br>

<br>`sudo nmap -p- 127.0.0.1` |
| **Lettura esclusiva dei file di log** | `studente ALL=(ALL) /bin/cat /var/log/*` | `sudo cat /var/log/syslog` | `sudo cat /etc/shadow` |
| **Riavviare solo un servizio specifico** | `studente ALL=(ALL) /usr/bin/systemctl restart nginx` | `sudo systemctl restart nginx` | `sudo systemctl restart sshd`<br>

<br>`sudo systemctl stop nginx` |
| **Wildcard (`*`) su percorsi sicuri** | `studente ALL=(ALL) /bin/ls /home/*` | `sudo ls /home/studente` | `sudo ls /root` |

---

## 5. Alias in Sudoers (User_Alias, Cmnd_Alias)

Negli ambienti di produzione o negli esami complessi, si usano gli **Alias** per raggruppare utenti o elenchi di comandi:

```text
# Definizione Alias comandi
Cmnd_Alias NETWORKING = /usr/bin/nmap, /usr/bin/tcpdump, /usr/sbin/iptables
Cmnd_Alias WEB_MANAGE = /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx

# Definizione Alias utenti
User_Alias SYSADMINS = studente, mario, luigi

# Applicazione della regola
SYSADMINS ALL=(ALL) NETWORKING, WEB_MANAGE

```

---

## 6. Il Template Bash Standard per gli Esercizi d'Esame

Usa questa struttura a prova d'errore per scrivere qualsiasi regola `sudo` all'interno dei tuoi script di automazione:

```bash
#!/bin/bash
set -e

# 1. Definisci i parametri dell'esercizio
TARGET_USER="studente"
RULE_FILE="/etc/sudoers.d/custom_rule"

# 2. Prepara la regola
REGOLA="$TARGET_USER ALL=(ALL) /usr/bin/nmap, !/usr/bin/nmap *-p*"

# 3. Scrivi nel file dedicato con tee
echo "$REGOLA" | sudo tee "$RULE_FILE"

# 4. Imposta i permessi restrittivi obbligatori (0440)
sudo chmod 0440 "$RULE_FILE"

# 5. Verifica sintassi immediata (fondamentale per evitare blocchi del sistema)
sudo visudo -c

```

---

## 7. Verifica e Troubleshooting

Per testare se le regole funzionano correttamente dal terminale:

```bash
# Mostra tutti i privilegi sudo concessi all'utente corrente
sudo -l

# Mostra i privilegi sudo di un altro utente specifico
sudo -l -U nomeutente

# Test esecuzione comando consentito
sudo /usr/bin/nmap 127.0.0.1

# Test esecuzione comando vietato (deve restituire "Sorry, user ... is not allowed to execute...")
sudo /usr/bin/nmap -p 80 127.0.0.1

```

---

## 8. Insidie Tipiche da Evitare (Security Pitfalls)

* **Uso di editor di testo (Privilege Escalation immediato):**
Se consenti `studente ALL=(ALL) /usr/bin/nano /var/log/syslog` o `vi`, l'utente può aprire una shell di root direttamente dall'interno dell'editor (es. con `:!/bin/bash` in `vi` o `Ctrl+R -> Ctrl+X` in `nano`). Per la sola lettura, usa sempre `/bin/cat` o `/usr/bin/view` limitato.
* **Wildcard all'inizio (`*`):**
Evita regole come `!/usr/bin/nmap *` prima del comando positivo, altrimenti la negazione annullerà tutto. L'ordine corretto è sempre: **prima il comando positivo, poi l'eccezione col `!**`.
* **Path relativo:**
Scrivi sempre il percorso binario assoluto (`/usr/bin/nmap`, `/bin/cat`, `/usr/bin/systemctl`). I percorsi relativi senza `/` vengono rifiutati da `visudo`.
