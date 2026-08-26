
# Capitolo 1: Gestione dei Servizi con `systemd` e Hardening della Configurazione

### 1.1 `systemd`: Il Cuore dello Spazio Utente

Nei moderni sistemi Linux, **`systemd`** è il sistema di inizializzazione (*init system*) incaricato di eseguire il bootstrap dello spazio utente e di supervisionare tutti i processi e i servizi di sistema e utente dopo l'avvio del kernel. Ha storicamente rimpiazzato i vecchi sistemi di init come *SysV* e *Upstart*.

Dal punto di vista della sicurezza, la gestione di `systemd` è un punto di controllo critico: i servizi di sistema vengono quasi sempre avviati con i massimi privilegi (**`root`**). Di conseguenza, un demone configurato male o vulnerabile rappresenta una via diretta per consentire a un attaccante locale di scalare i privilegi (*privilege escalation*).

---

### 1.2 `systemctl`: Controllo, Triage e Hardening

Lo strumento da riga di comando principale per interagire con `systemd` è **`systemctl`**, essenziale sia per monitorare lo stato del sistema sia per eseguire attività di diagnosi (*triage*) e irrobustimento (*hardening*).

* **Audit complessivo**: Eseguito senza argomenti, `systemctl` elenca tutte le unità attive (servizi, socket, punti di mount) e il relativo stato operativo, permettendo di individuare rapidamente anomalie o servizi non necessari in esecuzione.

* **Riduzione della superficie d'attacco**: La prima regola di hardening consiste nello spegnere e disabilitare tutto ciò che non è strettamente indispensabile per il funzionamento della macchina.

#### Comandi di gestione essenziali:

* `systemctl stop <servizio>`: Interrompe subito l'esecuzione di un servizio attivo.
* `systemctl disable <servizio>`: Rimuove l'avvio automatico del servizio al boot del sistema.
* `systemctl start <servizio>`: Avvia un servizio arrestato.
* `systemctl restart <servizio>`: Riavvia il processo del servizio.
* `systemctl status <servizio>`: Mostra lo stato dettagliato, il PID e le ultime righe di log utili per il debug.

---

### 1.3 Unit Files: Posizione e Gerarchia

Le risorse e i servizi gestiti da `systemd` sono definiti tramite file di testo detti **Unit Files** (es. `nginx.service`), contenenti variabili d'ambiente, comandi di avvio/arresto e dipendenze.

Per garantire l'integrità del sistema, i file sono organizzati secondo una precisa gerarchia di directory:

1. **`/lib/systemd/system/` (Predefiniti)**: Contiene le unità fornite dai pacchetti software installati. Questi file non vanno mai modificati direttamente.


2. **`/etc/systemd/system/` (Personalizzazioni Locali)**: È la directory riservata all'amministratore di sistema. Qualsiasi file o configurazione (*override*) inserito qui sovrascrive il file corrispondente presente in `/lib/`.

---

### 1.4 Ciclo di Vita delle Configurazioni e Controllo del Rischio

I servizi memorizzano i propri file di configurazione all'interno di `/etc/` (spesso in sottocartelle dedicate o con suffisso `*.d`).

Una modifica a un file di configurazione non viene applicata automaticamente in tempo reale: i servizi leggono la configurazione solo all'avvio o alla rilettura esplicita. Per evitare disservizi (*downtime*) e garantire la continuità operativa (**Disponibilità**), il flusso corretto da seguire è:

```text
[1. Modifica configurazione in /etc/] ──► [2. Test Sintattico/Logico] ──► [3. Reload o Restart]
```

1. **Modifica**: Si aggiornano i parametri nel file di configurazione in `/etc/`.
2. **Test preventivo**: Si valida la sintassi tramite gli strumenti dedicati del servizio (es. `nginx -t` o `apachectl configtest`) per scongiurare errori che impedirebbero il riavvio.
3. **Applicazione controllata**:
   - `systemctl reload <servizio>`: Ordina al processo di rileggere i file di configurazione **senza terminare i processi attivi**, preservando le connessioni degli utenti e la disponibilità del servizio.
   - `systemctl restart <servizio>`: Riavvia completamente il processo (da usare se il reload a caldo non è supportato).

---
Ecco la rielaborazione del **Capitolo 2**, strutturata con spiegazioni chiare, sintassi dettagliata ed esempi pratici per Obsidian.

---

# Capitolo 2: Gestione Utenti, Login e Database del Sistema (`/etc/passwd` e `/etc/shadow`)

In questo capitolo analizziamo i meccanismi che regolano l'accesso al sistema operativo Linux, la gestione delle identità e le protezioni applicate alle credenziali sul filesystem.

---

### 2.1 Il Flusso di Login e le Chiamate di Sistema

L'autenticazione di un utente segue un processo strutturato in 4 fasi operative:

```text
[1. Inserimento Credenziali] ──► [2. Verifica nei Database] ──► [3. Transizione Privilegi] ──► [4. Avvio Shell (execve)]
```

1. **Richiesta Credenziali**: L'utente inserisce username e password tramite interfaccia testuale o grafica.
2. **Verifica Database**: Il sistema calcola l'hash della password inserita e lo confronta con quello salvato in `/etc/shadow`.
3. **Transizione dei Privilegi (Fase Critica)**: Il processo di login parte con i privilegi di `root`. Una volta convalidate le credenziali, deve "spogliarsi" dei privilegi amministrativi e assumere l'identità dell'utente autenticato. Il kernel esegue due chiamate di sistema (*syscall*) fondamentali:
   - **`setreuid()`** (*Set Real and Effective User ID*): imposta l'UID numerico reale ed effettivo dell'utente.
   - **`setregid()`** (*Set Real and Effective Group ID*): imposta il GID numerico del gruppo.
1. **Avvio dell'Ambiente**: Impostati i permessi del processo, il sistema chiama **`execve`** per avviare l'interprete dei comandi (la shell, es. `/bin/bash`) o l'ambiente grafico dell'utente.

---

### 2.2 Anatomia di `/etc/passwd` (Metadati Utente)

Il file `/etc/passwd` è il database principale degli attributi di tutti gli account del sistema.

- **Requisito di accesso**: Deve essere **world-readable** (leggibile da chiunque, permessi `644`) perché utility come `ls -l` devono poter mappare gli UID numerici nei corrispondenti nomi utente.
- **Struttura della riga (7 campi separati da `:`)**:
  $$\text{username} : \text{password} : \text{UID} : \text{GID} : \text{GECOS} : \text{home\_dir} : \text{shell}$$
#### Esempio e analisi dei campi:
`username:x:1001:1001:User Name,,,:/home/username:/bin/bash`

1. **`username`**: Nome utente per il login.
2. **`password` (`x`)**: Storicamente conteneva l'hash. Oggi ospita un segnaposto `x` per compatibilità con i programmi legacy; l'hash reale è protetto in `/etc/shadow`.
3. **`UID`**: Identificativo numerico dell'utente. 
   - *Regola d'oro*: L'utente **`root` ha sempre `UID=0`**. Chiunque abbia UID pari a 0 viene trattato dal kernel come amministratore a tutti gli effetti.
1. **`GID`**: Identificativo numerico del gruppo primario.
2. **`GECOS` (`User Name,,,`)**: Informazioni anagrafiche opzionali (nome completo, telefono, ufficio).
3. **`home_dir` (`/home/username`)**: Percorso assoluto della cartella personale dell'utente.
4. **`shell` (`/bin/bash`)**: Percorso dell'eseguibile della shell avviata dopo il login.
   - *Nota di Hardening*: Gli account di servizio che non devono interagire via terminale (es. `www-data`) vengono configurati con `/bin/false` o `/usr/sbin/nologin`.

---

### 2.3 Il Database dei Gruppi: `/etc/group`

Anche `/etc/group` è leggibile da tutti e definisce l'elenco dei gruppi e l'assegnazione degli utenti ai gruppi secondari:
$$\text{nome\_gruppo} : \text{password\_gruppo} : \text{GID} : \text{lista\_utenti}$$

- *Esempio*: `sudo:x:27:username,mario` $\rightarrow$ il gruppo `sudo` (GID 27) include gli utenti `username` e `mario`, abilitandoli all'uso di `sudo`.

---

### 2.4 Anatomia di `/etc/shadow` (Riservatezza degli Hash)

Poiché `/etc/passwd` è accessibile a tutti, gli hash delle password sono stati spostati in `/etc/shadow`.

- **Permessi restrittivi**: Il file è leggibile solo da `root` (permessi `600` o `400`), proteggendo le password da tentativi di cracking offline (es. attacchi a dizionario o rainbow tables).
- **Formato dell'Hash**:
  $$\mathbf{\$\,\text{id}\,\$\,\text{salt}\,\$\,\text{hashedpassword}}$$
  - **`id` (Algoritmo)**: `$1$` indica MD5, `$5$` indica SHA-256, `$6$` indica SHA-512 (lo standard moderno).
  - **`salt`**: Valore casuale combinato con la password prima dell'hashing. Evita l'uso di rainbow table e fa sì che due password identiche generino hash completamente diversi sul disco.

#### I 9 Campi di `/etc/shadow`:
1. **Login name**: Nome utente.
2. **Encrypted password**: Stringa formattata come `$id$salt$hashedpassword`.
3. **Last change**: Giorni trascorsi dal 1° gennaio 1970 dall'ultima modifica password.
4. **Minimum age**: Giorni minimi prima di poter ricambiare la password.
5. **Maximum age**: Validità massima della password prima di doverla rinnovare (rotazione).
6. **Warning period**: Giorni di preavviso prima della scadenza.
7. **Inactivity period**: Giorni di tolleranza dopo la scadenza prima del blocco dell'account.
8. **Expiration date**: Data assoluta (in giorni dal 1970) di disattivazione permanente dell'account.
9. **Reserved**: Campo riservato.

---

### 2.5 Modifica Sicura e Prevenzione di Denial of Service (DoS)

Modificare manualmente `/etc/passwd` o `/etc/shadow` con editor come `nano` o `vim` è rischioso: un semplice errore di sintassi corrompe il database e impedisce a qualsiasi utente (incluso root) di autenticarsi, provocando un blocco totale del sistema (**DoS**).

Si usano sempre le **utility di sistema dedicate**, che gestiscono blocchi di concorrenza e controlli sintattici:
- `useradd` / `adduser`: Creazione utenti.
- `userdel` / `deluser`: Eliminazione utenti.
- `usermod`: Modifica attributi utente.
- `passwd`: Aggiornamento password e policy di scadenza.

---

### 2.6 Controllo Accessi a Livello Filesystem (Hardening)

- **Directory `/etc`**: Tutti possono leggere i file per conoscere le configurazioni, ma **solo `root` ha permessi di scrittura**. Se un utente ordinario potesse scrivere in `/etc`, potrebbe modificare file di configurazione dei servizi per forzare l'esecuzione di comandi malevoli ed eseguire privilege escalation.
- **Isolamento Home (`/home/username`)**: Le home directory devono essere inaccessibili agli altri utenti non privilegiati, garantendo l'isolamento dei dati personali e dei permessi.

---
# Capitolo 3: Autenticazione Avanzata e Pluggable Authentication Modules (PAM)

I sistemi Linux moderni devono autenticare gli accessi per numerosi programmi locali (come `login`, `su`, `sudo`, `ssh`) e servizi esterni (come database o web server), integrandosi con metodi differenti: database locali (`/etc/shadow`), server aziendali (LDAP, Active Directory) o autenticazione a più fattori (MFA).

Per evitare che ogni singola applicazione debba implementare nativamente il codice per ciascun metodo, Linux adotta l'architettura modulare **PAM (Pluggable Authentication Modules)**.

---

### 3.1 Cos'è PAM e Perché è Importante?

**PAM** fa da intermediario flessibile tra i programmi che richiedono autenticazione e i reali meccanismi sottostanti:

* **L'applicazione** si limita a interrogare le API di PAM per convalidare l'accesso.

* **L'amministratore** definisce le politiche di sicurezza modificando file di testo, senza dover ricompilare i programmi di sistema.

#### Vantaggi principali:

* **Modularità**: Possibilità di aggiungere o modificare metodi di verifica (es. token OTP o biometria) a caldo.

* **Centralizzazione**: Le regole di accesso sono definite in un unico punto per tutto il sistema.

* **MFA Semplificata**: Facilita l'integrazione di controlli a cascata su più fattori.

---

### 3.2 Struttura dei File di Configurazione

Le configurazioni PAM si trovano nella directory **`/etc/pam.d/`**, dove ogni servizio ha un file dedicato con il proprio nome (es. `/etc/pam.d/login`, `/etc/pam.d/sshd`, `/etc/pam.d/sudo`).

Le regole all'interno di un file formano uno *stack* (catena di moduli eseguiti in sequenza):

```text
# Esempio di stack PAM (servizio login)
auth       requisite  pam_securetty.so
auth       required   pam_nologin.so
auth       required   pam_env.so
auth       required   pam_unix.so nullok
account    required   pam_unix.so
session    required   pam_unix.so
session    optional   pam_lastlog.so
```

Ogni riga è composta da 3 elementi:
1. **Gruppo del Modulo (Management Group)**: L'ambito operativo.
2. **Flag di Controllo (Control Flag)**: Come il risultato del singolo modulo influisce sull'esito complessivo.
3. **Percorso del Modulo e Parametri**: La libreria `.so` da eseguire ed eventuali opzioni.

---

### 3.3 I Gruppi di Moduli (Management Groups)

- **`auth`**: Verifica l'identità dell'utente (richiesta e controllo di password o token).
- **`account`**: Esegue controlli non legati alle credenziali (es. account scaduto, orari di accesso consentiti).
- **`session`**: Gestisce le operazioni preliminari all'accesso o successive alla disconnessione (es. montaggio home dir, variabili d'ambiente, registrazione log).
- **`password`**: Gestisce l'aggiornamento e il cambio credenziali (es. forzatura di criteri di complessità).

---

### 3.4 Le Flag di Controllo (Control Flags)

- **`required`**: Il modulo **deve avere successo**. Se fallisce, l'autenticazione complessiva sarà respinta, ma **PAM prosegue comunque l'esecuzione dello stack** per evitare che un attaccante capisca quale controllo specifico ha fallito (prevenzione information leak).
- **`requisite`**: Se il modulo fallisce, **l'autenticazione viene interrotta immediatamente** con esito negativo, senza eseguire i moduli successivi.
- **`sufficient`**: Se ha successo (e nessun modulo `required` precedente è fallito), l'autenticazione viene approvata subito senza valutare il resto della catena.
- **`optional`**: Il risultato non è vincolante per l'accesso complessivo (usato per azioni secondarie, es. registrare statistiche o mostrare avvisi).

---

### 3.5 Moduli PAM Comuni

- **`pam_securetty.so`**: Impedisce il login diretto di `root` se non proviene da un terminale considerato sicuro (definito in `/etc/securetty`).
- **`pam_nologin.so`**: Blocca l'accesso a tutti gli utenti non-root se è presente il file temporaneo `/etc/nologin` (utile durante la manutenzione).
- **`pam_env.so`**: Imposta o rimuove le variabili d'ambiente specificate in `/etc/environment`.
- **`pam_unix.so`**: Gestisce l'autenticazione standard verificando gli hash in `/etc/shadow`. Con l'opzione `nullok` accetta anche account senza password impostata.
- **`pam_lastlog.so`**: Aggiorna e mostra data e ora dell'ultimo login riuscito dell'utente.

---
# Capitolo 4: Escalation dei Privilegi, `sudo` e il Principio del Minimo Privilegio (PoLP)

In Linux, l'utente **`root`** è l'amministratore supremo, dotato di poteri illimitati in grado di bypassare qualsiasi controllo dei permessi ed eseguire qualsiasi operazione sul sistema. Per questo motivo, gestire l'accesso amministrativo in modo sicuro è uno dei pilastri fondamentali dell'hardening.

---
### 4.1 I Rischi del Login Diretto come `root`

Effettuare il login diretto con l'account `root` è una pratica altamente sconsigliata:

* **Errori operativi catastrofici**: Uno sbaglio di digitazione (es. un comando distruttivo) viene eseguito all'istante senza alcuna richiesta di conferma o barriera di sicurezza.

* **Hardening predefinito**: Nelle moderne distribuzioni Linux, l'utente `root` viene configurato spesso senza password impostata nel database `/etc/shadow`. In questo modo si disabilita il login diretto con quell'account, forzando gli utenti ad accedere prima con la propria utenza nominale.

---
### 4.2 `sudo` e il Principio del Minimo Privilegio (PoLP)

Lo strumento standard per eseguire attività amministrative controllate è **`sudo` (superuser do)**. Permette a un utente autorizzato di **eseguire un singolo comando con i privilegi di un altro utente** (solitamente `root`), tornando immediatamente al livello di privilegi standard al termine del processo.

`sudo` permette di implementare in modo efficace il **Principle of Least Privilege (PoLP)**:

* **Concessione granulare**: Agli utenti vengono assegnati solo i permessi strettamente necessari per le loro mansioni operative, senza concedere una shell interattiva di `root` illimitata.

* **Contenimento dei danni**: Se l'account di un utente viene violato, l'attaccante si trova comunque confinato ai soli comandi concessi tramite `sudo`, impedendo la compromissione totale della macchina.

---
### 4.3 Tracciabilità e Responsabilità (Accountability)

Oltre a limitare i permessi, `sudo` garantisce la totale **tracciabilità delle operazioni**:

* **Logging sistematico**: Ogni richiesta di esecuzione con privilegi elevati viene registrata nei log di sistema.

* **Responsabilità individuale**: Poiché gli amministratori non condividono una singola password di `root` ma usano le proprie credenziali personali, in fase di analisi post-incidente (*forensic audit*) è sempre possibile risalire a quale utente ha eseguito una specifica modifica.

---

### 4.4 Configurazione di `/etc/sudoers` e Regole di Sicurezza

Le autorizzazioni concesse tramite `sudo` sono regolate dal file di configurazione **`/etc/sudoers`**.

#### Esempi di configurazione:

1. **Privilegi completi**:
```text
mario ALL=(ALL:ALL) ALL

```

Consente all'utente `mario` di eseguire qualsiasi comando impersonando qualsiasi utente o gruppo.

2. **Comando specifico (Applicazione del PoLP)**:
```text
username ALL=(root) /usr/bin/systemctl restart nginx

```

L'utente `username` può eseguire con privilegi di root **esclusivamente** il riavvio del servizio Nginx. Tentativi di aprire shell o visualizzare file riservati verranno bloccati e registrati nei log.

3. **Esecuzione senza password (`NOPASSWD`)**:
```text
mario ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart postfix

```

Permette l'esecuzione del comando senza richiedere la password di login (utile per script di automazione e monitoraggio).

> [!CAUTION] Regola Fondamentale di Modifica: `visudo`
> Non modificare mai `/etc/sudoers` con normali editor come `nano` o `vim`. È obbligatorio usare il comando dedicato **`visudo`**, che blocca il file per impedire scritture concorrenti e **valida la correttezza sintattica prima di salvare**. Un refuso in `/etc/sudoers` corrompe il funzionamento di `sudo`, bloccando l'accesso amministrativo all'intero sistema.
> 
> 

---
# Capitolo 5: Tracciabilità (Logging) e Network Hardening (SSH e Porte Aperte)

Questo capitolo affronta la registrazione degli eventi di sistema (indispensabile per monitoraggio e analisi forense) e le tecniche operative per proteggere i servizi di rete e ridurre la superficie d'attacco.

---
### 5.1 Importanza dei Log e Finalità di Sicurezza

Il logging rappresenta la vista principale sullo stato operativo del sistema operativo. Svolge tre ruoli cardine:

* **Tracciabilità (Accountability)**: associa in modo certo ogni azione critica all'utente o al processo che l'ha richiesta.

* **Rilevamento e Diagnostica**: permette di identificare in tempo reale guasti software o tentativi di intrusione (es. attacchi brute-force su SSH).

* **Analisi Forense**: consente di ricostruire la dinamica e la timeline di un incidente di sicurezza per individuare la vulnerabilità iniziale.

---
### 5.2 Modalità di Registrazione: `journald` vs Logging Diretto su File

In Linux coesistono principalmente due approcci di archiviazione dei log:

#### A. `journald` (Integrato in `systemd`)

* Raccoglie in modo automatico e centralizzato l'output standard (`stdout`) e gli errori (`stderr`) di tutti i servizi gestiti da `systemd`, oltre ai messaggi del kernel.

* Si consulta tramite il comando **`journalctl`**.

* *Esempio pratico per filtrare un servizio*: `journalctl -u nginx.service`.

#### B. Direct File Logging (`/var/log`)

* Molte applicazioni e daemon complessi scrivono i propri registri direttamente su file nel filesystem.

* La directory convenzionale è **`/var/log`**.

---

### 5.3 Gestione dello Spazio Disco e Ispezione Sicura dei Log

Se non controllati, i log possono saturare il disco e bloccare l'intero sistema operativo, provocando una vera e propria **Denial of Service (DoS)** infrastrutturale.

* **Rotazione automatica con `logrotate`**: archivia a intervalli regolari i log correnti, li comprime (spesso in formato `.gz`), mantiene solo un numero limitato di storici ed elimina i file più vecchi.

* **Ispezione sicura da riga di comando**: non aprire mai file di log giganti con editor come `nano` o `vim` per non saturare la memoria RAM (rischio crash/DoS). Usare invece utility di streaming e filtraggio:

	* `tail -f <file>`: segue l'output e mostra in tempo reale le ultime righe aggiunte.
	
	* `head -n 20 <file>`: visualizza le prime 20 righe iniziali.
	
	* `grep <pattern> <file>`: estrae istantaneamente solo le righe che contengono una parola chiave specifica senza caricare l'intero file in memoria.
	
	* `less <file>`: permette di scorrere il file in modo leggero e paginato.

---
### 5.4 Hardening di SSH (Secure Shell)

Il servizio SSH opera di default sulla **porta 22** e consente la gestione remota della macchina. Essendo un punto di ingresso privilegiato, è il bersaglio principale di attacchi via rete.

* **Crittografia forte**: cifra il canale di comunicazione proteggendo credenziali e comandi da intercettazioni (MitM).

* **Disabilitazione password**: le password sono vulnerabili ad attacchi a dizionario e forza bruta. La contromisura standard consiste nel disabilitare l'accesso con password nel file di configurazione (`/etc/ssh/sshd_config`).

* **Autenticazione a Chiave Pubblica**: forzare l'uso esclusivo di coppie di chiavi asimmetriche (es. Ed25519 o RSA robuste), azzerando il rischio di violazione tramite brute-force.

---

### 5.5 Gestione delle Porte e Riduzione della Superficie d'Attacco

Ogni porta aperta con un servizio in ascolto rappresenta un potenziale vettore d'attacco.

#### 1. Spegnere i servizi superflui

La prima linea di difesa non è il firewall ma la disattivazione del servizio stesso: un demone disabilitato e spento non può essere sfruttato da un attaccante.

#### 2. Binding dell'indirizzo di ascolto

Configurare con precisione l'interfaccia di rete su cui il servizio accetta connessioni:

* `0.0.0.0` (o `::`): accetta connessioni da **qualsiasi interfaccia**, compresa la rete pubblica Internet (da usare solo per servizi che devono essere esposti a tutti, come un web server pubblico).

* `127.0.0.1` (Loopback): limita le connessioni **esclusivamente alla macchina locale**. I servizi interni (come un database che deve parlare solo con l'applicazione locale) devono essere vincolati su `127.0.0.1` per fare in modo che il kernel rifiuti sul nascere qualsiasi richiesta proveniente dall'esterno.

#### 3. Audit delle porte aperte con `netstat`

Per verificare quali processi occupano porte di rete si esegue periodicamente:
```bash
netstat -tulnp
```

- `-t`: mostra le connessioni e porte TCP.
- `-u`: mostra le porte UDP.
- `-l`: filtra solo i socket in ascolto (*listening*).
- `-n`: visualizza IP e porte in formato numerico (evitando rallentamenti dovuti alla risoluzione DNS).
- `-p`: mostra il nome del programma e il PID del processo associato (richiede privilegi amministrativi).

---
