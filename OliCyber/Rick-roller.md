# Writeup Challenge: Rick roller

**Target:** `get_flag.php`

**Flag:** `flag{r1ck_4st1ey_c14ssic_m3m3}`

**Categoria:** Web Security / HTTP Redirection & Information Disclosure

---

### Obiettivo

Recuperare la flag associata al pulsante **"VINCI!"**, che punta alla risorsa server-side `get_flag.php`.

---

### Analisi del Comportamento

1. **Client Browser Behaviour:**
Cliccando sul link dal browser, l'utente viene reindirizzato immediatamente al video musicale di Rick Astley su YouTube (`[https://www.youtube.com/watch?v=dQw4w9WgXcQ](https://www.youtube.com/watch?v=dQw4w9WgXcQ)`), senza mostrare alcuna informazione utile a video.
2. **HTTP 302 Found & Body Scrapping:**
Il server PHP imposta un redirect inviando lo status code `HTTP/1.1 302 Found` e l'header `Location: [https://www.youtube.com/watch?v=dQw4w9WgXcQ](https://www.youtube.com/watch?v=dQw4w9WgXcQ)`. I normali browser seguono il redirect all'istante, scartando il body della risposta associata al codice 302. Tuttavia, il payload HTTP contiene dati nel corpo della risposta (`Content-Length: 30`).

---

### Risoluzione ed Exploitation

Interrogando direttamente l'endpoint senza abilitare l'inseguimento automatico dei redirect (`follow redirects`), è possibile leggere la risposta HTTP grezza completa di header e payload.

#### Comando `curl`

```bash
curl -i http://<target-url>/get_flag.php

```

#### Risposta del Server

```http
HTTP/1.1 302 Found
Content-Length: 30
Content-Type: text/html; charset=UTF-8
Date: Mon, 24 Aug 2026 14:39:35 GMT
Location: https://www.youtube.com/watch?v=dQw4w9WgXcQ
Server: Apache/2.4.56 (Debian)
X-Powered-By: PHP/8.0.30

flag{r1ck_4st1ey_c14ssic_m3m3}

```

---

### Risultato

La flag si trovava nel **body della risposta HTTP 302**, nascosta dal redirect automatico del browser.
