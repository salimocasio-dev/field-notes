# One short sheet per scene, for a story writer: python3 hojas_escena.py <repo> > out.md
import json,glob,os,re,sys
R=sys.argv[1]
def cuento(i):
    try: return json.load(open(f"{R}/historia/cuentos/{i}.json"))
    except: return None
def comentarios(src):
    out={};lines=src.split("\n")
    for n,l in enumerate(lines):
        for m in re.finditer(r"async\s+([a-zA-Z_0-9]+)\s*\(",l):
            name=m.group(1);c=None
            pre=l[:m.start()]
            mm=re.search(r"//\s*(.+?)\s*$",pre)
            if mm: c=mm.group(1)
            else:
                k=n-1
                while k>=0 and lines[k].strip().startswith("//"):
                    c=lines[k].strip()[2:].strip(); break
                if c is None and k>=0:
                    mm=re.search(r"/\*\s*-*\s*(.+?)\s*-*\s*\*/\s*$",lines[k].strip())
                    if mm: c=mm.group(1)
            if name not in out: out[name]=c
    return out
SH={"ir":"the frog hops to a spot: {\"act\":\"ir\",\"a\":spot}","burbuja":"a bubble over someone: {\"act\":\"burbuja\",\"quien\":\"cq\"|other,\"que\":kind}","calla":"clears every bubble","pose":"abuela's pose: {\"act\":\"pose\",\"que\":pose}","fin":"the ending: heart and stars when nothing was lost"}
print("# Scene sheets\n\nMade from coqui/ref/escenas/*/inventory.json and historia/escenas/*.js by hojas_escena.py. Regenerate after a scene changes. Do not edit by hand.\n")
for inv in sorted(glob.glob(f"{R}/coqui/ref/escenas/*/inventory.json")):
    d=json.load(open(inv));sid=d["scene"];g=d.get("given",{})
    src=open(f"{R}/{d['file']}").read();com=comentarios(src)
    acts=g.get("acts",{}) if isinstance(g.get("acts"),dict) else {}
    own=acts.get("own") or sorted(set(re.findall(r"^\s*async\s+([a-zA-Z_0-9]+)\(",src,re.M)))
    shared=acts.get("shared",[])
    things=d.get("hitTest",{}).get("idsAnswered") or d.get("thingIds",[])
    lug=g.get("lugar") or {}
    if not lug:
        m=re.search(r"const LUGAR=\{(.*?)\}[,;]",src)
        if m: lug={k:1 for k in re.findall(r"([a-z_A-Z0-9]+):\[",m.group(1))}
    views=d.get("views") or g.get("CAM") or {}
    stories=d.get("stories",[])
    focus,stakes,names,people=[],set(),{},set()
    uso={}
    def walk(x,sname):
        if isinstance(x,list):
            for i in x: walk(i,sname)
        elif isinstance(x,dict):
            if "act" in x and x["act"] not in uso: uso[x["act"]]=(sname,json.dumps(x,ensure_ascii=False))
            for v in x.values(): walk(v,sname)
    for s in stories:
        c=cuento(s)
        if not c: continue
        if c.get("stake"): stakes.add(c["stake"].get("thing"))
        for w in c.get("focus_words",[]):
            if w not in focus: focus.append(w)
        names.update(c.get("names",{}))
        walk(c.get("beats",[]),s);walk(c.get("final",[]),s)
        for cl in c.get("clips",{}).values():
            if cl.get("habla"): people.add(cl["habla"])
    print(f"## {sid}\n")
    print(f"- Stories: {', '.join(stories)}")
    print(f"- Review file: {d.get('reviewFile')}")
    print(f"- Words already taught here: {', '.join(focus) or '-'}")
    print(f"- Stakes used: {', '.join(sorted(x for x in stakes if x)) or '-'}")
    print(f"- Who speaks here (\"habla\"): {', '.join(sorted(people)) or '-'}")
    print(f"- Things he can touch: {', '.join(things)}")
    print(f"- Spots (for ir): {', '.join(lug.keys()) or 'none named; the scene places the frog itself'}")
    print(f"- Views (for cam): {', '.join(views.keys())}")
    print(f"- Names already recorded (thing: clip): {', '.join(f'{k}: {v}' for k,v in sorted(names.items()))}")
    print(f"- Shared acts: {', '.join(shared)}")
    print("- Acts:")
    for a in own:
        if a in SH and a not in ("fin",): continue
        c=com.get(a) or SH.get(a) or ""
        ex=uso.get(a)
        tail=(f": {c}" if c else "")+(f" (e.g. {ex[1]} in {ex[0]})" if ex and ex[1]!=json.dumps({"act":a}) else (f" (used in {ex[0]})" if ex else " (not used by any story yet)"))
        print(f"    - {a}"+tail)
    print()
