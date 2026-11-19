"""Builds the picture books of the Leer part (docs/proyecto/10-leer-y-repaso.md, "What goes in a book").

  python3 historia/tools/gen_libros.py [story ids ...] [--jobs N] [--fast F] [--sheets DIR] [--check] [--solve ID ...]

  no ids   every story in historia/curso.js: the map stories of every place, then each place's picture stories (dibujos) and routines (haz)
  --jobs   stories played at once (default 6)
  --fast   speed of the machine play (default 8; the pictures do not depend on it)
  --sheets a contact sheet per book (the page picture, its lines under it) into DIR
  --check  only checks the books already written (counts, audio, left-out clips, pictures)
  --no-hud takes the scenes' own counters (E.hud) off the pictures too; --icon-bubbles keeps the picture bubbles above the speakers
  --solve  finds the draws a story's "leer" list was written for (see DRAWS) and prints them; writes nothing

It writes historia/libros/<story id>.json = {"id","title","pages":[{"img":"img/<id>-<n>.png","clips":[...]}]}
and the page pictures historia/libros/img/<id>-<n>.png. Serves the repo on port 8767 if nothing answers there. Needs playwright,
a Chrome at /usr/bin/google-chrome, node (to read curso.js) and PIL (sheets and checks).

HOW A BOOK IS MADE (all of it mechanical; nothing is read by a person)
1. The story is played by machine, all right, at phone size, the way juega.py plays it: every ask and decision is answered with the right
   thing (a choice with no wrong answer takes the first option), with no voice (clips take their time as in a silent play) and no speaking turns.
   The first draw: every draw, deal and decision of the play takes its first option (Math.random is held at 0 inside the play), except for the
   stories in DRAWS (see there); a choice with no wrong answer (elige) takes its first option, as juega.py plays "r". The play is logged: every clip the engine starts (with where it came from), every scene act (E.acts) and
   every step (cam, set, ...). At the start of every clip the scene canvas (#cv, 196 x 216, the art's own size) is saved as a PNG: only the
   canvas, with the big sign (spot, hand, twinkle), the answer bubbles (resp), the star effects and the picture bubbles above the speakers
   (HIDE_ICON_BUBBLES: the speaker markers) off, the frog's hop offset 0 and the
   frame counter fixed (no blink, mouth shut), so a play gives the same picture again (a handful of pixels can differ in a few pictures where a dog
   or a ball is still moving when the line starts). No DOM: no caption, no speech bubble, no UI.
2. The lines, in play order: the story's "leer" list if it has one. Else the lines that historia/app.html leer() walks today (a bare line or
   {say}, the lead lines and the question line of an ask, decide or elige, and the lines inside after / then / right and the options),
   in the order they are played in the all-right play: so a $ variable is what the draw gave it, an {if} takes the branch the play took,
   an elige takes its first option. Clips the walk does not walk (said answers, praise) are not added.
3. Left out: a clip that is the question line ("line") of any ask, decide or elige of the story (all values of its $ variables); the engine's
   generic clips (GENERIC below); a clip already used earlier in the book.
4. Pages: at most three consecutive kept lines; a new page whenever a scene act (any E.acts call) ran in the play between two kept lines.
   (Camera moves, {set} and the touches themselves do not count: BREAK_ON.)
5. The picture of a page is the canvas saved when its first line started.
6. OVERRIDES: per story, later fixes for what the reviewers flag; never edit the JSON by hand. Each entry is one of
     {"drop": clip}                     leave the clip out of the book
     {"move": clip, "after": other}     put the clip right after another one (or "after": null for the very first place)
     {"break": clip}                    a page starts at this clip
     {"join": clip}                     no page break before this clip (the page limit of three still holds)
     {"pic": clip, "at": other}         the page that starts at clip takes its picture from where the line 'other' started
   It is empty for now.
"""
import sys, os, re, io, json, time, asyncio, subprocess, socket, itertools, argparse, shutil

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))   # the repo (this file is historia/tools/gen_libros.py)
HIST = os.path.join(ROOT, "historia")
OUT = os.path.join(HIST, "libros")
PORT = 8767
BASE = f"http://127.0.0.1:{PORT}/historia/index.html"
CHROME = "/usr/bin/google-chrome"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

# What ends a page (besides the limit of three): a scene act. Names in this set are the kinds of event that break a page ("act" = any E.acts call).
# Other kinds the log also holds, for a reader who wants to see what a stricter rule would do: "cam", "set". Not in the default.
BREAK_ON = {"act"}

# The engine's generic clips (found in historia/juego.js): the praise (bien(): S.bien, a step's "bien", else "muy_bien"), "Ahora tú." (the
# speaking turns), and the Haz esto reply to a wrong touch ("hz_no_" + what was touched: "No. Esa es la puerta."). The touch names (S.names:
# "Es la puerta.", "¡Coquí!") are the engine's too, but a story that places one in its own script uses it as a story line (esta_es_mama in
# La familia, c30_nevera in No hay leche), so they are left in when the story lists them and they never get in otherwise.
GENERIC_IDS = {"muy_bien", "si_muy_bien", "ahora_tu"}
GENERIC_PREFIX = ("hz_no_",)

# What the picture leaves out of the canvas besides the sign, the answer bubbles and the star effects (see 1 above).
# The picture bubbles above a speaker (the hand, the heart, the ?, the faces) are speaker markers: a page holds up to three lines, so they are off.
# The scene's own counters (frog and bird tallies, the card of what is asked: E.hud) are part of the scene canvas and stay; --no-hud takes them off.
HIDE_ICON_BUBBLES = True
HIDE_HUD = False

# Per-story fixes (see 6 above). Empty for now.
OVERRIDES = {}

# The first draw. Every draw, deal and decision of the play takes its first option, and a choice with no wrong answer (elige) takes its first
# option too. The stories below have a "leer" list that was written for another draw: there the plan lists, in order of the random steps of the
# play (draws, deals, decisions with no fixed pick, elige), which option each takes (0 = the first), so that every clip of the list really
# plays and the picture of a line is the scene that line is about. Found by  --solve <id>  (a search over the real engine's draws, scored by how
# many "leer" clips play in the order of the list); trailing zeros are left off. Stories not named here play their first draw.
DRAWS = {
    "el-jugo": [1, 0, 1],               # d=agua, l=silla, t=pequeno
    "que-calor": [0, 0, 1],             # the elige: jugo
    "la-foto": [1, 1],
    "quien-eres-tu": [1],               # the deal: hermano and hermana the other way round
    "las-flores": [0, 0, 0, 1],
    "donde-esta-el-gato": [1, 0, 3, 0, 4],
    "la-piragua": [0, 1],
}


# ---------------------------------------------------------------- the course and the story files
def course():
    """[(story id, kind, place id)] in the order of curso.js: per place its map stories, then dibujos, then haz."""
    js = open(os.path.join(HIST, "curso.js"), encoding="utf8").read()
    prog = "const vm=require('vm');const c={};vm.createContext(c);vm.runInContext(" + json.dumps(js + "\n;this.__C=CURSO;") + ",c);process.stdout.write(JSON.stringify(c.__C))"
    C = json.loads(subprocess.run(["node", "-e", prog], capture_output=True, text=True, check=True).stdout)
    out = []
    for l in C["lugares"]:
        for kind in ("cuentos", "dibujos", "haz"):
            for s in l.get(kind) or []:
                out.append((s, kind, l["id"]))
    return out, C


def story(sid):
    return json.load(open(os.path.join(HIST, "cuentos", sid + ".json"), encoding="utf8"))


def ready():
    return set(json.load(open(os.path.join(HIST, "audio", "ready.json"), encoding="utf8"))["clips"])


# ---------------------------------------------------------------- static reading of the story file (for the left-out clips)
def children(st):
    """The lists of steps inside a step, the way app.html leer() and the engine reach them (plus the branches that play only on a wrong answer)."""
    r = []
    for k in ("after", "then", "right", "wrong", "else"):
        if isinstance(st.get(k), list):
            r.append(st[k])
    for o in st.get("options") or []:
        if isinstance(st.get(o), list):
            r.append(st[o])
    if isinstance(st.get("gratis"), dict):
        r += [v for v in st["gratis"].values() if isinstance(v, list)]
    return r


def all_steps(T):
    def go(lst):
        for st in lst or []:
            if isinstance(st, dict):
                yield st
                for c in children(st):
                    yield from go(c)
    yield from go(T.get("beats"))
    yield from go(T.get("final"))


def pool(T):
    """Every string the story can give to a $ variable: the options of its draws, deals and decisions, and the results of its calcs
    (a value that is itself a pattern with $ is expanded once against the clips of the story)."""
    p, pats = set(), set()
    for st in all_steps(T):
        vals = [v for k in ("options", "reparte", "vale", "burbujas", "resp") for v in st.get(k) or [] if isinstance(v, str)]
        if "calc" in st:
            vals += [st[k] for k in ("then", "else") if isinstance(st.get(k), str)]
        for v in vals:
            (pats if "$" in v else p).add(v)
    ids = set(T["clips"])
    for v in pats:
        p |= expand(v, p, ids)
    return p


def expand(pat, P, ids):
    """The clip ids (of `ids`) a line given as a pattern with $ variables can be."""
    if "$" not in pat:
        return {pat} & ids
    alt = "(?:" + "|".join(sorted(map(re.escape, P), key=len, reverse=True)) + ")" if P else "[a-z0-9_]+"
    rx = re.compile("^" + re.sub(r"\\\$[a-z]+", lambda m: alt, re.escape(pat)) + "$")
    return {i for i in ids if rx.match(i)}


def question_clips(T):
    """Every clip that is the question line of an ask, decide or elige of the story ("line"), whatever the values of its $ variables."""
    P, ids, q = pool(T), set(T["clips"]), set()
    for st in all_steps(T):
        if (st.get("ask") or st.get("decide") or st.get("elige")) and isinstance(st.get("line"), str):
            q |= expand(st["line"], P, ids)
    return q


def praise_clips(T):
    p = {T.get("bien")} if T.get("bien") else set()
    for st in all_steps(T):
        if isinstance(st.get("bien"), str):
            p.add(st["bien"])
    return p


def is_generic(T, c):
    return c in GENERIC_IDS or c in praise_clips(T) or c.startswith(GENERIC_PREFIX)


# ---------------------------------------------------------------- the machine play
HOOK = r"""(cfg)=>{
 window.__ev=[];const ev=__ev;window.__plan=cfg.plan||[];window.__k=0;window.__pickj=0;window.__RV=0;
 const shot=()=>{const sv={spot:W.spot,tw:W.twinkle,resp:W.resp,fx:W.fx,dy:W.cq.dy,F:F,camA:camA};
   const b0=bub,b1=bubble,h0=E.hud;
   W.spot=null;W.twinkle=null;W.resp=null;W.fx=[];W.cq.dy=0;F=948;camA=null;let u=null;
   if(cfg.bubbles){bub=function(){};bubble=function(){};}
   if(cfg.hud)E.hud=null;
   try{draw();u=cv.toDataURL('image/png');}catch(e){u=null;}
   bub=b0;bubble=b1;E.hud=h0;
   W.spot=sv.spot;W.twinkle=sv.tw;W.resp=sv.resp;W.fx=sv.fx;W.cq.dy=sv.dy;F=sv.F;camA=sv.camA;return u;};
 let mark=null,leads=null;
 const _say=say;say=function(id,gap){let src='other';
   if(mark&&mark===id){src='line';mark=null;}
   else if(leads&&leads.includes(id)){src='lead';leads.splice(leads.indexOf(id),1);}
   else if(window.__q&&window.__q===id){src='q';window.__q=null;}
   ev.push({k:'say',id,src,img:shot()});return _say.apply(this,arguments);};
 const _paso=paso;paso=function(st){
   if(st&&typeof st==='object'&&!st.act){
     if(st.say){mark=sub(st.say);}
     ev.push({k:'step',t:Object.keys(st)[0]});
     if(st.elige){const n=(st.options||[]).length,j=(window.__plan[window.__k]||0);window.__k++;window.__pickj=j;
       ev.push({k:'rand',n,j,what:'elige:'+st.elige});}
     const rs=st.draw||st.reparte||(st.decide&&!st.pick);
     if(rs){const n=st.reparte?2:(st.options||[]).length,j=(window.__plan[window.__k]||0);window.__k++;
       const r=st.reparte?(j?0.99:0):(j+0.5)/n;ev.push({k:'rand',n,j,what:st.draw||st.reparte&&st.reparte.join('+')||st.decide});window.__RV=r;
       try{return _paso.apply(this,arguments);}finally{window.__RV=0;}}}
   else if(typeof st==='string'){mark=sub(st);ev.push({k:'step',t:'line'});}
   return _paso.apply(this,arguments);};
 const _esp=espera;espera=function(l,lead,line,o){leads=(lead||[]).filter(x=>typeof x==='string').map(x=>sub(x));window.__q=line||null;
   ev.push({k:'ask',line:line||null,kind:(o&&o.kind)||'ask'});return _esp.apply(this,arguments);};
 for(const n of Object.keys(E.acts)){const f=E.acts[n];E.acts[n]=function(){ev.push({k:'act',n});return f.apply(this,arguments);};}
 Math.random=()=>window.__RV;
}"""
STATE = """()=>{const p=Story.pending;return {live:p?p.live.join('|'):null,kind:p?p.kind:null,pick:p?p.pick:null,asked:p?p.asked:0,running:Story.running,j:window.__pickj||0}}"""


async def play(browser, sid, plan, fast, limit=300, hud=None):
    """One all-right machine play. Returns {"ev": [...], "V": {...}, "errs": [...], "timeout": bool}."""
    ctx = await browser.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=1, is_mobile=True, has_touch=True)
    try:
        await ctx.route("**/audio/**", lambda r: r.abort())   # no voice: the play keeps its own time, nothing to decode
        pg = await ctx.new_page(); errs = []
        pg.on("pageerror", lambda e: errs.append(str(e)))
        await pg.goto(f"{BASE}?cuento={sid}&fast={fast}&mic=off")
        await pg.wait_for_function("window.Story&&Story.ready", timeout=20000)
        await pg.wait_for_timeout(600)
        await pg.evaluate(HOOK, {"plan": plan, "bubbles": HIDE_ICON_BUBBLES, "hud": HIDE_HUD if hud is None else hud})
        await pg.click("#go"); t0 = time.time(); last = None; timeout = False; i = 0
        while True:
            i += 1
            await pg.wait_for_timeout(30)
            s = await pg.evaluate(STATE)
            if s["live"] and s["asked"]:
                key = (s["live"], s["pick"])
                if key != last:   # the right thing: the only live one; for a decision its pick; for an ask or a choice the first (as juega.py plays "r")
                    live = s["live"].split("|")
                    tgt = live[0] if len(live) == 1 else (s["pick"] if s["kind"] == "decide" else live[min(s["j"], len(live) - 1)])
                    await pg.wait_for_timeout(120)
                    await pg.evaluate("t=>Story.tapOn(t)", tgt); last = key
            if not s["live"]:
                last = None
            if not s["running"] and i > 40:
                break
            if time.time() - t0 > limit:
                timeout = True; break
        ev = await pg.evaluate("__ev"); V = await pg.evaluate("Story.V")
        return {"ev": ev, "V": V, "errs": errs, "timeout": timeout}
    finally:
        await ctx.close()


# ---------------------------------------------------------------- the book
class Stop(Exception):
    """Something the page does not answer: the story is not built, and the reason is reported."""


def lines_of(T, ev):
    """The story's lines in play order, each with the index of its event in the play: [(clip id, event index)]."""
    says = [(e["id"], n) for n, e in enumerate(ev) if e["k"] == "say"]
    if T.get("leer"):
        out, pos, missing = [], -1, []
        for c in T["leer"]:
            nxt = next((n for (i, n) in says if i == c and n > pos), None)
            if nxt is None:
                nxt = next((n for (i, n) in says if i == c), None)   # played, but earlier than the clip before it in the list
                if nxt is not None:
                    out.append((c, nxt, "order")); continue
                missing.append(c); continue
            out.append((c, nxt, "")); pos = nxt
        if missing:
            raise Stop("leer clips that never play in the play: " + ", ".join(missing))
        return out
    return [(ev[n]["id"], n, "") for (i, n) in says if ev[n]["src"] in ("line", "lead")]


def kept(T, sid, lines, ev, why):
    """Leaves out the question lines, the generic clips and repeats. `why` collects what was left out and why."""
    Q = question_clips(T) | {e["line"] for e in ev if e["k"] == "ask" and e["line"]}; seen = set(); out = []
    for c, n, flag in lines:
        if c in Q:
            why.append((c, "question")); continue
        if is_generic(T, c):
            why.append((c, "generic")); continue
        if c in seen:
            why.append((c, "repeat")); continue
        seen.add(c); out.append((c, n, flag))
    return out


def overrides(sid, lst):
    """OVERRIDES[sid] on the list of kept (clip, event index, flag); returns (list, {clip: event index to take the picture at}, set of clips that start a page, set of clips that do not)."""
    pic, brk, join = {}, set(), set()
    for o in OVERRIDES.get(sid, []):
        if "drop" in o:
            lst = [x for x in lst if x[0] != o["drop"]]
        elif "move" in o:
            it = next(x for x in lst if x[0] == o["move"]); lst = [x for x in lst if x[0] != o["move"]]
            k = 0 if o.get("after") is None else 1 + next(i for i, x in enumerate(lst) if x[0] == o["after"])
            lst.insert(k, it)
        elif "break" in o:
            brk.add(o["break"])
        elif "join" in o:
            join.add(o["join"])
        elif "pic" in o:
            pic[o["pic"]] = o["at"]
    return lst, pic, brk, join


def breaks(e):
    return (e["k"] == "act" and "act" in BREAK_ON) or (e["k"] == "step" and e["t"] in BREAK_ON)


def paginate(sid, lst, ev, pic, brk, join):
    """Pages of at most three consecutive lines, a new page where a scene act ran between two lines. -> [{"first": event index, "clips": [...], "pic": event index}]"""
    pages = []
    ev_of = {c: n for c, n, _ in lst}
    for k, (c, n, _) in enumerate(lst):
        new = not pages or len(pages[-1]["clips"]) >= 3 or c in brk
        if not new and c not in join:
            prev = lst[k - 1][1]
            if any(breaks(e) for e in ev[prev + 1:n]):
                new = True
        if new:
            at = ev_of[pic[c]] if c in pic else n
            pages.append({"first": n, "clips": [c], "pic": at})
        else:
            pages[-1]["clips"].append(c)
    return pages


def stats_more(lst, ev, pages):
    """What a stricter rule would do (information only): pages that hold a camera move or a {set} between two lines, and acts per page."""
    inner = 0
    for p in pages:
        ns = [ev_n for c, ev_n, _ in lst if c in p["clips"]]
        if len(ns) > 1 and any(e["k"] == "step" and e["t"] in ("cam", "set") for e in ev[ns[0] + 1:ns[-1]]):
            inner += 1
    return inner


def build(sid, res):
    T = story(sid); ev = res["ev"]
    why = []
    lines = lines_of(T, ev)
    lst = kept(T, sid, lines, ev, why)
    lst, pic, brk, join = overrides(sid, lst)
    pages = paginate(sid, lst, ev, pic, brk, join)
    book = {"id": sid, "title": T["title"], "pages": [{"img": f"img/{sid}-{i + 1}.png", "clips": p["clips"]} for i, p in enumerate(pages)]}
    imgs = []
    for p in pages:
        u = ev[p["pic"]].get("img")
        if not u:
            raise Stop("no picture could be saved at the start of " + p["clips"][0])
        imgs.append(__import__("base64").b64decode(u.split(",", 1)[1]))
    info = {"empty": not pages, "left_out": why, "order_flags": [c for c, n, f in lst if f == "order"], "pages_with_cam_or_set": stats_more(lst, ev, pages)}
    # the lead question check: a lead line that asks something and is not a question line of the story is reported (none exist now)
    Q = question_clips(T)
    for st in all_steps(T):
        for x in st.get("lead") or []:
            if isinstance(x, str) and "$" not in x and x in T["clips"] and "¿" in T["clips"][x]["text"] and x not in Q:
                info.setdefault("lead_questions", []).append(x)
    # the question lines the play really asked must all be in the static set
    dyn = {e["line"] for e in ev if e["k"] == "ask" and e["line"]}
    if dyn - Q:
        info["unknown_questions"] = sorted(dyn - Q)
    return book, imgs, info


# ---------------------------------------------------------------- finding the draws a leer list was written for
async def solve(browser, sid, fast):
    """Coordinate search: step by step along the random steps of the play, try every other option, keep what plays more of the leer list in its order."""
    T = story(sid)
    if not T.get("leer"):
        return [], 0, 0

    def score(r):
        try:
            got = lines_of(T, r["ev"]); return len(got) * 2 - sum(1 for x in got if x[2])
        except Stop as e:
            m = len(str(e).split(": ", 1)[1].split(", ")); return (len(T["leer"]) - m) * 2 - 1
    plan = []; best = await play(browser, sid, plan, fast); bs = score(best); full = 2 * len(T["leer"]); k = 0
    while bs < full:
        steps = [e for e in best["ev"] if e["k"] == "rand"]
        if k >= len(steps):
            break
        cands = []
        for j in range(steps[k]["n"]):
            p = (plan + [0] * (k + 1))[:max(len(plan), k + 1)]
            if j != p[k]:
                p[k] = j; cands.append(p)
        rs = await asyncio.gather(*[play(browser, sid, p, fast) for p in cands])
        for p, r in zip(cands, rs):
            if score(r) > bs:
                bs, plan, best = score(r), p, r
        k += 1
    while plan and plan[-1] == 0:
        plan.pop()
    return plan, bs, full


# ---------------------------------------------------------------- the checks and the sheets
def check(ids, rd, verbose=True):
    from PIL import Image
    bad, tot = [], {"books": 0, "pages": 0, "lines": 0, "bytes": 0}
    for sid in ids:
        p = os.path.join(OUT, sid + ".json")
        if not os.path.exists(p):
            bad.append((sid, "no book")); continue
        B = json.load(open(p, encoding="utf8")); T = story(sid); Q = question_clips(T); seen = set()
        tot["books"] += 1
        if B["id"] != sid or not B["title"]:
            bad.append((sid, "id or title"))
        for i, pg in enumerate(B["pages"]):
            tot["pages"] += 1; tot["lines"] += len(pg["clips"])
            if not 1 <= len(pg["clips"]) <= 3:
                bad.append((sid, f"page {i + 1} has {len(pg['clips'])} clips"))
            for c in pg["clips"]:
                if c not in T["clips"]:
                    bad.append((sid, f"clip {c} is not in the story"))
                if c not in rd:
                    bad.append((sid, f"clip {c} has no audio"))
                if c in seen:
                    bad.append((sid, f"clip {c} repeats"))
                seen.add(c)
                if c in Q or is_generic(T, c):
                    bad.append((sid, f"left-out clip {c} is in the book"))
            f = os.path.join(OUT, pg["img"])
            if pg["img"] != f"img/{sid}-{i + 1}.png":
                bad.append((sid, f"page {i + 1} image name {pg['img']}"))
            if not os.path.exists(f) or os.path.getsize(f) == 0:
                bad.append((sid, f"image {pg['img']} missing or empty")); continue
            tot["bytes"] += os.path.getsize(f)
            im = Image.open(f).convert("RGB")
            if im.size != (196, 216):
                bad.append((sid, f"image {pg['img']} is {im.size}"))
            if len(im.getcolors(maxcolors=1 << 20) or []) < 2:
                bad.append((sid, f"image {pg['img']} is one colour"))
    return tot, bad


def sheet(sid, T, B, outdir, info=None):
    from PIL import Image, ImageDraw, ImageFont
    f20, f16, f14 = (ImageFont.truetype(FONT, s) for s in (20, 16, 14))
    if not B["pages"]:   # no line is left: the sheet says so, and lists what was left out
        rows = ["No pages: every line of this story is left out (question lines, generic clips).", ""] + [f"{c}  ({w}):  {T['clips'][c]['text']}" for c, w in (info or {}).get("left_out", [])]
        S = Image.new("RGB", (1000, 50 + 24 * len(rows)), (244, 240, 230)); d = ImageDraw.Draw(S)
        d.text((12, 10), f"{B['title']}  ({sid})  0 pages", font=f20, fill=(20, 20, 20))
        for i, t in enumerate(rows):
            d.text((12, 46 + 24 * i), t, font=f16, fill=(10, 10, 10))
        os.makedirs(outdir, exist_ok=True); S.save(os.path.join(outdir, sid + ".png")); return
    Z, W, M, cols = 2, 392, 12, 3   # picture twice its size; cell width; margin; columns
    cells = []
    for i, pg in enumerate(B["pages"]):
        im = Image.open(os.path.join(OUT, pg["img"])).convert("RGB").resize((196 * Z, 216 * Z), Image.NEAREST)
        rows = []
        for c in pg["clips"]:
            cl = T["clips"][c]; txt = ("Coquí: " if cl.get("who") == "tu" else "") + cl["text"]
            words, cur = txt.split(" "), ""
            for w in words:
                t = (cur + " " + w).strip()
                if f16.getlength(t) > W - 8 and cur:
                    rows.append(cur); cur = w
                else:
                    cur = t
            rows.append(cur); rows.append(None)
        cells.append((i + 1, im, rows))
    def hgt(rows): return 28 + 216 * Z + 8 + sum(10 if r is None else 22 for r in rows) + M
    n = len(cells); nr = max(1, (n + cols - 1) // cols)
    rowh = [max(hgt(c[2]) for c in cells[r * cols:(r + 1) * cols]) for r in range(nr)]
    head = 44
    S = Image.new("RGB", (cols * (W + M) + M, head + sum(rowh) + M), (244, 240, 230)); d = ImageDraw.Draw(S)
    d.text((M, 10), f"{B['title']}  ({sid})  {n} pages, {sum(len(p['clips']) for p in B['pages'])} lines", font=f20, fill=(20, 20, 20))
    y = head
    for r in range(nr):
        for k, (num, im, rows) in enumerate(cells[r * cols:(r + 1) * cols]):
            x = M + k * (W + M)
            d.rectangle([x - 2, y - 2, x + W + 2, y + rowh[r] - M + 2], fill=(255, 255, 255), outline=(190, 185, 170))
            d.text((x + 4, y + 4), f"page {num}", font=f14, fill=(90, 90, 90))
            S.paste(im, (x, y + 28)); yy = y + 28 + 216 * Z + 8
            for t in rows:
                if t is None:
                    yy += 10
                else:
                    d.text((x + 4, yy), t, font=f16, fill=(10, 10, 10)); yy += 22
        y += rowh[r]
    os.makedirs(outdir, exist_ok=True)
    S.save(os.path.join(outdir, sid + ".png"))


# ---------------------------------------------------------------- main
def serve():
    s = socket.socket()
    try:
        s.settimeout(1); s.connect(("127.0.0.1", PORT)); s.close(); return None
    except OSError:
        s.close()
    p = subprocess.Popen([sys.executable, "-m", "http.server", str(PORT), "--bind", "127.0.0.1"], cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1.2); return p


async def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ids", nargs="*"); ap.add_argument("--jobs", type=int, default=6); ap.add_argument("--fast", default="8")
    ap.add_argument("--sheets"); ap.add_argument("--check", action="store_true"); ap.add_argument("--solve", action="store_true")
    ap.add_argument("--no-hud", action="store_true"); ap.add_argument("--icon-bubbles", action="store_true")
    a = ap.parse_args()
    global HIDE_HUD, HIDE_ICON_BUBBLES
    HIDE_HUD = HIDE_HUD or a.no_hud; HIDE_ICON_BUBBLES = HIDE_ICON_BUBBLES and not a.icon_bubbles
    cs, C = course(); allids = [s for s, _, _ in cs]
    ids = a.ids or allids
    for i in ids:
        if i not in allids:
            sys.exit(f"{i} is not a story of curso.js")
    rd = ready()
    if a.check:
        tot, bad = check(ids, rd); print(json.dumps(tot)); [print("BAD", b) for b in bad]; sys.exit(1 if bad else 0)
    srv = serve()
    from playwright.async_api import async_playwright
    stops, infos, sem = {}, {}, asyncio.Semaphore(a.jobs)
    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])

            async def one(sid):
                async with sem:
                    if a.solve:
                        r = await solve(browser, sid, a.fast); print(sid, "DRAWS =", r, flush=True); return
                    res = await play(browser, sid, DRAWS.get(sid, []), a.fast)
                    if res["timeout"] or res["errs"]:
                        stops[sid] = ("timeout" if res["timeout"] else "page errors: " + "; ".join(res["errs"][:3])); return
                    try:
                        book, imgs, info = build(sid, res)
                    except Stop as e:
                        stops[sid] = str(e); return
                    os.makedirs(os.path.join(OUT, "img"), exist_ok=True)
                    for f in os.listdir(os.path.join(OUT, "img")):   # pictures of an earlier, longer build of this book
                        if re.match(re.escape(sid) + r"-\d+\.png$", f) and int(f[len(sid) + 1:-4]) > len(imgs):
                            os.remove(os.path.join(OUT, "img", f))
                    for i, b in enumerate(imgs):
                        open(os.path.join(OUT, "img", f"{sid}-{i + 1}.png"), "wb").write(b)
                    open(os.path.join(OUT, sid + ".json"), "w", encoding="utf8").write(
                        '{"id": %s, "title": %s, "pages": [\n%s\n]}\n' % (json.dumps(book["id"]), json.dumps(book["title"], ensure_ascii=False), ",\n".join(" " + json.dumps(x, ensure_ascii=False) for x in book["pages"])))
                    infos[sid] = info
                    print(f"{sid}: {len(book['pages'])} pages, {sum(len(x['clips']) for x in book['pages'])} lines", flush=True)
            await asyncio.gather(*[one(s) for s in ids])
            await browser.close()
    finally:
        if srv:
            srv.terminate()
    if a.solve:
        return
    for sid, why in stops.items():
        print("STOP", sid, why)
    for sid, inf in infos.items():
        for k in ("empty", "order_flags", "lead_questions", "unknown_questions"):
            if inf.get(k):
                print("NOTE", sid, k, inf[k] if k != "empty" else "no line is left: the book has no pages")
    if a.sheets:
        for sid in ids:
            if os.path.exists(os.path.join(OUT, sid + ".json")) and sid not in stops:
                sheet(sid, story(sid), json.load(open(os.path.join(OUT, sid + ".json"), encoding="utf8")), a.sheets, infos.get(sid))
    tot, bad = check([s for s in ids if s not in stops], rd)
    if infos:
        lo = {}
        for inf in infos.values():
            for c, w in inf["left_out"]:
                lo[w] = lo.get(w, 0) + 1
        print("INFO left out:", json.dumps(lo), "| pages that hold a camera move or a {set} between two of their lines:", sum(i["pages_with_cam_or_set"] for i in infos.values()))
    print("TOTAL", json.dumps(tot)); [print("BAD", b) for b in bad]
    sys.exit(1 if (bad or stops) else 0)


if __name__ == "__main__":
    asyncio.run(main())
