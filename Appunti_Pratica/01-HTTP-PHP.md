# Capitolo 1: Fondamenti di Web Security e URL Encoding

### 1.1 Web Security e Superficie di Attacco

La sicurezza web si occupa di identificare e mitigare le vulnerabilità nelle applicazioni online. La superficie di attacco odierna è notevolmente aumentata a causa della natura del protocollo HTTP:
* **Origine**: Concepito come protocollo *stateless* e minimale per la distribuzione di soli documenti HTML statici.
* **Evoluzione**: Pagine generate dinamicamente lato server, interpretazione client-side complessa (HTML5, CSS, JavaScript, WebAssembly) e gestione di segreti/dati sensibili su larga scala.

---

### 1.2 Classificazione: Server-Side vs Client-Side

* **Sicurezza Lato Server (Server-Side)**:
	L'impatto compromette direttamente l'infrastruttura di backend (es. accesso non autorizzato al database, RCE, bypass logico).

* **Sicurezza Lato Client (Client-Side)**:
	L'impatto ricade sul browser dell'utente (es. XSS, CSRF). Non presuppone necessariamente un bug nel browser, ma sfrutta la fiducia che il browser ripone nel sito o nell'utente.
	
> **Regola pratica**: Se per portare a termine l'attacco è necessario indurre la vittima a interagire (es. cliccare su un link fornito dall'attaccante), la vulnerabilità è quasi certamente *Client-Side*.

---

### 1.3 Il Toolkit del Security Analyst

* **Browser Developer Tools**: Ispezione DOM/JS, debug script e analisi delle richieste HTTP di rete in tempo reale.
* **cURL / wget**: Invio manuale di richieste HTTP da terminale e parsing della risposta grezza.
* **Python (`requests`)**: Automazione di richieste, creazione di script per exploit ed estrazione di dati.
* **Burp Suite / OWASP ZAP**: Interception proxy per visualizzare, bloccare, alterare e ritrasmettere pacchetti HTTP/HTTPS grezzi.
* **Webhook.site**: Listener pubblico immediato per catturare callback HTTP/DNS durante test Out-of-Band (OOB).
* **Test Server PHP Locale**:

```bash
php -S 127.0.0.1:5000
```

> ⚠️ **Avviso**: Avviare sempre il comando all'interno di una cartella di test isolata. Eseguirlo nella home directory o nella root espone i file locali (inclusa la cartella `~/.ssh/`).

---

### 1.4 URL Encoding (Percent-Encoding)

I caratteri riservati negli URL hanno un significato strutturale per interpreti e parser:

* `#` (*Fragment*): Identifica sezioni client-side; i caratteri successivi non vengono inviati al server.
* `&` (*Ampersand*): Separa le coppie chiave-valore all'interno della *query string*.

Se questi simboli devono essere trasmessi come **valore letterale**, vanno convertiti tramite **Percent-Encoding** (`%` + codice esadecimale ASCII):
* `#` $\rightarrow$ `%23`
* `&` $\rightarrow$ `%26`
* `Spazio` $\rightarrow$ `%20` oppure `+`

**Esempio di Trasmissione (Parametro `var` con valore `hello &# world`)**:

 *Non Codificato (Errato)*:
```text
http://foobar.com/?var=hello &# world
```
Il server legge `var = "hello "` (troncato a causa di `&` e `#`).

 *Codificato (Corretto)*:
```text
http://foobar.com/?var=hello+%26%23+world
```
Il server decodifica correttamente l'intera stringa `hello &# world`.

---

# Capitolo 2: Anatomia dei Messaggi HTTP — Richieste, Risposte e Status Code

Sia le richieste che le risposte HTTP sono messaggi testuali basati su una struttura condivisa a tre sezioni:

1. **Riga Iniziale** (*Request Line* per il client, *Status Line* per il server).
2. **Header Fields** (metadati in formato `Nome: Valore`).
3. **Corpo del Messaggio (Body)** (opzionale, contenente dati come form, JSON o HTML).

**Regole di Formattazione e Parsing**:

* **Terminatore di Riga (CRLF)**: Ogni riga deve terminare tassativamente con `\r\n` (byte `0x0d 0x0a`).
* **Separatore di Fine Header**: L'ultimo header e il corpo del messaggio sono separati da una riga vuota, ovvero un doppio CRLF consecutivo (`\r\n\r\n`).

---

### 2.1 La Richiesta HTTP (Client 📤 Server)

**1. Request Line (Prima riga)**:
Composta da tre campi separati da spazi:

* **Metodo**: L'azione richiesta sulla risorsa:
	* `GET`: Recupera una risorsa (privo di body).
	* `POST`: Invia dati al backend per l'elaborazione (es. login o caricamento form).
	* `HEAD`: Identico a `GET`, ma richiede solo gli header senza scaricare il body.
	* `OPTIONS`: Interroga il server sui metodi HTTP supportati per quell'endpoint.
	* `PUT` / `DELETE`: Creazione/sostituzione o rimozione di una risorsa.

* **Risorsa (URL-Path)**: Il percorso target sul server (es. `/index.php` o `/api/v1/user`).
* **Versione del Protocollo**: Lo standard concordato (es. `HTTP/1.1`).

**2. Header di Richiesta Principali**:

* `Host`: Obbligatorio in HTTP/1.1; specifica il dominio target (es. `Host: www.example.com`).
* `User-Agent`: Stringa identificativa del client/browser o tool di testing.
* `Cookie`: Invia al server i token e le coppie chiave-valore salvate in precedenza per quel dominio.
* `Referer`: URL della pagina di provenienza che ha originato la richiesta corrente.
* `Content-Length` e `Content-Type`: Indicano rispettivamente la dimensione in byte e il formato MIME dei dati nel body (es. `application/x-www-form-urlencoded`, `application/json`).

**Esempio di Richiesta HTTP (GET)**:

```http
GET /index.php HTTP/1.1\r\n
Host: www.example.com\r\n
User-Agent: Mozilla/5.0\r\n
Cookie: session_id=abc123xyz\r\n
\r\n
```

---

### 2.2 La Risposta HTTP (Server 📥 Client)

**1. Status Line (Prima riga)**:

* **Versione del Protocollo**: es. `HTTP/1.1`.
* **Status Code**: Numero a 3 cifre che esprime l'esito dell'operazione.
* **Reason Phrase**: Breve descrizione testuale leggibile (es. `OK`, `Not Found`).

**2. Classificazione degli Status Code**:

* **`1xx` (Informativi)**: Richiesta ricevuta, elaborazione in corso (es. `100 Continue`).
* **`2xx` (Successo)**: Richiesta completata con successo (es. `200 OK`).
* **`3xx` (Reindirizzamento)**: Necessaria un'ulteriore azione da parte del client per raggiungere la risorsa (es. `301 Moved Permanently`, `302 Found`).
* **`4xx` (Errore del Client)**: Richiesta non valida, malformata o priva di autorizzazioni:
	* `400 Bad Request`: Errore sintattico nella richiesta.
	* `403 Forbidden`: Accesso negato alla risorsa.
	* `404 Not Found`: Risorsa inesistente.
* **`5xx` (Errore del Server)**: Il server ha fallito l'elaborazione di una richiesta lecita:
	* `500 Internal Server Error`: Eccezione non gestita o errore critico nel backend.

**Esempio di Risposta HTTP**:

```http
HTTP/1.1 200 OK\r\n
Host: 127.0.0.1:5000\r\n
Date: Wed, 19 Aug 2026 15:07:30 GMT\r\n
Connection: close\r\n
Content-Type: text/html\r\n
\r\n
<b>Hello World!</b>
```

---

# Capitolo 3: Gestione dello Stato, Cookie e Header di Autorizzazione

Il protocollo HTTP è nato per lo scambio di documenti statici ed è privo di meccanismi nativi per tracciare le interazioni nel tempo. Le applicazioni moderne richiedono invece continuità operativa per gestire accessi, preferenze e flussi complessi.

---
### 3.1 La Natura Stateless di HTTP

HTTP è intrinsecamente **stateless** (senza stato):
* Ogni singola richiesta viene elaborata dal server come un'entità indipendente e isolata.
* Il server non conserva memoria delle richieste precedenti dello stesso client.
* La persistenza dell'identità dell'utente richiede meccanismi applicativi sovrapposti al protocollo base.

---

### 3.2 Introduzione ai Cookie

I **cookie** sono frammenti di testo inviati dal server al browser per rendere l'interazione *stateful*:
* **Memorizzazione**: Il client memorizza il cookie sul proprio storage locale.
* **Ritrasmissione Automatica**: Il browser allega automaticamente il cookie a ogni richiesta successiva indirizzata a quello specifico dominio.

* **Scopi Principali**:
	* *Session Management*: Mantenimento dell'utente autenticato (es. ID di sessione).
	* *Personalizzazione*: Salvataggio di preferenze di interfaccia (lingua, tema).
	* *Tracciamento*: Monitoraggio delle abitudini di navigazione.

---

### 3.3 Funzionamento Tecnico e Scope dei Cookie

* **Generazione Lato Server**: Tramite l'header di risposta `Set-Cookie`:
```http
Set-Cookie: session_id=xyz789; Path=/; Secure; HttpOnly
```

* **Generazione Lato Client**: Tramite codice JavaScript manipolando l'oggetto `document.cookie`.
* **Anatomia del Cookie**: Coppia chiave-valore (`name=value`) accompagnata da attributi e metadati (data di scadenza, flag di sicurezza, dominio).
* **Scope e Isolamento (Same-Origin)**:
	Il browser applica regole rigide di isolamento: invia il cookie **esclusivamente** al dominio/origine che lo ha generato (un cookie impostato da `google.com` non verrà mai trasmesso a `microsoft.com`).

---

### 3.4 Gestione dell'Autenticazione: Cookie vs Header `Authorization`

Le applicazioni web moderne (in particolare Single Page Application e REST API) spesso sostituiscono o affiancano i cookie con token espliciti:

* **Cookie di Sessione**:
	* Gestiti in modo trasparente dal browser.
	* Inviati automaticamente ad ogni richiesta verso il dominio di origine.

* **Header `Authorization` (Token-based / Bearer)**:
	* Il client riceve un token di autenticazione (es. JWT o API Key) dopo il login.
	* Il client allega esplicitamente il token all'interno dell'header di ogni richiesta HTTP:
```http
GET /api/v1/profile HTTP/1.1
Host: target.com
Authorization: Bearer eyJhbGciOi...
```

* Non dipende dai meccanismi automatici del browser, riducendo l'esposizione ad attacchi di tipo Cross-Site Request Forgery (CSRF).

---
# Capitolo 4: Introduzione a PHP — Sintassi, Tipi, Casting ed Equality vs Identity

PHP (*Hypertext Preprocessor*) è un linguaggio di scripting interpretato lato server, concepito per integrarsi direttamente all'interno del codice HTML.

---
### 4.1 Filosofia del Linguaggio e Sintassi di Base

* **Eredità Sintattica**:
	* Dal **C**: Blocchi di codice racchiusi da parentesi graffe `{}`, terminazione obbligatoria delle istruzioni con punto e virgola `;`, gestione libera degli spazi bianchi.
	* Dal **Perl**: Prefisso obbligatorio `$` per i nomi di variabili, supporto nativo agli array associativi.

* **Filosofia Esecutiva**:
	* Massima permissività sintattica e tipizzazione debole.
	* **Fail Silently**: Tendenza a gestire errori o conversioni di tipo senza interrompere bruscamente l'esecuzione (comportamento che introduce frequenti anomalie logiche e di sicurezza).

**Esempio di Integrazione PHP/HTML**:

```html
<p>
<?php
  echo "Ciao a tutti.\n";
  $answer = 6 * 7;
  echo "La risposta è $answer";
?>
</p>
```

*Output sul Client*: `Ciao a tutti. La risposta è 42`

---

### 4.2 Gestione di Variabili e Nomi

* **Regole di Naming**:
	* Devono iniziare con `$` seguito da una lettera o underscore `_` (es. `$valido`, `$_test`).
	* Non possono iniziare con cifre (es. `$1errore` non è valido).
	* Sono **case-sensitive** (`$var` e `$VAR` sono distinte).

* **Tipizzazione e Ispezione**:
	* Tipizzazione dinamica: il tipo viene inferito dall'interprete a runtime.
	* Ispezione approfondita di tipo e valore: funzione nativa `var_dump($variabile)`.

---

### 4.3 Gestione delle Stringhe e Operatori

* **Apici Doppi (`"..."`)**:
	* Eseguono l'**interpolazione delle variabili** (es. `"Ciao $nome"` $\rightarrow$ `Ciao Marco`).
	* Interpretano le sequenze di escape (es. `\n` per andare a capo).

* **Apici Singoli (`'...'`)**:
	* Trattano il testo in modo puramente letterale (nessuna espansione di variabili o escape di `\n`).

* **Operatore di Concatenazione (`.`) vs Addizione (`+`)**:
	* `.` $\rightarrow$ Concatena stringhe (es. `"10" . "20"` $\rightarrow$ `"1020"`).
	* `+` $\rightarrow$ Esegue esclusivamente l'addizione matematica (es. `"10" + "20"` $\rightarrow$ `30`). In PHP 8+, l'uso di `+` su stringhe non numeriche solleva un `TypeError`.



---

### 4.4 Meccanismo del Casting e Coercizione di Tipo

PHP applica la conversione di tipo implicita (*type juggling*) a seconda dell'operatore:

* **Regole degli Operatori**:
	* `/` (Divisione): Restituisce sempre un `float` se il risultato non è intero esatto (es. `56 / 12` $\rightarrow$ `float(4.666...)`).
	* `+` (Somma): Converte gli operandi a numerici (`int` o `float`). Il valore `true` diventa `1`, `false` diventa `0`.
	* `.` (Concatenazione): Converte automaticamente qualsiasi operando in `string`.

* **Casting Esplicito**:
	* `(int) 9.9` $\rightarrow$ Tronca la parte decimale verso lo zero, restituendo `9`.
	* `(bool)` $\rightarrow$ Valori considerati *falsy*: `0`, `0.0`, `""`, `"0"`, `null`, `[]` (tutto il resto è `true`).

---

### 4.5 Uguaglianza Debole (`==`) vs Identità Stretta (`===`)

* **Uguaglianza (`==` e `!=`)**:
	* Confronta i dati **dopo** aver applicato la conversione implicita di tipo (*type juggling*).

* **Identità (`===` e `!==`)**:
	* Confronta **valore e tipo** senza alcuna conversione automatica.

**Casi Pratici d'Esame**:

* `123 == "123"` $\rightarrow$ `TRUE` (la stringa viene convertita a intero prima del confronto).
* `123 === "123"` $\rightarrow$ `FALSE` (`int` vs `string`).
* `FALSE == "0"` $\rightarrow$ `TRUE` (la stringa `"0"` è considerata valore falsy).
* `(5 < 6) == "2" - "1"` $\rightarrow$ `TRUE` (a sinistra `true`, a destra l'intero `1`, equivalenti sotto `==`).
* `(5 < 6) === TRUE` $\rightarrow$ `TRUE` (entrambi booleani con valore `true`).