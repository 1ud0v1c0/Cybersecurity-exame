# Capitolo 1: Introduzione alla SQL Injection e Login Bypass

### 1.1 Cos'è una SQL Injection (SQLi)?

L'**SQL Injection** è una delle vulnerabilità web più critiche e note. Si verifica quando un'applicazione non fa distinzione tra i **dati inseriti dall'utente** e i **comandi SQL** che compongono l'interrogazione al database.

In un'applicazione sicura, qualsiasi valore inviato dall'utente (ad esempio un nome o un'email) deve essere trattato come semplice testo. Se invece il codice concatena direttamente l'input all'interno della query, un attaccante può iniettare caratteri di controllo per manipolare la logica stessa della query ed eseguire comandi arbitrari sul database.
#### Impatto pratico
Riuscire a iniettare comandi SQL consente di:
* **Rubare dati riservati**: leggere password, dati personali, credenziali o numeri di carte di credito.
* **Bypassare l'autenticazione**: accedere ad account e pannelli riservati senza password.
* **Alterare o eliminare record**: modificare permessi, saldi o cancellare intere tabelle.
* **Compromettere il server**: in determinate configurazioni, leggere/scrivere file di sistema o eseguire comandi tramite web shell.

---

### 1.2 Login Bypass: Sovvertire l'Autenticazione

Il **Login Bypass** è l'esempio classico di SQLi: non serve a estrarre dati, ma a ingannare il controllo delle credenziali per farsi riconoscere come utente valido.

#### Anatomia della query e del payload

Immaginiamo una classica query PHP/SQL vulnerabile costruita per string concatenation:
```sql
SELECT * FROM users WHERE email = '$email' AND password = '$password'
```

Se nel campo di input dell'email inseriamo il payload:
```text
' OR 1=1 -- -
```

La query finale assemblata dal backend diventerà:
```sql
SELECT * FROM users WHERE email = '' OR 1=1 -- ' AND password = ''
```

#### Cosa succede a livello di esecuzione?

1. **`'` (Apice iniziale)**: chiude forzatamente la stringa del valore `email` prima del previsto.
2. **`OR 1=1`**: introduce una condizione sempre vera (tautologia). Dato che in una clausola con `OR` basta una sola condizione verificata, l'intero blocco `WHERE` diventa `TRUE` per tutte le righe della tabella.
3. **`--` (Commento SQL)**: indica al database che tutto ciò che segue sulla stessa riga va ignorato. In questo modo viene completamente tagliato fuori il controllo sulla password (`AND password = '...'`).

>**Risultato**: La query restituisce tutti i record presenti nella tabella `users`. Molti backend interpretano la presenza di almeno un risultato come esito positivo e concedono l'accesso con l'identità del **primo record** estratto (che solitamente è l'utente amministratore).

---
### 1.3 Identificazione preliminare: I Caratteri Sentinella

Per individuare se un campo di input è vulnerabile durante un'analisi o un test pratico, si iniettano singoli caratteri speciali che hanno un significato sintattico preciso in SQL:

* `'` (Apice singolo)
* `"` (Apice doppio)
* `\` (Backslash)
* `--` (Sequenza di commento)
- `` ` `` (Backtick)

> [!TIP] Come interpretare il feedback
> Se dopo l'inserimento di questi caratteri l'applicazione restituisce un **errore di sintassi SQL** (es. `SQL syntax error`, `database error`), o mostra un comportamento visibilmente anomalo (es. errore 500 o pagina troncata), significa che l'input non è sanitizzato ed è suscettibile a iniezione.
> 
> 

---

# Capitolo 2: Union-Based SQL Injections e Information Schema

Quando un'applicazione web vulnerabile stampa a schermo i dati estratti dal database (ad esempio nei risultati di ricerca o nella visualizzazione di un articolo), la tecnica più diretta per estrarre informazioni è la **Union-Based SQLi**. Questa tecnica sfrutta l'operatore `UNION` per fondere i risultati della query originale con una query arbitraria creata da noi.

---
### 2.1 Il Funzionamento dell'operatore `UNION`

L'istruzione `UNION` combina il set di risultati di due o più query `SELECT` in un'unica risposta. Per funzionare senza errori, il motore SQL impone **due vincoli obbligatori**:

1. **Stesso numero di colonne**: Entrambe le query devono selezionare l'esatto stesso numero di campi.

2. **Tipi di dato compatibili**: Le colonne corrispondenti devono avere tipi compatibili (es. non inserire testo dove il database si aspetta obbligatoriamente un intero).

---

### 2.2 Fase 1: Determinare il Numero di Colonne (Black-Box)

Senza conoscere il codice sorgente, dobbiamo prima scoprire quante colonne seleziona la query originale. Esistono due metodi pratici:

#### Metodo A: Utilizzo di `ORDER BY` (Consigliato)
La clausola `ORDER BY` accetta l'indice numerico della colonna da ordinare. Se indichiamo un indice inesistente, il database restituirà un errore. Procediamo per tentativi crescenti:

* `1 ORDER BY 1` $\rightarrow$ **OK** (le colonne sono almeno 1)
* `1 ORDER BY 2` $\rightarrow$ **OK** (le colonne sono almeno 2)
* `1 ORDER BY 4` $\rightarrow$ **Errore** (il numero reale è inferiore a 4)
* `1 ORDER BY 3` $\rightarrow$ **OK**

*Conclusione*: La query originale estrae esattamente **3 colonne**.
#### Metodo B: Tentativi con `UNION SELECT`
Si incrementano le colonne fittizie finché la pagina non carica correttamente senza errori di sintassi:

* `1 UNION SELECT 1` $\rightarrow$ **Errore**
* `1 UNION SELECT 1,2` $\rightarrow$ **Errore**
* `1 UNION SELECT 1,2,3` $\rightarrow$ **OK** (colonne individuate: 3)

---

### 2.3 Fase 2: Forzare la Visualizzazione dei Nostri Dati

Spesso l'applicazione mostra a schermo solo il **primo record** restituito. Poiché `UNION` appende i nostri dati *dopo* quelli legittimi, a video continueremo a vedere solo il contenuto originale.

Per risolvere il problema, rendiamo nulla la prima query forzando una condizione sempre falsa (es. `1=0` o un ID inesistente come `-1`):

```sql
SELECT title, post FROM posts WHERE id = 1 AND 1=0 UNION SELECT 1, 2
```

In questo modo la prima query restituisce 0 righe e la pagina sarà costretta a mostrare i valori (`1, 2`) della nostra `UNION`.

---

### 2.4 Fase 3: Mappare il Database tramite `INFORMATION_SCHEMA`

In MySQL (e DBMS analoghi), `INFORMATION_SCHEMA` è il database di sistema che raccoglie tutti i metadati relativi a tabelle e colonne.

Le tre viste essenziali da interrogare sono:

* `information_schema.schemata`: elenco di tutti i database presenti.
* `information_schema.tables`: elenco delle tabelle.
* `information_schema.columns`: elenco delle colonne di ciascuna tabella.

#### Query tipiche di ricognizione

* **Elencare i database**:
```sql
SELECT schema_name FROM information_schema.schemata
```

* **Elencare le tabelle del database corrente**:
```sql
SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE()
```

* **Elencare tutte le colonne del database corrente**:
```sql
SELECT table_name, column_name FROM information_schema.columns WHERE table_schema = DATABASE()
```

---

### 2.5 Fase 4: Aggregare i Risultati con `GROUP_CONCAT()`

Se la pagina web visualizza un solo campo di testo ma dobbiamo recuperare decine di righe, usiamo **`GROUP_CONCAT()`**. Questa funzione concatena tutti i record in una singola stringa separata da virgole (o caratteri a scelta).

```sql
UNION SELECT 1, group_concat(table_name, ':', column_name) FROM information_schema.columns WHERE table_schema = DATABASE()
```

*Esempio di output*: `users:id,users:username,users:password,posts:id,posts:title`.

---

### 2.6 Fase 5: Estrazione Finale dei Dati Sensibili

Una volta individuata la tabella bersaglio (es. `users`) e i relativi campi (`username`, `password`), si esegue il dump completo:

```sql
SELECT title, post FROM posts WHERE id = 1 AND 1=0 UNION SELECT 1, group_concat(username, ':', password) FROM users
```

La pagina stamperà direttamente tutte le credenziali estratte (es. `admin:hash1,user2:hash2`).

---
# Capitolo 3: Blind SQL Injections (Oracolo Booleano e Tecniche Content-Based)

Nelle **Blind SQL Injection** l'applicazione è "cieca": non stampa a schermo i dati del database e non mostra errori SQL dettagliati. Non potendo leggere direttamente l'output, dobbiamo ricavare le informazioni ponendo al database una serie di domande a risposta binaria (**VERO** o **FALSO**), ricostruendo i dati un singolo carattere alla volta.

---

### 3.1 Il Concetto di Oracolo Booleano

Trasformiamo la vulnerabilità in un **oracolo**: inviamo una richiesta contenente una condizione logica e osserviamo la reazione del backend.

* **Condizione VERA**: L'applicazione risponde in un modo noto (es. login riuscito, messaggio visibile, caricamento regolare).

* **Condizione FALSA**: L'applicazione risponde in modo differente (es. login fallito, errore generico, elemento mancante).

#### Il flusso logico di estrazione (Esempio password admin):

1. *"La password inizia con 'a'?"* $\rightarrow$ L'applicazione risponde negativamente $\rightarrow$ **FALSO**.
2. *"La password inizia con 'b'?"* $\rightarrow$ L'applicazione risponde positivamente $\rightarrow$ **VERO**.
3. Primo carattere confermato: **`b`**.
4. Si passa alla query successiva: *"La password inizia con 'ba'?"*, e così via fino alla fine della stringa.

---

### 3.2 Blind Content-Based: Sfruttare le Differenze Visive

La variante **Content-Based** si basa sulle modifiche nel contenuto della risposta HTTP tra un esito vero e uno falso (ad esempio una frase che compare o scompare, o una variazione nella lunghezza in byte della pagina).

#### Costruzione del Payload con sub-query

Data una query base come:
```sql
SELECT * FROM posts WHERE id = 1
```

Aggiungiamo la nostra condizione tramite l'operatore `AND` e una sotto-query:
```sql
SELECT * FROM posts WHERE id = 1 AND (SELECT 1 WHERE [condizione_da_testare]) = 1
```

* Se la condizione è **VERA**, l'`AND` è soddisfatto e il database restituisce il post `1` (la pagina carica normalmente).

* Se la condizione è **FALSA**, la sotto-query non restituisce nulla, l'`AND` fallisce e il post non viene mostrato (la pagina sarà vuota o mostrerà un avviso).

---

### 3.3 Confronto di Stringhe: L'Operatore `LIKE` e le Wildcard

In ambiente MySQL, lo strumento più rapido per formulare le domande all'oracolo è l'operatore **`LIKE`**, che supporta caratteri jolly (wildcard):

* **`%`**: rappresenta zero, uno o più caratteri qualsiasi.
* **`_`**: rappresenta esattamente un singolo carattere.
#### Esempi di matching:

* `'segreto' LIKE 'seg%'` $\rightarrow$ **VERO** (inizia con "seg").
* `'segreto' LIKE '%reto'` $\rightarrow$ **VERO** (finisce con "reto").
* `'segreto' LIKE 'segret_'` $\rightarrow$ **VERO** (c'è un solo carattere dopo "segret").


> [!NOTE] Comportamento in MySQL
> Per impostazione predefinita, in MySQL l'operatore `LIKE` è **case-insensitive** (non distingue tra maiuscole e minuscole), il che riduce notevolmente il numero di tentativi necessari durante un test.
> 
> 

---

### 3.4 Esempio Pratico: Indovinare una Password Carattere per Carattere

Ipotizziamo di voler estrarre la password dell'utente `id=1` dalla tabella `users` tramite un parametro `id` vulnerabile nella visualizzazione post:

1. `... id=1 AND (SELECT 1 FROM users WHERE id=1 AND password LIKE 'a%') = 1` $\rightarrow$ **Pagina vuota (FALSO)**.

2. `... id=1 AND (SELECT 1 FROM users WHERE id=1 AND password LIKE 'b%') = 1` $\rightarrow$ **Pagina carica (VERO)** $\rightarrow$ Il primo carattere è `b`.

3. `... id=1 AND (SELECT 1 FROM users WHERE id=1 AND password LIKE 'ba%') = 1` $\rightarrow$ **Pagina vuota (FALSO)**.

4. `... id=1 AND (SELECT 1 FROM users WHERE id=1 AND password LIKE 'bc%') = 1` $\rightarrow$ **Pagina carica (VERO)** $\rightarrow$ I primi due caratteri sono `bc`.


(In alternativa all'operatore `LIKE`, si può usare la funzione nativa `SUBSTR(password, posizione, 1)` per estrarre e confrontare direttamente il carattere a un indice specifico).

---

# Capitolo 4: Time-Based SQL Injections (Gestione dei Ritardi e Calibrazione)

Nelle situazioni in cui l'applicazione è completamente "muta" (non mostra dati, non restituisce errori SQL e il contenuto della pagina non cambia minimamente tra una condizione vera e una falsa), l'unico canale di comunicazione utilizzabile resta il **tempo di risposta del server**. Questa tecnica prende il nome di **Time-Based SQL Injection**.

---

### 4.1 Il Meccanismo: La Funzione `sleep()`

In questo scenario chiediamo al database di **sospendere l'esecuzione per un certo numero di secondi** solo se la nostra condizione di test è vera.

#### Anatomia della Query

```sql
SELECT sleep(5) FROM secrets WHERE secret LIKE 'a%' LIMIT 1

```

* **`SELECT sleep(5)`**: ordina al database di arrestarsi per 5 secondi prima di inviare la risposta. Il valore ritornato dalla funzione non ha importanza, conta unicamente il ritardo generato.

* **`FROM secrets`**: la tabella contenente i dati bersaglio.

* **`WHERE secret LIKE 'a%'`**: la domanda posta all'oracolo (*"Il segreto inizia con la lettera 'a'?"*).

#### Misurazione dell'Oracolo

* **Risposta VERA**: la condizione è soddisfatta, il database esegue lo `sleep(5)` e la risposta HTTP impiega **almeno 5 secondi** ad arrivare.

* **Risposta FALSA**: la condizione non è soddisfatta, lo `sleep` viene saltato e la risposta arriva **immediatamente**.

---

### 4.2 La Gestione della Latenza di Rete

La sfida principale del Time-Based è non confondere un rallentamento naturale della connessione o del server con una risposta positiva dell'oracolo.

Per impostare l'attacco in modo affidabile si seguono tre passaggi:

1. **Misurare la Baseline**: inviare alcune richieste innocue per rilevare il tempo medio di risposta del server in condizioni ordinarie.

2. **Scegliere un margine di sicurezza**: impostare il tempo di `sleep()` ben al di sopra della latenza massima riscontrata (es. se il server risponde in 300ms con picchi di 1s, usare `sleep(5)` garantisce che il ritardo sia intenzionale).

3. **Bilanciare il trade-off**:
	* *Ritardo alto (es. 5-10s)*: elimina i falsi positivi ma rende l'estrazione molto lenta.
	* *Ritardo basso (es. 1-2s)*: estrazione più rapida ma rischio elevato di errori per sbalzi di rete.

---
### 4.3 Automazione dell'Estrazione

Dover attendere diversi secondi per ogni singolo carattere rende l'estrazione manuale impraticabile. Si utilizzano quindi script (o tool come **SQLMap**) che automatizzano il flusso:

1. Definire il set di caratteri di prova (es. `a-z`, `0-9`).
2. Ciclare sulla posizione corrente del carattere nella stringa.
3. Inviare la richiesta con la condizione e misurare il tempo di risposta HTTP.
4. Quando viene registrato un ritardo pari o superiore alla soglia di sicurezza, il carattere viene confermato e aggiunto alla stringa.
5. Avanzare alla posizione successiva e ripetere fino al termine della stringa.

---

# Capitolo 5: Tecniche di Prevenzione (Prepared Statements, ORM ed Escaping)

Il principio cardine della sicurezza contro le SQL Injection è semplice: **non fidarsi mai dell'input dell'utente**. Qualsiasi dato in ingresso deve essere gestito in modo che non possa mai essere interpretato dal motore del database come codice eseguibile.

Nel tempo sono stati adottati approcci diversi per raggiungere questo obiettivo, ma solo alcuni rappresentano lo standard moderno di sicurezza.

---

### 5.1 Escaping dell'Input (Metodo Obsoleto)

L'escaping consiste nel passare in rassegna la stringa fornita dall'utente e anteporre un carattere speciale (solitamente il backslash `\`) a tutti i simboli critici per la sintassi SQL (ad esempio trasformando `'` in `\'`).

#### Perché è considerato fragile e sconsigliato?

* **Rischio di errore umano**: È sufficiente che lo sviluppatore dimentichi di applicare la funzione di escape a un singolo parametro per esporre l'intera applicazione.

* **Possibili bypass**: La sicurezza dipende interamente dall'implementazione della funzione di sanitizzazione. Storicamente, alcune configurazioni (ad esempio la gestione di set di caratteri multi-byte con funzioni come `addslashes`) consentivano di neutralizzare il carattere di escape e riattivare l'iniezione.

---

### 5.2 Prepared Statements (Lo Standard di Sicurezza)

I **Prepared Statements** (o *Query Parametrizzate*) rappresentano la soluzione definitiva contro le SQLi perché mantengono una **separazione totale tra la logica della query (codice) e i dati forniti dall'utente**.

#### Come funzionano in due fasi:

1. **Fase di Preparazione**: Il backend invia al database un template fisso della query con appositi segnaposto (**placeholders**, indicati con `?` o etichette come `:nome`). Il database compila e valida la struttura logica della query prima ancora di ricevere i dati.

2. **Fase di Associazione (Binding) ed Esecuzione**: I valori dell'utente vengono inviati separatamente e associati ai segnaposto.

Poiché la logica è già stata compilata nella prima fase, il database tratta l'input **esclusivamente come valore letterale (stringa di testo pura)**. Anche se l'utente inserisce caratteri speciali o payload come `' OR 1=1 --`, questi non avranno alcun effetto sulla struttura della query.

#### Esempio Pratico in PHP (con PDO):

```php
// 1. Preparazione della query con placeholders (:username e :password)
$stmt = $pdo->prepare('SELECT * FROM users WHERE username = :username AND password = :password');

// 2. Binding sicuro dei valori inseriti dall'utente
$stmt->bindParam(':username', $username);
$stmt->bindParam(':password', $password);

// 3. Esecuzione sicura
$stmt->execute();

```

---

### 5.3 ORM (Object-Relational Mapping): L'Approccio Consigliato

L'**ORM** è un livello di astrazione che si interpone tra il linguaggio di programmazione e il database relazionale, consentendo di manipolare i record come se fossero normali oggetti del codice senza dover scrivere SQL a mano.

```python
# Esempio concettuale in Python (es. Django ORM / SQLAlchemy)
utente = User.objects.get(username=input_utente)

```

#### I Vantaggi per la Sicurezza:

* **Prepared Statements automatici**: Dietro le quinte, l'ORM genera le query utilizzando nativamente e sistematicamente i Prepared Statements.

* **Azzeramento dell'errore umano**: Rimuovendo la necessità di concatenare stringhe o costruire query SQL grezze, si elimina alla radice il rischio di introdurre punti di iniezione nel codice applicativo.

---
