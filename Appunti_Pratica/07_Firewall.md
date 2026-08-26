# Capitolo 1: Introduzione alla Sicurezza di Rete e Classificazione dei Firewall

La **sicurezza di rete** comprende l'insieme di strumenti hardware, moduli software e policy progettati per impedire accessi non autorizzati, alterazioni indebite o interruzioni di servizio.

Le reti attuali presentano vulnerabilità strutturali intrinseche:

* **Distanza fisica**: gli attacchi possono essere sferrati da qualsiasi posizione geografica preservando l'anonimato.

* **Debolezza dei protocolli**: molti standard trasmissivi mancano di autenticazione e cifratura nativa, esponendo i dati a sniffing e manipolazioni.

* **Fattore umano**: gli utenti sono vulnerabili a tecniche di ingegneria sociale come il phishing via e-mail o web.

#### Difesa in Profondità (Defense-in-Depth) sullo stack OSI

Per proteggere l'infrastruttura si applicano contromisure stratificate sui diversi livelli dello stack protocollare:

* **Livello Applicativo (L7)**: Application Gateway, NIDS applicativi, autenticazione robusta e crittografia dei dati.

* **Livello di Trasporto (L4)**: Firewall stateful, crittografia del canale di trasporto e NIDS.

* **Livello di Rete (L3)**: Screening router, NAT, segmentazione tramite VLAN e crittografia di rete.

* **Livelli Link e Fisico (L2/L1)**: Hardening degli switch, isolamento fisico delle tratte e crittografia a livello di linea.

---

### 1.1 Classificazione dei Firewall

Un **Firewall** è un dispositivo hardware o software posizionato a confine per filtrare e regolare il traffico tra domini di rete distinti. Si distinguono due macro-categorie principali:

1. **Network Firewall**: operano ai livelli Network (L3) e Transport (L4), esaminando le intestazioni dei pacchetti (IP sorgente/destinazione e porte TCP/UDP) per decidere se consentire il transito.

2. **Application Firewall (Deep Packet Inspection)**: operano fino al livello Applicativo (L7), ispezionando direttamente il carico utile (*payload*) dei pacchetti per rilevare pattern d'attacco o anomalie applicative.

---

### 1.2 Firewall Stateless vs. Firewall Stateful

Nel filtraggio di rete a livello L3/L4, la distinzione chiave riguarda la capacità di memorizzare lo stato temporale delle comunicazioni:

#### 1. Firewall Stateless

Ispeziona ogni singolo pacchetto in maniera totalmente isolata, applicando regole statiche prefissate.

* **Funzionamento**: Valuta esclusivamente la tupla a 4 elementi:
$$\langle\text{IP sorgente}, \text{Porta sorgente}, \text{IP destinazione}, \text{Porta destinazione}\rangle$$

* **Limite**: Non ha memoria del passato; non distingue un pacchetto appartenente a una connessione legittima in corso da un pacchetto ostile isolato (es. blocca o accetta incondizionatamente il traffico UDP su una determinata porta).

#### 2. Firewall Stateful

Traccia l'intera evoluzione della sessione all'interno di una tabella dinamica degli stati (*connection tracking*). Monitora i flag e i numeri di sequenza per le connessioni TCP, mentre per protocolli privi di stato come UDP simula la sessione raggruppando temporalmente i pacchetti con le medesime tuple IP/porta.

* **Stati Principali**:
	* `NEW`: pacchetto iniziale che avvia la connessione (es. TCP SYN).
	* `ESTABLISHED`: tutti i pacchetti successivi che viaggiano all'interno di una sessione già autorizzata.

* **Safe Default Policy**: una volta convalidato il primo pacchetto (`NEW`), tutti i pacchetti di ritorno appartenenti alla medesima sessione (`ESTABLISHED`) vengono **accettati in automatico**. In assenza di questa regola di ritorno, i client non riceverebbero le risposte dai server remoti.

---
### 1.3 Unified Threat Management (UTM)

I dispositivi **UTM** (o firewall evoluti) integrano in un unico apparato hardware diverse funzioni di sicurezza che storicamente richiedevano macchine separate:

* Firewall stateful di rete.
* NIDS/NIPS (rilevamento e prevenzione intrusioni).
* Antivirus, antimalware e antispam a livello di gateway.
* Terminazione di tunnel VPN.
* Deep Packet Inspection (DPI).
* Bilanciamento del carico di traffico (*Load Balancing*).

---

# Capitolo 2: Architetture di Sicurezza: NAT, DMZ e Configurazione dei Confini

La segmentazione di rete e il posizionamento corretto dei firewall sono fondamentali per compartimentare le risorse e impedire i movimenti laterali degli aggressori.

---
### 2.1 Firewall a Due Interfacce (Configurazione Base)

![[Screenshot 2025-11-07 alle 15.16.51.png]]

La topologia classica a due interfacce separa la rete interna fidata (**Intranet**) da quella esterna non fidata (**Internet**):

* **Interfaccia Trusted**: connessa alla Intranet.
* **Interfaccia Untrusted**: connessa alla rete Internet pubblica.

#### Politica Predefinita (Safe Default)

* **Traffico in Uscita (Outbound)**: consentito per le nuove connessioni (`state NEW`), permettendo la normale navigazione degli utenti interni verso l'esterno.

* **Traffico in Entrata (Inbound)**: bloccato di default per i nuovi tentativi di connessione; vengono accettati solo i pacchetti di ritorno appartenenti a sessioni già avviate dall'interno (`state ESTABLISHED,RELATED`).

---

### 2.2 NAT (Network Address Translation)

Poiché la rete interna adotta classi di IP privati non instradabili su Internet, il firewall esegue la traduzione degli indirizzi al volo:

* **S-NAT (Source NAT)**: usato quando un host privato deve uscire su Internet. Il gateway riscrive l'IP sorgente privato con il proprio IP pubblico e memorizza l'associazione in tabella per reindirizzare le risposte.
	* *Collocazione in Netfilter*: tabella `nat`, catena `POSTROUTING` (un attimo prima che il pacchetto esca).

* **D-NAT (Destination NAT / Port Forwarding)**: usato per esporre un servizio interno (es. server web) tramite l'IP pubblico del firewall. Il gateway riceve il pacchetto e ne riscrive l'IP di destinazione con l'indirizzo privato reale del server.
	* *Collocazione in Netfilter*: tabella `nat`, catena `PREROUTING` (appena il pacchetto entra, prima della decisione di routing).

---

### 2.3 DMZ (Demilitarized Zone): Isolamento dei Servizi Pubblici

![[Screenshot 2025-11-07 alle 15.18.20.png]]

Posizionare i server pubblici direttamente nella Intranet è un grave rischio: la compromissione del server esporrebbe immediatamente tutti i client e i database interni.

Per questo si isolano i server esposti all'interno di una **DMZ** (zona perimetrale separata da Internet e Intranet):

* **Da Internet a DMZ**: accesso consentito per nuove connessioni (`NEW`) esclusivamente sulle porte dei servizi esposti (es. 80/443 per HTTP/HTTPS).

* **Da Intranet a DMZ**: consentito per manutenzione e consultazione da parte degli utenti interni.

* **Da DMZ a Intranet**: **tassativamente vietato avviare nuove connessioni (`NEW`)**. Se il server web in DMZ viene compromesso, l'attaccante resta confinato nella DMZ e non può scansionare o attaccare la Intranet.

---

### 2.4 Analisi Pratica di un Ruleset Iptables con DMZ

![[Screenshot 2025-11-07 alle 15.54.40.png]]

Topologia a 3 interfacce:
* `eth0`: Intranet (Fidata)
* `eth1`: DMZ (Server Web)
* `eth2`: Internet (Esterna)

```iptables
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

-A FORWARD -i eth2 -o eth1 -m state --state NEW -j ACCEPT
-A FORWARD -i eth2 -o eth0 -m state --state NEW -j ACCEPT
-A FORWARD -i eth0 -o eth1 -m state --state NEW -j ACCEPT
-A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
COMMIT
```

#### Valutazione delle Regole:
- `:FORWARD DROP`: policy di default che scarta tutto il traffico in transito non esplicitamente consentito.
- `-A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT`: consente il transito bidirezionale a tutti i pacchetti di ritorno per sessioni già autorizzate.
- `-A FORWARD -i eth2 -o eth1 -m state --state NEW -j ACCEPT`: permette all'esterno di avviare connessioni verso i servizi in DMZ.
- `-A FORWARD -i eth0 -o eth1 -m state --state NEW -j ACCEPT`: consente alla rete interna di accedere ai server in DMZ.

> [!CAUTION] Falla di Configurazione
> La regola `-A FORWARD -i eth2 -o eth0 -m state --state NEW -j ACCEPT` consente a chiunque da Internet (`eth2`) di avviare nuove connessioni direttamente verso la Intranet interna (`eth0`)[cite: 4]. Questa regola **annulla l'isolamento della rete privata** e va categoricamente rimossa[cite: 4].

---

# Capitolo 3: Minacce di Rete: Denial of Service (DoS/DDoS) e Sistemi di Mitigazione

Gli attacchi **Denial of Service (DoS)** e **Distributed Denial of Service (DDoS)** mirano a colpire la **Disponibilità** (*Availability*) di un servizio, esaurendo le risorse fisiche o computazionali della vittima per renderla irraggiungibile agli utenti legittimi.

---

### 3.1 DoS vs. DDoS
* **DoS**: condotto da una singola macchina sorgente.
* **DDoS**: orchestrato tramite una rete distribuita di macchine compromesse (**botnet**), spesso costituita da migliaia di dispositivi IoT non protetti.

#### Caratteristiche dei DDoS:

* **Volumetria enorme**: flussi da decine o centinaia di Gbps che saturano l'ampiezza di banda dei collegamenti di rete.

* **IP Spoofing**: falsificazione dell'indirizzo IP di origine nei pacchetti, impedendo il filtraggio banale per singolo IP sorgente.

* **Vettori multipli**: combinazione simultanea di attacchi a livello di rete (L3/L4) e a livello applicativo (L7).

---

### 3.2 Tassonomia delle Tecniche di Attacco

1. **Flooding Attacks (L3/L4)**: inondazione di pacchetti standard per saturare canali o risorse di routing (es. UDP flood, ICMP/Ping flood, TCP SYN-flood).

2. **Logic/Application Attacks (L7)**: attacchi a basso consumo di banda che sfruttano la logica dei server applicativi per esaurirne i thread o i processi (es. Slowloris).

3. **Amplification Attacks**: sfruttamento di protocolli asimmetrici privi di autenticazione basati su UDP (es. DNS, NTP).

---

### 3.3 TCP SYN-flood e Mitigazione con SYN-proxy

#### Il Meccanismo del SYN-flood

Sfrutta la fase iniziale del **TCP 3-way handshake**:

```text
[Attaccante (Spoofed)]      [Server]
        |                      |
        |------ 1. SYN ------->| (Alloca RAM: Half-Open)
        |<---- 2. SYN-ACK -----| (Attende risposta...)
        |                      |
      [ × ] (Nessun ACK inviato)
```

L'attaccante invia valanghe di pacchetti SYN con IP di origine falsificati. Il server risponde con SYN-ACK e alloca strutture dati in memoria per le connessioni semi-aperte (*half-open*). Non ricevendo mai l'ACK finale di conferma, la RAM del server si satura e non accetta più nuove connessioni legittime.

#### La Difesa: SYN-proxy sul Firewall (L4)
Il firewall intercetta il traffico e funge da cuscinetto di validazione:

```text
[Client]              [Firewall / Proxy]            [Server]
   |                          |                        |
   |------- 1. SYN ---------->|                        | (Nessuna allocazione)
   |<----- 2. SYN-ACK --------|                        |
   |------- 3. ACK ---------->|                        |
   |                          |                        |
   |               [ Verifica Riuscita! ]              |
   |                          |                        |
   |                          |------- 4. SYN -------->|
   |                          |<----- 5. SYN-ACK ------|
   |                          |------- 6. ACK -------->|
   |                          |                        |
   |<============ Flusso Dati Bidirezionale ===========>|
```

1. Il firewall riceve il SYN dal client e risponde direttamente con un proprio SYN-ACK, **senza disturbare il server di backend**.
2. Se l'IP era falso, il pacchetto ACK finale non arriva e il tentativo decade sul firewall a costo computazionale nullo per il server.
3. Se l'IP è legittimo, all'arrivo dell'ACK finale il firewall apre un handshake reale con il server e inizia a fare da proxy trasparente per il flusso dati.

---

### 3.4 Attacco Slowloris (Livello Applicativo L7)

Lo **Slowloris** consente a una singola macchina con pochissima banda di mandare offline server web a processi/thread dedicati (come Apache):

1. L'attaccante apre centinaia di connessioni HTTP simultanee verso il server.
2. Invia le intestazioni HTTP (*headers*) **in modo estremamente frammentato e lento** (es. una riga ogni 10-15 secondi), senza mai inviare la sequenza di chiusura `\r\n\r\n`.
3. Il server web tiene bloccati i thread in attesa del completamento delle richieste fino a saturare il pool massimo disponibile, rendendo impossibile servire gli utenti reali.

---

### 3.5 Attacchi di Amplificazione (DNS e NTP)

Sfruttano protocolli UDP non autenticati in cui una richiesta minuscola genera una risposta volumetrica enorme:

- **Meccanismo**: L'attaccante invia richieste a server pubblici (DNS/NTP) inserendo tramite **IP Spoofing** l'indirizzo della vittima come mittente. I server riflettono e amplificano le risposte direttamente contro la vittima.
- **DNS Amplification**: query con record complessi (es. `ANY`) trasformano una richiesta di pochi byte in pacchetti di risposta di dimensioni fino a decine di volte superiori.
- **NTP Amplification** (_Network Time Protocol_): l'esecuzione di comandi diagnostici storici come `monlist` restituisce la lista degli ultimi 600 host connessi, generando una risposta massiccia.

---

### 3.6 Limiti dei Firewall contro i DDoS Volumetrici

- **Saturazione del Canale Fisico**: Se l'attacco DDoS satura la capacità massima della linea del provider, **il firewall locale non può fare nulla** perché il link di accesso è già completamente intasato a monte.
- **Mitigazioni su Scala Geografica**: Richiedono servizi di rete distribuiti come **CDN** e instradamento tramite **Anycast** per assorbire e distribuire il carico su scala globale.
- **Contromisure Anti-Bot (Senza Spoofing)**: Se gli IP sorgente sono reali, il firewall può applicare rate-limiting, blacklist dinamiche e strutture in memoria come i *Bloom Filters* per isolare le sessioni anomale.

---
# Capitolo 4: Linux Netfilter: Architettura, Tabelle, Catene e Regole (iptables)

In ambiente Linux, la gestione e il filtraggio del traffico di rete sono integrati direttamente nel kernel del sistema operativo tramite il framework **Netfilter**.

* **Netfilter**: è il modulo interno al kernel dotato di speciali punti di aggancio (*hooks*) nello stack di rete per intercettare i pacchetti ed eseguire packet filtering, connection tracking e NAT.

* **`iptables`**: è l'utility da riga di comando nello spazio utente (*user-space*) che permette all'amministratore di definire e inviare le regole al motore Netfilter.

---

### 4.1 Le Tabelle (Tables)

Le tabelle raggruppano le regole in base alla tipologia di operazione da applicare sul pacchetto:

* **`filter`** (Default): deputata al filtraggio classico (decidere se accettare o scartare un pacchetto).
	* *Catene*: `INPUT`, `FORWARD`, `OUTPUT`.

* **`nat`**: dedicata alla traduzione degli indirizzi IP e delle porte (SNAT/DNAT).
	* *Catene*: `PREROUTING`, `POSTROUTING`, `OUTPUT`.

* **`mangle`**: usata per manipolazioni avanzate degli header, come il *packet marking* per Quality of Service (QoS) o routing avanzato.
	* *Catene*: `PREROUTING`, `INPUT`, `FORWARD`, `OUTPUT`, `POSTROUTING`.

---

### 4.2 Le Catene (Chains)

Le catene sono sequenze ordinate di regole valutate nei diversi punti di passaggio del pacchetto attraverso il kernel:

* **`PREROUTING`**: appena il pacchetto entra nell'interfaccia, prima di qualunque decisione di instradamento (ideale per DNAT).
* **`INPUT`**: per i pacchetti destinati localmente a processi o servizi dell'host.
* **`FORWARD`**: per i pacchetti in transito da inoltrare verso un'altra interfaccia (l'host funge da router).
* **`OUTPUT`**: per i pacchetti generati localmente da applicazioni dell'host e diretti all'esterno.
* **`POSTROUTING`**: subito prima che il pacchetto lasci fisicamente l'interfaccia di uscita (ideale per SNAT).

> [!NOTE] Policy di Default
> Se un pacchetto scorre l'intera catena senza attivare nessuna regola, viene applicata la **Policy di Default** della catena (impostata di norma su `DROP` per ragioni di sicurezza).
> 
> 

---

### 4.3 Regole (Rules) e Target (Actions)

![[Screenshot 2025-11-07 alle 15.29.34.png]]

Ogni regola segue una logica *if-then*: verifica una serie di parametri di corrispondenza (*match*) e applica una specifica azione (*target*).

#### 1. Parametri di Corrispondenza (Match)

* `-p <proto>`: protocollo di trasporto (`tcp`, `udp`, `icmp`).
* `-s <ip>` / `-d <ip>`: IP sorgente (`-s`) o destinazione (`-d`). Il punto esclamativo `!` inverte il match  (es. `-s ! 192.168.1.50`  tutto tranne `192.168.1.50`).
* `--sport <porta>` / `--dport <porta>`: porta di origine o destinazione.
* `-i <iface>` / `-o <iface>`: interfaccia di ingresso (`-i`) o di uscita (`-o`).
* `--syn`: intercetta i pacchetti di avvio connessione TCP (SYN=1, ACK=0).

#### 2. Target e Decisioni

* **Terminanti** (interrompono subito la catena):
	* `ACCEPT`: lascia passare il pacchetto.
	* `DROP`: scarta il pacchetto silenziosamente senza alcuna notifica al mittente.
	* `REJECT`: scarta il pacchetto inviando un messaggio di errore ICMP al mittente.

* **Non Terminanti** (controllo del flusso):
	* `-j <catena_personalizzata>`: salta a una catena definita dall'utente.
	* `RETURN`: interrompe la catena corrente e torna a quella chiamante.

---

### 4.4 Gestione e Persistenza dei Comandi

* `-t <table>`: seleziona la tabella (default `filter`).
* `-L`: elenca le regole attive.
* `-F` (o `--flush`): svuota tutte le regole della tabella selezionata.
* `-A <catena>`: appende una regola in coda alla catena.

> [!WARNING] Volatilità della configurazione
> I comandi `iptables` lavorano **solo in memoria RAM**. Al riavvio della macchina tutte le modifiche andrebbero perse.
> 
> 
> Per salvare e ripristinare le configurazioni:
> 
> 
> ```bash
> # Salvataggio su file
> iptables-save > /etc/iptables/rules.v4
> 
> # Ripristino da file
> iptables-restore < /etc/iptables/rules.v4
> 
> ```
> 
> 

---

### 4.5 Esempi Pratici di Configurazione

Topologia di riferimento:

* `eth0`: Intranet (`192.168.1.0/24`)
* `eth1`: DMZ (Web Server `10.0.1.50`)
* `eth2`: Internet (IP Pubblico Firewall `203.0.113.5`)
#### Esempio 1: Filtraggio Traffico verso DMZ (Tabella `filter`)
Consentire il traffico HTTP da Internet verso il server in DMZ:
```bash
iptables -t filter -A FORWARD -i eth2 -o eth1 -p tcp --dport 80 -d 10.0.1.50 -j ACCEPT
```

#### Esempio 2: Navigazione Rete Interna con S-NAT (Tabella `nat`)
Mascherare gli indirizzi privati della Intranet con l'IP pubblico in uscita:
```bash
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth2 -j SNAT --to-source 203.0.113.5
```

#### Esempio 3: Port Forwarding con D-NAT (Tabella `nat`)
Inoltrare il traffico HTTP in arrivo sull'IP pubblico verso il server interno reale:
```bash
iptables -t nat -A PREROUTING -i eth2 -p tcp --dport 80 -j DNAT --to-destination 10.0.1.50:80
```

---
# Capitolo 5: Stateful Firewalling, Moduli Estesi e l'Evoluzione con `nftables`

### 5.1 Connection Tracking (`state` / `conntrack`)

Il modulo di **Connection Tracking** è il componente che trasforma Netfilter in un firewall **stateful**, registrando in una tabella dinamica lo stato delle sessioni attive che attraversano l'host.

#### Informazioni tracciate dal modulo

* Protocollo di trasporto.
* Per TCP/UDP: tupla a 5 elementi 
$$\langle\text{IP sorgente}, \text{Porta sorgente}, \text{IP destinazione}, \text{Porta destinazione}, \text{Protocollo}\rangle$$
* Per ICMP (es. ping): tupla 
$$\langle\text{IP sorgente}, \text{IP destinazione}\rangle$$
#### I 4 Stati di Connessione:

1. **`NEW`**: il pacchetto iniziale che tenta di aprire una connessione (es. TCP SYN).
2. **`ESTABLISHED`**: tutti i pacchetti successivi che transitano all'interno di una sessione già validata con traffico bidirezionale confermato.
3. **`RELATED`**: una nuova connessione aperta in stretta correlazione con una sessione già attiva (es. canale dati passivo in FTP o messaggi di errore ICMP associati a una connessione TCP).
4. **`INVALID`**: pacchetti anomali non associabili ad alcuna sessione nota (dati corrotti, combinazioni di flag TCP incoerenti).

---

### 5.2 Moduli Estesi (`-m`)

Netfilter può essere arricchito caricando moduli opzionali con il flag **`-m`** per definire criteri di filtraggio avanzati:

* **`state` / `conntrack`**: abilita il filtraggio basato sullo stato delle connessioni (`NEW`, `ESTABLISHED`, ecc.). trasformando quindi un Firewall stateless in uno __stateful__

* **`mac`**: filtra i pacchetti in ingresso controllando l'**indirizzo MAC fisico (Layer 2)**, utile per consentire o bloccare dispositivi hardware specifici sulla rete locale.

* **`limit`**: applica un tetto alla frequenza di ricezione dei pacchetti (*rate limiting*) per contrastare attacchi DoS (es. flood di ping ICMP) o rallentare i port scanner.

* **`iprange`**: consente di specificare un intervallo continuo di indirizzi IP sorgente o destinazione (es. `192.168.1.13-192.168.2.19`) senza vincoli di subnetting CIDR.

---
### 5.3 L'Evoluzione di Netfilter: `nftables`

Nei sistemi Linux attuali, **`nftables`** è il successore moderno deputato a rimpiazzare i vecchi comandi (`iptables`, `ip6tables`, `arptables`, `ebtables`).
#### Caratteristiche principali:

* **Costruito su Netfilter**: non sostituisce il framework Netfilter all'interno del kernel, ma fornisce un'interfaccia molto più efficiente e unificata per dialogare con esso.

* **Sintassi unica e coerente**: permette di gestire con un solo tool regole IPv4, IPv6, ARP e bridge di rete.

* **Transizione con `iptables-nft`**: per mantenere la retrocompatibilità, le distribuzioni moderne forniscono il wrapper `iptables-nft`, che converte al volo i classici comandi `iptables` in regole native per il motore `nftables`.

---
