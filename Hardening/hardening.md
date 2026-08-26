# Prerequisiti per la Sicurezza di un Server

Questi URL potrebbero essere utili per l’argomento hardening dei sistemi:

*   [Server Fault](https://serverfault.com/)
*   [Unix & Linux Stack Exchange](https://unix.stackexchange.com/)
*   [0xdf](https://0xdf.gitlab.io/tags)
*   [Local File Inclusion (LFI) - Web Application Penetration Testing](https://medium.com/@Aptive/local-file-inclusion-lfi-web-application-penetration-testing-cc9dc8dd3601)
*   [iptables Generator](https://iptablesgenerator.totalbits.com/)
*   [Fluid Attacks Knowledge Base](https://help.fluidattacks.com/portal/en/kb/criteria)

## Check e Analisi della Macchina

**Scopo:** Mettere in sicurezza il server analizzando servizi attivi, configurazioni e log.

I servizi sono demoni che operano in background; alcuni obbligatori, altri opzionali (es.: SSH obbligatorio, server FTP opzionale).

### Gestione dei Servizi con `systemctl`

Funzioni principali: avvio, riavvio, gestione e log dei servizi.

*   **Unit:** un servizio, mount point, device o socket.
*   **Principali comandi:**
    *   `systemctl start/stop/restart <service>`: avvio/arresto/riavvio di un servizio.
    *   `systemctl enable/disable <service>`: attivazione/disattivazione all’avvio.
    *   `systemctl status <service>`: stato del servizio.
    *   `systemctl list-units --type=service`: elenca i servizi attivi.
*   **Stati dei servizi:**
    *   `Active`: attivo e in esecuzione.
    *   `Exited`: terminato correttamente.
    *   `Loaded`: configurato ma non attivo.
*   **Configurazioni:** i file di configurazione si trovano in `/etc`, mentre le configurazioni di default sono in `/lib/systemd/system`.

### File System e Permessi

La cartella `/etc` contiene i file di configurazione (solo root può modificarli).

*   **Permessi:** `rwx` per root, `r--` per altri.
*   **Per modificare un file di configurazione:**
    1.  Modifica del file.
    2.  Test di sintassi (es.: `nginx -t`).
    3.  Reload/restart del servizio (`systemctl reload <service>`).

### Gestione Utenti e PAM

*   **File principali:**
    *   `/etc/passwd`: elenco utenti (leggibile da tutti).
    *   `/etc/shadow`: password (accessibile solo a root).
    *   `/etc/group`: gruppi (leggibile da tutti).
*   **Comandi:**
    *   Aggiunta utenti: `useradd`, `adduser`.
    *   Rimozione utenti: `userdel`, `deluser`.
    *   Modifica utenti: `usermod`, `passwd`.
*   **PAM (Pluggable Authentication Modules):**
    *   Centralizza l’autenticazione dei servizi (es.: SSH, Samba).
    *   Configurazioni in `/etc/pam.d`.
    *   Personalizzabile per adattare le regole di login e accesso.

### Comando SUDO e File sudoers

Permette di eseguire comandi come root mantenendo traccia delle attività.

*   **Configurazione tramite il comando `visudo`:**
    *   Bloccare comandi specifici:
        ```bash
        utente1 ALL=(ALL) ALL, !/bin/rm
        ```
    *   Concedere accesso a comandi specifici:
        ```bash
        utente1 ALL=(ALL) /usr/bin/apt, /usr/bin/systemctl
        ```
    *   Limitare directory:
        ```bash
        utente1 ALL=(ALL) ALL, !/bin/rm -rf /etc/*
        ```
    *   Alias per comandi:
        ```bash
        Cmnd_Alias PERMESSI_BASE = /usr/bin/apt, /usr/bin/systemctl
        ```
*   **Best practice:** non permettere sudo su o accesso root diretto.

### Logging

I log sono gestiti da systemd e consultabili con `journalctl -u <service>`.

*   **Strumento di gestione log:** `logrotate` (esempio di configurazione richiesto).
*   **Importanza:** evitare che i log occupino troppo spazio disco.

### Sicurezza di Rete e Firewall

*   **Verifica delle porte aperte:**
    *   Comando: `netstat -tulnp`.
    *   **Porte bindate:**
        *   `0.0.0.0`: accessibile da tutti.
        *   `127.0.0.1`: solo locale.
*   **Livelli di protezione:**
    *   Fisico: cifratura, isolamento.
    *   Link: VLAN, crittografia.
    *   IP: NAT, screening router.
    *   Trasporto: firewall stateful.
    *   Applicazione: gateway.
*   **Firewall: Linux Netfilter**
    *   **Componenti:**
        *   **Tabelle:** `filter` (input/output/forward), `nat` (prerouting, postrouting), `mangle` (tag pacchetti).
        *   **Catene:** `input`, `output`, `forward`.
        *   **Regole:**
            *   **Parametri:** protocollo (`-p`), indirizzo sorgente/destinazione (`-s`, `-d`), porte (`--sport`, `--dport`).
            *   **Target:** `accept`, `drop`, `reject` (es.: avviso ICMP).
    *   **Comandi principali:**
        *   `iptables -nvL`: elenca le regole attive.
        *   `iptables -A`: aggiunge una regola.
        *   `iptables-save`: salva la configurazione.
        *   `iptables-restore`: ripristina una configurazione.

### Vulnerability Assessment e Hardening

*   **Task di sicurezza:**
    *   Check servizi/processi attivi.
    *   Verifica dei permessi file e utenti.
    *   Analisi porte aperte e firewall.
    *   Monitoraggio dei log.
*   **Principi di hardening:**
    *   Minima esposizione (es.: chiudere porte non necessarie).
    *   Least privilege (es.: limitare i permessi root).
    *   Compartimentalizzazione e tracciabilità (es.: log auditing).
*   **Azioni concrete:**
    *   Proteggere servizi critici con firewall/proxy.
    *   Ridurre i privilegi utenti/gruppi (es.: sudoers).
    *   Configurare regole firewall di base:
        ```bash
        iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A FORWARD -i eth0 -o eth1 -m state --state NEW -j ACCEPT
        ```
    *   Effettuare vulnerability assessment periodico.

### SSH

*   Algoritmi di crittografia avanzati.
*   **Modalità di autenticazione:**
    *   Password (default).
    *   Chiave privata/pubblica (più sicura).

### Esempi e Configurazioni Richiesti

*   Configurazioni di `logrotate`.
*   Regole firewall aggiuntive.
*   Esempio di configurazione PAM.
*   Configurazione per limitare accesso con `sudoers`.

# Analisi di Sicurezza e Gestione di Permessi

Questo documento descrive diverse tecniche relative alla sicurezza di sistema, tra cui l'escalation di privilegi tramite setuid, la ricerca e rimozione di bit setuid, l'assegnazione di capabilities e l'analisi di server web con `testssl.sh`.

## Escalation di Privilegi con `os.system("/bin/sh -p")`

**Spiegazione:**

Questo comando esegue codice Python inline (`-c`). Il codice importa il modulo `os` e utilizza la funzione `os.system()` per eseguire un comando di sistema, in questo caso `/bin/sh -p`.

*   `python -c`: Esegue il codice Python specificato come stringa.
*   `import os`: Importa il modulo `os`, che fornisce funzioni per interagire con il sistema operativo.
*   `os.system("/bin/sh -p")`: Esegue il comando `/bin/sh -p`.
    *   `/bin/sh`: Invocazione della shell di sistema (solitamente Bash o un suo equivalente).
    *   `-p`: Questa opzione è cruciale per l'escalation di privilegi. Indica alla shell di non resettare i privilegi effettivi (UID e GID) all'UID e GID reali. Questo è importante quando si esegue un programma con il bit setuid impostato. In pratica, se il programma Python ha il bit setuid attivo (cioè, viene eseguito con i privilegi del proprietario del file, tipicamente root), la shell manterrà i privilegi di root.

**Scopo:**

Questo comando viene tipicamente utilizzato per ottenere una shell con privilegi elevati (ad esempio, root) sfruttando un programma Python con il bit setuid attivo.

## Trovare File con Bit Setuid Attivo

**Comando:**

```bash
find / \
  -type f \
  -perm -u=s \
  2>/dev/null
```

**Spiegazione:**

Questo comando cerca tutti i file con il bit setuid attivo.

*   `find /`: Cerca a partire dalla directory root (`/`).
*   `-type f`: Specifica di cercare solo file (non directory, link simbolici, ecc.).
*   `-perm -u=s`: Cerca file con il bit setuid attivo. `-u=s` è la notazione simbolica per il bit setuid.
*   `2>/dev/null`: Redireziona l'output degli errori (stderr, file descriptor 2) a `/dev/null`, sopprimendo i messaggi di errore (ad esempio, permessi negati).

**Scopo:**

Trovare rapidamente tutti i file eseguibili che potrebbero essere utilizzati per escalation di privilegi a causa del bit setuid.
*Importante:* Eseguire questo comando con privilegi di root (tramite `sudo`) fornirà risultati più completi, poiché altrimenti si potrebbero non avere i permessi per accedere a tutte le directory del filesystem.

## Rimuovere il Bit Setuid

**Comando:**

```bash
sudo chmod u-s /usr/bin/python3.9
```

**Spiegazione:**

Questo comando rimuove il bit setuid dal file eseguibile `python3.9`.

*   `sudo`: Esegue il comando con privilegi di root.
*   `chmod u-s`: Modifica i permessi del file. `u-s` significa "rimuovi il bit setuid all'utente proprietario".
*   `/usr/bin/python3.9`: Il percorso del file eseguibile di Python.

**Scopo:**

Mitigare un potenziale rischio di sicurezza disattivando il bit setuid su un eseguibile che non dovrebbe averlo.

## Assegnare Capabilities a un Binario

**Comando:**

```bash
sudo setcap CAP_NET_BIND_SERVICE=+eip /path/to/binary
```

**Spiegazione:**

Questo comando utilizza `setcap` per assegnare una capability specifica a un binario.

*   `sudo`: Esegue il comando con privilegi di root.
*   `setcap CAP_NET_BIND_SERVICE=+eip`: Imposta la capability `CAP_NET_BIND_SERVICE`.
    *   `CAP_NET_BIND_SERVICE`: Permette al binario di associare socket a porte con numeri inferiori a 1024 (porte privilegiate).
    *   `+eip`: Significa "effective, inherited, permitted", impostando la capability in tutti e tre i set.
*   `/path/to/binary`: Il percorso del file binario a cui assegnare la capability.

**Scopo:**

Permettere a un programma non root di utilizzare porte privilegiate senza dover essere eseguito come root. Questo è un approccio di sicurezza più granulare rispetto all'uso del bit setuid.

## Analisi di un Server Web con `testssl.sh`

**Accesso al Server Web:**

Accedi al browser e naviga su `http://server.secureflag/`.

**Scopo:**

Verificare il funzionamento del server web e visualizzare la pagina predefinita.

**Scansione con `testssl.sh`:**

**Comando:**

```bash
testssl.sh -n none --quiet -s -p https://server.secureflag
```

**Spiegazione:**

Questo comando esegue una scansione di sicurezza su un server web utilizzando lo strumento `testssl.sh`.

*   `testssl.sh`: Invocazione dello script.
*   `-n none`: Disabilita la risoluzione DNS inversa.
*   `--quiet`: Modalità silenziosa, mostra solo i risultati essenziali.
*   `-s`: Esegue solo i test relativi ai cipher.
*   `-p`: Esegue solo i test relativi ai protocolli.
*   `https://server.secureflag`: L'URL del server da analizzare.
