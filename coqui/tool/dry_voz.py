#!/usr/bin/env python3
"""A dry run of the audio job (historia/tools/voz.py in MODO=cuento), with no key and no network.

    python3 coqui/tool/dry_voz.py                      the voz.py of this tree
    python3 coqui/tool/dry_voz.py --voz /path/voz.py   another copy (for example the one on main), same tree around it
    python3 coqui/tool/dry_voz.py --rate=-10%          a what-if (a changed rate must list every clip): proves the dry run can see a change
    python3 coqui/tool/dry_voz.py --new abuela_dice    a what-if: that clip is forgotten by ready.json, so voz.py "records" it again; the stand-in
                                                       for Azure answers with the clip's own mp3, so the marks step runs on a real file

voz.py has no dry-run switch, and its decision (a clip is recorded when the hash of voice, rate and text differs
from ready.json, or its mp3 is missing) sits in the middle of the script, after the call that lists Azure's voices.
So the script itself is run, unchanged, in a scratch copy of historia/ (the stories, the mp3 files, ready.json and
marcas.json are copied, so nothing in the repository can be written), with:
  - the environment the workflow gives a push (voices and rate read from .github/workflows/voz.yml);
  - urllib.request.urlopen replaced: the list of voices is answered from ready.json, and any other request (a clip to
    record) is counted and answered with an empty body, never sent; socket connections are refused as well;
  - time.sleep made instant.
Prints voz.py's own output, how many clips it would have recorded, and whether ready.json and marcas.json came out
byte-identical. Exit 1 when it would record anything.
"""
import argparse, html, json, os, re, runpy, shutil, socket, sys, tempfile, time, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HIS = os.path.join(ROOT, "historia")

ap = argparse.ArgumentParser()
ap.add_argument("--voz", default=os.path.join(HIS, "tools", "voz.py"))
ap.add_argument("--rate", default=None)
ap.add_argument("--new", action="append", default=[])
args = ap.parse_args()

# ---- the environment of a push, from the workflow -------------------------------------------------------------
yml = open(os.path.join(ROOT, ".github", "workflows", "voz.yml"), encoding="utf-8").read()
def push_default(name):
    m = re.search(r"^\s*" + name + r":\s*\$\{\{\s*inputs\.\w+\s*\|\|\s*'([^']*)'\s*\}\}", yml, re.M)
    if m:
        return m.group(1)
    if re.search(r"^\s*" + name + r":\s*\$\{\{\s*inputs\.\w+\s*\}\}", yml, re.M):
        return ""   # no default: empty on a push
    raise SystemExit(f"dry_voz: {name} not found in voz.yml")
env = {"AZURE_SPEECH_KEY": "dry-run-no-key", "AZURE_SPEECH_REGION": "dry-run", "MODO": push_default("MODO"),
       "V_NARR": push_default("V_NARR"), "V_ABUELA": push_default("V_ABUELA"), "V_TU": push_default("V_TU"), "RATE": push_default("RATE")}

if args.rate is not None:
    env["RATE"] = args.rate

# ---- a scratch copy of historia/ --------------------------------------------------------------------------------
tmp = tempfile.mkdtemp(prefix="dry_voz_")
his = os.path.join(tmp, "historia")
os.makedirs(os.path.join(his, "tools"))
shutil.copytree(os.path.join(HIS, "cuentos"), os.path.join(his, "cuentos"))   # copies, never links: voz.py writes into audio/ and a link would reach the repository
shutil.copytree(os.path.join(HIS, "audio"), os.path.join(his, "audio"))
shutil.copy(args.voz, os.path.join(his, "tools", "voz.py"))
for extra in ("marcas.py",):   # a helper voz.py may import, taken from this tree
    if os.path.exists(os.path.join(HIS, "tools", extra)):
        shutil.copy(os.path.join(HIS, "tools", extra), os.path.join(his, "tools", extra))
ready = json.load(open(os.path.join(HIS, "audio", "ready.json"), encoding="utf-8"))
if args.new:   # forget these clips in the scratch ready.json, and keep their mp3 to answer with
    scratch = os.path.join(his, "audio", "ready.json")
    forgot = json.load(open(scratch, encoding="utf-8"))
    for cid in args.new:
        if cid not in forgot["hechos"]:
            raise SystemExit(f"dry_voz: {cid} is not in ready.json")
        del forgot["hechos"][cid]
    json.dump(forgot, open(scratch, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    import glob
    text_of = {}
    for f in glob.glob(os.path.join(HIS, "cuentos", "*.json")):
        for cid, clip in json.load(open(f, encoding="utf-8")).get("clips", {}).items():
            text_of[cid] = clip["text"]
    answers = {text_of[cid]: open(os.path.join(HIS, "audio", cid + ".mp3"), "rb").read() for cid in args.new}   # the line's text -> its own mp3
else:
    answers = {}

# ---- no network ---------------------------------------------------------------------------------------------------
would = []
class Body:
    def __init__(self, b): self.b = b
    def __enter__(self): return self
    def __exit__(self, *a): return False
    def read(self): return self.b
def urlopen(req, timeout=None):
    url = req.full_url if hasattr(req, "full_url") else str(req)
    if url.endswith("/voices/list"):
        names = sorted(set(list(ready["voces"].values()) + [env["V_NARR"], env["V_TU"]] + ([env["V_ABUELA"]] if env["V_ABUELA"] else [])))
        return Body(json.dumps([{"ShortName": n, "Locale": n[:5], "Gender": "x"} for n in names]).encode())
    ssml = (req.data or b"").decode("utf-8", "replace")
    text = html.unescape(re.sub(r"<[^>]*>", "", ssml))
    would.append(text)
    return Body(answers.get(text, b""))
def refuse(*a, **k): raise OSError("dry_voz: no network in a dry run")
urllib.request.urlopen = urlopen
socket.socket.connect = refuse
time.sleep = lambda s: None

# ---- run it ---------------------------------------------------------------------------------------------------------
os.environ.update(env)
sys.argv = [os.path.join(his, "tools", "voz.py")]
sys.path.insert(0, os.path.join(his, "tools"))
print(f"dry run of {os.path.relpath(args.voz, ROOT) if args.voz.startswith(ROOT) else args.voz} with voices {env['V_NARR']} / {env['V_ABUELA'] or '(narr)'} / {env['V_TU']}, rate {env['RATE']}")
try:
    runpy.run_path(sys.argv[0], run_name="__main__")
finally:
    print(f"\nrequests that would have recorded a clip: {len(would)}" + "".join(f"\n  {t[:80]}" for t in would[:10]))
    for name in ("ready.json", "marcas.json"):
        a, b = os.path.join(HIS, "audio", name), os.path.join(his, "audio", name)
        if os.path.exists(a):
            print(f"{name}: {'byte-identical to the repository copy' if open(a, 'rb').read() == open(b, 'rb').read() else 'CHANGED by the run'}")
    shutil.rmtree(tmp, ignore_errors=True)
sys.exit(1 if would else 0)
