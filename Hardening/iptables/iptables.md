# Guida & Cheat-Sheet Iptables per Esame Pratico (Debian)


* [iptables Generator](https://iptablesgenerator.totalbits.com/)


## 1. I Concetti Fondamentali

`iptables` lavora per **Tabelle**, **Catene** e **Regole ordinate**:

* **Tabelle:** La più usata per il filtraggio è `filter` (quella di default).
* **Catene principali (`filter`):**
* `INPUT`: Traffico indirizzato **alla macchina locale**.
* `OUTPUT`: Traffico generato **dalla macchina locale verso l'esterno**.
* `FORWARD`: Traffico in transito che attraversa la macchina (routing).

* **Target / Azioni (`-j`):**
* `ACCEPT`: Lascia passare il pacchetto.
* `DROP`: Scarta il pacchetto silenziosamente (senza avvisare il mittente).
* `REJECT`: Rifiuta il pacchetto inviando un errore ICMP indietro.

> **Regola dell'ordine:** Le regole vengono valutate **dall'alto verso il basso**. La prima regola che matcha il pacchetto determina l'azione (`ACCEPT`/`DROP`). Se nessuna regola matcha, scatta la **Policy di default** della Catena.

---

## 2. Anatomia dei Parametri e Flag Più Utilizzati

| Flag | Nome | Significato ed Esempio |
| --- | --- | --- |
| `-F` | Flush | Cancella tutte le regole attive nella tabella: `iptables -F` |
| `-X` | Delete Chains | Cancella le catene personalizzate create dall'utente: `iptables -X` |
| `-P` | Policy | Imposta il comportamento predefinito di una catena: `iptables -P INPUT DROP` |
| `-A` | Append | Aggiunge una regola in fondo alla catena: `iptables -A INPUT ...` |
| `-I` | Insert | Inserisce una regola in cima (o in posizione $N$): `iptables -I INPUT 1 ...` |
| `-D` | Delete | Elimina una specifica regola: `iptables -D INPUT 2` |
| `-p` | Protocol | Protocollo (`tcp`, `udp`, `icmp`, `all`): `-p tcp` |
| `-s` | Source | IP o subnet sorgente: `-s 1.2.3.4` oppure `-s 192.168.1.0/24` |
| `-d` | Destination | IP o subnet di destinazione: `-d 10.0.0.5` |
| `--sport` | Source Port | Porta di chi invia il pacchetto (richiede `-p`): `--sport 80` |
| `--dport` | Dest Port | Porta di chi riceve il pacchetto (richiede `-p`): `--dport 22` |
| `-i` | In-Interface | Interfaccia di rete in ingresso: `-i lo` (loopback), `-i eth0` |
| `-o` | Out-Interface | Interfaccia di rete in uscita: `-o eth0` |
| `-m` | Match Module | Carica un modulo esteso (`conntrack`, `multiport`, `recent`, `mac`) |
| `-j` | Jump / Action | Azione da intraprendere (`ACCEPT`, `DROP`, `REJECT`, `LOG`) |

---

## 3. Il Template Standard (Stateful Firewall)

Ogni script di configurazione Iptables d'esame deve rispettare questa struttura di base per evitare blocchi o disconnessioni accidentali durante l'esecuzione:

```bash
#!/bin/bash
set -e

# 1. AZZERAMENTO (FLUSH)
sudo iptables -F
sudo iptables -X

# 2. DEFAULT POLICIES RESTRITTIVE
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT   # Lascia ACCEPT a meno che non sia richiesto il blocco uscite

# 3. ABILITAZIONE LOOPBACK (127.0.0.1)
# Indispensabile per la comunicazione tra servizi interni del sistema
sudo iptables -A INPUT -i lo -j ACCEPT

# 4. GESTIONE STATO CONNESSIONI (ESTABLISHED, RELATED)
# Mantiene vive le connessioni già attive (evita che cada la sessione SSH dello script)
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 5. INSERISCI QUI LE REGOLE SPECIFICHE DELL'ESERCIZIO...

```

---

## 4. Ricettario Script per Casi Tipici d'Esame

### Caso A: Accesso consentito SOLO via SSH (Porta 22)

```bash
#!/bin/bash
sudo iptables -F && sudo iptables -X
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Regola specifica: solo TCP 22
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

```

---

### Caso B: SSH limitato a un IP sorgente + Webserver (80, 443) aperto a tutti

```bash
#!/bin/bash
ALLOWED_IP="1.2.3.4"

sudo iptables -F && sudo iptables -X
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH solo dall'IP specificato con -s
sudo iptables -A INPUT -p tcp -s "$ALLOWED_IP" --dport 22 -j ACCEPT

# Webserver aperto a tutti con modulo multiport
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

```

---

### Caso C: Blocco di tutto il traffico Internet in uscita, ma Webserver funzionante

> **Scenario:** La macchina non deve poter navigare (`OUTPUT DROP`), ma deve poter rispondere ai client web che chiedono le pagine sulle porte 80 e 443.

```bash
#!/bin/bash
sudo iptables -F && sudo iptables -X

# Blocchiamo sia INPUT che OUTPUT
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP

# Loopback bidirezionale
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# Gestione stato bidirezionale (consente le RISPOSTE ai client)
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Apertura porte Webserver in ingresso
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

```

---

### Caso D: Solo SSH (22) e Webserver (80, 443)

```bash
#!/bin/bash
sudo iptables -F && sudo iptables -X
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Raggruppa tutte le porte in un'unica regola multiport
sudo iptables -A INPUT -p tcp -m multiport --dports 22,80,443 -j ACCEPT

```

---

### Caso E: Blocco traffico ICMP / Ping (Evitare Host Discovery)

```bash
# Blocca le richieste di ping in ingresso (echo-request)
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

```

---

### Caso F: Consentire la risoluzione DNS se OUTPUT è in DROP

Se la policy di `OUTPUT` è impostata su `DROP` ma la macchina deve poter risolvere i nomi di dominio (es. per aggiornare pacchetti):

```bash
# DNS lavora principalmente su UDP 53 e di fallback su TCP 53
sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

```

---

## 5. Verifica e Troubleshooting delle Regole

### Comandi essenziali di ispezione

```bash
# Visualizzazione dettagliata, numerica e con contatore pacchetti (LA PIÙ UTILE)
sudo iptables -L -v -n

# Visualizzazione con numeri di riga (serve per eliminare una specifica riga)
sudo iptables -L -n --line-numbers

# Esempio: eliminare la riga 3 della catena INPUT
sudo iptables -D INPUT 3

```

### Come leggere l'output di `iptables -L -v -n`

```text
Chain INPUT (policy DROP 12 packets, 720 bytes)
 pkts bytes target     prot opt in     out     source               destination         
  150 12000 ACCEPT     all  --  lo     *       0.0.0.0/0            0.0.0.0/0           
  420 35000 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
   25  1500 ACCEPT     tcp  --  *      *       1.2.3.4              0.0.0.0/0            tcp dpt:22

```

* Se la colonna **`pkts`** aumenta quando provi a connetterti, la regola sta intercettando correttamente il traffico.
* `0.0.0.0/0` indica qualsiasi indirizzo IP (*Any*).

---

## 6. Persistenza delle Regole (Salvataggio al Riavvio)

Su Debian, `iptables` perde le regole in memoria al riavvio della macchina. Se l'esercizio richiede di renderle permanenti:

```bash
# 1. Installa il pacchetto non-interattivamente
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent netfilter-persistent

# 2. Salva le regole correnti nei file /etc/iptables/rules.v4 e rules.v6
sudo netfilter-persistent save

# Per ricaricarle manualmente in qualsiasi momento:
sudo netfilter-persistent reload

```
