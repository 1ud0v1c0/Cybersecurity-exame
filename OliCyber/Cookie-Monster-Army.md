# Writeup Challenge: CMA (Cookie Monster Army)

**Target:** `[http://cma.challs.olicyber.it/](http://cma.challs.olicyber.it/)`

**Flag:** `flag{c00ki3_4rmy_will_c0nqu3r_th3_w0rld!}`

**Categoria:** Web Security / Insecure Session Management & Broken Object Level Authorization (Privilege Escalation)

---

### Obiettivo

Ottenere i privilegi di amministratore (`admin`) all'interno della piattaforma "L'esercito del cookie monster" per accedere alla dashboard protetta e recuperare la flag.

---

### Analisi della Vulnerabilità

1. **Filtri restrittivi sul Login Form:**
I tentativi di Authentication Bypass tramite SQL Injection tradizionale (es. `' OR 1=1 -- -`) vengono intercettati e bloccati dal backend con l'errore `Caratteri invalidi`, dovuto a una sanitizzazione basata su blacklist o controllo rigoroso dei caratteri.
2. **Insecure Session Management & Client-Side Predictability:**
Registrandosi tramite il pulsante **"Arruolati"** con un account utente arbitrario, il server rilascia un cookie di sessione privo di cifratura o firma crittografica di integrità (come un HMAC o un token JWT verificato).
3. **Analisi del Cookie:**
Il valore del cookie assegnato si presentava come una stringa codificata in Base64:

```text
MjAyNi8wOC8yNC0xNzg3NTg1NjY4LWFkbWlu (o con il proprio username)

```

Eseguendo la decodifica Base64:

```text
2026/08/24-1787585668-ludovico

```

La struttura del token segue un pattern deterministico e prevedibile:
`[DATA]-[ID/TIMESTAMP]-[USERNAME]`

---

### Risoluzione ed Exploitation

Poiché il backend decodifica semplicemente la stringa per estrarre l'identità dell'utente autenticato senza validarne la provenienza o l'integrità, è possibile eseguire un attacco di **Privilege Escalation** tramite impersonificazione dell'utente `admin`.

1. **Costruzione del Payload:**
Sostituzione del campo `[USERNAME]` finale con `admin`:

```text
2026/08/24-1787585668-admin

```

1. **Codifica in Base64:**

```bash
echo -n "2026/08/24-1787585668-admin" | base64
# Output: MjAyNi8wOC8yNC0xNzg3NTg1NjY4LWFkbWlu

```

utilizzato CyberChef per codificare la stringa. [https://gchq.github.io/CyberChef/](https://gchq.github.io/CyberChef/)

1. **Cookie Tampering:**

* Apertura dei DevTools del browser (**F12** > scheda **Application/Storage** > **Cookies**).
* Modifica del valore del cookie di sessione incollando la nuova stringa Base64.
* Ricaricamento della pagina (`F5`).

---

### Risultato

Il server valida il cookie contraffatto identificando la sessione come appartenente ad `admin` e restituisce l'accesso all'area riservata con la flag:

```text
flag{c00ki3_4rmy_will_c0nqu3r_th3_w0rld!}

```

---

### Mitigazione (Best Practice)

* **Session ID opachi e casuali:** I cookie di sessione non devono mai contenere dati in chiaro o semplicemente codificati (la codifica Base64 **non** è crittografia). Devono essere generati come stringhe pseudocasuali ad alta entropia memorizzate lato server.
* **Integrità crittografica:** Se si utilizzano token stateless (come i JWT), è obbligatorio firmarli con un segreto robusto (`HMAC-SHA256` o chiavi asimmetriche) e verificare sempre la firma prima di elaborare qualsiasi operazione privilegiata.
