**Richieste GET**

* **GET di base:**

```bash
curl https://example.com/api/risorsa

```

* **GET con parametri di query (Query Parameters):**

```bash
curl "https://example.com/search?q=test&page=1"

```

*(Le virgolette `"` evitano che la shell interpreti caratteri speciali come `&` o `?`).*

* **GET silenzioso (senza barra di progresso) con output a video:**

```bash
curl -s https://example.com/data

```

* **GET mostrando solo gli header HTTP della risposta:**

```bash
curl -I https://example.com

```

* **GET seguendo i redirect (HTTP 301/302):**

```bash
curl -L https://example.com

```

* **GET con Cookie personalizzato:**

```bash
curl -b "session_id=abcdef123456" https://example.com/dashboard

```

* **GET con Custom Header / Authorization (Bearer Token):**

```bash
curl -H "Authorization: Bearer TUO_TOKEN" -H "Accept: application/json" https://example.com/api/user

```

---

**Richieste POST**

* **POST classico da form (`application/x-www-form-urlencoded`):**

```bash
curl -d "username=admin&password=secretpassword" https://example.com/login

```

*(Il flag `-d` o `--data` imposta automaticamente il metodo su `POST`).*

* **POST con payload JSON (`application/json`):**

```bash
curl -X POST https://example.com/api/utenti \
     -H "Content-Type: application/json" \
     -d '{"name": "Mario", "role": "admin"}'

```

* **POST caricando i dati direttamente da un file locale:**

```bash
curl -X POST https://example.com/api/data \
     -H "Content-Type: application/json" \
     -d @payload.json

```

* **POST multipart per upload file / form data (`multipart/form-data`):**

```bash
curl -F "file=@/percorso/del/file.pdf" -F "categoria=documenti" https://example.com/upload

```

* **POST con parametri multipli via flag separati:**

```bash
curl https://example.com/login -d "user=test" -d "pass=1234"

```

---

**Tabella Riepilogativa dei Flag Principali**

| Flag | Significato | Utilizzo tipico |
| --- | --- | --- |
| `-X` | Specifica il metodo HTTP (`GET`, `POST`, `PUT`, `DELETE`) | `curl -X POST ...` |
| `-d` | Invia dati nel body (imposta metodo su `POST`) | `curl -d "campo=valore" ...` |
| `-H` | Aggiunge un header personalizzato | `curl -H "Content-Type: ..."` |
| `-F` | Invia campi in formato multipart/form-data (upload file) | `curl -F "file=@nome.txt"` |
| `-s` | Modalità silenziosa (Silent, nasconde statistiche) | `curl -s ...` |
| `-i` / `-I` | Mostra gli header della risposta (`-I` invia solo HEAD) | `curl -i ...` |
| `-L` | Segue eventuali reindirizzamenti (3xx) | `curl -L ...` |
| `-b` | Invia cookie di sessione | `curl -b "key=val" ...` |
| `-o` | Salva l'output in un file su disco | `curl -o out.html ...` |
