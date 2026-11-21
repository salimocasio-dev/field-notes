#!/usr/bin/env python3
"""Carries the readers' pair verdicts over to new pair sheets by sentence text, so that only sentences no reader has judged go to readers.

Why: make_repaso.py --hojas-par numbers a word's sentences in the order of its items in the final data (a mixed order), so when stories
are added the same sentence gets another id and a verdict file judged before no longer matches its sheet. A verdict is a reader's answer to
"does this sentence fit picture A or B of this word's pair": it holds for the same word, the same sentence text and the same two pictures
in the same order (par.png byte for byte), whatever its id. Nothing else is carried.

    python3 coqui/tool/repaso/arrastra.py --hace --antes OLD --ahora NEW [--veredictos-antes DIR] [--registro FILE]
        OLD and NEW are make_repaso.py --out folders holding par/ (--hojas-par): OLD made from the tree the verdicts of DIR (default
        coqui/tool/repaso/veredictos-par) were judged against, NEW from the tree now. For every word whose sheet is new or changed it
        writes the record FILE (default coqui/tool/repaso/arrastre.json): the word, the SHA-256 of its par.png, and for each sentence of
        its new sheet either the carried verdict (new id, text, old id, value) or "sin juzgar". A word whose par.png is not byte for byte
        the old one, or that had no verdict file, carries nothing. The old verdict files must pass make_repaso's check against OLD.
    python3 coqui/tool/repaso/arrastra.py --hojas DIR --lectores N --ahora NEW [--registro FILE]
        the sheets of the sentences still unjudged, for N readers (whole words to one reader, course order, about equal numbers of
        sentences): DIR/lectorK/<slug>/par.png and frases.json (only the unjudged sentences, with their ids in NEW's numbering),
        DIR/lectorK/LEEME.txt, an empty DIR/lectorK/out/ for the reader's files, and DIR/lectores.json. No answer key is written.
    python3 coqui/tool/repaso/arrastra.py --junta OUT1 [OUT2 ...] --ahora NEW [--registro FILE] [--veredictos-par DIR]
        each reader's files (<slug>.json: {"palabra", "frases": {id: A|B|ambas|ninguna|duda}} with exactly the ids of the sheet) merged with
        the carried verdicts into one full verdict file per word of the record, written into DIR (default coqui/tool/repaso/veredictos-par);
        then every file of DIR is checked against NEW with make_repaso's own check, every word required. Exit 1 on any fault (nothing is
        written when a reader's file is wrong).
    python3 coqui/tool/repaso/arrastra.py --check [--ahora NEW] [--registro FILE] [--veredictos-par DIR]
        proves the record against the sheets the tool makes now (NEW, or made in a temporary folder when not given) and the verdict files:
        for every word of the record, par.png is the recorded one byte for byte, every carried id has the recorded text, and the verdict
        file holds the carried value; every sentence of the word's sheet is in the record. Exit 1 on any fault.
        With --antes OLD --veredictos-antes DIR it also proves the old side: each carried text had the recorded old id in OLD's sheet, the
        old verdict file gave it the carried value, and OLD's par.png is the recorded one.
"""
import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
from collections import OrderedDict
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import make_repaso as MR  # noqa: E402

ROOT = HERE.parents[2]
REGISTRO = HERE / "arrastre.json"
VPAR = HERE / "veredictos-par"
UNJUDGED = "sin juzgar"


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def sheets(out):
    index, _claves, docs = MR.pair_sheets_on_disk(out)   # the key (claves) is never used here
    return index, docs


def texts(doc):
    return OrderedDict((x["id"], x["text"]) for x in doc["frases"])


def hace(a):
    oi, od = sheets(a.antes)
    ni, nd = sheets(a.ahora)
    vdir = Path(a.veredictos_antes)
    faults, _ = MR.valida_veredictos_par(vdir, a.antes)
    if faults:
        raise SystemExit("the old verdicts do not match the old sheets (%s): %s" % (a.antes, "; ".join(faults[:5])))
    rec = OrderedDict([("made", "python3 coqui/tool/repaso/arrastra.py --hace"), ("palabras", OrderedDict())])
    carried = unjudged = 0
    for slug, word in ni.items():
        nt = texts(nd[slug])
        same = slug in oi and list(texts(od[slug]).items()) == list(nt.items())
        if same:
            continue   # the sheet did not change: its verdict file stays as it is
        psha = sha(Path(a.ahora) / "par" / slug / "par.png")
        e = OrderedDict([("palabra", word), ("par_png_sha256", psha)])
        old_v, why = {}, None
        if slug not in oi:
            why = "a new word: no verdict before"
        elif not (vdir / (slug + ".json")).exists():
            why = "no verdict file before"
        elif sha(Path(a.antes) / "par" / slug / "par.png") != psha:
            why = "par.png is not the one the readers saw: nothing carried"
        else:
            vf = vdir / (slug + ".json")
            e["veredicto_antes_sha256"] = sha(vf)
            v = MR.read_json(vf)["frases"]
            old_v = {t: (i, v[i]) for i, t in texts(od[slug]).items()}
        if why:
            e["nota"] = why
        fr = OrderedDict()
        for i, t in nt.items():
            if t in old_v:
                fr[i] = OrderedDict([("texto", t), ("antes", old_v[t][0]), ("valor", old_v[t][1])])
                carried += 1
            else:
                fr[i] = OrderedDict([("texto", t), ("valor", UNJUDGED)])
                unjudged += 1
        e["frases"] = fr
        rec["palabras"][slug] = e
    MR.jdump(rec, a.registro)
    print("record %s: %d words, %d verdicts carried by text, %d sentences unjudged" % (a.registro, len(rec["palabras"]), carried, unjudged))
    return 0


def todo(rec):
    """{slug: [(id, text)]}: the unjudged sentences of each word of the record, in sheet order."""
    return OrderedDict((s, [(i, f["texto"]) for i, f in e["frases"].items() if f["valor"] == UNJUDGED]) for s, e in rec["palabras"].items())


LEEME = """Sheets for one reader: {words} words, {n} sentences.

Each folder <slug>/ holds par.png (two pictures, A and B) and frases.json ({{"palabra", "frases": [{{"id", "text"}}]}}).
For every sentence of frases.json: does it fit picture A, picture B, both, neither, or can you not tell?
Answer A, B, ambas, ninguna or duda. Look only at the two pictures and the sentence.

Write one file per word into out/ (this folder's out/), named <slug>.json (the folder's name):
  {{"palabra": "<the palabra of frases.json, exactly>", "frases": {{"<id>": "A" | "B" | "ambas" | "ninguna" | "duda", ...}}}}
Every id of that word's frases.json, and no other.
"""


def hojas(a):
    rec = MR.read_json(a.registro)
    ni, _ = sheets(a.ahora)
    for s, e in rec["palabras"].items():
        if sha(Path(a.ahora) / "par" / s / "par.png") != e["par_png_sha256"]:
            raise SystemExit("%s: par.png is not the recorded one: make the record again (--hace)" % s)
    work = [(s, l) for s, l in todo(rec).items() if l]
    work.sort(key=lambda x: list(ni).index(x[0]))   # course order
    total, n = sum(len(l) for _, l in work), a.lectores
    groups, acc = [[] for _ in range(n)], 0
    g = 0
    for s, l in work:   # whole words, cut where the running count passes k/n of the total
        if g < n - 1 and groups[g] and acc + len(l) / 2 > total * (g + 1) / n:
            g += 1
        groups[g].append((s, l))
        acc += len(l)
    out = Path(a.hojas)
    if out.exists() and any(out.iterdir()):
        raise SystemExit("%s is not empty" % out)
    resumen = OrderedDict()
    for k, grp in enumerate(groups, 1):
        d = out / ("lector%d" % k)
        (d / "out").mkdir(parents=True)
        for s, l in grp:
            (d / s).mkdir()
            (d / s / "par.png").write_bytes((Path(a.ahora) / "par" / s / "par.png").read_bytes())
            MR.jdump(OrderedDict([("palabra", rec["palabras"][s]["palabra"]), ("frases", [OrderedDict([("id", i), ("text", t)]) for i, t in l])]), d / s / "frases.json")
        nn = sum(len(l) for _, l in grp)
        (d / "LEEME.txt").write_text(LEEME.format(words=len(grp), n=nn), encoding="utf-8")
        resumen["lector%d" % k] = OrderedDict([("palabras", [s for s, _ in grp]), ("frases", nn)])
    MR.jdump(resumen, out / "lectores.json")
    for k, v in resumen.items():
        print("%s: %d words, %d sentences (%s)" % (k, len(v["palabras"]), v["frases"], ", ".join(v["palabras"])))
    return 0


def junta(a):
    rec = MR.read_json(a.registro)
    _, nd = sheets(a.ahora)
    want = todo(rec)
    got, faults = {}, []
    for d in a.junta:
        for p in sorted(Path(d).glob("*.json")):
            s = p.stem
            if s not in want or not want[s]:
                faults.append("%s: not a word with unjudged sentences" % p)
                continue
            if s in got:
                faults.append("%s: the word is in two readers' folders" % p)
                continue
            try:
                v = MR.read_json(p)
            except ValueError as e:
                faults.append("%s: not JSON (%s)" % (p, e))
                continue
            sub = OrderedDict([("palabra", rec["palabras"][s]["palabra"]), ("frases", [OrderedDict([("id", i), ("text", t)]) for i, t in want[s]])])
            faults += ["%s: %s" % (p, x) for x in MR.check_verdict_par(rec["palabras"][s]["palabra"], sub, v)]
            got[s] = v.get("frases", {}) if isinstance(v, dict) else {}
    for s, l in want.items():
        if l and s not in got:
            faults.append("%s.json: no reader's file" % s)
    if faults:
        print("\n".join(faults))
        print("%d faults; nothing written" % len(faults))
        return 1
    vdir = Path(a.veredictos_par)
    for s, e in rec["palabras"].items():
        ids = [x["id"] for x in nd[s]["frases"]]
        fr = OrderedDict((i, e["frases"][i]["valor"] if e["frases"][i]["valor"] != UNJUDGED else got[s][i]) for i in ids)
        MR.jdump(OrderedDict([("palabra", e["palabra"]), ("frases", fr)]), vdir / (s + ".json"))
    print("wrote %d verdict files into %s" % (len(rec["palabras"]), vdir))
    faults, notes = MR.valida_veredictos_par(vdir, a.ahora, require_all=True)
    MR.report_faults(faults, notes, len(list(vdir.glob("*.json"))))
    if faults:
        return 1
    return check(a)


def check(a):
    rec = MR.read_json(a.registro)
    tmp = None
    if not a.ahora:   # make the sheets as test_all.sh does
        tmp = tempfile.TemporaryDirectory()
        a.ahora = tmp.name
        mk = [sys.executable, str(HERE.parent / "make_repaso.py"), "--out", tmp.name]
        for extra in (["--hojas-libro"], ["--veredictos", str(HERE / "veredictos"), "--hojas-par"]):
            r = subprocess.run(mk + extra, capture_output=True, text=True)
            if r.returncode:
                print(r.stdout + r.stderr)
                return 1
    ni, nd = sheets(a.ahora)
    vdir, faults, carried = Path(a.veredictos_par), [], 0
    if a.antes:
        oi, od = sheets(a.antes)
    for s, e in rec["palabras"].items():
        if s not in ni:
            faults.append("%s: no sheet now" % s)
            continue
        if sha(Path(a.ahora) / "par" / s / "par.png") != e["par_png_sha256"]:
            faults.append("%s: par.png is not the recorded one (the pictures changed: judge the word again)" % s)
        if ni[s] != e["palabra"]:
            faults.append("%s: the word is %s now, %s in the record" % (s, ni[s], e["palabra"]))
        nt = texts(nd[s])
        if list(nt) != list(e["frases"]):
            faults.append("%s: the sheet's ids are not the record's" % s)
        v = MR.read_json(vdir / (s + ".json"))["frases"] if (vdir / (s + ".json")).exists() else {}
        ov = MR.read_json(Path(a.veredictos_antes) / (s + ".json"))["frases"] if a.antes and (Path(a.veredictos_antes) / (s + ".json")).exists() else {}
        ot = texts(od[s]) if a.antes and s in oi else {}
        for i, f in e["frases"].items():
            if nt.get(i) != f["texto"]:
                faults.append("%s %s: the text is %r now, %r in the record" % (s, i, nt.get(i), f["texto"]))
            if f["valor"] == UNJUDGED:
                continue
            carried += 1
            if v.get(i) != f["valor"]:
                faults.append("%s %s: the verdict file says %r, the carried verdict is %r" % (s, i, v.get(i), f["valor"]))
            if a.antes:
                if ot.get(f["antes"]) != f["texto"]:
                    faults.append("%s %s: the old sheet's %s is %r, not the carried text" % (s, i, f["antes"], ot.get(f["antes"])))
                if ov.get(f["antes"]) != f["valor"]:
                    faults.append("%s %s: the old verdict of %s is %r, not the carried %r" % (s, i, f["antes"], ov.get(f["antes"]), f["valor"]))
        if a.antes and "veredicto_antes_sha256" in e:
            if sha(Path(a.antes) / "par" / s / "par.png") != e["par_png_sha256"]:
                faults.append("%s: the old par.png is not the recorded one" % s)
    if tmp:
        tmp.cleanup()
    for x in faults:
        print(x)
    print("%s: %d words, %d carried verdicts%s" % ("FAILED, %d faults" % len(faults) if faults else "ok", len(rec["palabras"]), carried,
                                                   " (old side checked too)" if a.antes else ""))
    return 1 if faults else 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--hace", action="store_true")
    ap.add_argument("--hojas", metavar="DIR")
    ap.add_argument("--junta", nargs="+", metavar="OUT")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--antes", metavar="OLD")
    ap.add_argument("--ahora", metavar="NEW")
    ap.add_argument("--lectores", type=int, default=2)
    ap.add_argument("--veredictos-antes", default=str(VPAR))
    ap.add_argument("--veredictos-par", default=str(VPAR))
    ap.add_argument("--registro", default=str(REGISTRO))
    a = ap.parse_args(argv)
    if sum(map(bool, (a.hace, a.hojas, a.junta, a.check))) != 1:
        ap.error("one of --hace, --hojas, --junta, --check")
    if (a.hace or a.hojas or a.junta) and not a.ahora:
        ap.error("--ahora NEW is needed")
    if a.hace and not a.antes:
        ap.error("--hace needs --antes OLD")
    return hace(a) if a.hace else hojas(a) if a.hojas else junta(a) if a.junta else check(a)


if __name__ == "__main__":
    sys.exit(main())
