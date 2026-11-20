"""Checks a story file against its scene and every other story, before any machine play.
    python3 revisa_cuento.py <repo> <story.json> [more.json ...]
Errors stop a build. Notes are worth reading. Reads only data files, never runs the game."""
import json,glob,os,re,sys,unicodedata
R=sys.argv[1]
def norm(t):return re.sub(r"[^a-z0-9ñ ]","",unicodedata.normalize("NFC",t.lower())).strip()
todos={}
for f in glob.glob(f"{R}/historia/cuentos/*.json"):
    try:todos[os.path.basename(f)[:-5]]=json.load(open(f))
    except Exception as e:print("cannot read",f,e)
try:FIJOS=set(json.load(open(f"{R}/historia/datos/fijos.json")).get("lineas",{}).keys())
except Exception:FIJOS=set()
def inv(scene):
    p=f"{R}/coqui/ref/escenas/{scene}/inventory.json"
    return json.load(open(p)) if os.path.exists(p) else None
REF_KEYS={"say","line","bien"}          # values that are clip ids
LIST_KEYS={"lead"}                       # lists of steps
MAP_KEYS={"said","voces"}                # maps of answer -> clip id
def check(path):
    s=json.load(open(path));sid=s.get("id") or os.path.basename(path)[:-5]
    err,note=[],[]
    for k in ["id","title","place","scene","goal","stake","focus_words","clips","beats","final"]:
        if k not in s:err.append(f"missing field {k}")
    clips=s.get("clips",{});scene=s.get("scene")
    I=inv(scene)
    if I is None:note.append(f"scene '{scene}' has no sheet yet (a new scene): acts, things, spots and views are not checked; list them for the scene's designer")
    acts=set();things=set();spots=set();views=set()
    if I:
        g=I.get("given",{});a=g.get("acts",{}) if isinstance(g.get("acts"),dict) else {}
        acts=set(a.get("own",[]))|set(a.get("shared",[]))
        if not acts:
            src=open(f"{R}/{I['file']}").read();acts=set(re.findall(r"async\s+([a-zA-Z_0-9]+)\s*\(",src))
        things=set(I.get("hitTest",{}).get("idsAnswered") or I.get("thingIds",[]))
        spots=set((g.get("lugar") or {}).keys())
        if not spots:
            src=open(f"{R}/{I['file']}").read();m=re.search(r"const LUGAR=\{(.*?)\}[,;]",src)
            if m:spots=set(re.findall(r"([a-z_A-Z0-9]+):\[",m.group(1)))
        views=set((I.get("views") or g.get("CAM") or {}).keys())
    used=set()
    def ref(x,where):
        if not isinstance(x,str) or "$" in x:return
        used.add(x)
        if x not in clips:err.append(f"{where}: clip '{x}' is not in this file's clips")
    def walk(x,where):
        if isinstance(x,str):ref(x,where);return
        if isinstance(x,list):
            for i,y in enumerate(x):walk(y,f"{where}.{i}")
            return
        if not isinstance(x,dict):return
        for k in REF_KEYS:
            if k in x and isinstance(x[k],str):ref(x[k],where)
        for k in MAP_KEYS:
            for v in (x.get(k) or {}).values():ref(v,where)
        for k in ("lead","after","wrong","right")+(("then","else") if ("if" in x or "ask" in x) else ()):
            if k in x:walk(x[k],f"{where}.{k}")
        if "elige" in x:
            for o in x.get("options",[]):
                if o in x:walk(x[o],f"{where}.{o}")
        if "gratis" in x:
            for v in x["gratis"].values():walk(v,f"{where}.gratis")
        if "act" in x:
            if acts and x["act"] not in acts:err.append(f"{where}: the scene has no act '{x['act']}' (new code: list it under Needs)")
            if x["act"]=="ir" and spots:
                sp=x.get("a") or x.get("en")
                if sp and "$" not in sp and sp not in spots:err.append(f"{where}: no spot '{sp}'")
        if "cam" in x and views and x["cam"] not in views:err.append(f"{where}: no view '{x['cam']}'")
        if ("ask" in x or "decide" in x) and things:
            for o in ([x["ask"]] if "ask" in x else [])+list(x.get("options",[])):
                if isinstance(o,str) and "$" not in o and o not in things and o not in (x.get("resp") or []) and x.get("decide")!="say":
                    note.append(f"{where}: '{o}' is not a thing he can touch in this scene (fine only if the scene shows it as a bubble)")
    walk(s.get("beats",[]),"beats");walk(s.get("final",[]),"final")
    for k,v in (s.get("names") or {}).items():
        ref(v,f"names.{k}")
        if things and k not in things:note.append(f"names: '{k}' is not a thing he can touch here")
    if isinstance(s.get("bien"),str):ref(s["bien"],"bien")
    for c in s.get("leer") or []:ref(c,"leer")
    # clips against every other story
    new_chars=0
    texto={};unused=[]
    for o,d in todos.items():
        if o==sid:continue
        for cid,c in (d.get("clips") or {}).items():texto.setdefault(norm(c["text"])+"|"+c.get("who","narr"),(o,cid));
    for cid,c in clips.items():
        if c.get("who","narr") not in ("narr","tu"):err.append(f"clip {cid}: who must be narr or tu")
        same=None
        for o,d in todos.items():
            if o==sid:continue
            oc=(d.get("clips") or {}).get(cid)
            if oc and (oc["text"]!=c["text"] or oc.get("who","narr")!=c.get("who","narr")):same=(o,oc["text"])
        if same:err.append(f"clip id '{cid}' already means \"{same[1]}\" in {same[0]}; give this line a new id")
        k=norm(c["text"])+"|"+c.get("who","narr")
        if k in texto and texto[k][1]!=cid:note.append(f"clip {cid}: the same line is already recorded as '{texto[k][1]}' ({texto[k][0]}); reuse that id and save a recording")
        elif not any(cid in (d.get("clips") or {}) for o,d in todos.items() if o!=sid):new_chars+=len(c["text"])
        if cid not in used and cid not in FIJOS:unused.append(cid)
    if unused:note.append("clips not named in the steps (fine when a $ id builds them, or the scene or a name plays them): "+", ".join(unused))
    # words
    allt=" ".join(norm(c["text"]) for c in clips.values())
    for w in s.get("focus_words",[]):
        n=len(re.findall(r"\b"+re.escape(norm(w))+r"\b",allt))
        if n<3:note.append(f"focus word '{w}' is in only {n} line(s); a clean run must hear it 3 times")
    fw=set(s.get("focus_words",[]))
    for cid,c in clips.items():
        for t in c.get("tu_turno") or []:
            if t.get("palabra") in fw:err.append(f"clip {cid}: a speaking turn on '{t['palabra']}', a word new in this story; turns use earlier words only")
    turns=sum(1 for c in clips.values() if c.get("tu_turno"))
    if turns and not 2<=turns<=4:note.append(f"{turns} speaking turns; new stories have 2 to 4")
    print(f"== {sid}  ({len(clips)} clips, about {new_chars} new characters to record, {turns} speaking turns)")
    for e in err:print("  ERROR",e)
    for n in note:print("  note ",n)
    return not err
ok=all([check(p) for p in sys.argv[2:]])
sys.exit(0 if ok else 1)
