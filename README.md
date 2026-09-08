# Cybersecurity - Materiale ed Esercizi d'Esame (Uni Roma 3)

Repository GitHub di riferimento:
🔗 **[https://github.com/1ud0v1c0/Cybersecurity-exame/](https://github.com/1ud0v1c0/Cybersecurity-exame/)**

---

## 🚀 Clonare la Repository nella Macchina Virtuale

Durante l'esame o durante le prove pratiche, puoi clonare rapidamente tutti gli script e le soluzioni all'interno della cartella home (`~`) della macchina virtuale tramite:

```bash
git clone https://github.com/1ud0v1c0/Cybersecurity-exame.git
cd Cybersecurity-exame
```

Oppure, se la macchina virtuale non dispone di Git ma ha connessione internet:
```bash
# Scarica l'archivio zip della repository
wget https://github.com/1ud0v1c0/Cybersecurity-exame/archive/refs/heads/main.zip -O repo.zip
unzip repo.zip
cd Cybersecurity-exame-main
```

---

## 📂 Struttura della Repository

### 🛡️ Linux Hardening (`Hardening/`)
Script completamente automatizzati per le tracce d'esame di messa in sicurezza:
* **`iptables/`**: Regole firewall stateful, filtraggio porte Web (80, 443), SSH (22), limitazione per IP sorgente (`-s`) e blocco traffico in uscita (`OUTPUT DROP`). Include la guida teorico-pratica [iptables.md](file:///Users/ludovicovitiello/Desktop/uni_roma3/Cybersecurity/Hardening/iptables/iptables.md).
* **`sudo/`**: Regole in `/etc/sudoers.d/` per consentire singoli comandi o vietare specifici argomenti (es. `!*-p*`).
* **`03-suid-sgid.sh`**: Ricerca automatica di eseguibili con bit SUID e SGID attivi.
* **`04-systemd-netcat-shell.sh`**: Creazione e avvio di un servizio Systemd con shell bind via ncat.
* **`05-pam-semplice.sh`**: Configurazione del modulo PAM `pwquality` per requisiti minimi di robustezza password.
* **`06-GRUB-password.sh`**: Protezione del bootloader GRUB con utente e password cifrata PBKDF2.
* **`07-docker-escalation.sh`**: Privilege escalation tramite container Docker con montaggio rootfs host.
* **`08-File-Directory-scrivibili-da-tutti.sh`**: Rilevamento file e cartelle world-writable nella home utente.
* **`09-passw-utente-che-scade.sh`**: Creazione utente con invecchiamento password giornaliero (`chage -M 1`).
* **`permessi/06-var-log.sh`**: Hardening dei permessi di `/var/log` e configurazione accesso controllato.

### 🌐 Web Security
* **`01-HTTP-PHP`**: Basi di protocollo HTTP, header e PHP security.
* **`02-Command-Code-Injection`**: Vulnerabilità di iniezione comandi OS e codice.
* **`03-File-disclusure`**: Local File Inclusion (LFI) e Path Traversal.
* **`04-SSRF`**: Server-Side Request Forgery.
* **`05-SQL-Injection`**: SQLi, payload e blind exploitation.
* **`06-XSS`**: Cross-Site Scripting (Reflected, Stored, DOM).
* **`07-CSRF`**: Cross-Site Request Forgery e bypass.
* **`08-Insecure-File-Upload`**: Bypass di validazione estensioni e content-type.

### 📖 Guide e Risorse
* **[Guida-SSH.md](file:///Users/ludovicovitiello/Desktop/uni_roma3/Cybersecurity/Guida-SSH.md)**: Guida completa alla connessione SSH, port forwarding con VirtualBox e trasferimento file (SCP).
