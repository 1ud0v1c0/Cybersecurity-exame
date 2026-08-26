# CodeLook: Guida per Analizzare il Codice nei Vulnerability Challenges

## 1. **SQL Injection (SQLi)**

### Cosa cercare:
- **Concatenazione di query**: Cerca l'uso diretto di input utente nelle query SQL, come:
    ```php
  $query = "SELECT * FROM users WHERE username='$username'";
    ```
- **Assenza di query parametrizzate**: Controlla se il codice usa funzioni sicure come `PreparedStatement` o `PDO` con parametri.
- **Esecuzione diretta**: Cerca funzioni come `mysqli_query()` o `pg_query()` che eseguono query SQL con input concatenati.
- **Tabella bersaglio**: Cerca riferimenti a `users`, `admin`, `passwords`, ecc.

### Indicatori di vulnerabilità:
- Uso di `$_GET`, `$_POST`, `$_REQUEST` o dati direttamente nella query.
- Assenza di sanitizzazione o escape (es. `mysqli_real_escape_string()`).

---

## 2. **Cross-Site Scripting (XSS)**

### Cosa cercare:
- **Output diretto di input utente**: Controlla se variabili derivate da input (es. `$_GET`, `$_POST`) vengono mostrate nella pagina senza sanitizzazione, come:
    ```php
  echo $_GET['q'];
    ```
- **Assenza di escape HTML**: Controlla se l’output non passa per funzioni come `htmlspecialchars()` o `htmlentities()`.
- **Luoghi vulnerabili**:
  - Campi di ricerca.
  - URL riflessi nei parametri GET.
  - Input che finiscono in attributi HTML (es. `value`, `src`, `href`).

### Indicatori di vulnerabilità:
- Assenza di validazione o sanitizzazione dell’input.
- Uso di `echo`, `print` o output diretto di variabili senza filtraggio.

---

## 3. **Server-Side Request Forgery (SSRF)**

### Cosa cercare:
- **Chiamate HTTP generate dal server**: Cerca funzioni come `file_get_contents()`, `curl_exec()`, o librerie HTTP.
- **Input utente come URL**: Controlla se l’utente può specificare l’URL che il server usa, ad esempio:
    ```php
  $data = file_get_contents($_GET['url']);
    ```
- **Validazione degli URL**: Cerca l’uso di `FILTER_VALIDATE_URL` o controlli che limitino l’accesso a domini esterni.

### Indicatori di vulnerabilità:
- Assenza di limitazioni sui domini consentiti.
- Nessun controllo su IP o host (es. `localhost`, `127.0.0.1`).

---

## 4. **Local File Inclusion (LFI) e File Disclosure**

### Cosa cercare:
- **Inclusione di file dinamica**: Cerca funzioni come `include()`, `require()`, `file_get_contents()`, o simili con input utente:
    ```php
  include $_GET['page'];
    ```
- **Path traversal**: Verifica se l’input non è validato e consente percorsi relativi come `../../etc/passwd`.
- **Controlli sui file**:
  - Esiste una whitelist dei file consentiti?
  - L’input è filtrato per evitare caratteri pericolosi (es. `../`)?

### Indicatori di vulnerabilità:
- Assenza di una lista di file consentiti.
- Uso diretto di input utente per aprire file o includerli.

---

## 5. **Command Injection**

### Cosa cercare:
- **Esecuzione di comandi di sistema**: Cerca funzioni come `exec()`, `shell_exec()`, `system()`, o backtick (\``):
    ```php
  $output = shell_exec("ls " . $_GET['dir']);
    ```
- **Input non filtrato**: Verifica se l’input utente è concatenato direttamente al comando.
- **Controlli sul comando**: Esistono restrizioni sui caratteri ammessi nell’input?

### Indicatori di vulnerabilità:
- Assenza di funzioni di escape come `escapeshellarg()` o `escapeshellcmd()`.
- Esecuzione diretta di comandi con input utente.

---

## 6. **Insecure File Upload**

### Cosa cercare:
- **Caricamento di file**: Individua sezioni di codice che gestiscono file upload con funzioni come `move_uploaded_file()`.
- **Controlli sul file**:
  - Estensione ammessa?
  - Tipo MIME verificato?
  - Il contenuto del file viene validato?
- **Permessi della directory**: Verifica se i file caricati sono eseguibili dal server (es. `.php`).

### Indicatori di vulnerabilità:
- Assenza di controlli sulle estensioni o sui tipi di file.
- I file caricati sono accessibili pubblicamente in una directory eseguibile.

---

## 7. **Cross-Site Request Forgery (CSRF)**

### Cosa cercare:
- **Azioni critiche senza token**: Controlla se le azioni sensibili (es. modifica password) mancano di un controllo CSRF.
- **Assenza di token anti-CSRF**:
  - Non c’è un token unico inviato come parte della richiesta POST o GET.
  - Non viene verificato un token di sessione.

### Indicatori di vulnerabilità:
- Form o azioni critiche che accettano richieste POST/GET senza verificare l’origine.

---

## 8. **Unrestricted Input Manipulation (Esempio: SHOP FLAG)**

### Cosa cercare:
- **Parametri di input critici**: Cerca campi come `costo`, `id`, o simili usati direttamente nelle operazioni.
- **Validazione lato client**: Verifica se il codice si affida solo a controlli JavaScript o frontend.
- **Logica di validazione server**: Assicurati che il server validi i dati inviati dal client.

### Indicatori di vulnerabilità:
- Valori critici modificabili dal client senza essere verificati lato server.
- Assenza di controlli su parametri inviati con metodi come POST o cookie.

---

## 9. **XPATH Injection**

### Cosa cercare:
- **Query XML**: Controlla se il codice utilizza XPATH per interrogare documenti XML con input utente.
- **Input concatenato nelle query**: Cerca query che usano input utente direttamente:
    ```php
  $xpath = "//user[username/text()='$username']";
    ```
- **Validazione dell’input**: Esistono controlli per sanitizzare caratteri speciali (es. apici)?

### Indicatori di vulnerabilità:
- Uso di input utente senza escape o sanitizzazione.
- Query XPATH costruite dinamicamente.

---

# **Consigli Generali**
1. **Cerca Input Utente**: Qualsiasi cosa derivi da `$_GET`, `$_POST`, `$_COOKIE`, `$_REQUEST` è sospetta.
2. **Output Diretto**: Controlla se l’input viene usato senza essere validato o filtrato.
3. **Controlla Funzioni Critiche**: Cerca funzioni per query, inclusioni di file, esecuzioni di comando e output HTML.
4. **Indizi nel Codice**:
   - Commenti lasciati dai programmatori.
   - Struttura del database o file.
   - Variabili con nomi come `flag`, `admin`, o `secret`.
```text

