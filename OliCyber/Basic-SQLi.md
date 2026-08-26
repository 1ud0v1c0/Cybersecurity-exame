# Writeup Challenge: Basic SQLi (Authentication Bypass)

**Target:** `/index.php`

**Flag:** `flag{y0u_sh0uld_u53_pr3p4r3d_st4t3m3nt5}`

**Categoria:** Web Security / SQL Injection (Authentication Bypass)

---

### Obiettivo

Eseguire un bypass del modulo di autenticazione (*login form*) per accedere all'area riservata come utente amministratore (`Admin`) e ottenere la flag.

---

### Analisi della Vulnerabilità

1. **SQL Concatenation & Insecure Query:**
Il backend PHP costruisce la query SQL concatenando direttamente l'input utente inviato via `POST` (`username` e `password`) senza sanitizzazione o parametrizzazione:

```sql
SELECT * FROM users WHERE username = '$username' AND password = '$password'
```

1. **Error-based Evidence:**
In caso di sintassi errata, il backend mostrava un warning esplicito:

```text
Warning: mysqli_num_rows() expects parameter 1 to be mysqli_result, bool given in /var/www/html/index.php on line 5
```

Questo indica l'utilizzo del driver `mysqli` e la gestione del login tramite verifica del numero di righe restituite (`mysqli_num_rows($result) > 0`).

---

### Risoluzione ed Exploitation

Sfruttando l'assenza di Prepared Statements, è possibile iniettare una tautologia logica nel campo `username` e commentare il resto della query:

* **Campo Username:** `' OR 1=1 -- -`
* **Campo Password:** `qualsiasi_valore`

#### Query risultante sul Database

```sql
SELECT * FROM users WHERE username = '' OR 1=1 -- -' AND password = '...'
```

* **Meccanica:**
* L'apice iniziale `'` chiude il delimitatore di stringa per il parametro `username`.
* La clausola `OR 1=1` rende la condizione di filtro sempre vera (`TRUE`) per tutti i record della tabella.
* Il commento `-- -` tronca ed esclude la verifica della password (`AND password = '...'`).
* Il database restituisce il primo record trovato (generalmente l'account `Admin`), consentendo il login con successo.

---

### Risultato

Il server valida l'autenticazione per l'amministratore e renderizza la risposta:

```text
Hello Admin!
The flag is flag{y0u_sh0uld_u53_pr3p4r3d_st4t3m3nt5}
```

---

### Mitigazione (Best Practice)

Utilizzare **Prepared Statements (Query Parametrizzate)** con PDO o MySQLi per separare la logica SQL dai dati di input:

```php
$stmt = $mysqli->prepare("SELECT id, username FROM users WHERE username = ? AND password = ?");
$stmt->bind_param("ss", $username, $password);
$stmt->execute();
$result = $stmt->get_result();
```
