"""Turns the story's lines into audio files with Azure Speech.

MODO=muestras  the same six lines, read by every Spanish voice Azure has. No voice is left out.
               -> historia/muestras/<voice>.mp3 and historia/muestras/voces.json
MODO=cuento    every clip in historia/lines.json, in the chosen voices
               -> historia/audio/<clip>.mp3 and historia/audio/ready.json
The key is read from the environment and is never printed.
"""
import json, os, sys, time, html, urllib.request, urllib.error

KEY = os.environ.get("AZURE_SPEECH_KEY", "").strip()
REGION = os.environ.get("AZURE_SPEECH_REGION", "").strip()
MODO = os.environ.get("MODO", "muestras").strip() or "muestras"
RATE = os.environ.get("RATE", "-12%").strip() or "-12%"
if not KEY or not REGION:
    sys.exit("Missing the secret AZURE_SPEECH_KEY (or the region).")
BASE = f"https://{REGION}.tts.speech.microsoft.com/cognitiveservices"
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # historia/
CHARS = 0

def call(url, data=None, headers=None, tries=6):
    h = {"Ocp-Apim-Subscription-Key": KEY, "User-Agent": "coqui-voz"}
    h.update(headers or {})
    for n in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, data=data, headers=h), timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503) and n < tries - 1:
                time.sleep(8 * (n + 1)); continue
            sys.exit(f"Azure answered {e.code} for {url.split('/')[-1]}: {e.read()[:300]!r}")
        except urllib.error.URLError as e:
            if n < tries - 1:
                time.sleep(5); continue
            sys.exit(f"Could not reach Azure: {e}")

def speak(voice, locale, parts, out):
    """parts: list of lines; a pause is put between them."""
    global CHARS
    body = "<break time='800ms'/>".join(html.escape(p) for p in parts)
    CHARS += sum(len(p) for p in parts)
    ssml = (f"<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='{locale}'>"
            f"<voice name='{voice}'><prosody rate='{RATE}'>{body}</prosody></voice></speak>")
    audio = call(BASE + "/v1", ssml.encode("utf-8"),
                 {"Content-Type": "application/ssml+xml", "X-Microsoft-OutputFormat": "audio-24khz-48kbitrate-mono-mp3"})
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "wb") as f:
        f.write(audio)
    time.sleep(3.2)   # the free tier allows 20 requests a minute

voices = json.loads(call(BASE + "/voices/list"))
spanish = sorted((v for v in voices if v.get("Locale", "").lower().startswith("es-")), key=lambda v: (v["Locale"], v["ShortName"]))
by_name = {v["ShortName"]: v for v in voices}
lines = json.load(open(os.path.join(HERE, "lines.json"), encoding="utf-8"))["clips"]

if MODO == "muestras":
    sample = ["La casa.", "Toca la puerta.", "Sí. Es la abuela.", "La abuela abre la puerta.", "Hola, abuela.", "La casa de la abuela."]
    done = []
    for v in spanish:
        speak(v["ShortName"], v["Locale"], sample, os.path.join(HERE, "muestras", v["ShortName"] + ".mp3"))
        done.append({"voz": v["ShortName"], "nombre": v.get("LocalName") or v.get("DisplayName"), "lugar": v.get("LocaleName"), "locale": v["Locale"], "genero": v.get("Gender")})
        print("ok", v["ShortName"])
    json.dump({"lineas": sample, "rate": RATE, "voces": done}, open(os.path.join(HERE, "muestras", "voces.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(len(done), "voices,", CHARS, "characters")
else:
    pick = {"narr": os.environ.get("V_NARR", "").strip(), "abuela": os.environ.get("V_ABUELA", "").strip(), "tu": os.environ.get("V_TU", "").strip()}
    if not pick["narr"]:
        sys.exit("cuento needs a narrator voice.")
    pick["abuela"] = pick["abuela"] or pick["narr"]
    pick["tu"] = pick["tu"] or pick["narr"]
    for who, name in pick.items():
        if name not in by_name:
            sys.exit(f"Azure has no voice called {name} in this region.")
    for cid, clip in lines.items():
        v = by_name[pick.get(clip.get("who", "narr"), pick["narr"])]
        speak(v["ShortName"], v["Locale"], [clip["text"]], os.path.join(HERE, "audio", cid + ".mp3"))
        print("ok", cid)
    json.dump({"voces": pick, "rate": RATE, "clips": sorted(lines)}, open(os.path.join(HERE, "audio", "ready.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(len(lines), "clips,", CHARS, "characters")
