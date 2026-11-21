#!/usr/bin/env python3
"""Makes the candidate data for Repaso as games (docs/proyecto/15-repaso-juegos.md, "The games" and "The data").

    python3 coqui/tool/make_repaso.py --out <dir> [--repo <root>] [--no-sheets]
    python3 coqui/tool/make_repaso.py --out <dir> --hojas-libro
    python3 coqui/tool/make_repaso.py --out <dir> --valida-veredictos <veredictos>
    python3 coqui/tool/make_repaso.py --out <dir> --veredictos <veredictos> --hojas-par
    python3 coqui/tool/make_repaso.py --out <dir> --valida-veredictos-par <veredictos-par>
    python3 coqui/tool/make_repaso.py --out <dir> --veredictos <veredictos> [--veredictos-par <veredictos-par>] --final <file>

Reads the repo it sits in (or --repo): historia/datos/curso.json, historia/cuentos/*.json, historia/audio/ready.json,
historia/libros/*.json and libros/img/, docs/hablar/02-marcas.json. A file of historia/cuentos/ is one of three kinds:
  - named by the course (curso.json: a story, picture story or routine of a place, or a review set of `cual`): read as a story;
  - the word list, palabras-solas.json (`tipo` "palabras": each tracked word said alone, made by make_palabras_solas.py): not a story, it makes
    no candidate sentence and no page, and is read only for the clips of the words alone (solo_clips);
  - STAGED: any other file (a story another session has pushed before the course lists it). It is ignored entirely: never read, so it is not a
    story, makes no candidate, gives no word alone, and its words are not "known". The output is the same, byte for byte, with or without it.
A book, historia/libros/<id>.json, is the book of the story <id>: it is read only when the course names that story. The book of a staged story
(and its pictures in libros/img/) may be there before the course names the story; the tool ignores it the same way.
Writes into <dir>:

    candidatos.json     the 156 words, every candidate sentence, the proposed wrong pictures, the false sentences for a
                        picture, the Parejas sets, and how each story was walked
    resumen.md          counts and tables, and every STOP and every place the data did not fit a rule
    hojas/              one vetting sheet per candidate that has a book page (hojas/<book>/NNNN.png), the sheets' list
                        (hojas/<book>/hojas.jsonl) and the key (hojas/claves.json). Not written with --no-sheets.

Deterministic (two runs give the same bytes: nothing reads the clock, a random seed is fixed, nothing iterates a set into
an output), and offline. Nothing under historia/ is written.

THE READERS' STEP (the old rules 3 to 5 above judged a sentence against a picture from page texts only, which was too weak;
readers now look at the pictures).
  --hojas-libro             writes only <dir>/libro/: for each of the books (course order) <book>/paginas.png (every page picture,
                            2x nearest neighbour, three per row, the page number in digits above each; paginas-1.png, paginas-2.png
                            ... of at most 9 pages when a book has more), <book>/frases.json (the page numbers and every distinct
                            candidate sentence that stands on a page of that book, in story order, ids "<book>:<k>", k from 1; nothing
                            says which page a sentence is on) and libro/indice.json.
  verdict file              <veredictos>/<book>.json: {"libro", "frases": {"<book>:<k>": {"si": [..], "no": [..], "duda": [..]}},
                            "parecidas": [[p, q], ..]}. Every sentence id of frases.json is there; every page of the book is in exactly
                            one of si / no / duda for each sentence.
  --valida-veredictos DIR   checks every file of DIR against its frases.json (needs the same --out) and prints each fault: missing
                            sentence, unknown id, missing page, unknown page, page in two lists, and a file or list that is malformed.
                            Exit 1 if any. Books that have no file yet are only noted.
  --veredictos DIR --final FILE
                            with a valid verdict file for every book (the same check, and a missing file is a fault): writes the final
                            data FILE and resumen-final.md beside it. Per word: its sentences (`frases`) in a fixed mixed order (a
                            Fisher-Yates shuffle seeded by the word's text: SHA-256 of "<word>|<i>", see mix()), `par`, `par_frases`,
                            `no_juntas`, `dilo`, `puntua`; per item `par` and `tokens_extra_prohibidos`; per book page: `falsas` and
                            `ciertas`. (The book-page Parejas sets are no longer made: none exist.)
  A sentence's "own page" is the page of its first clip in the story. A sentence that is a candidate in two stories is judged in both
  books; its item takes the picture of the earlier story (the same page as in candidatos.json). A sentence of the story that stands on no
  page of the book is not judged (nothing uses it: every use of a verdict needs the sentence's own page).

THE PAIR STEP (the scored game uses each word's own designed picture pair, the course's review pair: a `si` picture and a `no` picture
drawn for one sentence, with a DIFFERENT sentence each time, but only a sentence a reader has judged to fit the `si` picture and not the
`no` picture).
  --hojas-par (with --veredictos DIR, the book verdicts: the sentences of the word are those of its items in the final data they make)
                            writes <dir>/par/: for each word that has a picture pair, in course order, <slug>/par.png (the pair's two
                            pictures side by side at 4x nearest neighbour, labelled only A and B above them; the order is fixed by the
                            word, SHA-256 of "par|<word>", so `si` is not always A) and <slug>/frases.json ({"palabra", "frases": [{"id":
                            "<slug>:<k>", "text"}]}: the pair's own sentence first, then every distinct sentence text of the word's items;
                            nothing says which letter is which); <dir>/par/claves.json (slug -> the letter that is `si`);
                            <dir>/par/indice.json (slug -> word, course order); <dir>/par/grupos.json (the words in course order cut into
                            5 runs of about equal numbers of sentences). A pair's files: `coqui/ref/escenas/<scene>/pairs.json` has an entry
                            {file, w, say, sayText, si: {png}, no: {png}} for the story file (`cual-<scene>`, the `scene` of the story
                            file) and the word; the pictures are `coqui/ref/escenas/<scene>/pairs/<png>`. A pair whose entry or files cannot
                            be found (or whose entry says another clip than the story) gets no sheet and is listed as a STOP.
  verdict file              <veredictos-par>/<slug>.json: {"palabra", "frases": {"<slug>:<k>": "A" | "B" | "ambas" | "ninguna" | "duda"}}.
  --valida-veredictos-par DIR
                            checks every file of DIR against <dir>/par/<slug>/frases.json: right `palabra`, every id present, no unknown id,
                            only the five values. Prints each fault; exit 1 if any. Words with no file yet are only noted.
  --veredictos DIR --veredictos-par DIR --final FILE
                            the merge above, plus: an item is `par` when its word has a pair and the verdict for its sentence is the pair's
                            `si` letter; `par_frases` of a word = its pair's own sentence, then its `par` items (no text twice). Without
                            --veredictos-par no item is `par` and `par_frases` is the own sentence only (the tool says so).
  `no_juntas` of a word: the other tracked words that must never be a wrong written tile beside a sentence with that word, nor in a matching
  round with it: (a) accent twins, (b) one a whole-word part of the other (accents folded), (c) the same first NO_JUNTAS_PREFIX (3) letters
  when both are single words, NO_JUNTAS_PREFIX_PHRASE (4) when one is a phrase (both of at least that many), (d) equal length and one letter apart, (e) one is the other plus a final s or es. Letters are those of the
  words with accents folded and spaces and signs taken out. `tokens_extra_prohibidos` of an item: the tracked words in its sentence (accents
  folded, a final s or es allowed), which can never be a wrong tile for it.

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
PAR_VALUES = ("A", "B", "ambas", "ninguna", "duda")    # what a reader may say about a sentence and a picture pair
PAR_SCALE = 4                                          # the pair's pictures on par.png: 4x nearest neighbour
PAR_GROUPS = 5                                         # grupos.json
NO_JUNTAS_PREFIX = 3                                   # rule (c) of no_juntas: the same first three letters for two single words
NO_JUNTAS_PREFIX_PHRASE = 4                            # ... and four when one of the two is a phrase (has a space)
PAR_BUCKETS = ["1", "2", "3-4", "5-9", "10+"]
EXPECTED_WORDS = 156
PALABRAS_FILE = "palabras-solas"             # the one file of historia/cuentos/ that is a word list, not a story, and that the course does not name
PALABRAS_TIPO = "palabras"                   # its `tipo`: a file of single words, not a story
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


def ftoks(s):
    """The tokens of s, accents folded, as a tuple."""
    return tuple(fold(t) for t in toks(s))


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


def course_files(curso):
    """{name} of the files of historia/cuentos/ the course names (curso.json): the stories, picture stories (`dibujos`) and routines (`haz`)
    of its places, the ids of its `cuentos`, and its review sets (`cual`). A file of that folder that is neither one of these nor the word
    list palabras-solas.json is STAGED: the tool does not read it. The same names tell the books: historia/libros/<id>.json is the book of the
    story <id>, and the tool reads it only when the course names <id>."""
    names = set(curso.get("cuentos", {})) | set(curso.get("cual", []))
    for l in curso["lugares"]:
        for key in ("cuentos", "dibujos", "haz"):
            names.update(l.get(key, []))
    return names


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
    D.palabras = OrderedDict()      # clip id -> clip of palabras-solas.json (each tracked word alone): not stories
    named = course_files(D.curso)
    for p in sorted((H / "cuentos").glob("*.json")):
        if p.stem == PALABRAS_FILE:
            d = read_json(p)
            if d.get("tipo") != PALABRAS_TIPO:
                raise SystemExit("STOP: %s is the word list, so its `tipo` must be %r, not %r" % (p.name, PALABRAS_TIPO, d.get("tipo")))
            D.palabras.update(d.get("clips", {}))
        elif p.stem in named:
            d = read_json(p)
            D.story[d["id"]] = d
        # any other file is STAGED (another session pushed it before the course lists it): not read, not a story, nothing of it is used
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
        if p.stem not in named:
            continue    # a STAGED book (libros/<id>.json of a story the course does not name yet): not read, nothing of it is used
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
    posmap = {}                # (story, clip) -> place of the clip in its story's all-right play (story order)
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
            posmap[(sid, clip)] = pos
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
    return out, M, posmap


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


# ---------------------------------------------------------------------------------------------------------------- 8. sheets for the readers
# Readers LOOK at each book's pictures and say which sentences fit which page (the verdict files, 9). Nothing here says which page a
# sentence belongs to.

COLS = 3                 # pictures per row on a sheet
PAGES_PER_SHEET = 9      # pages on one sheet
MAX_CUAL = 3             # fair wrong pictures per sentence
MAX_FALSAS = 6           # false sentences kept for a page
LISTS = ("si", "no", "duda")


def sentences_by_book(R):
    """The sentences the readers judge: for each book (course order), every DISTINCT candidate sentence (distinct by text; the same
    sentence under several words is one) that is recorded in that book's story and stands on a page of that book, in story order
    (the place of its first such clip in the all-right play). A sentence that is a candidate in two stories is judged in each book.
    Rows: k (1 up, in story order), id "<book>:<k>", text, clip (its first clip in the story), own (the page of that clip), pages
    (every page the sentence stands on in this book, own first in the sort), words (the tracked words it is a candidate for, course
    order), pos."""
    D, pos = R["D"], R["pos"]
    wordidx = {w["word"]: i for i, w in enumerate(R["words"])}
    words_of = defaultdict(set)
    occ = defaultdict(lambda: defaultdict(set))       # story -> text -> {(pos, clip, page)}
    for c in R["cands"]:
        words_of[c["text"]].add(c["word"])
        for o in c["apariciones"]:
            if o["page"] is not None:
                occ[o["story"]][c["text"]].add((pos[(o["story"], o["clip"])], o["clip"], o["page"]))
    out = OrderedDict()
    for sid in D.eligible:
        rows = []
        for text, os_ in occ[sid].items():
            os_ = sorted(os_)
            rows.append({"text": text, "clip": os_[0][1], "own": os_[0][2], "pages": sorted({p for _, _, p in os_}),
                         "pos": os_[0][:2], "words": sorted(words_of[text], key=wordidx.get)})
        rows.sort(key=lambda r: r["pos"])
        for k, r in enumerate(rows, 1):
            r["k"] = k
            r["id"] = "%s:%d" % (sid, k)
        out[sid] = rows
    return out


def frases_doc(D, sid, rows):
    """frases.json of a book: the page numbers and the sentences (id, text). Nothing about which page a sentence belongs to."""
    return OrderedDict([("libro", sid), ("paginas", list(range(1, len(D.book[sid]["pages"]) + 1))),
                        ("frases", [OrderedDict([("id", r["id"]), ("text", r["text"])]) for r in rows])])


def book_sheet(D, sid, pages, font):
    """One sheet: the pictures of `pages` (numbers), 2x nearest neighbour, COLS per row, the page number in digits above each."""
    from PIL import Image, ImageDraw
    scale, gap, top, margin = 2, 16, 44, 12
    BG, INK = (240, 240, 240), (20, 20, 20)
    imgs = []
    for n in pages:
        with Image.open(D.H / "libros" / D.book[sid]["pages"][n - 1]["img"]) as im:
            im = im.convert("RGBA")
            bg = Image.new("RGBA", im.size, (255, 255, 255, 255))     # a transparent pixel is drawn on white
            bg.alpha_composite(im)
            im = bg.convert("RGB")
        imgs.append(im.resize((im.width * scale, im.height * scale), Image.NEAREST))
    cw, ch = max(i.width for i in imgs), max(i.height for i in imgs)
    cols = min(COLS, len(imgs))
    rows = (len(imgs) + COLS - 1) // COLS
    W = margin * 2 + cols * cw + (cols - 1) * gap
    H = margin * 2 + rows * (top + ch) + (rows - 1) * gap
    sheet = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(sheet)
    for i, (n, im) in enumerate(zip(pages, imgs)):
        x = margin + (i % COLS) * (cw + gap)
        y = margin + (i // COLS) * (top + ch + gap)
        d.text((x + cw // 2, y + top // 2), str(n), fill=INK, font=font, anchor="mm")
        sheet.paste(im, (x + (cw - im.width) // 2, y + top))
    return sheet


def sheet_chunks(n):
    """[(file name, page numbers)] of a book of n pages: paginas.png, or paginas-1.png, paginas-2.png ... of at most 9 pages each."""
    chunks = [list(range(a, min(a + PAGES_PER_SHEET, n + 1))) for a in range(1, n + 1, PAGES_PER_SHEET)]
    return [("paginas.png" if len(chunks) == 1 else "paginas-%d.png" % (i + 1), c) for i, c in enumerate(chunks)]


def write_hojas_libro(R, out_dir):
    """<out>/libro/<book>/paginas.png (paginas-1.png, ... when a book has more than 9 pages), frases.json, and <out>/libro/indice.json."""
    D = R["D"]
    S = sentences_by_book(R)
    base = Path(out_dir) / "libro"
    base.mkdir(parents=True, exist_ok=True)
    font = load_font(36)
    index = []
    for sid in D.eligible:
        folder = base / sid
        folder.mkdir(exist_ok=True)
        for old in sorted(folder.glob("paginas*.png")):
            old.unlink()
        n = len(D.book[sid]["pages"])
        sheets = sheet_chunks(n)
        for name, chunk in sheets:
            book_sheet(D, sid, chunk, font).save(folder / name, compress_level=6)
        jdump(frases_doc(D, sid, S[sid]), folder / "frases.json")
        index.append(OrderedDict([("libro", sid), ("paginas", n), ("frases", len(S[sid])), ("hojas", [name for name, _ in sheets])]))
    jdump(OrderedDict([("libros", index), ("totales", OrderedDict([("libros", len(index)), ("paginas", sum(i["paginas"] for i in index)),
                                                                   ("frases", sum(i["frases"] for i in index))]))]), base / "indice.json")
    return index


# ---------------------------------------------------------------------------------------------------------------- 9. the verdict files

def is_page(x):
    return isinstance(x, int) and not isinstance(x, bool)


def check_verdict(book, fr, v):
    """Every fault of one verdict file against its frases.json (fr), as a list of lines. Kinds: not an object, wrong `libro`, missing
    or malformed `frases` / lists / `parecidas`, unknown id, missing sentence, unknown page, missing page, page in two lists (or twice in one)."""
    f = []
    if not isinstance(v, dict):
        return ["not a JSON object"]
    if v.get("libro") != book:
        f.append("`libro` is %s, not %s" % (json.dumps(v.get("libro"), ensure_ascii=False), json.dumps(book)))
    pages = set(fr["paginas"])
    ids = [x["id"] for x in fr["frases"]]
    got = v.get("frases")
    if not isinstance(got, dict):
        f.append("`frases` is missing or is not an object")
        got = {}
    for sid in got:
        if sid not in ids:
            f.append("unknown sentence id %s" % sid)
    for sid in ids:
        if sid not in got:
            f.append("missing sentence %s" % sid)
            continue
        e = got[sid]
        if not isinstance(e, dict):
            f.append("%s: not an object" % sid)
            continue
        seen = defaultdict(list)       # page -> the lists that hold it (once each time it is written)
        for name in LISTS:
            lst = e.get(name)
            if not isinstance(lst, list):
                f.append("%s: list `%s` is missing or is not a list" % (sid, name))
                continue
            for p in lst:
                if not is_page(p):
                    f.append("%s: `%s` holds %s, which is not a page number" % (sid, name, json.dumps(p, ensure_ascii=False)))
                elif p not in pages:
                    f.append("%s: unknown page %d in `%s`" % (sid, p, name))
                else:
                    seen[p].append(name)
        if all(isinstance(e.get(n), list) for n in LISTS):
            for p in sorted(pages):
                if p not in seen:
                    f.append("%s: missing page %d (in none of si, no, duda)" % (sid, p))
                else:
                    names = list(dict.fromkeys(seen[p]))
                    if len(names) > 1:
                        f.append("%s: page %d is in two lists (%s)" % (sid, p, ", ".join(names)))
                    for nm in names:
                        if seen[p].count(nm) > 1:
                            f.append("%s: page %d is written twice in `%s`" % (sid, p, nm))
    par = v.get("parecidas")
    if not isinstance(par, list):
        f.append("`parecidas` is missing or is not a list (write [] when there is none)")
        par = []
    for i, pr in enumerate(par):
        if not (isinstance(pr, list) and len(pr) == 2 and all(is_page(x) for x in pr) and pr[0] != pr[1]):
            f.append("parecidas[%d] is %s, not two different page numbers" % (i, json.dumps(pr, ensure_ascii=False)))
        else:
            for x in pr:
                if x not in pages:
                    f.append("parecidas[%d]: unknown page %d" % (i, x))
    return f


def libro_frases(out_dir):
    """(books in course order, {book: frases.json}) from <out>/libro/. Raises when the sheets were not written."""
    base = Path(out_dir) / "libro"
    if not (base / "indice.json").exists():
        raise SystemExit("no %s: write the sheets first (--hojas-libro)" % (base / "indice.json"))
    books = [b["libro"] for b in read_json(base / "indice.json")["libros"]]
    return books, {b: read_json(base / b / "frases.json") for b in books}


def valida_veredictos(vdir, out_dir, require_all=False):
    """-> (faults, notes). faults: lines "<file>: <fault>" for every file of vdir (a file that is not <book>.json of a book is a fault
    too). notes: the books that have no file yet (a fault only with require_all)."""
    books, frs = libro_frases(out_dir)
    vdir = Path(vdir)
    faults, have = [], set()
    for p in sorted(vdir.glob("*.json")):
        b = p.stem
        if b not in frs:
            faults.append("%s: not the file of a book (%s.json for a book of the course)" % (p.name, "<book>"))
            continue
        have.add(b)
        try:
            v = read_json(p)
        except (ValueError, OSError) as e:
            faults.append("%s: cannot be read as JSON (%s)" % (p.name, e))
            continue
        faults += ["%s: %s" % (p.name, x) for x in check_verdict(b, frs[b], v)]
    missing = [b for b in books if b not in have]
    notes = []
    if missing:
        if require_all:
            faults += ["%s.json: no verdict file for this book" % b for b in missing]
        else:
            notes.append("books with no verdict file yet: %d of %d (%s)" % (len(missing), len(books), ", ".join(missing)))
    return faults, notes


def load_veredictos(vdir, books):
    """{book: {"frases": {id: {"si","no","duda": set}}, "parecidas": {frozenset({p, q})}}} from files that passed the check."""
    out = {}
    for b in books:
        v = read_json(Path(vdir) / (b + ".json"))
        out[b] = {"frases": {i: {n: set(e[n]) for n in LISTS} for i, e in v["frases"].items()},
                  "parecidas": {frozenset(pr) for pr in v["parecidas"]}}
    return out


# ---------------------------------------------------------------------------------------------------------------- 9b. the pair sheets and their verdicts
# The scored game shows a word's own picture pair (a `si` and a `no` picture drawn for one sentence) with a different sentence each
# time. Readers LOOK at the two pictures (A and B, in a fixed order that hides which is `si`) and say, for each sentence, which one fits.

def slugify(word):
    """The word made file-safe: accents folded, every run of anything but a-z and 0-9 one '-', no '-' at the ends."""
    return re.sub(r"[^a-z0-9]+", "-", fold(nfc(word))).strip("-") or "palabra"


def pair_slugs(words):
    """{word: slug}, unique and the same every time: the slug of the word, and `-2`, `-3` ... for each later word (course order, the
    order of `words`) that makes the same slug (esta / está: the first of them in the course has the plain slug)."""
    out, used = OrderedDict(), set()
    for w in words:
        base = slugify(w)
        slug, n = base, 1
        while slug in used:
            n += 1
            slug = "%s-%d" % (base, n)
        used.add(slug)
        out[w] = slug
    return out


def pair_si_letter(word):
    """The letter (A or B) that the `si` picture of the word's pair has on par.png: fixed by the word (the parity of the first byte of the
    SHA-256 of "par|<word>" in UTF-8 and NFC), so it is the same on every machine and `si` is not always A."""
    return "A" if hashlib.sha256(("par|%s" % nfc(word)).encode("utf-8")).digest()[0] % 2 == 0 else "B"


def escenas_pairs(root):
    """{scene: [pair entries of coqui/ref/escenas/<scene>/pairs.json]} for every scene folder that has the file, scene names sorted."""
    base = Path(root) / "coqui" / "ref" / "escenas"
    out = OrderedDict()
    if base.is_dir():
        for d in sorted(p for p in base.iterdir() if p.is_dir()):
            if (d / "pairs.json").exists():
                out[d.name] = read_json(d / "pairs.json").get("pairs", [])
    return out


def find_pair_files(root, esc, word, pair):
    """The two captured pictures of a word's pair -> (si path, no path, None), or (None, None, why not). The entry is the one of
    `<scene>/pairs.json` with `file` = the story file of the pair (cual-<scene>) and `w` = the word, looked up first in the scene folder of
    the story file and then in the others; its `si.png` and `no.png` name the files in `<scene>/pairs/`, and its `say` must be the clip the
    story gives. The first scene where the entry and both files are found is used."""
    base = Path(root) / "coqui" / "ref" / "escenas"
    order = ([pair["scene"]] if pair["scene"] in esc else []) + [s for s in esc if s != pair["scene"]]
    why = "no entry for file %s, word %s in any coqui/ref/escenas/*/pairs.json" % (pair["file"], word)
    for sc in order:
        for e in esc[sc]:
            if e.get("file") != pair["file"] or e.get("w") != word:
                continue
            if e.get("say") != pair["say"]:
                why = "coqui/ref/escenas/%s/pairs.json says the clip %s, the story file says %s" % (sc, e.get("say"), pair["say"])
                continue
            paths = [base / sc / "pairs" / (e.get(side) or {}).get("png", "") for side in ("si", "no")]
            lost = [str(p.relative_to(root)) for p in paths if not p.is_file()]
            if lost:
                why = "file not found: " + ", ".join(lost)
                continue
            return paths[0], paths[1], None
    return None, None, why


def plan_pairs(R):
    """-> (plans, stops). plans: {word: {"slug", "letter", "si", "no"}} for the words that have a pair whose pictures are found and whose
    own sentence is known, course order (the slug of every word with a pair is made first, so a pair that is missing does not move
    another word's slug); stops: lines "word: why" for the pairs that have no sheet."""
    root = R["D"].root
    esc = escenas_pairs(root)
    pw = [w for w in R["words"] if w["pair"]]
    slugs = pair_slugs([w["word"] for w in pw])
    plans, stops = OrderedDict(), []
    for w in pw:
        p = w["pair"]
        if not p["text"]:
            stops.append("%s: the clip %s of the story file %s has no text" % (w["word"], p["say"], p["file"]))
            continue
        si, no, why = find_pair_files(root, esc, w["word"], p)
        if why:
            stops.append("%s: %s" % (w["word"], why))
            continue
        plans[w["word"]] = OrderedDict([("slug", slugs[w["word"]]), ("letter", pair_si_letter(w["word"])), ("si", si), ("no", no)])
    return plans, stops


def pair_texts(own, items):
    """The distinct sentence texts to judge for a word: the pair's own sentence, then the texts of its items in their order, none twice."""
    out, seen = [own], {own}
    for i in items:
        if i["text"] not in seen:
            seen.add(i["text"])
            out.append(i["text"])
    return out


def pair_doc(slug, word, own, items):
    """frases.json of a word: nothing in it says which letter is which."""
    return OrderedDict([("palabra", word), ("frases", [OrderedDict([("id", "%s:%d" % (slug, k)), ("text", t)]) for k, t in enumerate(pair_texts(own, items), 1)])])


def pair_sheet(first, second, font):
    """par.png: the two pictures (paths) side by side at PAR_SCALE x nearest neighbour, `A` over the first and `B` over the second."""
    from PIL import Image, ImageDraw
    gap, top, margin = 16, 44, 12
    BG, INK = (240, 240, 240), (20, 20, 20)
    imgs = []
    for p in (first, second):
        with Image.open(p) as im:
            im = im.convert("RGBA")
            bg = Image.new("RGBA", im.size, (255, 255, 255, 255))     # a transparent pixel is drawn on white
            bg.alpha_composite(im)
            im = bg.convert("RGB")
        imgs.append(im.resize((im.width * PAR_SCALE, im.height * PAR_SCALE), Image.NEAREST))
    W = margin * 2 + sum(i.width for i in imgs) + gap
    H = margin * 2 + top + max(i.height for i in imgs)
    sheet = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(sheet)
    x = margin
    for letter, im in zip("AB", imgs):
        d.text((x + im.width // 2, margin + top // 2), letter, fill=INK, font=font, anchor="mm")
        sheet.paste(im, (x, margin + top))
        x += im.width + gap
    return sheet


def pair_groups(counts, n=PAR_GROUPS):
    """Cut `counts` (the number of sentences of each word, course order) into n runs of about equal sums: the cut after word i that is
    nearest to total * g / n (the earlier on a tie), for g = 1 .. n - 1, each run with at least one word (fewer than n runs when there are
    fewer than n words). -> list of lists of indexes."""
    if not counts:
        return []
    n = min(n, len(counts))
    total, cum = sum(counts), list(itertools.accumulate(counts))
    cuts, last = [], 0
    for g in range(1, n):
        lo, hi = last + 1, len(counts) - (n - g)           # the cut is after word index c - 1: c words so far
        c = min(range(lo, hi + 1), key=lambda c: (abs(cum[c - 1] * n - total * g), c))
        cuts.append(c)
        last = c
    bounds = [0] + cuts + [len(counts)]
    return [list(range(a, b)) for a, b in zip(bounds, bounds[1:])]


def write_hojas_par(R, items_of, out_dir):
    """<out>/par/<slug>/par.png and frases.json for each word with a pair (course order), claves.json, indice.json and grupos.json.
    items_of: {word: its items in the final data}. -> (index {slug: word}, docs {slug: doc}, stops)."""
    plans, stops = plan_pairs(R)
    base = Path(out_dir) / "par"
    base.mkdir(parents=True, exist_ok=True)
    font = load_font(36)
    index, docs, claves = OrderedDict(), OrderedDict(), OrderedDict()
    pairs = {w["word"]: w["pair"] for w in R["words"] if w["pair"]}
    for word, pl in plans.items():
        slug = pl["slug"]
        folder = base / slug
        folder.mkdir(exist_ok=True)
        first, second = (pl["si"], pl["no"]) if pl["letter"] == "A" else (pl["no"], pl["si"])
        pair_sheet(first, second, font).save(folder / "par.png", compress_level=6)
        docs[slug] = pair_doc(slug, word, pairs[word]["text"], items_of[word])
        jdump(docs[slug], folder / "frases.json")
        index[slug] = word
        claves[slug] = pl["letter"]
    for old in sorted(p for p in base.iterdir() if p.is_dir() and p.name not in index):       # a folder of an earlier run
        if {f.name for f in old.iterdir()} <= {"par.png", "frases.json"}:
            for f in old.iterdir():
                f.unlink()
            old.rmdir()
    jdump(claves, base / "claves.json")
    jdump(index, base / "indice.json")
    slugs = list(index)
    groups = pair_groups([len(docs[s]["frases"]) for s in slugs])
    jdump(OrderedDict((str(g + 1), [slugs[i] for i in idx]) for g, idx in enumerate(groups)), base / "grupos.json")
    return index, docs, stops


def pair_sheets_on_disk(out_dir):
    """(index {slug: word}, claves {slug: letter}, docs {slug: frases.json}) from <out>/par/. Raises when the sheets were not written."""
    base = Path(out_dir) / "par"
    if not (base / "indice.json").exists():
        raise SystemExit("no %s: write the sheets first (--hojas-par)" % (base / "indice.json"))
    index = read_json(base / "indice.json")
    return index, read_json(base / "claves.json"), {s: read_json(base / s / "frases.json") for s in index}


def check_verdict_par(word, doc, v):
    """Every fault of one pair verdict file against its frases.json (doc), as a list of lines: not an object, wrong `palabra`, missing or
    malformed `frases`, unknown id, missing sentence, a value that is none of A, B, ambas, ninguna, duda."""
    if not isinstance(v, dict):
        return ["not a JSON object"]
    f = []
    if v.get("palabra") != word:
        f.append("`palabra` is %s, not %s" % (json.dumps(v.get("palabra"), ensure_ascii=False), json.dumps(word, ensure_ascii=False)))
    got = v.get("frases")
    if not isinstance(got, dict):
        f.append("`frases` is missing or is not an object")
        got = {}
    ids = [x["id"] for x in doc["frases"]]
    for sid in got:
        if sid not in ids:
            f.append("unknown sentence id %s" % sid)
    for sid in ids:
        if sid not in got:
            f.append("missing sentence %s" % sid)
        elif not (isinstance(got[sid], str) and got[sid] in PAR_VALUES):
            f.append("%s: %s is not one of %s" % (sid, json.dumps(got[sid], ensure_ascii=False), ", ".join(PAR_VALUES)))
    return f


def valida_veredictos_par(vdir, out_dir, require_all=False):
    """-> (faults, notes), as valida_veredictos does for the books: faults are lines "<file>: <fault>" for every file of vdir; notes: the
    words that have no file yet (a fault only with require_all)."""
    index, _, docs = pair_sheets_on_disk(out_dir)
    faults, have = [], set()
    for p in sorted(Path(vdir).glob("*.json")):
        slug = p.stem
        if slug not in index:
            faults.append("%s: not the file of a word with a sheet (<slug>.json, the slugs are in par/indice.json)" % p.name)
            continue
        have.add(slug)
        try:
            v = read_json(p)
        except (ValueError, OSError) as e:
            faults.append("%s: cannot be read as JSON (%s)" % (p.name, e))
            continue
        faults += ["%s: %s" % (p.name, x) for x in check_verdict_par(index[slug], docs[slug], v)]
    missing = [s for s in index if s not in have]
    notes = []
    if missing:
        if require_all:
            faults += ["%s.json: no verdict file for this word" % s for s in missing]
        else:
            notes.append("words with no verdict file yet: %d of %d (%s)" % (len(missing), len(index), ", ".join(missing)))
    return faults, notes


def load_veredictos_par(vdir, index):
    """{slug: {id: value}} from files that passed the check."""
    return {s: read_json(Path(vdir) / (s + ".json"))["frases"] for s in index}


# ---------------------------------------------------------------------------------------------------------------- 9c. words that must not meet

NO_JUNTAS_RULES = OrderedDict([
    ("a", "accent twins (equal after folding accents)"),
    ("b", "one is a whole-word part of the other, which is a phrase (accents folded)"),
    ("c", "the same first %d letters after folding accents, both of at least %d letters (%d when one of the two is a phrase)" % (
        NO_JUNTAS_PREFIX, NO_JUNTAS_PREFIX, NO_JUNTAS_PREFIX_PHRASE)),
    ("d", "equal length, differing in exactly one letter after folding accents"),
    ("e", "one is the other plus a final s or es"),
])


def has_run(small, big):
    """small (a tuple of tokens) stands in big as a run of whole tokens."""
    n = len(small)
    return n > 0 and any(big[i:i + n] == small for i in range(len(big) - n + 1))


def no_juntas_pairs(words):
    """{rule: [(a, b), ..]}: every pair of tracked words that meets the rule, a before b in the course order of `words`. A pair is in every
    rule it meets. Letters are the folded tokens of a word joined, so a space or a sign is no letter."""
    ft = [ftoks(w) for w in words]
    ls = ["".join(t) for t in ft]
    out = OrderedDict((r, []) for r in NO_JUNTAS_RULES)
    for i, j in itertools.combinations(range(len(words)), 2):
        a, b, la, lb = ft[i], ft[j], ls[i], ls[j]
        pair = (words[i], words[j])
        if a == b:
            out["a"].append(pair)
        if a != b and (has_run(a, b) or has_run(b, a)):
            out["b"].append(pair)
        k = NO_JUNTAS_PREFIX if len(a) == 1 and len(b) == 1 else NO_JUNTAS_PREFIX_PHRASE
        if len(la) >= k and len(lb) >= k and la[:k] == lb[:k]:
            out["c"].append(pair)
        if len(la) == len(lb) and sum(1 for x, y in zip(la, lb) if x != y) == 1:
            out["d"].append(pair)
        if lb in (la + "s", la + "es") or la in (lb + "s", lb + "es"):
            out["e"].append(pair)
    return out


def no_juntas(words):
    """{word: sorted list of the other tracked words it must not be shown with}, for every word of `words`; symmetric."""
    mine = OrderedDict((w, set()) for w in words)
    for pairs_ in no_juntas_pairs(words).values():
        for a, b in pairs_:
            mine[a].add(b)
            mine[b].add(a)
    return OrderedDict((w, sorted(s)) for w, s in mine.items())


def tracked_in(text, words, fts):
    """The sorted tracked words that are in the text, accents folded; the last token of a word may carry a final s or es (a plural).
    fts: the folded tokens of each word (ftoks)."""
    st = ftoks(text)
    out = []
    for w, t in zip(words, fts):
        n = len(t)
        if n and any(st[i:i + n - 1] == t[:-1] and st[i + n - 1] in (t[-1], t[-1] + "s", t[-1] + "es") for i in range(len(st) - n + 1)):
            out.append(w)
    return sorted(out)


# ---------------------------------------------------------------------------------------------------------------- 10. the final data
# The rules take pages and verdicts as plain values so that the tests can call them with made-up ones.

def cual_pages(own, others, v, par):
    """The fair wrong pictures of a sentence: the pages the verdict puts in `no` that are not `parecidas` with the sentence's own page
    (nor with another page the same sentence stands on: `others`), at most MAX_CUAL, farthest from the own page first (then the lower
    page number). Empty when the verdict does not put the own page in `si`. v: {"si", "no", "duda"} sets; par: {frozenset({p, q})}."""
    if own not in v["si"]:
        return []
    mine = [own] + list(others)
    ok = [p for p in v["no"] if p not in mine and not any(frozenset((p, m)) in par for m in mine)]
    ok.sort(key=lambda p: (-abs(p - own), p))
    return ok[:MAX_CUAL]


def puntua(items, par):
    """How a word is scored: "cual" when the word has a picture pair; else "que_oyes" when it has an item that has que_oyes; else "nada"."""
    if par:
        return "cual"
    if any(i["que_oyes"] for i in items):
        return "que_oyes"
    return "nada"


def falsas_for_page(sents, V, par, n):
    """The sentences (clip, text) that are false for page n: the verdict puts n in `no`, n is not a page the sentence stands on, and the
    sentence's own page is not `parecidas` with n. Farthest own page first (then story order), at most MAX_FALSAS."""
    rows = []
    for s in sents:
        if n in s["pages"] or n not in V[s["id"]]["no"]:
            continue
        if any(frozenset((p, n)) in par for p in s["pages"]):
            continue
        rows.append(s)
    rows.sort(key=lambda s: (-abs(s["own"] - n), s["k"]))
    return [OrderedDict([("clip", s["clip"]), ("text", s["text"])]) for s in rows[:MAX_FALSAS]]


def mix(seq, key):
    """A fixed shuffle of seq, seeded by the text `key` (a word). Fisher-Yates from the end; the swap partner of position i is
    int(SHA-256 of "<key>|<i>" in UTF-8, first 16 hex digits) mod (i + 1). Nothing but SHA-256 is involved, so it is the same on every
    machine and every Python."""
    out = list(seq)
    key = nfc(key)
    for i in range(len(out) - 1, 0, -1):
        j = int(hashlib.sha256(("%s|%d" % (key, i)).encode("utf-8")).hexdigest()[:16], 16) % (i + 1)
        out[i], out[j] = out[j], out[i]
    return out


def pagina_ref(D, book, n):
    return OrderedDict([("book", book), ("page", n), ("img", D.book[book]["pages"][n - 1]["img"])])


def collect_items(R, V):
    """The items of every word that the book verdicts V keep, each word's in its fixed order, without the pair fields.
    -> (OrderedDict word -> list of items, the number of candidates left out)."""
    D = R["D"]
    S = sentences_by_book(R)
    by_text = {b: {s["text"]: s for s in rows} for b, rows in S.items()}
    by_word = defaultdict(list)
    for c in R["cands"]:
        by_word[c["word"]].append(c)
    out, left_out = OrderedDict(), 0
    for w in R["words"]:
        items = []
        for c in mix(by_word.get(w["word"], []), w["word"]):
            pg = c["pagina"]
            cual, dudosa, own_ok = [], False, False
            if pg:
                s = by_text[pg["book"]][c["text"]]
                assert s["own"] == pg["page"], (pg["book"], c["text"])
                v, par = V[pg["book"]]["frases"][s["id"]], V[pg["book"]]["parecidas"]
                own_ok = s["own"] in v["si"]
                dudosa = not own_ok
                cual = cual_pages(s["own"], [p for p in s["pages"] if p != s["own"]], v, par)
            arma, oyes, _ = usable_flags(c)
            if not own_ok and not (arma or oyes):
                left_out += 1
                continue
            items.append(OrderedDict([("clip", c["clip"]), ("cuento", c["story"]), ("text", c["text"]), ("tokens", c["tokens"]),
                                      ("pagina", pagina_ref(D, pg["book"], pg["page"]) if pg else None), ("cual", cual),
                                      ("propia_dudosa", dudosa), ("arma", arma), ("que_oyes", oyes)]))
        out[w["word"]] = items
    return out, left_out


def pair_stale_faults(R, V, out_dir):
    """Faults of the pair sheets in <out>/par/ against what the tool makes now from the repo and the book verdicts V: a sheet, a key or an
    index that is not the same (the readers' verdicts of that word would not match). Lines "<what>: <fault>"."""
    index, claves, docs = pair_sheets_on_disk(out_dir)
    items_of, _ = collect_items(R, V)
    plans, _ = plan_pairs(R)
    pairs = {w["word"]: w["pair"] for w in R["words"] if w["pair"]}
    want_index = OrderedDict((pl["slug"], word) for word, pl in plans.items())
    f = []
    if list(index.items()) != list(want_index.items()):
        f.append("par/indice.json: is not what the tool makes from the repo now (write the sheets again with --hojas-par)")
    for word, pl in plans.items():
        slug = pl["slug"]
        if slug not in docs:
            continue
        if json.loads(json.dumps(pair_doc(slug, word, pairs[word]["text"], items_of[word]))) != docs[slug]:
            f.append("par/%s/frases.json: is not what the tool makes from the repo and the book verdicts now (write the sheets again; the readers' verdicts of this word no longer match)" % slug)
        if claves.get(slug) != pl["letter"]:
            f.append("par/claves.json: the letter of %s is not what the tool makes (write the sheets again)" % slug)
    return f


def build_final(R, V, PV=None):
    """The final data from the build (R), the book verdicts (V, from load_veredictos) and the pair verdicts (PV, {slug: {id: value}} from
    load_veredictos_par, or None when there are none: then no item is `par` and `par_frases` is the own sentence only). -> dict."""
    D = R["D"]
    S = sentences_by_book(R)
    by_word = defaultdict(list)
    for c in R["cands"]:
        by_word[c["word"]].append(c)
    items_of, left_out = collect_items(R, V)
    plans, stops = plan_pairs(R)
    names = [w["word"] for w in R["words"]]
    fts = [ftoks(w) for w in names]
    juntas = no_juntas(names)
    palabras = []
    for w in R["words"]:
        word = w["word"]
        items = items_of[word]
        pl = plans.get(word)
        verdict = PV[pl["slug"]] if (pl and PV is not None) else None
        k_of = {t: k for k, t in enumerate(pair_texts(w["pair"]["text"], items), 1)} if pl else {}
        for it in items:
            it["par"] = bool(verdict is not None and verdict.get("%s:%d" % (pl["slug"], k_of[it["text"]])) == pl["letter"])
            it["tokens_extra_prohibidos"] = tracked_in(it["text"], names, fts)
        par_w, par_frases = None, []
        if w["pair"]:
            p = w["pair"]
            par_w = OrderedDict([("clip", p["say"]), ("text", p["text"]), ("si", p["si"]), ("no", p["no"]), ("scene", p["scene"]), ("file", p["file"])])
            par_frases = [OrderedDict([("clip", p["say"]), ("text", p["text"])])]
            seen = {p["text"]}
            for it in items:
                if it["par"] and it["text"] not in seen:
                    seen.add(it["text"])
                    par_frases.append(OrderedDict([("clip", it["clip"]), ("text", it["text"])]))
        dilo = []
        for c in by_word.get(word, []):
            m = c["marca_habla"]
            if not (m and m["antes"]):
                continue
            formas = []
            for t in m["targets"]:
                if t["palabra"] == word:
                    formas += [x for x in t["formas"] if x not in formas]
            if formas:
                dilo.append(OrderedDict([("clip", c["clip"]), ("cuento", c["story"]), ("formas", formas),
                                         ("antes", OrderedDict([("clip", m["antes"]["clip"]), ("text", m["antes"]["text"])])),
                                         ("pagina", pagina_ref(D, c["pagina"]["book"], c["pagina"]["page"]) if c["pagina"] else None)]))
        palabras.append(OrderedDict([("word", word), ("puntua", puntua(items, par_w)), ("par", par_w), ("par_frases", par_frases),
                                     ("no_juntas", juntas[word]), ("dilo", dilo), ("frases", items)]))
    paginas = OrderedDict()
    for sid in D.eligible:
        fr, par = V[sid]["frases"], V[sid]["parecidas"]
        for n in range(1, len(D.book[sid]["pages"]) + 1):
            paginas["%s/%d" % (sid, n)] = OrderedDict([
                ("img", D.book[sid]["pages"][n - 1]["img"]),
                ("falsas", falsas_for_page(S[sid], {s["id"]: fr[s["id"]] for s in S[sid]}, par, n)),
                ("ciertas", [OrderedDict([("clip", s["clip"]), ("text", s["text"])]) for s in S[sid] if n in fr[s["id"]]["si"]])])
    meta = OrderedDict([("version", 1), ("palabras", len(palabras)), ("libros", len(D.eligible)), ("frases_fuera", left_out),
                        ("veredictos_par", PV is not None), ("pares_sin_hoja", stops),
                        ("mezcla", "Fisher-Yates from the end; the swap partner of position i is int(first 16 hex digits of SHA-256 of "
                                   "'<word>|<i>' in UTF-8 and NFC) mod (i + 1)")])
    return OrderedDict([("meta", meta), ("palabras", palabras), ("paginas", paginas)])


# ---------------------------------------------------------------------------------------------------------------- 11. the app's file
# historia/datos/repaso.json: only what the games of page 15 need, read by the app (coqui_content). Written with --app.

APP_VERSION = 1


def solo_clips(D, words):
    """{word: clip} for each tracked word that has a recorded clip (one in historia/audio/ready.json) whose whole text is the word: case
    and accents kept (so tú and tu are two words with two clips), signs and spaces ignored (the tokens are equal, as make_palabras_solas.py
    reads them). The clip is found among the clips of the stories (the first in course order: map stories, then picture stories, then the
    other files; then the clip id) or among the clips of the files of `tipo` "palabras" (historia/cuentos/palabras-solas.json: the first in
    the file). That file holds only the words that had no such clip in a story, so a word never has both: when one does, this stops
    (SystemExit) and says which."""
    want = OrderedDict((w, tuple(toks(w))) for w in words)
    in_story, in_palabras = {}, {}
    for sid in sorted(D.story, key=lambda x: (story_rank(D, x), x)):
        for cid in sorted(D.story[sid].get("clips", {})):
            if cid not in D.audio:
                continue
            ft = tuple(toks(D.story[sid]["clips"][cid].get("text") or ""))
            for w, t in want.items():
                if t and ft == t and w not in in_story:
                    in_story[w] = cid
    for cid, clip in D.palabras.items():
        if cid not in D.audio:
            continue
        ft = tuple(toks(clip.get("text") or ""))
        for w, t in want.items():
            if t and ft == t and w not in in_palabras:
                in_palabras[w] = cid
    both = [w for w in words if w in in_story and w in in_palabras]
    if both:
        raise SystemExit("STOP: a clip of the word alone is in a story and in the file of single words (palabras-solas.json) for: " +
                         "; ".join("%s: %s, %s" % (w, in_story[w], in_palabras[w]) for w in both))
    return OrderedDict((w, (in_story.get(w) or in_palabras[w])) for w in words if w in in_story or w in in_palabras)


def build_app(R, final):
    """The app's file from the final data: {"v", "frases": [sentence], "palabras": [word]}. A sentence (clip, cuento, text, tokens, `prohibidas`:
    the tracked words in it, `img`: its book picture when the readers judged it to show the sentence, else null, `oyes`, `arma`) is kept once
    and named by its place in `frases`. A word: `w`, `lugar` (its place), `puntua`, `solo` (the clip of the word alone, in a story or in palabras-solas.json, or null), `no_juntas`,
    `cual` (its picture pair's sentences: clip, text, cuento, null for the pair's own), `frases` (its sentences for ¿Qué oyes? and Arma la
    frase, in the fixed order, as indexes), `donde` (sentence index, `otras`: the fair wrong pictures), `dilo` (clip, cuento, text, formas,
    antes: the clip before it, img)."""
    D = R["D"]
    place = {w["word"]: w["place"] for w in R["words"]}
    solo = solo_clips(D, [w["word"] for w in R["words"]])
    frases, index = [], {}

    def sentence(it):
        img = it["pagina"]["img"] if (it["pagina"] and not it["propia_dudosa"]) else None
        rec = OrderedDict([("clip", it["clip"]), ("cuento", it["cuento"]), ("text", it["text"]), ("tokens", it["tokens"]),
                           ("prohibidas", it["tokens_extra_prohibidos"]), ("img", img), ("oyes", it["que_oyes"]), ("arma", it["arma"])])
        key = (it["clip"], it["cuento"])
        if key in index:
            assert frases[index[key]] == rec, key
        else:
            index[key] = len(frases)
            frases.append(rec)
        return index[key]

    palabras = []
    for w in final["palabras"]:
        refs = [sentence(it) for it in w["frases"] if it["que_oyes"] or it["arma"]]
        donde = []
        for it in w["frases"]:
            if it["cual"]:
                k = sentence(it)
                book = it["pagina"]["book"]
                donde.append(OrderedDict([("frase", k), ("otras", [D.book[book]["pages"][n - 1]["img"] for n in it["cual"]])]))
        story_of = {}
        for it in w["frases"]:
            if it["par"]:
                story_of.setdefault(it["text"], it["cuento"])
        cual = []
        for i, f in enumerate(w["par_frases"]):
            cual.append(OrderedDict([("clip", f["clip"]), ("text", f["text"]), ("cuento", None if i == 0 else story_of[f["text"]])]))
        dilo = []
        for d in w["dilo"]:
            k = index.get((d["clip"], d["cuento"]))
            img = frases[k]["img"] if k is not None else None
            dilo.append(OrderedDict([("clip", d["clip"]), ("cuento", d["cuento"]), ("text", clip_text(D, d["cuento"], d["clip"])),
                                     ("formas", d["formas"]), ("antes", d["antes"]["clip"]), ("img", img)]))
        palabras.append(OrderedDict([("w", w["word"]), ("lugar", place[w["word"]]), ("puntua", w["puntua"]), ("solo", solo.get(w["word"])),
                                     ("no_juntas", w["no_juntas"]), ("cual", cual), ("frases", refs), ("donde", donde), ("dilo", dilo)]))
    return OrderedDict([("v", APP_VERSION), ("frases", frases), ("palabras", palabras)])


def app_bytes(app):
    """The file's bytes: compact JSON (UTF-8, no ASCII escapes), keys in the order built, one newline at the end."""
    return (json.dumps(app, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")


def write_resumen_final(R, final, path):
    D = R["D"]
    L = []
    A = L.append
    ws = final["palabras"]
    first = {w["word"]: w["first_index"] for w in R["words"]}
    A("# Repaso final data: counts")
    A("")
    A("Made by `coqui/tool/make_repaso.py --veredictos ... --final ...` from the readers' verdicts. Every number is printed by the tool. No advice.")
    A("")
    items_all = [i for w in ws for i in w["frases"]]
    n_cual = sum(1 for i in items_all if i["cual"])
    dud_items = [i for i in items_all if i["propia_dudosa"]]
    dud_sent = {(i["pagina"]["book"], i["text"]) for i in dud_items}
    A("## Counts")
    A("")
    L += md_table(["", "n"], [
        ("words", len(ws)),
        ("items (word, sentence) kept", len(items_all)),
        ("candidates left out (own page not in si and neither arma nor que_oyes)", final["meta"]["frases_fuera"]),
        ("items with a non-empty `cual`", n_cual),
        ("items with 2 or more wrong pictures", sum(1 for i in items_all if len(i["cual"]) >= 2)),
        ("items with 3 wrong pictures", sum(1 for i in items_all if len(i["cual"]) == 3)),
        ("items `arma`", sum(1 for i in items_all if i["arma"])),
        ("items `que_oyes`", sum(1 for i in items_all if i["que_oyes"])),
        ("items with `propia_dudosa` (a picture of its own that the verdict does not put in si)", len(dud_items)),
        ("  distinct sentences (book, text) with `propia_dudosa`", len(dud_sent)),
        ("dilo lines (word, line)", sum(len(w["dilo"]) for w in ws)),
        ("words with a picture pair", sum(1 for w in ws if w["par"])),
        ("  of them with no sheet for the readers (a STOP)", len(final["meta"]["pares_sin_hoja"])),
        ("items `par` (the pair's sentence judged to fit the `si` picture only)", sum(1 for i in items_all if i["par"])),
    ])
    A("")
    A("Words by `puntua`: " + ", ".join("%s %d" % (k, sum(1 for w in ws if w["puntua"] == k)) for k in ("cual", "que_oyes", "nada")))
    A("")
    if final["meta"]["veredictos_par"]:
        A("Pair verdicts: given. An item is `par` when its word has a pair and the reader's verdict for its sentence is the letter of the pair's `si` picture.")
    else:
        A("Pair verdicts: NONE given (no `--veredictos-par`). No item is `par`, and the `par_frases` of a word with a pair is the pair's own sentence only.")
    A("")
    for x in final["meta"]["pares_sin_hoja"]:
        A("STOP, no sheet for a pair: " + x)
        A("")

    A("## Per word")
    A("")
    A("Fewest items with a non-empty `cual` first (then fewest items, then course order). `cual`: items with a non-empty `cual`; `2+ wrong`: items with 2 or more wrong pictures.")
    A("")
    order = {w["word"]: i for i, w in enumerate(ws)}
    rows = []
    for w in ws:
        it = w["frases"]
        rows.append((w["word"], len(it), sum(1 for i in it if i["cual"]), sum(1 for i in it if len(i["cual"]) >= 2), sum(1 for i in it if i["arma"]),
                     sum(1 for i in it if i["que_oyes"]), len(w["dilo"]), w["puntua"]))
    rows.sort(key=lambda r: (r[2], r[1], order[r[0]]))
    L += md_table(["word", "items", "cual", "2+ wrong", "arma", "que_oyes", "dilo", "puntua"], rows)
    A("")

    A("## Distribution of words by number of items with a non-empty `cual`")
    A("")
    A("A learner who has finished stories 1..k: the words first met in a map story 1..k, and their items whose story (`cuento`) is a map story 1..k or a picture story of a place whose map stories are all in 1..k.")
    A("")

    def dist(sel):
        cnt = Counter(bucket(n) for n in sel)
        return [cnt.get(b, 0) for b in BUCKETS]

    rows = [["all words, all stories", len(ws)] + dist([sum(1 for i in w["frases"] if i["cual"]) for w in ws])]
    for k in KS:
        met = [w for w in ws if first[w["word"]] <= k]
        rows.append(["finished stories 1..%d" % k, len(met)] + dist([sum(1 for i in w["frases"] if i["cual"] and scope_has(D, {"story": i["cuento"]}, k, True)) for w in met]))
    L += md_table(["learner", "words"] + BUCKETS, rows)
    A("")

    A("## Words that are not scored by `cual`")
    A("")
    for k in ("que_oyes", "nada"):
        sel = [w["word"] for w in ws if w["puntua"] == k]
        A("`puntua` = `%s`: %d words%s" % (k, len(sel), (": " + ", ".join(sel)) if sel else ""))
        A("")

    A("## Pages")
    A("")
    pg2 = [(k, v) for k, v in final["paginas"].items() if len(v["falsas"]) >= 2]
    A("Book pages: %d. Pages with at least 2 `falsas`: %d. With none: %d. Pages with at least 1 `ciertas`: %d." % (
        len(final["paginas"]), len(pg2), sum(1 for v in final["paginas"].values() if not v["falsas"]), sum(1 for v in final["paginas"].values() if v["ciertas"])))
    A("")
    rows = []
    for s in D.eligible:
        mine = [v for k, v in final["paginas"].items() if k.rsplit("/", 1)[0] == s]
        rows.append((s, len(mine), sum(1 for v in mine if len(v["falsas"]) >= 2), sum(1 for v in mine if not v["falsas"])))
    L += md_table(["book", "pages", "pages with 2+ falsas", "pages with no falsas"], rows)
    A("")

    pw = [w for w in ws if w["par"]]

    def par_count(w, k=None):
        """The number of `par_frases` of w for a learner who finished stories 1..k (None: all): the pair's own sentence, and the texts of its
        `par` items whose story is finished (a map story 1..k, or a picture story of a place whose map stories are all in 1..k)."""
        seen = {w["par"]["text"]}
        for i in w["frases"]:
            if i["par"] and (k is None or scope_has(D, {"story": i["cuento"]}, k, True)):
                seen.add(i["text"])
        return len(seen)

    A("## Sentences usable with a word's picture pair (`par_frases`)")
    A("")
    A("`par_frases` of a word with a pair: the pair's own sentence, then its items with `par` true, no text twice. A word with no pair has none. "
      "`judged`: the sentences the readers judge for the word (the own sentence and every distinct text of its items).")
    A("")
    L += md_table(["word", "judged", "items par", "par_frases"],
                  [(w["word"], len(pair_texts(w["par"]["text"], w["frases"])), sum(1 for i in w["frases"] if i["par"]), len(w["par_frases"])) for w in pw])
    A("")
    for w in pw:
        assert len(w["par_frases"]) == par_count(w), w["word"]
    A("## Distribution of words with a pair by number of `par_frases`")
    A("")
    A("A learner who has finished stories 1..k: the words with a pair first met in a map story 1..k, and per word the pair's own sentence (always) and "
      "its `par` items whose story (`cuento`) is a map story 1..k or a picture story of a place whose map stories are all in 1..k.")
    A("")

    def pdist(counts):
        cnt = Counter("1" if n == 1 else "2" if n == 2 else "3-4" if n <= 4 else "5-9" if n <= 9 else "10+" for n in counts)
        return [cnt.get(b, 0) for b in PAR_BUCKETS]

    rows = [["all words with a pair, all stories", len(pw)] + pdist([par_count(w) for w in pw])]
    only = [("all stories", [w["word"] for w in pw if par_count(w) == 1])]
    for k in KS:
        met = [w for w in pw if first[w["word"]] <= k]
        rows.append(["finished stories 1..%d" % k, len(met)] + pdist([par_count(w, k) for w in met]))
        only.append(("finished stories 1..%d" % k, [w["word"] for w in met if par_count(w, k) == 1]))
    L += md_table(["learner", "words with a pair"] + PAR_BUCKETS, rows)
    A("")
    A("Words whose only `par_frases` is the pair's own sentence:")
    A("")
    for name, sel in only:
        A("- %s: %d words%s" % (name, len(sel), (": " + ", ".join(sel)) if sel else ""))
    A("")

    A("## Words that must not meet (`no_juntas`)")
    A("")
    A("For each tracked word, the other tracked words that must never be shown as a wrong written tile beside a sentence with that word, nor together "
      "with it in a matching round. A pair is listed under every rule it meets; `new` is the pairs that no earlier rule of the table has.")
    A("")
    rules = no_juntas_pairs([w["word"] for w in ws])
    seen_pairs, rows = set(), []
    for r, desc in NO_JUNTAS_RULES.items():
        fresh = [pr for pr in rules[r] if pr not in seen_pairs]
        seen_pairs |= set(rules[r])
        rows.append((r, desc, len(rules[r]), len(fresh)))
    L += md_table(["rule", "what", "pairs", "new"], rows)
    A("")
    A("Pairs of different words in all: %d. Words with at least one: %d of %d." % (len(seen_pairs), sum(1 for w in ws if w["no_juntas"]), len(ws)))
    A("")
    for r, desc in NO_JUNTAS_RULES.items():
        A("(%s) %s: %d" % (r, desc, len(rules[r])))
        A("")
        if rules[r]:
            A("    " + "; ".join("%s / %s" % pr for pr in rules[r]))
            A("")
    A("Items whose sentence has a tracked word besides the item's own (`tokens_extra_prohibidos` longer than 1): %d of %d." % (
        sum(1 for i in items_all if len(i["tokens_extra_prohibidos"]) > 1), len(items_all)))
    A("")
    A("## Order of the sentences of a word")
    A("")
    A(final["meta"]["mezcla"] + ". The shuffle is made on all of a word's candidates before any is left out, so leaving one out does not move the others.")
    A("")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L))


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
    cands, M, posmap = build_candidates(D, words, walks, stops, fits)
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
            "fits": fits, "M": M, "pos": posmap}


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


def report_faults(faults, notes, n_files):
    for x in faults:
        print(x)
    for x in notes:
        print("note: " + x)
    print("%d faults in %d files" % (len(faults), n_files) if faults else "ok: %d files, no fault" % n_files)


def checked_books(out, vdir, root):
    """The build and the book verdicts of vdir checked for the pair step and the merge: every book has a valid file, and the sheets in
    <out>/libro/ are what the tool makes from the repo now. -> (R, books, faults, notes)."""
    books, frs = libro_frases(out)
    faults, notes = valida_veredictos(vdir, out, require_all=True)
    R = build(root)
    S = sentences_by_book(R)
    for b in books:
        if json.loads(json.dumps(frases_doc(R["D"], b, S[b]))) != frs[b]:
            faults.append("%s: frases.json is not what the tool makes from the repo now (write the sheets again; the readers' verdicts of this book no longer match)" % b)
    return R, books, faults, notes


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", required=True, help="directory to write into (and, for the verdict checks, where libro/ and par/ were written)")
    ap.add_argument("--repo", default=None, help="repo root (default: the repo this file sits in)")
    ap.add_argument("--no-sheets", action="store_true", help="do not write the vetting sheets")
    ap.add_argument("--hojas-libro", action="store_true", help="write only <out>/libro/: the page sheets and sentences for the readers, and indice.json")
    ap.add_argument("--valida-veredictos", metavar="DIR", help="check every <book>.json in DIR against <out>/libro/<book>/frases.json; exit 1 on any fault")
    ap.add_argument("--hojas-par", action="store_true", help="with --veredictos: write only <out>/par/: for each word with a picture pair its sheet and sentences, claves, indice and grupos")
    ap.add_argument("--valida-veredictos-par", metavar="DIR", help="check every <slug>.json in DIR against <out>/par/<slug>/frases.json; exit 1 on any fault")
    ap.add_argument("--veredictos", metavar="DIR", help="with --final or --hojas-par: the verdicts of every book")
    ap.add_argument("--veredictos-par", metavar="DIR", help="with --veredictos and --final: the verdicts of every word that has a pair sheet")
    ap.add_argument("--final", metavar="FILE", help="with --veredictos: write the final data here, and resumen-final.md beside it")
    ap.add_argument("--app", metavar="FILE", help="with --veredictos (and --veredictos-par): write the app's slim file here (historia/datos/repaso.json)")
    ap.add_argument("--check", action="store_true", help="with --app: write nothing; exit 1 when FILE is not what the tool makes now")
    a = ap.parse_args(argv)
    if a.final and not a.veredictos:
        ap.error("--final needs --veredictos")
    if a.app and not a.veredictos:
        ap.error("--app needs --veredictos")
    if a.check and not a.app:
        ap.error("--check goes with --app")
    if a.hojas_par and not a.veredictos:
        ap.error("--hojas-par needs --veredictos")
    if a.veredictos and not (a.final or a.hojas_par or a.app):
        ap.error("--veredictos goes with --final, --app or --hojas-par")
    if a.veredictos_par and not (a.final or a.app):
        ap.error("--veredictos-par goes with --veredictos and --final or --app")
    if sum([a.hojas_libro, bool(a.valida_veredictos), bool(a.valida_veredictos_par), a.hojas_par, bool(a.final or a.app)]) > 1:
        ap.error("one of --hojas-libro, --valida-veredictos, --valida-veredictos-par, --hojas-par, --final / --app at a time")
    root = a.repo or Path(__file__).resolve().parents[2]
    out = Path(a.out)
    if a.valida_veredictos:
        faults, notes = valida_veredictos(a.valida_veredictos, out)
        report_faults(faults, notes, len(list(Path(a.valida_veredictos).glob("*.json"))))
        return 1 if faults else 0
    if a.valida_veredictos_par:
        faults, notes = valida_veredictos_par(a.valida_veredictos_par, out)
        report_faults(faults, notes, len(list(Path(a.valida_veredictos_par).glob("*.json"))))
        return 1 if faults else 0
    if a.final or a.hojas_par or a.app:
        R, books, faults, notes = checked_books(out, a.veredictos, root)
        if faults:
            report_faults(faults, notes, len(list(Path(a.veredictos).glob("*.json"))))
            return 1
        V = load_veredictos(a.veredictos, books)
        if a.hojas_par:
            items_of, _ = collect_items(R, V)
            index, docs, stops = write_hojas_par(R, items_of, out)
            counts = [(w, len(docs[s]["frases"])) for s, w in index.items()]
            few = min(n for _, n in counts)
            print("words %d, sentences to judge %d (the pairs' own sentences %d, the others %d)" % (
                len(counts), sum(n for _, n in counts), len(counts), sum(n for _, n in counts) - len(counts)))
            big = max(counts, key=lambda x: x[1])
            print("largest word: %s (%d sentences); smallest: %d sentence%s (%d words, first in the course: %s)" % (
                big[0], big[1], few, "" if few == 1 else "s", sum(1 for _, n in counts if n == few), next(w for w, n in counts if n == few)))
            for x in stops:
                print("STOP, no sheet for the pair of " + x)
            return 0
        PV = None
        if a.veredictos_par:
            faults, notes = valida_veredictos_par(a.veredictos_par, out, require_all=True)
            faults += pair_stale_faults(R, V, out)
            if faults:
                report_faults(faults, notes, len(list(Path(a.veredictos_par).glob("*.json"))))
                return 1
            PV = load_veredictos_par(a.veredictos_par, pair_sheets_on_disk(out)[0])
        else:
            print("note: no --veredictos-par: no item is `par`, and the `par_frases` of a word with a pair is its own sentence only")
        final = build_final(R, V, PV)
        if a.app:
            ap_ = Path(a.app)
            want = app_bytes(build_app(R, final))
            if a.check:
                have = ap_.read_bytes() if ap_.is_file() else None
                if have != want:
                    print("STALE: %s is %s; write it again with --app (without --check)" % (ap_, "missing" if have is None else "not what the tool makes now"))
                    return 1
                print("ok: %s is what the tool makes (%d bytes)" % (ap_, len(want)))
            else:
                ap_.parent.mkdir(parents=True, exist_ok=True)
                ap_.write_bytes(want)
                app = json.loads(want)
                print("app file %s: %d bytes, %d sentences, %d words" % (ap_, len(want), len(app["frases"]), len(app["palabras"])))
        if not a.final:
            return 0
        fp = Path(a.final)
        fp.parent.mkdir(parents=True, exist_ok=True)
        jdump(final, fp)
        write_resumen_final(R, final, fp.with_name("resumen-final.md"))
        its = [i for w in final["palabras"] for i in w["frases"]]
        print("words %d, items %d (with a wrong picture %d, par %d), left out %d, puntua %s, words with par_frases beyond the own sentence %d" % (
            len(final["palabras"]), len(its), sum(1 for i in its if i["cual"]), sum(1 for i in its if i["par"]), final["meta"]["frases_fuera"],
            "/".join("%s %d" % (k, sum(1 for w in final["palabras"] if w["puntua"] == k)) for k in ("cual", "que_oyes", "nada")),
            sum(1 for w in final["palabras"] if len(w["par_frases"]) > 1)))
        for x in final["meta"]["pares_sin_hoja"]:
            print("STOP, no sheet for the pair of " + x)
        return 0
    out.mkdir(parents=True, exist_ok=True)
    R = build(root)
    if a.hojas_libro:
        index = write_hojas_libro(R, out)
        print("books %d, pages %d, sentences to judge %d" % (len(index), sum(i["paginas"] for i in index), sum(i["frases"] for i in index)))
        return 0
    sheets_n = dup = 0
    if not a.no_sheets:
        sheets_n = write_sheets(R["D"], R["cands"], out, R["stops"])
        seen = Counter((c["pagina"]["book"], c["pagina"]["page"], c["text"]) for c in R["cands"] if c["pagina"])
        dup = sum(v - 1 for v in seen.values() if v > 1)
    jdump(candidatos_json(R), out / "candidatos.json")
    write_resumen(R["D"], R["words"], R["cands"], R["parejas"], R["pstats"], R["falsas"], R["walks"], R["classes"], R["stops"], R["fits"], out / "resumen.md", sheets_n, dup)
    print("words %d, candidates %d (with a page %d), sheets %d" % (len(R["words"]), len(R["cands"]), sum(1 for c in R["cands"] if c["pagina"]), sheets_n))
    return 0


if __name__ == "__main__":
    sys.exit(main())
