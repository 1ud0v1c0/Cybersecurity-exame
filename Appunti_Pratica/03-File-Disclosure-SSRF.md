# Capitolo 1: File Disclosure — Introduzione, Impatto e Punti Vulnerabili (Sinks)

### 1.1 Definizione di File Disclosure (Impatto vs Vulnerabilità)

La **File Disclosure** (o *Information Disclosure via File*) non è una vulnerabilità a sé stante, ma l'**impatto** (conseguenza) derivante dallo sfruttamento di una debolezza nel sistema. Consiste nell'estrazione o lettura non autorizzata di file residenti sul filesystem del server.

Le cause scatenanti possono essere molteplici:
* **Path Traversal / LFI** (Local File Inclusion).
* **Remote Code Execution (RCE)** (es. esecuzione di comandi di lettura come `cat`).
* **Misconfiguration del Web Server** (es. directory listing attivo, errato mapping MIME).

---
### 1.2 Impatto Pratico: Dati a Rischio

L'esposizione di file sul server compromette diversi livelli dell'infrastruttura:

* **File Utente (User Data)**: Documenti, fatture, referti, immagini personali. Comporta impatti legali immediati (violazione GDPR / Privacy).

* **Configurazioni e Segreti di Sistema**:
	* *Credenziali DB*: Password in chiaro per l'accesso diretto ai database.
	* *Pannelli di Gestione*: File come `tomcat-users.xml` per ottenere accessi amministrativi.
	* *Secret Keys di Sessione*: Chiavi segrete (es. Flask `SECRET_KEY`, machine key in `.NET`) che permettono il forging dei cookie di sessione per impersonare qualsiasi utente (Account Takeover).

* **Codice Sorgente dell'Applicazione**:
	* Analisi della logica applicativa comodamente offline (White-box review).
	* Rottura del paradigma della *Security by Obscurity*, esponendo bug logici e ulteriori vulnerabilità nascoste.

---

### 1.3 I Sinks Triviali (Funzioni Native di File System)

Un **sink** è il punto di arrivo nel codice: una funzione interna potenzialmente pericolosa se alimentata con input non controllato (*tainted source*). I sink triviali sono le funzioni native dedicate all'I/O sui file.

| Linguaggio / Framework | Funzioni Vulnerabili (Sinks)                                                                   | Note                                       |
| ---------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------ |
| **PHP**                | `fopen()`, `file_get_contents()`, `readfile()`, `file()`, `exif_read_data()`, `getimagesize()` | Include anche funzioni di parsing metadati |
| **Python (Flask)**     | `open()`, `send_file()`, `send_from_directory()`                                               | Invio file al client                       |
| **Node.js**            | `fs.readFile()`, `fs.readFileSync()`, `fs.createReadStream()`                                  | Modulo nativo filesystem                   |

---

### 1.4 I Sinks Meno Triviali (Canali Non Convenzionali)

* **Uso Improprio di cURL (Wrapper Protocol `file://`)**:
	cURL gestisce nativamente molteplici protocolli. Se l'input dell'utente controlla l'URL passato a `curl_init()`, l'attaccante può specificare lo schema `file://` invece di `http://`:

```php
// Codice Vulnerabile
$url = $_GET['url']; // Payload: file:///etc/passwd
$fd = curl_init($url);
echo curl_exec($fd); // Esegue il dump del file locale nella risposta HTTP

```

* **Directory `.git` Esposta Pubblicamente**:
	Copia accidentale della cartella `.git` in produzione. Tramite strumenti come `git-dumper`, chiunque acceda a `http://target.com/.git/` può ricostruire l'intero albero del codice sorgente e la cronologia dei commit.

* **Web-Server Misrouting (Mancata esecuzione script)**:
	Errori nelle direttive del server (Apache/Nginx) per cui l'interprete (es. PHP-FPM) non processa il file richiesto, servendolo invece come file statico (`text/plain`), esponendo il codice PHP in chiaro.

---

# Capitolo 2: L'Attacco Path Traversal — Concetti dei Percorsi e Casi di Iniezione

Il **Path Traversal** (o *Directory Traversal*) è la vulnerabilità specifica che si verifica quando un input non sanificato raggiunge una funzione di filesystem (sink), consentendo a un attaccante di manipolare il percorso per accedere a file e directory al di fuori del contesto previsto dall'applicazione.

---

### 2.1 Concetti Fondamentali sui Percorsi (Paths 101)

* **Percorso Assoluto (*Absolute Path*)**: Specifica la posizione esatta a partire dalla radice (`/` su sistemi Unix/Linux o `C:\` su Windows), indipendentemente dalla *working directory* corrente.
	*Esempio:* `/etc/passwd`

* **Percorso Relativo (*Relative Path*)**: Specifica la posizione a partire dalla directory corrente di esecuzione del processo.
	*Esempio:* `uploads/images/photo.jpg`

**Anatomia di un Percorso**:
* **Dirname**: Porzione del percorso fino all'ultimo separatore `/` (es. in `/var/www/index.php` il dirname è `/var/www`).
* **Basename**: Nome della risorsa dopo l'ultimo separatore `/` (es. `index.php`).
	![[Screenshot 2026-08-19 alle 15.13.58 1.png|344]]

**Directory Speciali di Navigazione**:
* `.` (punto singolo): Fa riferimento alla directory **corrente**.
* `..` (doppio punto): Fa riferimento alla directory **padre** (*parent directory*), permettendo di risalire la gerarchia del filesystem.

---

### 2.2 Path Traversal e Normalizzazione dei Percorsi

Il **Path Traversal** (o *Directory Traversal*) si verifica quando un input utente non sanificato viene concatenato a un percorso base e passato a funzioni di filesystem (`open()`, `fopen()`, `file_get_contents()`).

La vulnerabilità esiste e ha successo proprio perché il sistema operativo **normalizza i percorsi**: invece di trattare il percorso come un semplice testo vincolato alla cartella base, Il sistema operativo "semplifica" il percorso fino alla sua destinazione reale, permettendo all'attaccante di scavalcare i limiti della cartella dell'applicazione ed entrare nei file protetti del server. (es. `/var/www/uploads/../../../etc/passwd` $\rightarrow$ `/etc/passwd`).

##### I Meccanismi di Risoluzione del Filesystem
* **Risalita con `../`:** Istruisce il filesystem a risalire alla directory padre (*parent directory*), "cancellando" virtualmente il segmento precedente nella gerarchia.
* **Attraversamento della Root (`/`):** L'iniezione di sequenze ridondanti (es. `../../../../`) garantisce l'atterraggio nella directory radice `/`, poiché i tentativi di risalire oltre la root vengono ignorati dai sistemi operativi senza sollevare errori.
* **Eliminazione delle Ridondanze:** Il processo di normalizzazione rimuove elementi sintattici neutri come `./` (directory corrente) e `//` (barre multiple), trasformando qualsiasi percorso relativo o ridondante nel rispettivo percorso assoluto effettivo e annullando il prefisso imposto dall'applicazione.

##### L'Insidia della Risoluzione: Sintattica vs Kernel
Se un payload include directory intermedie inesistenti (es. `/foo/non_esisto/../bar`), l'esito dell'attacco dipende da *dove* e *quando* viene risolto il path:

* **Risoluzione Sintattica Preventiva (Libreria / Runtime):**
	La stringa viene manipolata a livello puramente logico prima della system call. La porzione `/non_esisto/..` viene rimossa a priori, convertendo il percorso in `/foo/bar` $\rightarrow$ l'inesistenza fisica della directory viene ignorata e l'exploit ha **successo**.
* **Risoluzione Diretta (Kernel OS):**
	Il kernel esegue la system call tentando di validare l'inode di ogni singola directory in sequenza prima di interpretare `..` $\rightarrow$ l'accesso fallisce immediatamente con errore `ENOENT` (*No such file or directory*) non appena incontra `/foo/non_esisto/`.
---

### 2.3 Casi di Iniezione (Scenari d'Esame)

A seconda di come lo sviluppatore concatena la variabile utente (`$input`) con il percorso di base, si presentano quattro scenari:

* **1. Iniezione Semplice (*Plain*)**:
	L'input controlla interamente il parametro del sink.
```php
open($input); // Payload: "/etc/passwd" o "../../../etc/passwd"
```

* **2. Iniezione Prepend**:
	L'applicazione aggiunge una stringa fissa *dopo* l'input controllato dall'utente.
```php
open($input . '/config.php'); // Payload: "/var/secret" -> apre "/var/secret/config.php"
```

* **3. Iniezione Append**:
	L'applicazione confina l'input concatenandolo *dopo* una directory base prefissata.
```php
open('/var/www/uploads/' . $input); // Payload: "../../etc/passwd"
```

* **4. Iniezione Append e Prepend (Combinata)**:
	L'input è racchiuso tra un prefisso di percorso e un suffisso fisso (spesso un'estensione).
```php
open('/var/www/templates/' . $input . '.html');
```

> Nei sistemi moderni richiede tecniche come il *Path Truncation* (su versioni legacy) o la ricerca di file che condividano la medesima estensione prefissata.

---

# Capitolo 3: Server-Side Request Forgery (SSRF) — Funzionamento ed Impatto

Il **Server-Side Request Forgery (SSRF)** è una vulnerabilità web in cui l'attaccante **costringe il server vittima a fare richieste di rete al posto suo**.

se un server può scaricare link o contattare altri serveer, l'attaccante lo "inganna" facendogli visitare indirizzi che dall'esterno sarebbero vietati. (diventa un **proxy/ponte** involontario)

![[Screenshot 2026-08-19 alle 15.40.34 1.png|332]]

---

### 3.1 Definizione e Livelli di Controllo

A seconda del punto di iniezione e della logica applicativa, l'attaccante può esercitare diversi livelli di controllo sulla richiesta contraffatta:

* **Controllo sull'intero pacchetto TCP**: Scenario critico; consente di forgiare header, payload e protocolli arbitrari.
* **Controllo su parametri della richiesta HTTP**: Manipolazione di URL di destinazione, parametri di query o specifici header HTTP.
* **Controllo limitato a Host o Porta**: L'attaccante può solo specificare la destinazione (utile per port scanning e ricognizione interna).

---

### 3.2 Perché l'SSRF è Critico: Bypass del Firewall e Abuso di Fiducia

Nelle reti aziendali, il firewall perimetrale blocca le connessioni dirette da Internet verso la rete interna (*Intranet*). Tuttavia, il Web Server pubblico si trova all'interno del perimetro (o dispone di rotte autorizzate) e gode di una **fiducia implicita** da parte dei sistemi interni.

* **Flusso dell'attacco**:
	1. L'attaccante invia un payload con un target interno (es. `http://192.168.1.10/admin`).
	2. La richiesta parte dall'**IP del server vulnerabile**, non dall'attaccante.
	3. Il firewall interno la valida come traffico lecito/trusted.
	4. L'attaccante accede a pannelli interni, database o API non esposte al pubblico.

---

### 3.3 SSRF in Ambiente Cloud: Furto di Metadati

Nei provider Cloud (AWS, GCP, Azure), le istanze hanno accesso a endpoint di metadati locali tramite indirizzi IP non instradabili (*link-local*).

**L'Endpoint Metadati AWS (`169.254.169.254`)**:

* **URL di riferimento**: `http://169.254.169.254/latest/meta-data/`
	* **Informazioni esposte**: Dati di configurazione dell'istanza e, soprattutto, **credenziali IAM temporanee** associate al ruolo della macchina.
	* **Impatto**: L'attaccante estrae le credenziali IAM e le utilizza per autenticarsi direttamente nell'infrastruttura Cloud (accedendo a bucket S3, database RDS, altre VM).

---

### 3.4 Blind SSRF (SSRF Cieco)

Si parla di **Blind SSRF** quando l'applicazione esegue la richiesta sul backend ma **non restituisce la risposta HTTP o il corpo del payload** all'attaccante.

Sebbene non permetta l'estrazione diretta di dati, il Blind SSRF consente comunque di:

* **Mappare la rete interna**: Identificare host attivi e porte aperte tramite variazioni nei tempi di risposta (*Time-based analysis*) o codici di errore.
* **Innescare azioni (*Triggering*)**: Eseguire comandi su servizi interni vulnerabili richiamando endpoint tramite semplici richieste `GET` (es. `http://internal-router/reboot` o Webhook interni).

---

# Capitolo 4: Identificazione dell'SSRF — Blind SSRF, Endpoints e Pingback

Identificare una vulnerabilità SSRF richiede un'analisi sistematica dei parametri di input e la verifica di canali di comunicazione sia in-band (risposta visibile) che out-of-band (OOB / Blind).

---

### 4.1 Individuazione degli Endpoint Sospetti

L'analisi parte dall'intercettazione del traffico (es. tramite Burp Suite) cercando funzionalità in cui il server agisce come client HTTP per recuperare risorse esterne:

* **Download/Caricamento Immagini Remote**: `?avatar_url=http://...` o `?image=http://...`
* **Integrazione Webhook e API Esterne**: `?callback=http://...` o `?endpoint=http://...`
* **Importazione Documenti o Feed**: `?feed=http://...` o `?file=http://...`

> **Regola pratica**: Qualsiasi parametro che accetta un URL completo o un indirizzo IP è un candidato prioritario per il test di SSRF.

---

### 4.2 Verifica Out-of-Band (OOB) tramite Pingback

Prima di tentare attacchi su host interni, si verifica la capacità del server di generare traffico in uscita verso l'esterno (*Pingback*).

1. **Configurazione del Server di Ascolto**: Si imposta un endpoint pubblico controllato dall'attaccante tramite strumenti come `ngrok`, `Webhook.site` o `Burp Collaborator`.
2. **Iniezione del Payload**: Si inserisce l'URL del proprio listener:

```text
http://target.com/profile?avatar_url=http://attacker-listener.ngrok.io/ssrf-test
```


3. **Analisi dei Log**: La ricezione di una richiesta HTTP/DNS in ingresso dall'IP pubblico del target conferma la vulnerabilità SSRF.

4. **Pivot Interno**: Confermato il trigger, si devia il traffico verso target interni:
	* `http://127.0.0.1/` o `http://localhost/` (servizi locali non esposti).
	* Subnet private: `192.168.x.x`, `10.x.x.x`, `172.16.x.x`.

---

### 4.3 Analisi dei Tempi di Risposta (Response Time Analysis per Blind SSRF)

Se il firewall blocca il traffico in uscita (niente OOB) e l'applicazione non mostra risposte a schermo (Blind), si sfruttano le risposte dei socket di rete del server per mappare la rete interna:

| Scenario di Rete sul Target | Comportamento del Socket TCP | Effetto sul Tempo di Risposta HTTP |
| --- | --- | --- |
| **Porta Aperta** (es. `127.0.0.1:80`) | Connessione `SYN/ACK` rapida, handshake completato. | Risposta del server **molto veloce**. |
| **Porta Chiusa** (es. `127.0.0.1:9999`) | Ricezione immediata del pacchetto `RST` (Reset). | Risposta **veloce** (spesso con errore di connessione). |
| **Host Inesistente / Porta Filtrata** (es. `10.0.0.99`) | Invio di `SYN` senza risposta, attesa del timeout TCP. | **Forte ritardo (Timeout)**: la risposta impiega diversi secondi (5–30s). |

---

### 4.4 Sinks Comuni nel Codice Sorgente (Analisi Whitebox)

| Linguaggio / Runtime | Librerie / Funzioni a Rischio |
| --- | --- |
| **PHP** | `curl_exec()`, `file_get_contents()`, `fopen()` (se `allow_url_fopen` è attivo) |
| **Python** | `requests.get()`, `urllib.request.urlopen()`, `httpx.get()` |
| **Node.js** | `fetch()`, `axios.get()`, moduli core `http.request()`, `https.request()` |

---

# Capitolo 5: Strategie di Mitigazione per File Disclosure e SSRF

La mitigazione efficace di File Disclosure e SSRF richiede un approccio a più livelli (*Defense in Depth*), combinando controlli applicativi sul codice a vincoli architetturali sull'infrastruttura di rete.

---

### 5.1 Mitigazione del Path Traversal (Prevenzione File Disclosure)

Per impedire l'accesso non autorizzato al filesystem locale tramite manipolazione dei percorsi:

* **Eliminazione dell'Input Diretto**: Non utilizzare mai input forniti dall'utente per costruire direttamente percorsi di file.
* **Whitelist e Identificatori Indiretti (ID Mapping)**: Mappare gli input dell'utente su ID numerici o chiavi fisse associate internamente a percorsi statici e sicuri (es. `?file=1` $\rightarrow$ `/var/www/static/terms.pdf`).
* **Sanitizzazione Rigida**: Se il nome del file deve essere dinamico, applicare controlli per bloccare sequenze di attraversamento (`../`, `..\`) o consentire solo caratteri alfanumerici (`^[a-zA-Z0-9_-]+$`).
* **Verifica del Percorso Reale e Canonicalizzazione**:
1. Risolvere il percorso tramite funzioni native di canonicalizzazione (es. `realpath()` in PHP, `os.path.realpath()` in Python).
2. Verificare programmaticamente che il percorso reale ottenuto inizi rigorosamente con il prefisso della directory autorizzata:

```php
$real_path = realpath($base_dir . '/' . $user_input);
if ($real_path === false || strpos($real_path, $base_dir) !== 0) {
    die("Accesso non consentito");
}
```

---

### 5.2 Mitigazione del Server-Side Request Forgery (SSRF)

La difesa da SSRF deve coprire sia la logica del codice sia i permessi di rete del server:

* **1. Whitelist Rigida degli Host Autorizzati (Livello Applicativo)**:
	* Consentire le richieste solo verso domini o indirizzi IP esplicitamente verificati.
	* Risolvere i record DNS prima della richiesta per prevenire tecniche di *DNS Rebinding* o IP interni mascherati (es. `0.0.0.0`, `127.0.0.1`, subnet private RFC 1918).

* **2. Isolamento di Rete e Segmentazione (Livello Infrastrutturale)**:
	* Posizionare il servizio che esegue chiamate esterne in una DMZ o subnet isolata.
	* Applicare regole di firewall per inibire connessioni in uscita verso database, porte amministrative o altri host della Intranet.
	* **Protezione Cloud Metadata**: Bloccare a livello di firewall/iptables o disabilitare l'accesso all'indirizzo `169.254.169.254` (o forzare l'uso di IMDSv2 su AWS con session token obbligatorio).

* **3. Disabilitazione di Protocolli e Wrapper Non Necessari**:
	* Forzare l'uso esclusivo dei protocolli sicuri `http` e `https`.
	* Disabilitare schemi pericolosi come `file://`, `gopher://`, `dict://`, `ftp://` nelle librerie client:

```php
// Inibisce protocolli extra in cURL
curl_setopt($ch, CURLOPT_PROTOCOLS, CURLPROTO_HTTP | CURLPROTO_HTTPS);
curl_setopt($ch, CURLOPT_REDIR_PROTOCOLS, CURLPROTO_HTTP | CURLPROTO_HTTPS);
```