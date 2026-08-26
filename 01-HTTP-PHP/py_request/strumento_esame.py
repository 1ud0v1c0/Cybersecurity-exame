import json
import re
import requests

# ==============================================================================
# ⚙️ PANNELLO DI CONTROLLO ESAME - MODIFICA SOLO QUI
# ==============================================================================

# 1. Endpoint e Metodo HTTP
URL = "http://web-08.challs.olicyber.it/login"
METHOD = "POST"  # "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD"

# 2. Query Parameters (es. ?id=flag&page=1) -> Lascia {} se non servono
PARAMS = {
    # "id": "flag",
}

# 3. Header HTTP personalizzati -> Lascia {} se non servono
HEADERS = {
    # "X-Password": "admin",
    # "Accept": "application/xml",
    # "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
}

# 4. Cookie inviati con la richiesta -> Lascia {} se non servono
COOKIES = {
    # "session": "xyz123abc",
}

# 5. Payload Dati (Scegli solo UNO tra FORM_DATA o JSON_DATA)
# Form urlencoded (application/x-www-form-urlencoded):
FORM_DATA = {
    "username": "admin",
    "password": "admin",
}

# JSON payload (application/json) -> Lascia None se usi FORM_DATA o GET
JSON_DATA = None
# JSON_DATA = {
#     "username": "admin",
#     "password": "admin",
# }

# 6. Opzioni avanzate
USE_SESSION = False  # True = mantiene cookie/stato tra richieste (requests.Session)
ALLOW_REDIRECTS = True  # Segui i redirect 301/302 automatici
TIMEOUT = 10  # Secondi massimi di attesa

# ==============================================================================
# 🚀 MOTORE DI ESECUZIONE & ANALISI AUTOMATICA (NON MODIFICARE SOTTO)
# ==============================================================================


def inspect_flags(text_sources):
    """Scansiona pattern comuni di flag: flag{...}, FLAG{...}, ctf{...}, ecc."""
    flag_regex = r"(?:flag|FLAG|ctf|CTF|olicyber|[a-zA-Z0-9_-]+)\{[^ \r\n\t<>\"]+\}"
    found = set()
    for src in text_sources:
        if isinstance(src, str):
            matches = re.findall(flag_regex, src)
            for m in matches:
                found.add(m)
    return list(found)


def execute():
    client = requests.Session() if USE_SESSION else requests

    kwargs = {
        "params": PARAMS or None,
        "headers": HEADERS or None,
        "cookies": COOKIES or None,
        "allow_redirects": ALLOW_REDIRECTS,
        "timeout": TIMEOUT,
    }

    if JSON_DATA is not None:
        kwargs["json"] = JSON_DATA
    elif FORM_DATA:
        kwargs["data"] = FORM_DATA

    print(f"[*] Inoltro {METHOD.upper()} -> {URL}")
    if PARAMS:
        print(f"    [Params]  {PARAMS}")
    if HEADERS:
        print(f"    [Headers] {HEADERS}")
    if FORM_DATA:
        print(f"    [Form]    {FORM_DATA}")
    if JSON_DATA:
        print(f"    [JSON]    {JSON_DATA}")

    try:
        res = client.request(METHOD.upper(), URL, **kwargs)

        # 1. Header & Status
        print("\n" + "=" * 65)
        print(f"[+] Status Code  : {res.status_code} ({res.reason})")
        print(f"[+] URL Effettivo: {res.url}")
        print(f"[+] Content-Type : {res.headers.get('Content-Type', 'N/A')}")

        # Traccia eventuali redirect intermedi
        if res.history:
            history_chain = " -> ".join(
                [f"{r.status_code} ({r.url})" for r in res.history]
            )
            print(f"[+] Redirects    : {history_chain} -> {res.status_code}")

        # Mostra cookie ricevuti dal server
        if res.cookies:
            print(f"[+] Nuovi Cookie : {res.cookies.get_dict()}")

        print("=" * 65)

        # 2. Body della risposta (con auto-formattazione JSON)
        print("\n--- BODY RISPOSTA ---")
        is_json = "application/json" in res.headers.get("Content-Type", "")
        if is_json:
            try:
                parsed_json = res.json()
                print(json.dumps(parsed_json, indent=2, ensure_ascii=False))
            except Exception:
                print(res.text)
        else:
            print(res.text if res.text else "<Body Vuoto>")

        # 3. Analisi Automatica Flag (Body + Headers + Cookies)
        search_targets = (
            [res.text] + list(res.headers.values()) + list(res.cookies.values())
        )
        flags = inspect_flags(search_targets)

        if flags:
            print("\n" + "🏁" * 30)
            for f in flags:
                print(f"[🚩] FLAG TROVATA: {f}")
            print("🏁" * 30)
        else:
            print("\n[-] Nessuna flag rilevata automaticamente.")

    except requests.exceptions.RequestException as e:
        print(f"\n[!] Errore di connessione / Timeout: {e}")


if __name__ == "__main__":
    execute()
