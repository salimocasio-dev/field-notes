#!/usr/bin/env python3
"""Makes historia/cuentos/palabras-solas.json: each tracked word of the course, said alone, for the word tiles of Repaso
(docs/proyecto/15-repaso-juegos.md, "Asked of Salim", answer 2).

    python3 coqui/tool/make_palabras_solas.py [--repo <root>]      writes the file
    python3 coqui/tool/make_palabras_solas.py [--repo <root>] --check
                                                                   writes nothing; exit 1 when the file on disk is not what this
                                                                   tool makes (or is not there)

The file is not a story. It has the shape of a story file only as far as the recording job needs (`clips`): voz.py records every clip
of every file under historia/cuentos/ once, and a push of this file starts that job. It holds:

    { "id": "palabras-solas", "title": "Palabras", "tipo": "palabras", "note": "...",
      "clips": { "w_<slug>": { "who": "narr", "text": "<Text>" }, ... } }

THE WORDS are the tracked words of make_repaso.py (its load() and build_words(): the focus_words and back_again words of the map
stories, in course order; 156 today). A word gets a clip when no clip of any other file of historia/cuentos/ has the word as its whole
text. "Whole text" is make_repaso.py's own reading, toks(): lower case, signs taken out, accents kept. So "¡Hola!" and "Hola." are the
word hola, "Hasta mañana" is hasta mañana, and "Abuela dice: ¡Hola!" is not. An accent counts: a clip "Tú." gives tú a clip of its
own already and tu none. (23 words have one today.) This file's own clips are never read: they would make every word "already said"
the second time the tool runs.

THE ID of a clip is "w_" and the word's slug: lower case, accents folded (make_repaso.fold: ñ and ü too), every run of other
characters one "_", the ends trimmed ("¿cómo estás?" is w_como_estas). When two tracked words have the same slug (tu and tú, esta and
está, bebe and bebé; decided among all the tracked words, not only among the ones that get a clip, so that an id does not change
when another word later gets a recording of its own) the word spelled without an accent keeps the slug and the other one gets "_a"
after it (w_tu, w_tu_a). If that does not give every word an id of its own, or an id is one that a clip of another file has, the
tool stops with the list and writes nothing.

THE TEXT is the word exactly as the course spells it, its first letter upper case (after a leading ¿ or ¡, the letter after the
sign), and a full stop at the end unless the word already ends in ?, ! or a full stop: "puerta" is "Puerta.", "¿de qué color?" is
"¿De qué color?", "tú" is "Tú.".

THE ORDER of the clips is the course order of the words. The bytes are the same on every run (json.dumps with indent 1 and
ensure_ascii False and no newline at the end, as the files the gen_*.py tools write).
"""
import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_repaso as mr  # noqa: E402

OWN_ID = "palabras-solas"
OWN_FILE = OWN_ID + ".json"
TITLE = "Palabras"
TIPO = "palabras"
NOTE = ("Each tracked word alone, for the word tiles of Repaso (docs/proyecto/15-repaso-juegos.md). "
        "Made by coqui/tool/make_palabras_solas.py; not a story.")
PREFIX = "w_"
ACCENT_SUFFIX = "_a"


class Fault(Exception):
    """The file cannot be made as the rules say; the message says why."""


def slug_of(word):
    """The word lower-cased, accents folded, every run of other characters turned into one `_`, the ends trimmed."""
    s = re.sub(r"[^a-z0-9]+", "_", mr.fold(mr.nfc(word))).strip("_")
    if not s:
        raise Fault("the word %r has no letter or digit for an id" % word)
    return s


def has_accent(word):
    """The word is spelled with an accent (an acute accent, a tilde or a diaeresis)."""
    return mr.fold(mr.nfc(word)) != mr.nfc(word).lower()


def clip_ids(words):
    """{word: clip id} for every word given (all the tracked words). A group of words with one slug: the word without an accent keeps
    it, the others get ACCENT_SUFFIX. A Fault when the ids are still not each its own."""
    groups = defaultdict(list)
    for w in words:
        groups[slug_of(w)].append(w)
    ids = {}
    for slug, group in groups.items():
        if len(group) == 1:
            ids[group[0]] = PREFIX + slug
            continue
        plain = [w for w in group if not has_accent(w)]
        accented = [w for w in group if has_accent(w)]
        if len(plain) > 1 or len(accented) > 1:
            raise Fault("the words %s have one slug (%s) and the rule names only one without an accent and one with" % (
                ", ".join(repr(w) for w in group), slug))
        for w in plain:
            ids[w] = PREFIX + slug
        for w in accented:
            ids[w] = PREFIX + slug + ACCENT_SUFFIX
    by_id = defaultdict(list)
    for w, i in ids.items():
        by_id[i].append(w)
    twice = {i: ws for i, ws in by_id.items() if len(ws) > 1}
    if twice:
        raise Fault("one id for two words: " + "; ".join("%s: %s" % (i, ", ".join(repr(w) for w in ws)) for i, ws in sorted(twice.items())))
    return ids


def text_of(word):
    """The word as the course spells it, its first letter upper case, and a full stop unless it ends in ?, ! or a full stop."""
    i = next((k for k, c in enumerate(word) if c.isalpha()), None)
    if i is None:
        raise Fault("the word %r has no letter" % word)
    t = word[:i] + word[i].upper() + word[i + 1:]
    return t if t[-1] in ".?!" else t + "."


def make_doc(words, existing):
    """The file, as a dict. words: the tracked words in course order. existing: (clip id, text) of every clip of every other file of
    historia/cuentos/. A Fault when an id of the new clips is one of an existing clip."""
    whole = {tuple(mr.toks(text)) for _, text in existing}
    taken = {cid for cid, _ in existing}
    ids = clip_ids(words)
    clips = {}
    for w in words:
        if tuple(mr.toks(w)) in whole:
            continue
        clips[ids[w]] = {"who": "narr", "text": text_of(w)}
    clash = sorted(set(clips) & taken)
    if clash:
        raise Fault("a clip id of this file is one that another file of historia/cuentos/ already has: " + ", ".join(clash))
    return {"id": OWN_ID, "title": TITLE, "tipo": TIPO, "note": NOTE, "clips": clips}


def render(doc):
    """The bytes of the file."""
    return json.dumps(doc, ensure_ascii=False, indent=1).encode("utf-8")


def tracked_words(root):
    D = mr.load(root)
    return [w["word"] for w in mr.build_words(D, [])]


def existing_clips(root):
    """(clip id, text) of every clip of every file of historia/cuentos/ except this tool's own file."""
    out = []
    for p in sorted((Path(root) / "historia" / "cuentos").glob("*.json")):
        if p.name == OWN_FILE:
            continue
        for cid, clip in mr.read_json(p).get("clips", {}).items():
            out.append((cid, clip["text"]))
    return out


def build(root):
    return make_doc(tracked_words(root), existing_clips(root))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--repo", default=None, help="repo root (default: the repo this file sits in)")
    ap.add_argument("--check", action="store_true", help="write nothing; exit 1 when the file on disk is not what this tool makes")
    a = ap.parse_args(argv)
    root = Path(a.repo) if a.repo else Path(__file__).resolve().parents[2]
    path = root / "historia" / "cuentos" / OWN_FILE
    try:
        doc = build(root)
    except Fault as e:
        print("STOP: " + str(e), file=sys.stderr)
        return 1
    want = render(doc)
    n = len(doc["clips"])
    chars = sum(len(c["text"]) for c in doc["clips"].values())
    if a.check:
        have = path.read_bytes() if path.exists() else None
        if have == want:
            print("%s is what the tool makes: %d clips, %d characters" % (OWN_FILE, n, chars))
            return 0
        print("%s is %s: run python3 coqui/tool/make_palabras_solas.py (it would hold %d clips, %d characters)" % (
            path, "not there" if have is None else "not what the tool makes", n, chars), file=sys.stderr)
        return 1
    path.write_bytes(want)
    print("wrote %s: %d clips, %d characters" % (path, n, chars))
    return 0


if __name__ == "__main__":
    sys.exit(main())
