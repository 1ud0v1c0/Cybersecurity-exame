# Guida Pratica: Connessione SSH alla VM VirtualBox (Esame Cybersecurity)

Questa guida serve per collegarsi dal terminale del PC host (computer del laboratorio) alla macchina virtuale VirtualBox dell'esame.  
Permette di:
* **Copiare e incollare** comandi, payload e script senza limitazioni di clipboard della finestra VM.
* **Trasferire file, script e regole** (es. `iptables`, exploit, wordlist) bidirezionalmente tra Host e Guest.
* Lavorare comodamente con i tool e le finestre del terminale dell'host.

---

## Indice Rapido
1. [Metodo Principale: Scheda NAT + Port Forwarding (99% dei casi)](#1-metodo-principale-scheda-nat--port-forwarding)
2. [Scorciatoia CLI: Port Forwarding con VBoxManage](#2-scorciatoia-rapida-port-forwarding-via-linea-di-comando-vboxmanage)
3. [Metodo Alternativo: Rete Bridge o Scheda Solo Host](#3-metodo-alternativo-rete-bridge-o-scheda-solo-host)
4. [Trucchi Pro per l'Esame (Config Rapida & No Password)](#4-trucchi-pro-per-risparmiare-tempo-allesame)
5. [Trasferimento File Host $\leftrightarrow$ VM (SCP)](#5-trasferimento-file-host-%E2%86%94-vm-scp)
6. [Risoluzione Problemi & Errori Comuni (Troubleshooting)](#6-risoluzione-problemi--errori-comuni)

---

## 1. Metodo Principale: Scheda NAT + Port Forwarding

È la configurazione predefinita e più affidabile nei laboratori universitari.

### Passo 1: Configura il Port Forwarding su VirtualBox
1. Apri **VirtualBox** sul PC host.
2. Clicca con il tasto destro sulla VM dell'esame $\rightarrow$ **Impostazioni** *(funziona anche a VM già avviata)*.
3. Seleziona **Rete** $\rightarrow$ **Scheda 1** (verifica che sia *Connessa a: NAT*).
4. Espandi **Avanzate** $\rightarrow$ clicca sul pulsante **Inoltro delle porte** (Port Forwarding).
5. Clicca sull'icona verde **`+`** (Aggiungi nuova regola) e imposta:

| Campo | Valore | Note |
| :--- | :--- | :--- |
| **Nome** | `SSH` | Nome arbitrario |
| **Protocollo** | `TCP` | Protocollo SSH |
| **IP Host** | `127.0.0.1` | Loopback locale dell'host |
| **Porta Host** | `2222` | Porta libera sull'host *(se occupata usa `2200` o `22222`)* |
| **IP Guest** | *(vuoto)* | Lasciare completamente bianco |
| **Porta Guest** | `22` | Porta standard demone SSH nella VM |

6. Conferma cliccando **OK** e poi nuovamente **OK**.

---

### Passo 2: Avvia la VM
1. Seleziona la VM e clicca su **Avvia** (se non è già in esecuzione).
2. Attendi il completamento del boot fino alla schermata di login o al desktop.

---

### Passo 3: Collegati dal Terminale Host
1. Apri una nuova finestra di **Terminale sul PC Host** (fuori da VirtualBox).
2. Esegui il comando di connessione:
   ```bash
   ssh -p 2222 <UTENTE>@127.0.0.1
   ```
   *(Sostituisci `<UTENTE>` con l'utente fornito all'esame, ad esempio: `studente`, `debian` o `root`)*:
   ```bash
   ssh -p 2222 studente@127.0.0.1
   ```

3. **Primo avviso di sicurezza (Fingerprint):**  
   Se compare il messaggio:
   ```text
   The authenticity of host '[127.0.0.1]:2222' can't be established.
   Are you sure you want to continue connecting (yes/no/[fingerprint])?
   ```
   digita `yes` e premi **Invio**.

4. **Autenticazione:**  
   Inserisci la password dell'utente *(a video non compariranno asterischi né caratteri: è normale)* e premi **Invio**.

> [!TIP]
> **Sei collegato!** Tutto ciò che esegui in questa sessione di terminale viene processato direttamente dentro la VM.

---

## 2. Scorciatoia Rapida: Port Forwarding via Linea di Comando (`VBoxManage`)

Se preferisci evitare i menu grafici di VirtualBox o se la GUI è bloccata, puoi aggiungere la regola direttamente da terminale host:

```bash
# Se la VM è GIÀ ACCESA:
VBoxManage controlvm "<NOME_VM>" natpf1 "SSH,tcp,127.0.0.1,2222,,22"

# Se la VM è SPENTA:
VBoxManage modifyvm "<NOME_VM>" --natpf1 "SSH,tcp,127.0.0.1,2222,,22"
```

*(Per conoscere il nome esatto della VM esegui: `VBoxManage list vms`)*.

---

## 3. Metodo Alternativo: Rete Bridge o Scheda Solo Host

Se la VM è impostata con *Scheda con bridge* (Bridged) o *Scheda solo host* (Host-Only), la VM ottiene un IP dedicato nella subnet locale:

1. Apri la console direttamente nella finestra di VirtualBox.
2. Esegui il comando per trovare l'indirizzo IPv4 della VM:
   ```bash
   ip a
   # oppure
   hostname -I
   ```
3. Individua l'IP associato all'interfaccia di rete principale (es. `192.168.x.x` o `10.x.x.x`).
4. Dal terminale dell'Host collegati direttamente senza specificare la porta 2222:
   ```bash
   ssh <UTENTE>@<IP_TROVATO>
   ```

---

## 4. Trucchi Pro per Risparmiare Tempo all'Esame

Durante una prova pratica il tempo è prezioso. Puoi automatizzare la connessione in meno di un minuto.

### A. Creare un Alias SSH (`~/.ssh/config`)
Sul terminale del **PC Host**, apri o crea il file `~/.ssh/config`:
```bash
nano ~/.ssh/config
```
Incolla questa configurazione:
```ssh
Host vm
    HostName 127.0.0.1
    Port 2222
    User studente
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```
Ora ti basta digitare semplicemente:
```bash
ssh vm
```
senza dover ricordare porte, IP o incorrere in errori di fingerprint!

---

### B. Accesso Senza Password (Chiave SSH)
Per non inserire la password a ogni riconnessione:
```bash
# 1. Genera una coppia di chiavi sull'Host (premi Invio a tutte le richieste):
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_esame

# 2. Copia la chiave pubblica sulla VM:
ssh-copy-id -i ~/.ssh/id_esame.pub -p 2222 studente@127.0.0.1

# 3. Connettiti direttamente senza password:
ssh -i ~/.ssh/id_esame -p 2222 studente@127.0.0.1
```

---

## 5. Trasferimento File Host $\leftrightarrow$ VM (SCP)

I comandi `scp` vanno eseguiti **dal terminale del PC Host**:

### Inviare un file dall'Host alla VM
```bash
# Sintassi: scp -P <PORTA> <FILE_HOST> <UTENTE>@127.0.0.1:<PERCORSO_VM>
scp -P 2222 ./regole_firewall.sh studente@127.0.0.1:~/

# Per copiare un'intera cartella (flag -r):
scp -P 2222 -r ./scripts/ studente@127.0.0.1:~/
```

### Scaricare un file dalla VM all'Host (es. dump, report o log)
```bash
# Sintassi: scp -P <PORTA> <UTENTE>@127.0.0.1:<FILE_VM> <DESTINAZIONE_HOST>
scp -P 2222 studente@127.0.0.1:/var/log/auth.log ./auth_analisi.log
```

---

## 6. Risoluzione Problemi & Errori Comuni

### 1. `ssh: connect to host 127.0.0.1 port 2222: Connection refused`
Questo errore indica che nessun servizio sta rispondendo sulla porta 2222 dell'host:
* **Causa A: Il demone SSH non è attivo nella VM**  
  Entra nella console di VirtualBox ed esegui:
  ```bash
  sudo systemctl status ssh
  # Se inattivo o spento, avvialo con:
  sudo systemctl restart ssh
  # Su sistemi Debian più vecchi o leggeri:
  sudo service ssh restart
  ```
* **Causa B: Il pacchetto OpenSSH Server non è installato**  
  Dalla console della VM:
  ```bash
  sudo apt update && sudo apt install -y openssh-server
  sudo systemctl enable --now ssh
  ```
* **Causa C: Porta 2222 già occupata sull'Host**  
  Cambia la **Porta Host** nelle impostazioni di inoltro porte di VirtualBox (es. usa `2223`) e connettiti con `ssh -p 2223 ...`.

---

### 2. `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`
Accade frequentemente se la VM è stata riavviata da uno snapshot o se le chiavi host sono state rigenerate.  
Per pulire la vecchia chiave dalla cache dell'host, esegui **sul PC Host**:
```bash
ssh-keygen -R "[127.0.0.1]:2222"
```
Poi rilancia il comando `ssh -p 2222 ...`.

---

### 3. `Permission denied (publickey,password)`
* Verifica di aver digitato correttamente nome utente e password (attenzione a `Caps Lock` o layout tastiera US/IT).
* Se stai provando a entrare come `root`, Debian di default vieta l'accesso root via password.  
  Entra prima come utente normale (`studente`), poi fai:
  ```bash
  su -
  # oppure
  sudo -i
  ```
  *(Se necessario abilitare root: modifica `/etc/ssh/sshd_config` impostando `PermitRootLogin yes` e riavvia ssh con `sudo systemctl restart ssh`)*.

---

### 4. Lockout da Firewall (`iptables`)
Durante le prove di hardening o firewall, se applichi una regola errata:
```bash
sudo iptables -P INPUT DROP
```
senza consentire preventivamente il traffico sulla porta 22 (`-p tcp --dport 22 -j ACCEPT`) o le connessioni già stabilite (`-m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT`), **la sessione SSH si bloccherà all'istante**.

**Come sbloccarsi:**
1. Torna alla finestra grafica di VirtualBox.
2. Apri il terminale della console locale della VM.
3. Resetta immediatamente il firewall con un flush:
   ```bash
   sudo iptables -P INPUT ACCEPT
   sudo iptables -P OUTPUT ACCEPT
   sudo iptables -F
   ```
4. La connessione SSH dal terminale host tornerà immediatamente operativa.
