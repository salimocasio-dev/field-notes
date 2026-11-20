#!/usr/bin/env python3
"""Makes the candidate data for Repaso as games (docs/proyecto/15-repaso-juegos.md, "The games" and "The data").

    python3 coqui/tool/make_repaso.py --out <dir> [--repo <root>] [--no-sheets]

Reads the repo it sits in (or --repo): historia/datos/curso.json, historia/cuentos/*.json, historia/audio/ready.json,
historia/libros/*.json and libros/img/, docs/hablar/02-marcas.json. Writes into <dir>:

    candidatos.json     the 156 words, every candidate sentence, the proposed wrong pictures, the false sentences for a
                        picture, the Parejas sets, and how each story was walked
    resumen.md          counts and tables, and every STOP and every place the data did not fit a rule
    hojas/              one vetting sheet per candidate that has a book page (hojas/<book>/NNNN.png), the sheets' list
                        (hojas/<book>/hojas.jsonl) and the key (hojas/claves.json). Not written with --no-sheets.

Deterministic (two runs give the same bytes: nothing reads the clock, a random seed is fixed, nothing iterates a set into
an output), and offline. Nothing under historia/ is written.

The order of the rules follows the order that was given to the builder:
 1 words, 2 candidate sentences (2a to 2g), 3 fair wrong pictures, 4 false sentences for a picture, 5 Parejas sets,
 6 resumen.md, 7 vetting sheets.

HOW A STORY IS WALKED (rule 2d). The story's beats and final are played by a small interpreter that does what
historia/juego.js does when every answer is right, and it plays every random choice every way (a draw takes each of its
options, a deal each of its orders, a decision with no fixed pick each option, an elige each of its options: an elige has no
wrong answer, so each option is a right one). A line is "reached" when at least one such play says it. Specifically:
  - a line, {say}, the lead of an ask / decide / elige, its question line, its bubbles' voices, the said clip of the right
    answer, the praise, and the steps after / then / right are played; wrong, gratis (the optional answers that cost nothing),
    the touch names (names) and the Haz esto replies are not.
  - {if}, {calc}: evaluated on the variables the walk knows (draw, deal, decide as/other/pick, calc, recuerda, set); lost is 0
    and wet is 0 on an all-right play; V.ok is "1" after a decide. A condition on a key the walk cannot know (scene state set by
    an act: win, rain; a memory kept from an earlier play: mem_*) takes BOTH branches and is listed in resumen.md.
  - a $ in a clip id that the walk cannot fill is read as the story's own pool of values (the way gen_libros.question_clips
    reads it): each clip that fits is a possible line.
A clip with audio that no play reaches is classed: a question or order; a generic clip; only after a wrong touch or only in an
optional (gratis) answer; in a branch the all-right play does not take; the name of a thing touched; or "not placed" (no
step names it). The last class is what the report calls clips that could not be placed. None of these is a candidate.
"""
import argparse
import hashlib
import itertools
import json
import os
import random
import re
import sys
import unicodedata
from collections import Counter, OrderedDict, defaultdict
from pathlib import Path

# ---------------------------------------------------------------------------------------------------------------- constants

# Character names (rule 2: tiene_nombre; the correction rule 2e; the cluster placeholder). Fixed list: the four names of the
# stories ("Coquí" is the frog, the others are the children and the dog). abuela, abuelo, mamá, papá are words of the
# course, not names.
NAMES = ("coquí", "luis", "carmen", "canelo")
# 2: the function words that need no teaching (token_no_enseñado).
FUNCTION_WORDS = ("el la los las un una unos unas de del al a en y o con para por que es está son están hay no sí se le lo "
                  "me te mi tu su").split()
# 2: a sentence that starts like this is tied to its picture.
DEICTIC_STARTS = (("esta", "es"), ("este", "es"), ("es", "la"), ("es", "el"), ("es", "un"), ("es", "una"))
# 3 and 4, 5, 7.
MAX_WRONG = 4
MIN_APART = 2
MAX_SETS = 3
SHEET_SEED = 20261120
KS = (3, 11, 22, 32)
EXPECTED_WORDS = 156
ENGINE_ALLRIGHT = {"lost": 0, "wet": 0}      # what the engine holds when every answer is right
ENGINE_VARS = ("ok", "x", "elegido")          # keys the engine itself assigns in decide / elige
FONT_CANDIDATES = ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf",
                   "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf")


# ---------------------------------------------------------------------------------------------------------------- text

def nfc(s):
    return unicodedata.normalize("NFC", s)


TOKEN = re.compile(r"[0-9a-záéíóúüñ]+")


def toks(s):
    """Lower case, punctuation removed, accents kept."""
    return TOKEN.findall(nfc(s).lower())


def fold(s):
    """Accents folded (ñ and ü too)."""
    return "".join(c for c in unicodedata.normalize("NFD", s.lower()) if unicodedata.category(c) != "Mn")


TAG = re.compile(r"^\s*((?:(?:El|La|Los|Las)\s+)?[^\s:]+)\s+dice:\s*")


def split_tag(text):
    """('Abuela', '¡Hola!') for 'Abuela dice: ¡Hola!', else (None, text). The tag is <Name or El/La noun> dice: at the start."""
    m = TAG.match(nfc(text))
    if not m:
        return None, text
    return m.group(1), text[m.end():]


CORRECTION = re.compile(r"^\s*no[.,]\s*[¡¿]?\s*(?:%s|mira)\b" % "|".join(NAMES), re.I)


def is_correction(text):
    return bool(CORRECTION.match(nfc(text)))


def same_word(a, b):
    """Folded words that are the same word for the fair-picture checks: equal, or one begins with the other (a plural)."""
    return a == b or a.startswith(b) or b.startswith(a)


def loose_phrase(tokens_folded, phrase_folded):
    n = len(phrase_folded)
    if n == 0:
        return False
    for i in range(len(tokens_folded) - n + 1):
        if all(same_word(tokens_folded[i + k], phrase_folded[k]) for k in range(n)):
            return True
    return False


def jdump(obj, path):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1, sort_keys=False)
        f.write("\n")


def read_json(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


# ---------------------------------------------------------------------------------------------------------------- static reading of a story
# (the same reading as historia/tools/gen_libros.py: children, all_steps, pool, expand, question_clips, praise_clips)

def children(st):
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


def expand(pat, P, ids, free=frozenset()):
    """The clip ids (of `ids`) a line given as a pattern with $ variables can be: each $name stands for any value of the story's
    pool, as in gen_libros.py. `free`: variables that no step of the beats assigns (a scene act sets them); they stand for the
    pool or for any run of a-z0-9 as well (gen_libros reads them as the pool only, and so misses the values the scene gives)."""
    if "$" not in pat:
        return {pat} & ids
    alt = "(?:" + "|".join(sorted(map(re.escape, P), key=len, reverse=True)) + ")" if P else "[a-z0-9_]+"
    alt_free = "(?:" + alt + "|[a-z0-9]+)"
    rx = re.compile("^" + re.sub(r"\\\$([a-z]+)", lambda m: alt_free if m.group(1) in free else alt, re.escape(pat)) + "$")
    return {i for i in ids if rx.match(i)}


def template_vars(T):
    """Every $name that a string of the beats or final holds."""
    out = set()

    def go(o):
        if isinstance(o, str):
            out.update(re.findall(r"\$([a-z]+)", o))
        elif isinstance(o, list):
            for x in o:
                go(x)
        elif isinstance(o, dict):
            for k, v in o.items():
                go(k)
                go(v)
    go(T.get("beats"))
    go(T.get("final"))
    return out


def free_vars(T):
    return frozenset(template_vars(T) - story_vars(T))


def pool(T):
    p, pats = set(), set()
    for st in all_steps(T):
        vals = [v for k in ("options", "reparte", "vale", "burbujas", "resp") for v in st.get(k) or [] if isinstance(v, str)]
        if "calc" in st:
            vals += [st[k] for k in ("then", "else") if isinstance(st.get(k), str)]
        for v in vals:
            (pats if "$" in v else p).add(v)
    ids = set(T["clips"])
    for v in sorted(pats):
        p |= expand(v, p, ids)
    return p


def question_clips(T):
    P, ids, q, free = pool(T), set(T["clips"]), set(), free_vars(T)
    for st in all_steps(T):
        if (st.get("ask") or st.get("decide") or st.get("elige")) and isinstance(st.get("line"), str):
            q |= expand(st["line"], P, ids, free)
    return q


def praise_clips(T):
    p = {T.get("bien")} if isinstance(T.get("bien"), str) else set()
    for st in all_steps(T):
        if isinstance(st.get("bien"), str):
            p.add(st["bien"])
    return p


def story_vars(T):
    """Names the beats assign (draw, other, calc, as, reparte, recuerda), plus the engine's own."""
    v = set(ENGINE_VARS)
    for st in all_steps(T):
        for k in ("draw", "calc", "as", "other"):
            if isinstance(st.get(k), str):
                v.add(st[k])
        for n in st.get("reparte") or []:
            v.add(n)
    return v


def static_refs(T):
    """clip id -> set of 'main' | 'wrong' | 'gratis': where the beats name the clip, with every $ expanded over the story's pool.
    Used only to say why a clip that no play reaches is not reached."""
    ids, P, free = set(T["clips"]), pool(T), free_vars(T)
    out = defaultdict(set)

    def add(ref, ctx):
        if isinstance(ref, str):
            for c in expand(ref, P, ids, free):
                out[c].add(ctx)

    def lst(items, ctx):
        for st in items or []:
            if isinstance(st, str):
                add(st, ctx)
            elif isinstance(st, dict):
                step(st, ctx)

    def step(st, ctx):
        for k in ("say", "line", "bien"):
            add(st.get(k), ctx)
        for k in ("said", "voces"):
            if isinstance(st.get(k), dict):
                for v in st[k].values():
                    add(v, ctx)
        for k in ("lead", "after", "then", "else", "right"):
            if isinstance(st.get(k), list):
                lst(st[k], ctx)
        if isinstance(st.get("wrong"), list):
            lst(st["wrong"], "wrong")
        for o in st.get("options") or []:
            if isinstance(o, str) and isinstance(st.get(o), list):
                lst(st[o], ctx)
        if isinstance(st.get("gratis"), dict):
            for v in st["gratis"].values():
                if isinstance(v, list):
                    lst(v, "gratis")

    lst(T.get("beats"), "main")
    lst(T.get("final"), "main")
    return out


# ---------------------------------------------------------------------------------------------------------------- the walk

class World:
    """One state of the play with every answer right: what the walk knows (V: the story's variables, W: the {set} steps),
    whether a condition it could not evaluate was passed on the way (unsure), and the last clip heard (for what comes before)."""
    __slots__ = ("V", "W", "Wk", "last", "unsure")

    def __init__(self, V, W, Wk, last, unsure):
        self.V, self.W, self.Wk, self.last, self.unsure = V, W, Wk, last, unsure

    def fork(self):
        return World(dict(self.V), dict(self.W), self.Wk, self.last, self.unsure)


COND_KEY = re.compile(r"^!?([^=]+)")


def reads_of(obj, out):
    """The variables a step (or list of steps) can read: every $name in a string, and the key of every condition."""
    if isinstance(obj, str):
        out.update(re.findall(r"\$([a-z]+)", obj))
    elif isinstance(obj, list):
        for x in obj:
            reads_of(x, out)
    elif isinstance(obj, dict):
        for k, v in obj.items():
            if k in ("if", "cond") and isinstance(v, str):
                out.add(COND_KEY.match(v).group(1))
            reads_of(v, out)
            if isinstance(k, str):
                reads_of(k, out)
    return out


class Walker:
    """Plays one story the way juego.js does when every answer is right, every random choice every way at once. Plays that are
    in the same state (the variables still to be read, the {set} state, the last clip) are one state, so the number of states
    stays small. first=True follows only the first option of every choice (the order of the lines in the all-right play with the
    first draw, used to order the lines and to say what comes before a line)."""

    def __init__(self, T, first=False):
        self.T = T
        self.first = first
        self.ids = set(T["clips"])
        self.P = pool(T)
        self.assigned = story_vars(T)
        self.free = free_vars(T)
        self.unres = Counter()        # conditions that could not be evaluated -> number of times met
        self.unres_clips = Counter()  # $ clip ids that could not be filled
        self.dangling = set()         # clip ids named by a step that the story's clips do not have
        self.callado = bool(T.get("callado"))
        self.heard = {}               # clip -> {"sure": bool, "kinds": Counter}
        self.edges = defaultdict(list)  # clip -> [(previous clip, kind)] (None when nothing came before)
        self.seq = []                 # first=True: the clips in order
        self.peak = 0
        self._reads = {}

    def rd(self, st):
        k = id(st)
        if k not in self._reads:
            self._reads[k] = frozenset(reads_of(st, set()))
        return self._reads[k]

    # variables
    def sub(self, s, w):
        if not isinstance(s, str):
            return s
        return re.sub(r"\$([a-z]+)", lambda m: str(w.V[m.group(1)]) if w.V.get(m.group(1)) is not None else m.group(0), s)

    def val(self, key, w):
        if w.V.get(key) is not None:
            return True, w.V[key]
        if key in w.W:
            return True, w.W[key]
        if key in ENGINE_ALLRIGHT:
            return True, ENGINE_ALLRIGHT[key]
        return False, None

    def unknown(self, key):
        """True when a key that is not set cannot be known: scene state (set by an act) or memory kept from an earlier play."""
        return key.startswith("mem_") or key not in self.assigned

    def cond(self, e, w):
        """True, False, or None when the walk cannot know."""
        neg = e.startswith("!")
        if neg:
            e = e[1:]
        if "=" in e:
            key, rhs = e.split("=", 1)
            rhs = self.sub(rhs, w)
            found, v = self.val(key, w)
            if not found:
                r = None if self.unknown(key) else (rhs == "undefined")
            else:
                r = str(v) == rhs
        else:
            found, v = self.val(e, w)
            if not found:
                r = None if self.unknown(e) else False
            else:
                r = bool(v)
        if r is None:
            self.unres[("!" if neg else "") + e] += 1
            return None
        return (not r) if neg else r

    # recording
    def add(self, w, clip, kind):
        h = self.heard.setdefault(clip, {"sure": False, "kinds": Counter()})
        if not w.unsure:
            h["sure"] = True
        h["kinds"][kind] += 1
        if w.last not in self.edges[clip]:
            self.edges[clip].append(w.last)
        w.last = (clip, kind)
        if self.first:
            self.seq.append((clip, kind))

    def merge(self, ws, live):
        seen = OrderedDict()
        for w in ws:
            k = (tuple((n, w.V[n]) for n in sorted(w.V) if n in live and w.V[n] is not None), w.Wk, w.unsure, w.last)
            if k not in seen:
                seen[k] = w
        out = list(seen.values())
        if self.first:
            out = out[:1]
        self.peak = max(self.peak, len(out))
        return out

    # steps
    def say1(self, cid, w, kind):
        c = self.sub(cid, w)
        if not isinstance(c, str):
            return [w]
        if "$" in c:
            alts = sorted(expand(c, self.P, self.ids, self.free))
            if not alts:
                self.unres_clips[c] += 1
                return [w]
            out = []
            for a in alts:
                w2 = w.fork()
                w2.unsure = True
                self.add(w2, a, kind)
                out.append(w2)
            return out
        if c not in self.ids:
            if kind != "bien":
                self.dangling.add(c)
            return [w]
        self.add(w, c, kind)
        return [w]

    def say_all(self, cid, ws, kind):
        out = []
        for w in ws:
            out.extend(self.say1(cid, w, kind))
        return out

    def run(self, steps, ws, live):
        steps = steps or []
        suf = [None] * (len(steps) + 1)
        suf[len(steps)] = frozenset(live)
        for i in range(len(steps) - 1, -1, -1):
            suf[i] = suf[i + 1] | self.rd(steps[i])
        for i, st in enumerate(steps):
            nxt = []
            for w in ws:
                nxt.extend(self.one(st, w, suf[i + 1]))
            ws = self.merge(nxt, suf[i + 1])
        return ws

    def vmapa(self, m, w):
        return {self.sub(k, w): self.sub(v, w) for k, v in (m or {}).items()} if isinstance(m, dict) else {}

    def praise(self, st, ws):
        if self.callado or st.get("bien") is False:
            return ws
        return self.say_all(st.get("bien") or self.T.get("bien") or "muy_bien", ws, "bien")

    def bubbles(self, voz, order, ws):
        out = ws
        for k in order:
            if k in voz:
                out = self.say_all(voz[k], out, "voz")
        return out

    def one(self, st, w, live):
        if isinstance(st, str):
            return self.say1(st, w, "linea")
        if not isinstance(st, dict):
            return [w]
        if "say" in st:
            return self.say1(st["say"], w, "linea")
        inner = live | self.rd(st)
        if "if" in st:
            r = self.cond(st["if"], w)
            if r is True:
                return self.run(st.get("then"), [w], live)
            if r is False:
                return self.run(st.get("else"), [w], live)
            a, b = w.fork(), w.fork()
            a.unsure = b.unsure = True
            return self.run(st.get("then"), [a], live) + self.run(st.get("else"), [b], live)
        if "set" in st:
            w.W.update(st["set"])
            w.Wk = json.dumps(w.W, sort_keys=True)
            return [w]
        if "draw" in st:
            ops = [self.sub(o, w) for o in st["options"]]
            out = []
            for v in ops:
                w2 = w.fork()
                w2.V[st["draw"]] = v
                if st.get("other"):
                    w2.V[st["other"]] = next((x for x in ops if x != v), None)
                out.append(w2)
            return out
        if "reparte" in st:
            ops, names = list(st["options"]), st["reparte"]
            out = []
            for perm in itertools.permutations(ops, min(len(names), len(ops))):
                w2 = w.fork()
                for n, v in zip(names, perm):
                    w2.V[n] = v
                for n in names[len(perm):]:
                    w2.V[n] = None
                out.append(w2)
            return out
        if "calc" in st:
            r = self.cond(st["cond"], w)
            if r is None:
                a, b = w.fork(), w.fork()
                a.unsure = b.unsure = True
                a.V[st["calc"]] = self.sub(st.get("then"), a)
                b.V[st["calc"]] = self.sub(st.get("else"), b)
                return [a, b]
            w.V[st["calc"]] = self.sub(st["then"] if r else st.get("else"), w)
            return [w]
        if "recuerda" in st:
            w.V["mem_" + st["recuerda"]] = self.sub(str(st.get("valor")), w)
            return [w]
        if "ask" in st:
            return self.ask(st, w, inner)
        if "decide" in st:
            return self.decide(st, w, inner)
        if "elige" in st:
            return self.elige(st, w, inner)
        return [w]   # act, wait, cam, dots, cost, twinkle ...: no clip

    def ask(self, st, w, live):
        t = self.sub(st["ask"], w)
        voz, said = self.vmapa(st.get("voces"), w), self.vmapa(st.get("said"), w)
        ws = self.run(st.get("lead"), [w], live)
        if isinstance(st.get("line"), str):
            ws = self.say_all(st["line"], ws, "pregunta")
        if voz:
            if isinstance(st.get("resp"), list):
                order = [self.sub(x, w) for x in st["resp"]]
            elif isinstance(w.W.get("resp"), list):
                order = [self.sub(x, w) for x in w.W["resp"]]
            else:
                order = [t]
            ws = self.bubbles(voz, order, ws)
        if t in said:
            ws = self.say_all(said[t], ws, "dicho")
        ws = self.run(st.get("after"), ws, live)
        ws = self.praise(st, ws)
        return self.run(st.get("then"), ws, live)

    def decide(self, st, w, live):
        ops = [self.sub(o, w) for o in st["options"]]
        picks = [self.sub(st["pick"], w)] if st.get("pick") else list(OrderedDict.fromkeys(ops))
        out = []
        for pick in picks:
            w2 = w.fork() if len(picks) > 1 else w
            if st.get("as"):
                w2.V[st["as"]] = pick
            if st.get("other"):
                w2.V[st["other"]] = next((x for x in ops if x != pick), None)
            voz, said = self.vmapa(st.get("voces"), w2), self.vmapa(st.get("said"), w2)
            bur = [self.sub(b, w2) for b in st.get("burbujas") or []]
            ws = self.run(st.get("lead"), [w2], live)
            if isinstance(st.get("line"), str):
                ws = self.say_all(st["line"], ws, "pregunta")
            if voz:
                ws = self.bubbles(voz, bur or ops, ws)
            for x in ws:
                x.V["ok"] = "1"
                x.V["x"] = pick
            if pick in said:
                ws = self.say_all(said[pick], ws, "dicho")
            ws = self.praise(st, ws)
            out.extend(self.run(st.get("right"), ws, live))
        return out

    def elige(self, st, w, live):
        out = []
        ops = list(OrderedDict.fromkeys(st["options"]))
        for k in ops:
            w2 = w.fork() if len(ops) > 1 else w
            said = self.vmapa(st.get("said"), w2)
            ws = self.run(st.get("lead"), [w2], live)
            if isinstance(st.get("line"), str):
                ws = self.say_all(st["line"], ws, "pregunta")
            for x in ws:
                x.V["elegido"] = k
            if k in said:
                ws = self.say_all(said[k], ws, "dicho")
            out.extend(self.run(st.get(k), ws, live))
        return out

    def walk(self):
        live = frozenset()
        ws = self.run(self.T.get("beats"), [World({}, {}, "{}", None, False)], self.rd(self.T.get("final")))
        return self.run(self.T.get("final"), ws, live)


def walk_story(T):
    """-> dict: heard {clip: {sure, kinds}}, canon [(clip, kind)] (the first option of every choice), before {clip: [(prev, kind)]},
    peak (the most states at once), unres, unres_clips, dangling"""
    wk = Walker(T)
    wk.walk()
    first = Walker(T, first=True)
    first.walk()
    before = {c: [e for e in v] for c, v in wk.edges.items()}
    return {"states": wk.peak, "heard": wk.heard, "canon": first.seq, "before": before, "unres": dict(sorted(wk.unres.items())),
            "unres_clips": dict(sorted(wk.unres_clips.items())), "dangling": sorted(wk.dangling)}


# ---------------------------------------------------------------------------------------------------------------- loading

class Data:
    pass


def load(root):
    root = Path(root)
    H = root / "historia"
    D = Data()
    D.root, D.H = root, H
    D.curso = read_json(H / "datos" / "curso.json")
    D.ready = read_json(H / "audio" / "ready.json")
    clips = D.ready["clips"]
    D.audio = set(clips.keys()) if isinstance(clips, dict) else set(clips)
    D.story = {}
    for p in sorted((H / "cuentos").glob("*.json")):
        d = read_json(p)
        D.story[d["id"]] = d
    D.map, D.place_of, D.dib, D.place_order = [], {}, [], []
    for l in D.curso["lugares"]:
        D.place_order.append(l["id"])
        for s in l.get("cuentos", []):
            D.map.append(s)
            D.place_of[s] = l["id"]
        for s in l.get("dibujos", []):
            D.dib.append(s)
            D.place_of[s] = l["id"]
    D.idx = {s: i + 1 for i, s in enumerate(D.map)}
    D.place_last = {}      # place -> index of its last map story
    for s in D.map:
        D.place_last[D.place_of[s]] = D.idx[s]
    D.book = {}
    for p in sorted((H / "libros").glob("*.json")):
        d = read_json(p)
        D.book[d["id"]] = d
    mp = root / "docs" / "hablar" / "02-marcas.json"
    D.marcas = read_json(mp) if mp.exists() else {}
    D.pairs = {}
    for fn in D.curso.get("cual", []):
        p = H / "cuentos" / (fn + ".json")
        if not p.exists():
            continue
        d = read_json(p)
        for it in d.get("items", []):
            D.pairs[it["w"]] = {"say": it["say"], "text": d["clips"].get(it["say"], {}).get("text"), "si": it["si"], "no": it["no"],
                                "scene": d.get("scene"), "file": fn}
    D.eligible = [s for s in D.map + D.dib if s in D.story and s in D.book]
    return D


# ---------------------------------------------------------------------------------------------------------------- 1. words

def build_words(D, stops):
    track = OrderedDict()
    first_focus = {}
    first_back = {}
    for s in D.map:
        T = D.story[s]
        for w in T.get("focus_words", []) + T.get("back_again", []):
            if w not in track:
                track[w] = {"story": s, "index": D.idx[s]}
        for w in T.get("focus_words", []):
            first_focus.setdefault(w, s)
        for w in T.get("back_again", []):
            first_back.setdefault(w, s)
    words = []
    for w, f in track.items():
        place_story = first_focus.get(w, first_back.get(w))
        pair = D.pairs.get(w)
        words.append({"word": w, "place": D.place_of[place_story], "first_story": f["story"], "first_index": f["index"],
                      "first_place": D.place_of[f["story"]], "pair": pair})
    return words


# ---------------------------------------------------------------------------------------------------------------- matching tracked items

class Matcher:
    def __init__(self, words):
        self.items = [(w, tuple(toks(w))) for w in words]

    def spans(self, tokens):
        """{word: [(i, j)]} for the tracked words and phrases in the tokens. A word that stands inside a longer tracked phrase
        of the same sentence does not count there."""
        raw = []
        for w, pt in self.items:
            n = len(pt)
            if not n:
                continue
            for i in range(len(tokens) - n + 1):
                if tuple(tokens[i:i + n]) == pt:
                    raw.append((w, i, i + n))
        out = OrderedDict()
        for w, i, j in raw:
            if any(j2 - i2 > j - i and i2 <= i and j <= j2 for _, i2, j2 in raw):
                continue
            out.setdefault(w, []).append((i, j))
        return out

    def words_of(self, text):
        return list(self.spans(toks(text)).keys())


# ---------------------------------------------------------------------------------------------------------------- 2. candidates

def story_rank(D, sid):
    if sid in D.idx:
        return (0, D.idx[sid])
    return (1, D.dib.index(sid) if sid in D.dib else 999)


def page_of(D, sid, clip):
    b = D.book.get(sid)
    if not b:
        return None
    for n, p in enumerate(b["pages"], 1):
        if clip in p["clips"]:
            return n
    return None


def clip_text(D, sid, clip):
    c = D.story[sid]["clips"].get(clip)
    if c is None:
        for s in D.story.values():
            if clip in s["clips"]:
                c = s["clips"][clip]
                break
    return c["text"] if c else ""


def pagina_record(D, sid, n, clip):
    """The page that carries the clip: the book, the page number, the picture, and the page's other clips (id and text)."""
    p = D.book[sid]["pages"][n - 1]
    return {"book": sid, "page": n, "img": "historia/libros/" + p["img"],
            "other_clips": [{"clip": c, "text": clip_text(D, sid, c)} for c in p["clips"] if c != clip]}


def build_candidates(D, words, walks, stops, report):
    M = Matcher([w["word"] for w in words])
    wordidx = {w["word"]: i for i, w in enumerate(words)}
    fijos = read_json(D.H / "datos" / "fijos.json")
    generic_ids = set(v for v in fijos.get("clips", {}).values() if not v.endswith("_")) | set(fijos.get("lineas", {}).keys())
    generic_prefix = tuple(v for v in fijos.get("clips", {}).values() if v.endswith("_"))
    known = set(FUNCTION_WORDS) | set(NAMES)
    for w in words:
        known.update(toks(w["word"]))
    for s in sorted(D.story):
        for a in D.story[s].get("also_heard", []):
            known.update(toks(a))

    occ = defaultdict(list)    # (word, text) -> occurrences
    order_in_story = {}
    for sid in D.eligible:
        T = D.story[sid]
        W = walks[sid]
        Q = question_clips(T)
        P = praise_clips(T)
        canon_pos = {}
        for i, (c, _) in enumerate(W["canon"]):
            canon_pos.setdefault(c, i)
        extra = 0
        for clip, v in T["clips"].items():
            if clip not in D.audio:
                continue
            text = v["text"]
            reach = W["heard"].get(clip)
            tag, body = split_tag(text)
            tokens = toks(body)
            ok_generic = not (clip in generic_ids or clip in P or clip.startswith(generic_prefix))
            if not ok_generic or clip in Q or reach is None:
                continue
            if is_correction(text):
                continue
            if len(tokens) <= 2:
                continue
            hits = M.spans(tokens)
            if not hits:
                continue
            pos = canon_pos.get(clip)
            if pos is None:
                extra += 1
                pos = 100000 + extra
            pn = page_of(D, sid, clip)
            for w in hits:
                occ[(w, text)].append({"story": sid, "clip": clip, "voice": {"who": v.get("who"), "habla": v.get("habla")}, "page": pn,
                                       "pos": pos, "sure": reach["sure"]})
    cands = []
    for (w, text), os_ in occ.items():
        os_.sort(key=lambda o: (story_rank(D, o["story"]), o["pos"], o["clip"]))
        with_page = [o for o in os_ if o["page"] is not None]
        rep = with_page[0] if with_page else os_[0]
        cands.append((w, text, rep, os_))
    cands.sort(key=lambda c: (wordidx[c[0]], story_rank(D, c[2]["story"]), c[2]["pos"], c[2]["clip"]))

    # flags that need the whole list: cluster
    def cluster_key(text):
        tag, body = split_tag(text)
        ts = ["<nombre>" if t in NAMES else t for t in toks(body)]
        return tuple((["<tag>"] if tag else []) + ts)

    keys = sorted({cluster_key(c[1]) for c in cands})
    cl_id = {k: "k%04d" % (i + 1) for i, k in enumerate(keys)}

    out = []
    for n, (w, text, rep, os_) in enumerate(cands, 1):
        tag, body = split_tag(text)
        tokens = toks(body)
        sid, clip = rep["story"], rep["clip"]
        marks = D.marcas.get(sid, {}).get(clip)
        marca = None
        if marks:
            b = walks[sid]["before"].get(clip)
            canon = [c for c, _ in walks[sid]["canon"]]
            prev = None
            if clip in canon and canon.index(clip) > 0:
                i = canon.index(clip)
                prev = walks[sid]["canon"][i - 1]
            elif b and b[0]:
                prev = b[0]
            antes = {"clip": prev[0], "text": clip_text(D, sid, prev[0]), "tipo": prev[1]} if prev else None
            others = []
            for pv in b or []:
                if pv and (not prev or pv[0] != prev[0]):
                    others.append({"clip": pv[0], "text": clip_text(D, sid, pv[0]), "tipo": pv[1]})
            marca = {"targets": marks, "antes": antes, "otros_antes": others}
        rec = OrderedDict()
        rec["id"] = "%04d" % n
        rec["word"] = w
        rec["story"] = sid
        rec["clip"] = clip
        rec["voice"] = rep["voice"]
        rec["text"] = text
        rec["text_sin_tag"] = body
        rec["tokens"] = tokens
        rec["n_tokens"] = len(tokens)
        rec["tiene_nombre"] = any(t in NAMES for t in tokens)
        rec["palabra_repetida"] = len(set(tokens)) < len(tokens)
        rec["tag"] = tag is not None
        rec["atada_al_dibujo"] = bool(tokens[:1] == ["mira"] or tuple(tokens[:2]) in DEICTIC_STARTS)
        rec["token_no_enseñado"] = [t for t in tokens if t not in known]
        rec["cluster"] = cl_id[cluster_key(text)]
        rec["marca_habla"] = marca
        rec["ruta_cierta"] = rep["sure"]
        rec["apariciones"] = [{"story": o["story"], "clip": o["clip"], "page": o["page"],
                               "marca": bool(D.marcas.get(o["story"], {}).get(o["clip"]))} for o in os_]
        rec["pagina"] = pagina_record(D, rep["story"], rep["page"], rep["clip"]) if rep["page"] is not None else None
        rec["wrong_pictures"] = []
        out.append(rec)
    return out, M


# ---------------------------------------------------------------------------------------------------------------- 3. wrong pictures, 4. false sentences, 5. Parejas

class Fair:
    """Folded page texts of every book page, and the test 'does this text hold a tracked word of that sentence'."""

    def __init__(self, D, M):
        self.D, self.M = D, M
        self.ptoks = {}
        self.wtoks = {w: [fold(t) for t in pt] for w, pt in M.items}
        self.sent = {}

    def page_texts(self, sid, n):
        k = (sid, n)
        if k not in self.ptoks:
            p = self.D.book[sid]["pages"][n - 1]
            self.ptoks[k] = [[fold(t) for t in toks(clip_text(self.D, sid, c))] for c in p["clips"]]
        return self.ptoks[k]

    def sentence_words(self, text):
        if text not in self.sent:
            self.sent[text] = self.M.words_of(text)
        return self.sent[text]

    def shares(self, text, sid, n):
        """Does a tracked word of the sentence stand in any clip text of the page?"""
        pts = self.page_texts(sid, n)
        for w in self.sentence_words(text):
            pw = self.wtoks[w]
            if any(loose_phrase(pt, pw) for pt in pts):
                return True
        return False


def propose_wrong(D, fair, cands):
    for c in cands:
        pg = c["pagina"]
        if not pg:
            continue
        sid, n = pg["book"], pg["page"]
        total = len(D.book[sid]["pages"])
        opts = [m for m in range(1, total + 1) if abs(m - n) >= MIN_APART and not fair.shares(c["text"], sid, m)]
        opts.sort(key=lambda m: (-abs(m - n), m))
        c["wrong_pictures"] = [{"page": m, "img": "historia/libros/" + D.book[sid]["pages"][m - 1]["img"], "distance": abs(m - n)}
                               for m in opts[:MAX_WRONG]]


def placements(cands):
    """Every (candidate, story, clip, page) where a candidate sentence has a book page, in a fixed order."""
    out = []
    for c in cands:
        for o in c["apariciones"]:
            if o["page"] is not None:
                out.append({"cand": c["id"], "word": c["word"], "text": c["text"], "story": o["story"], "clip": o["clip"], "page": o["page"]})
    return out


def false_sentences(D, fair, pls):
    by_book = defaultdict(list)
    for p in pls:
        by_book[p["story"]].append(p)
    out = OrderedDict()
    for sid in sorted(by_book, key=lambda s: story_rank(D, s)):
        pages = sorted({p["page"] for p in by_book[sid]})
        for n in pages:
            seen, opts = set(), []
            for p in by_book[sid]:
                if abs(p["page"] - n) < MIN_APART or p["text"] in seen:
                    continue
                if fair.shares(p["text"], sid, n):
                    continue
                seen.add(p["text"])
                opts.append(p)
            opts.sort(key=lambda p: (-abs(p["page"] - n), p["page"], p["clip"], p["word"]))
            if not opts:
                out["%s/%d" % (sid, n)] = []
                continue
            row = []
            for p in opts[:MAX_WRONG]:
                row.append({"text": p["text"], "clip": p["clip"], "page": p["page"], "distance": abs(p["page"] - n),
                            "words": sorted({q["word"] for q in by_book[sid] if q["text"] == p["text"]}),
                            "candidates": sorted({q["cand"] for q in by_book[sid] if q["text"] == p["text"]})})
            out["%s/%d" % (sid, n)] = row
    return out


def build_parejas(D, fair, pls, wordidx):
    out, stats = OrderedDict(), OrderedDict()
    by_book = defaultdict(list)
    for p in pls:
        by_book[p["story"]].append(p)
    for sid in D.map:
        nodes = sorted(by_book.get(sid, []), key=lambda p: (p["page"], wordidx[p["word"]], p["clip"]))
        stats[sid] = {"pages": len(D.book[sid]["pages"]), "items": len(nodes), "pages_with_items": len({p["page"] for p in nodes}), "compatible_pairs": 0}
        if not nodes:
            out[sid] = []
            continue
        ok = {}

        def compat(a, b):
            k = (id(a), id(b))
            if k not in ok:
                ok[k] = (a["page"] != b["page"] and abs(a["page"] - b["page"]) >= MIN_APART and
                         not fair.shares(a["text"], sid, b["page"]) and not fair.shares(b["text"], sid, a["page"]))
            return ok[k]

        pages_pairs = set()
        for i, a in enumerate(nodes):
            for b in nodes[i + 1:]:
                if compat(a, b):
                    pages_pairs.add((a["page"], b["page"]))
        stats[sid]["compatible_pairs"] = len(pages_pairs)

        def dfs(avail, size, distinct, chosen):
            if len(chosen) == size:
                return chosen
            for i, a in enumerate(avail):
                if all(compat(a, b) for b in chosen) and (not distinct or a["word"] not in {b["word"] for b in chosen}):
                    r = dfs(avail[i + 1:], size, distinct, chosen + [a])
                    if r:
                        return r
            return None

        sets, used_pages, used_nodes = [], set(), set()
        for _ in range(MAX_SETS):
            found = None
            for size, distinct in ((4, True), (4, False), (3, True), (3, False)):
                for banned in ("pages", "nodes"):     # a set on pages no earlier set used; else on items no earlier set used
                    avail = [p for p in nodes if (p["page"] not in used_pages if banned == "pages" else id(p) not in used_nodes)]
                    found = dfs(avail, size, distinct, [])
                    if found:
                        break
                if found:
                    break
            if not found:
                break
            sets.append(found)
            used_pages |= {p["page"] for p in found}
            used_nodes |= {id(p) for p in found}
        out[sid] = [{"size": len(s), "words_differ": len({p["word"] for p in s}) == len(s),
                     "items": [{"cand": p["cand"], "word": p["word"], "text": p["text"], "clip": p["clip"], "page": p["page"],
                                "img": "historia/libros/" + D.book[sid]["pages"][p["page"] - 1]["img"]} for p in s]} for s in sets]
    return out, stats


# ---------------------------------------------------------------------------------------------------------------- the walk of every story, and the classes of clips

def walk_all(D, report):
    walks, classes = {}, {}
    for sid in D.eligible:
        T = D.story[sid]
        W = walk_story(T)
        walks[sid] = W
        Q = question_clips(T)
        P = praise_clips(T)
        fijos = read_json(D.H / "datos" / "fijos.json")
        gen_ids = set(v for v in fijos.get("clips", {}).values() if not v.endswith("_")) | set(fijos.get("lineas", {}).keys())
        gen_pre = tuple(v for v in fijos.get("clips", {}).values() if v.endswith("_"))
        refs = static_refs(T)
        names = {v for v in (T.get("names") or {}).values() if isinstance(v, str)}
        cl = Counter()
        which = {}
        for clip in T["clips"]:
            if clip not in D.audio:
                which[clip] = "sin_audio"
            elif clip in gen_ids or clip in P or clip.startswith(gen_pre):
                which[clip] = "generica"
            elif clip in Q:
                which[clip] = "pregunta"
            elif clip in W["heard"]:
                which[clip] = "alcanzada"
            elif refs.get(clip) and refs[clip] <= {"wrong", "gratis"}:
                which[clip] = "solo_error"
            elif refs.get(clip):
                which[clip] = "rama_no_tomada"
            elif clip in names:
                which[clip] = "nombre_de_toque"
            else:
                which[clip] = "sin_lugar"
            cl[which[clip]] += 1
        classes[sid] = {"counts": dict(cl), "which": which}
        # clips that the book carries but the walk did not reach
        miss = []
        for n, p in enumerate(D.book[sid]["pages"], 1):
            for c in p["clips"]:
                if c not in W["heard"] and which.get(c) not in ("pregunta", "generica"):
                    miss.append((n, c, which.get(c, "no_en_el_cuento")))
        classes[sid]["book_not_walked"] = miss
    return walks, classes


def why_not(D, walks, classes, M, sid, clip):
    """None when the clip is a candidate line for some tracked word, else the first rule it fails."""
    T = D.story.get(sid)
    if not T or clip not in T["clips"]:
        return "clip not in the story"
    if sid not in D.eligible:
        return "story has no book"
    w = classes[sid]["which"][clip]
    if w != "alcanzada":
        return {"generica": "generic clip (2c)", "pregunta": "question or order of an ask/decide/elige (2c)", "sin_audio": "no audio"}.get(w, "not reached on the all-right path (2d): " + w)
    text = T["clips"][clip]["text"]
    if is_correction(text):
        return "a correction (2e)"
    tag, body = split_tag(text)
    if len(toks(body)) <= 2:
        return "two words or fewer once the tag is off (2f)"
    if not M.spans(toks(body)):
        return "no tracked word in it (2a)"
    return None


# ---------------------------------------------------------------------------------------------------------------- 6. resumen.md

def bucket(n):
    return "0" if n == 0 else "1" if n == 1 else "2" if n == 2 else "3-4" if n <= 4 else "5+"


BUCKETS = ["0", "1", "2", "3-4", "5+"]


def md_table(head, rows):
    out = ["| " + " | ".join(head) + " |", "|" + "|".join("---" for _ in head) + "|"]
    for r in rows:
        out.append("| " + " | ".join(str(x).replace("|", "\\|") for x in r) + " |")
    return out


def scope_has(D, o, k, with_dib):
    s = o["story"]
    if s in D.idx:
        return D.idx[s] <= k
    if not with_dib:
        return False
    return D.place_last.get(D.place_of[s], 10 ** 6) <= k


def usable_flags(c):
    n = c["n_tokens"]
    arma = 3 <= n <= 6 and not c["tiene_nombre"] and not c["palabra_repetida"] and not c["tag"] and not c["token_no_enseñado"]
    oyes = 2 <= n <= 8
    dilo = bool(c["marca_habla"] and c["marca_habla"]["antes"] and any(t["palabra"] == c["word"] for t in c["marca_habla"]["targets"]))
    return arma, oyes, dilo


def write_resumen(D, words, cands, parejas, pstats, falsas, walks, classes, stops, fits, path, sheets_n, dup_sheets):
    L = []
    A = L.append
    by_word = defaultdict(list)
    for c in cands:
        by_word[c["word"]].append(c)
    wl = {w["word"]: w for w in words}
    n_page = sum(1 for c in cands if c["pagina"])
    A("# Repaso data: candidates, counts and every place the data did not fit")
    A("")
    A("Made by `coqui/tool/make_repaso.py`. Every number is printed by the tool from the files of this repo. No advice.")
    A("")
    A("## Counts")
    A("")
    rows = [
        ("words (union of focus_words and back_again of the %d map stories)" % len(D.map), len(words)),
        ("  expected", EXPECTED_WORDS),
        ("  with a picture pair", sum(1 for w in words if w["pair"])),
        ("  without a picture pair", sum(1 for w in words if not w["pair"])),
        ("stories read (map stories + picture stories with a book)", len(D.eligible)),
        ("candidates (word, distinct sentence)", len(cands)),
        ("  distinct sentences", len({c["text"] for c in cands})),
        ("  distinct clusters", len({c["cluster"] for c in cands})),
        ("candidates with a book page", n_page),
        ("candidates with at least 1 proposed wrong picture", sum(1 for c in cands if len(c["wrong_pictures"]) >= 1)),
        ("candidates with at least 2 proposed wrong pictures", sum(1 for c in cands if len(c["wrong_pictures"]) >= 2)),
        ("candidates with a decided speech mark (marca_habla)", sum(1 for c in cands if c["marca_habla"])),
        ("  of those with a line before it", sum(1 for c in cands if c["marca_habla"] and c["marca_habla"]["antes"])),
        ("candidates that are a line of `tu` (Coquí)", sum(1 for c in cands if c["voice"]["who"] == "tu")),
        ("candidates reached only through a condition the walk could not evaluate", sum(1 for c in cands if not c["ruta_cierta"])),
    ]
    L += md_table(["", "n"], rows)
    A("")
    A("Candidates by flag (a candidate can have several):")
    A("")
    flags = [("tiene_nombre", lambda c: c["tiene_nombre"]), ("palabra_repetida", lambda c: c["palabra_repetida"]),
             ("tag (had a speaker tag)", lambda c: c["tag"]), ("atada_al_dibujo", lambda c: c["atada_al_dibujo"]),
             ("token_no_enseñado (at least one)", lambda c: bool(c["token_no_enseñado"])),
             ("no flag at all", lambda c: not (c["tiene_nombre"] or c["palabra_repetida"] or c["tag"] or c["atada_al_dibujo"] or c["token_no_enseñado"])),
             ("voice narr", lambda c: c["voice"]["who"] == "narr"), ("voice tu", lambda c: c["voice"]["who"] == "tu"),
             ("has a character voice (habla)", lambda c: bool(c["voice"]["habla"])),
             ("n_tokens 3", lambda c: c["n_tokens"] == 3), ("n_tokens 4 to 6", lambda c: 4 <= c["n_tokens"] <= 6),
             ("n_tokens 7 or more", lambda c: c["n_tokens"] >= 7),
             ("from a map story", lambda c: c["story"] in D.idx), ("from a picture story (d-*)", lambda c: c["story"] not in D.idx)]
    L += md_table(["flag", "candidates", "with a page"], [(n, sum(1 for c in cands if f(c)), sum(1 for c in cands if f(c) and c["pagina"])) for n, f in flags])
    A("")
    A("Usable for each game (the rule of the order; a page is not part of the rule, so the second column counts those that have one):")
    A("")
    u_arma = [c for c in cands if usable_flags(c)[0]]
    u_oyes = [c for c in cands if usable_flags(c)[1]]
    u_dilo = [c for c in cands if usable_flags(c)[2]]
    L += md_table(["game", "candidates", "with a page"],
                  [("Arma la frase (3 to 6 tokens, no name, no repeated word, no tag, no untaught token)", len(u_arma), sum(1 for c in u_arma if c["pagina"])),
                   ("¿Qué oyes? (2 to 8 tokens)", len(u_oyes), sum(1 for c in u_oyes if c["pagina"])),
                   ("Dilo (decided speech mark that targets the word, with a line before it)", len(u_dilo), sum(1 for c in u_dilo if c["pagina"]))])
    A("")

    # ---- per word
    A("## Per word")
    A("")
    A("Sorted by fewest candidates with a page first (then fewest candidates, then course order). `pair`: has a picture pair. `clusters`: distinct clusters. `2+ wrong`: candidates with at least 2 proposed wrong pictures. `arma` / `oyes` / `dilo`: usable for Arma la frase / ¿Qué oyes? / Dilo.")
    A("")
    rows = []
    order = {w["word"]: i for i, w in enumerate(words)}
    for w in words:
        cs = by_word.get(w["word"], [])
        rows.append((w["word"], w["place"], w["first_story"], "yes" if w["pair"] else "no", len(cs), len({c["cluster"] for c in cs}),
                     sum(1 for c in cs if c["pagina"]), sum(1 for c in cs if len(c["wrong_pictures"]) >= 2),
                     sum(1 for c in cs if usable_flags(c)[0]), sum(1 for c in cs if usable_flags(c)[1]), sum(1 for c in cs if usable_flags(c)[2])))
    rows.sort(key=lambda r: (r[6], r[4], order[r[0]]))
    L += md_table(["word", "place", "first story", "pair", "candidates", "clusters", "with page", "2+ wrong", "arma", "oyes", "dilo"], rows)
    A("")

    # ---- distributions
    def dist(sel):
        cnt = Counter(bucket(n) for n in sel)
        return [cnt.get(b, 0) for b in BUCKETS]

    A("## Distribution")
    A("")
    A("Words by number of candidates (all %d words, every story)." % len(words))
    A("")
    pagecount = [sum(1 for c in by_word.get(w["word"], []) if c["pagina"]) for w in words]
    anycount = [len(by_word.get(w["word"], [])) for w in words]
    L += md_table(["candidates"] + BUCKETS, [["with a page"] + dist(pagecount), ["any"] + dist(anycount)])
    A("")
    A("For a learner who has finished stories 1..k of the course. Words counted: those first met in a story 1..k. Candidates counted: a sentence with an occurrence in a map story 1..k (a page counts if that occurrence has one). Second block: the picture stories of a place also count once all that place's map stories are in 1..k.")
    A("")
    for with_dib in (False, True):
        A("Map stories only." if not with_dib else "Map stories and the picture stories of the places already finished.")
        A("")
        rows = []
        for k in KS:
            met = [w for w in words if w["first_index"] <= k]
            pc, ac = [], []
            for w in met:
                cs = by_word.get(w["word"], [])
                inscope = [c for c in cs if any(scope_has(D, o, k, with_dib) for o in c["apariciones"])]
                pc.append(sum(1 for c in cs if any(scope_has(D, o, k, with_dib) and o["page"] is not None for o in c["apariciones"])))
                ac.append(len(inscope))
            rows.append(["k=%d" % k, len(met), "with a page"] + dist(pc))
            rows.append(["", "", "any"] + dist(ac))
        L += md_table(["k", "words met", "candidates"] + BUCKETS, rows)
        A("")

    # ---- words with nothing
    A("## Words with no candidate, and with none that has a page")
    A("")
    nothing = [w for w in words if not by_word.get(w["word"])]
    nopage = [w for w in words if by_word.get(w["word"]) and not any(c["pagina"] for c in by_word[w["word"]])]
    A("No candidate at all: %d words." % len(nothing))
    A("")
    if nothing:
        L += md_table(["word", "place", "first story", "picture pair"], [(w["word"], w["place"], w["first_story"], "yes" if w["pair"] else "no") for w in nothing])
        A("")
    A("Candidates, but none with a page: %d words." % len(nopage))
    A("")
    if nopage:
        L += md_table(["word", "place", "first story", "candidates", "picture pair"], [(w["word"], w["place"], w["first_story"], len(by_word[w["word"]]), "yes" if w["pair"] else "no") for w in nopage])
        A("")
    two = [w for w in words if len(by_word.get(w["word"], [])) < 3]
    A("Fewer than 3 candidates (any): %d words: %s" % (len(two), ", ".join("%s (%d)" % (w["word"], len(by_word.get(w["word"], []))) for w in two) or "none"))
    A("")
    wrong2 = [w for w in words if sum(1 for c in by_word.get(w["word"], []) if len(c["wrong_pictures"]) >= 2) == 0]
    A("No candidate with at least 2 proposed wrong pictures: %d words." % len(wrong2))
    A("")

    # ---- pages
    A("## Pages")
    A("")
    all_pages = [(s, n) for s in D.eligible for n in range(1, len(D.book[s]["pages"]) + 1)]
    carried = set()
    for c in cands:
        for o in c["apariciones"]:
            if o["page"] is not None:
                carried.add((o["story"], o["page"]))
    A("Book pages: %d. Pages that carry at least one candidate sentence (any occurrence): %d. Pages that are the picture of a candidate record: %d." %
      (len(all_pages), len(carried), len({(c["pagina"]["book"], c["pagina"]["page"]) for c in cands if c["pagina"]})))
    A("")
    rows = []
    nobooks = []
    for s in D.eligible:
        tot = len(D.book[s]["pages"])
        have = len({n for (b, n) in carried if b == s})
        rows.append((s, "map %d" % D.idx[s] if s in D.idx else "picture", tot, have, sum(1 for r in falsas if r.startswith(s + "/") and falsas[r])))
        if have == 0:
            nobooks.append(s)
    L += md_table(["book", "kind", "pages", "pages with a candidate", "pages with at least 1 false sentence"], rows)
    A("")
    A("Books with no page that carries a candidate: %s" % (", ".join(nobooks) if nobooks else "none"))
    A("")
    A("False sentences (rule 4): pages with a candidate: %d; of those with 4 proposals: %d, with 1 to 3: %d, with none: %d." % (
        len(falsas), sum(1 for v in falsas.values() if len(v) == 4), sum(1 for v in falsas.values() if 0 < len(v) < 4), sum(1 for v in falsas.values() if not v)))
    A("")
    A("Parejas sets (rule 5): sets of 4 with four different words: %d; sets of 4 with a repeated word: %d; sets of 3: %d; map stories with no set: %s." % (
        sum(1 for v in parejas.values() for s in v if s["size"] == 4 and s["words_differ"]),
        sum(1 for v in parejas.values() for s in v if s["size"] == 4 and not s["words_differ"]),
        sum(1 for v in parejas.values() for s in v if s["size"] == 3),
        ", ".join(k for k, v in parejas.items() if not v) or "none"))
    A("")
    L += md_table(["story", "pages", "items (candidate on a page)", "pages with an item", "page pairs with a compatible pair of items", "sets", "sizes", "words differ"],
                  [(k, pstats[k]["pages"], pstats[k]["items"], pstats[k]["pages_with_items"], pstats[k]["compatible_pairs"], len(v),
                    "/".join(str(s["size"]) for s in v), "/".join("y" if s["words_differ"] else "n" for s in v)) for k, v in parejas.items()])
    A("")
    A("Proposed wrong pictures per candidate that has a page:")
    A("")
    wc = Counter(len(c["wrong_pictures"]) for c in cands if c["pagina"])
    L += md_table(["wrong pictures proposed", "0", "1", "2", "3", "4"], [["candidates"] + [wc.get(i, 0) for i in range(5)]])
    A("")
    A("Vetting sheets written: %d (a sheet with one picture only is one with no proposed wrong picture: %d). Sheets that repeat the pictures and the sentence of another sheet (the same sentence under another word): %d." % (sheets_n, wc.get(0, 0) if sheets_n else 0, dup_sheets))
    A("")

    # ---- walk
    A("## How the stories were walked")
    A("")
    A("Each story file (map stories and picture stories that have a book) was played by an interpreter that follows historia/juego.js with every answer right, every random choice taken every way, an elige taken every way (it has no wrong answer). Question and order clips were found as `historia/tools/gen_libros.py` `question_clips` finds them: the `line` of every ask, decide and elige step, `$` templates expanded over the story's own pool of values. Lines heard only after a wrong touch were found by the walk itself: a `wrong` branch, a `gratis` answer, the name of a touched thing and the Haz esto reply are never played by it; a clip that is named only there is `solo_error`.")
    A("")
    tot = Counter()
    rows = []
    for s in D.eligible:
        c = classes[s]["counts"]
        tot.update(c)
        rows.append((s, walks[s]["states"], c.get("alcanzada", 0), c.get("pregunta", 0), c.get("generica", 0), c.get("solo_error", 0),
                     c.get("rama_no_tomada", 0), c.get("nombre_de_toque", 0), c.get("sin_lugar", 0), c.get("sin_audio", 0),
                     sum(walks[s]["unres"].values())))
    rows.append(("total (most states: the largest)", max(walks[s]["states"] for s in D.eligible), tot["alcanzada"], tot["pregunta"], tot["generica"], tot["solo_error"],
                 tot["rama_no_tomada"], tot["nombre_de_toque"], tot["sin_lugar"], tot["sin_audio"], sum(sum(walks[s]["unres"].values()) for s in D.eligible)))
    L += md_table(["story", "most states at once", "reached", "question/order", "generic", "only after wrong/gratis", "branch not taken", "touch name", "not placed", "no audio", "conditions not evaluated"], rows)
    A("")
    A("Clips that could not be placed (named by no step, not a touch name): %d. They are treated as not reached." % tot["sin_lugar"])
    A("")
    unp = [(s, c) for s in D.eligible for c, w in classes[s]["which"].items() if w == "sin_lugar"]
    if unp:
        A("Not placed: " + ", ".join("%s/%s" % x for x in unp))
        A("")
    unres = [(s, k, v) for s in D.eligible for k, v in walks[s]["unres"].items()]
    A("Conditions the walk could not evaluate (both branches were taken; a clip reached only that way has `ruta_cierta` false): %d kinds." % len(unres))
    A("")
    if unres:
        L += md_table(["story", "condition", "times met"], unres)
        A("")
    bn = [(s, n, c, w) for s in D.eligible for (n, c, w) in classes[s]["book_not_walked"]]
    A("Clips on a book page that the walk did not reach (the book was made by playing the story all right in the real engine; each of these is a place where the two readings differ): %d." % len(bn))
    A("")
    if bn:
        L += md_table(["book", "page", "clip", "class"], bn)
        A("")

    # ---- stops
    A("## STOPs and places the data did not fit a rule")
    A("")
    A("STOP (a rule that the data made impossible, left out, the rest applied): %s" % ("; ".join("%s (%s): %s" % x for x in stops) if stops else "none."))
    A("")
    A("Places the data did not fit a rule as written, or where the rule left room and a reading was made:")
    A("")
    for rule, where, why in fits:
        A("- **%s** (%s): %s" % (rule, where, why))
    A("")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L))


# ---------------------------------------------------------------------------------------------------------------- 7. vetting sheets

def load_font(size):
    from PIL import ImageFont
    for p in FONT_CANDIDATES:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default(size)


def write_sheets(D, cands, out_dir, stops):
    from PIL import Image, ImageDraw
    hojas = Path(out_dir) / "hojas"
    hojas.mkdir(parents=True, exist_ok=True)
    font = load_font(30)
    claves = OrderedDict()
    lines = defaultdict(list)
    n = 0
    scale, gap, top, margin = 2, 16, 44, 12
    BG, INK = (240, 240, 240), (20, 20, 20)
    for c in cands:
        pg = c["pagina"]
        if not pg:
            continue
        n += 1
        num = "%04d" % n
        pages = [pg["page"]] + [w["page"] for w in c["wrong_pictures"]]
        order = list(pages)
        random.Random("%d-%d" % (SHEET_SEED, n)).shuffle(order)
        imgs = []
        for m in order:
            p = D.book[pg["book"]]["pages"][m - 1]["img"]
            im = Image.open(D.H / "libros" / p)
            if im.mode in ("RGBA", "LA", "P"):
                im = im.convert("RGBA")
                bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
                bg.alpha_composite(im)
                im = bg
            im = im.convert("RGB").resize((im.width * scale, im.height * scale), Image.NEAREST)
            imgs.append(im)
        W = margin * 2 + sum(i.width for i in imgs) + gap * (len(imgs) - 1)
        H = top + max(i.height for i in imgs) + margin
        sheet = Image.new("RGB", (W, H), BG)
        d = ImageDraw.Draw(sheet)
        x = margin
        letters = {}
        for k, (m, im) in enumerate(zip(order, imgs)):
            L = chr(ord("A") + k)
            letters[L] = {"page": m, "img": "historia/libros/" + D.book[pg["book"]]["pages"][m - 1]["img"]}
            sheet.paste(im, (x, top))
            d.text((x + im.width // 2, top // 2), L, fill=INK, font=font, anchor="mm")
            x += im.width + gap
        bdir = hojas / pg["book"]
        bdir.mkdir(parents=True, exist_ok=True)
        sheet.save(bdir / (num + ".png"), compress_level=6)
        right = next(L for L, v in letters.items() if v["page"] == pg["page"])
        claves[num] = {"candidate": c["id"], "book": pg["book"], "right": right, "letters": letters}
        lines[pg["book"]].append(json.dumps({"n": num, "text": c["text"], "word": c["word"]}, ensure_ascii=False))
    for b, ls in lines.items():
        with open(hojas / b / "hojas.jsonl", "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(ls) + "\n")
    jdump(claves, hojas / "claves.json")
    return n


# ---------------------------------------------------------------------------------------------------------------- main

def build(root):
    """Everything but the files. Returns a dict with the pieces."""
    D = load(root)
    stops, fits = [], []
    words = build_words(D, stops)
    if len(words) != EXPECTED_WORDS:
        fits.append(("1 words", "curso.json map stories", "the tracked words are %d, not the %d that were expected" % (len(words), EXPECTED_WORDS)))
    odd = sorted(set(D.pairs) - {w["word"] for w in words})
    if odd:
        fits.append(("1 words", "picture pairs", "pair words that are not tracked words: %s" % ", ".join(odd)))
    diff = [(w["word"], w["place"], w["first_place"]) for w in words if w["place"] != w["first_place"]]
    if diff:
        fits.append(("1 words", "place", "the place by the app's rule (first story with the word in focus_words, else back_again) differs from the place of the first story that has it: " +
                     "; ".join("%s: %s / %s" % d for d in diff) + ". Both are in the data (`place`, `first_place`)."))
    walks, classes = walk_all(D, fits)
    for s in D.eligible:
        if walks[s]["dangling"]:
            fits.append(("2d walk", s, "steps name clips the story does not have: " + ", ".join(walks[s]["dangling"])))
        if walks[s]["unres_clips"]:
            fits.append(("2d walk", s, "a $ in a clip id could not be filled: " + ", ".join(walks[s]["unres_clips"])))
    cands, M = build_candidates(D, words, walks, stops, fits)
    # marks that are not on a candidate: say why
    fair = Fair(D, M)
    propose_wrong(D, fair, cands)
    pls = placements(cands)
    wordidx = {w["word"]: i for i, w in enumerate(words)}
    falsas = false_sentences(D, fair, pls)
    parejas, pstats = build_parejas(D, fair, pls, wordidx)
    # the decided speech marks: which stand on a candidate line, and for the others the first rule they fail
    mk_total, mk_cand, mk_why = 0, 0, Counter()
    for sid in sorted(D.marcas, key=lambda x: story_rank(D, x)):
        for clip in D.marcas[sid]:
            mk_total += 1
            r = why_not(D, walks, classes, M, sid, clip)
            if r is None:
                mk_cand += 1
            else:
                mk_why[r] += 1
    fits.append(("Dilo", "docs/hablar/02-marcas.json", "decided marks: %d; on a line that is a candidate for some tracked word: %d; the others, by the first rule they fail: %s" % (
        mk_total, mk_cand, "; ".join("%s: %d" % kv for kv in sorted(mk_why.items())) or "none")))
    nodef = sum(1 for c in cands if c["marca_habla"] and not c["marca_habla"]["antes"])
    if nodef:
        fits.append(("Dilo", "line before", "%d candidates have a mark but nothing comes before the line on the all-right path" % nodef))
    nplace = sum(len([1 for w in classes[x]["which"].values() if w == "sin_lugar"]) for x in D.eligible)
    fits.append(("2d walk", "clips not placed", "%d clips with audio are named by no step of their story and are not the name of a thing touched; treated as not reached (listed in resumen.md)" % nplace))
    sets4 = sum(1 for v in parejas.values() for t in v if t["size"] == 4)
    sets3 = sum(1 for v in parejas.values() for t in v if t["size"] == 3)
    fits.append(("5 Parejas", "map stories", "sets of 4: %d; sets of 3: %d; map stories with no set at all: %d of %d (the tracked words of a sentence, abuela, mira, está and the like, stand on most pages of a book)" % (
        sets4, sets3, sum(1 for v in parejas.values() if not v), len(parejas))))
    fits += [
        ("reading 2d", "all-right play", "a line is reached when at least one all-right play says it, over every draw, deal and decision; an elige has no wrong answer, so every option of it counts as right; the optional (gratis) answers are not played"),
        ("reading 2d", "conditions", "lost and wet are 0 on an all-right play and V.ok is 1 after a decide; a condition on scene state (win, rain, fa, pir, rana) or on a memory (mem_*) takes both branches; a candidate reached only that way has ruta_cierta false"),
        ("reading 2c", "templates", "a $ variable that no beats step assigns (a scene act sets it) stands for the story's pool of values or any run of a-z0-9, where gen_libros.py question_clips reads the pool only (it misses c13_*_3 in donde-esta-el-gato)"),
        ("reading 2", "same sentence twice", "the same text under several clips or stories is one candidate per word; its representative is the occurrence that has a book page, else the earliest in course order; every occurrence is listed in `apariciones`; rule 4 and rule 5 use every occurrence that has a page; the page of a candidate is looked up in the book of its own story only"),
        ("reading 2e", "correction", "No. or No, at the very start of the text, then Coquí, Luis, Carmen, Canelo or Mira (a name is one of those four; abuela, abuelo, mamá, papá are words of the course)"),
        ("reading 2", "token_no_enseñado", "known tokens, accents kept: every token of every tracked word or phrase, every token of every `also_heard` entry of every story file, the four names, and the fixed function words"),
        ("reading 3/4/5", "tracked words of a sentence", "the tracked words found in the whole recorded text (speaker tag included) by the same matching as rule 2a, where a word inside a longer tracked phrase of that sentence does not count; compared with accents folded, a plural or a word that begins with the other counting as the same word, on every clip text of the page"),
        ("reading 6", "learner who finished stories 1..k", "words counted are those first met in a map story 1..k; a candidate counts when one of its occurrences is in a map story 1..k (second table: or in a picture story of a place whose map stories are all in 1..k); it has a page when such an occurrence has one"),
        ("reading 2 dilo", "line before", "the line before is the clip before it in the all-right play that takes the first option of every choice (tipo says what kind it was); the clips that can come before it on other plays are in otros_antes"),
    ]
    return {"D": D, "words": words, "cands": cands, "falsas": falsas, "parejas": parejas, "pstats": pstats, "walks": walks, "classes": classes, "stops": stops,
            "fits": fits, "M": M}


def candidatos_json(R):
    D = R["D"]
    words = []
    for w in R["words"]:
        words.append(OrderedDict([("word", w["word"]), ("place", w["place"]), ("first_story", w["first_story"]), ("first_index", w["first_index"]),
                                  ("first_place", w["first_place"]), ("has_pair", w["pair"] is not None), ("pair", w["pair"])]))
    rec = OrderedDict()
    rec["words"] = words
    rec["candidates"] = R["cands"]
    rec["false_sentences_by_page"] = R["falsas"]
    rec["parejas"] = R["parejas"]
    rec["parejas_stats"] = R["pstats"]
    rec["walk"] = OrderedDict((s, OrderedDict([("states", R["walks"][s]["states"]), ("classes", R["classes"][s]["counts"]),
                                               ("clip_class", R["classes"][s]["which"]), ("conditions_not_evaluated", R["walks"][s]["unres"]),
                                               ("book_clips_not_walked", [list(x) for x in R["classes"][s]["book_not_walked"]])]))
                              for s in D.eligible)
    rec["stops"] = [list(x) for x in R["stops"]]
    rec["did_not_fit"] = [list(x) for x in R["fits"]]
    return rec


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", required=True, help="directory to write into")
    ap.add_argument("--repo", default=None, help="repo root (default: the repo this file sits in)")
    ap.add_argument("--no-sheets", action="store_true", help="do not write the vetting sheets")
    a = ap.parse_args(argv)
    root = a.repo or Path(__file__).resolve().parents[2]
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    R = build(root)
    sheets_n = dup = 0
    if not a.no_sheets:
        sheets_n = write_sheets(R["D"], R["cands"], out, R["stops"])
        seen = Counter((c["pagina"]["book"], c["pagina"]["page"], c["text"]) for c in R["cands"] if c["pagina"])
        dup = sum(v - 1 for v in seen.values() if v > 1)
    jdump(candidatos_json(R), out / "candidatos.json")
    write_resumen(R["D"], R["words"], R["cands"], R["parejas"], R["pstats"], R["falsas"], R["walks"], R["classes"], R["stops"], R["fits"], out / "resumen.md", sheets_n, dup)
    print("words %d, candidates %d (with a page %d), sheets %d" % (len(R["words"]), len(R["cands"]), sum(1 for c in R["cands"] if c["pagina"]), sheets_n))


if __name__ == "__main__":
    main()
