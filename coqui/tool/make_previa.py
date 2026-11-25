#!/usr/bin/env python3
"""Makes the app's preview content ("previa"): the story files of places 4 to 10 that are not on the old site yet, bundled in the
app package so that a published build can play them, silent, before they are recorded (coqui/AGENTS.md, "Preview content (previa)").

    python3 coqui/tool/make_previa.py --places colmado[,calle,...] [--allow-missing-scenes]
                    runs the generators, copies the asked places' story files into coqui/app/assets/previa/cuentos/ and writes the
                    overlay coqui/app/assets/previa/curso.json; then removes everything the generators wrote under historia/
    python3 coqui/tool/make_previa.py --places none
                    writes the empty overlay and removes every bundled story file (the state of the repo when no place is previewed)
    python3 coqui/tool/make_previa.py --check
                    writes nothing under coqui/; exit 0 when the bundled files are what the generators make now, 1 when not

Run it from the repository's root (it finds the root from its own place, so any working directory works). It never calls git add, commit
or push: it only reads `git status` and puts back what the generators changed.

THE RULE. Nothing it makes may be pushed under historia/cuentos/: a push there starts the paid recording job (.github/workflows/voz.yml).
So the tool refuses to start unless `git status --porcelain historia/` is empty and no story file under historia/cuentos/ is hidden by an
ignore rule (one there would change what the generators see), and at the end it removes every file that appeared under historia/ (the
generators write their three story files each into historia/cuentos/), puts back any file of historia/ they changed or removed, and fails
unless `git status --porcelain historia/` is empty again. It does this on failure too.

THE GENERATORS run in the order of page 13 (docs/proyecto/13-flutter-orders.md): El colmado mostrador, estantes, frutas, caja; La calle
esquina, parada, tiendas, cruce; La plaza plaza, reloj, quiosco, calendario; La playa orilla, sombrilla, ropa, cielo; La fonda entrada,
pedido, comida, cuenta; La casa, un día entero cuarto, bano, sala_dia, noche; El fuerte subida, musica, regalos, muralla. Each generator
"sees what was recorded before it" (it reuses the clip ids of the files already in historia/cuentos/), so every generator before the last
one asked for runs first, even when its place is not asked for.

THE BUNDLE is exactly the asked places: the bundled story files of any other place are removed. A later builder who adds a place names
every place to keep (`--places colmado,calle`). Each story file is copied byte for byte. The overlay is

    { "lugares": { "<place id>": [ "<story id>", ... ] }, "cuentos": { "<story id>": { "t": "<title>", "min": <minutes> } } }

with the places in the course's order and each place's stories in the order its generators write them (the course's numbers; checked
against each story's `next`). `t` is the story file's `title` (the generator writes it). `min` is a guess: no generator and no script
gives a story's length in minutes. It is the story's `dots` minus 3 (at least 2): over the 32 stories the course lists today, the median
of `min` for 6, 7, 8 and 9 dots is 3.5, 4, 5 and 6, and A comer's three stories (9 dots) are 6, 6 and 7 in curso.js. When the content
lane adds the place to curso.js the site's own `min` wins (the app ignores the overlay for a story the site lists).

THE SCENES. A place whose stories name a scene that is not in coqui_scenes scene folders (coqui/packages/core/coqui_scenes/lib/src/) is refused, unless
--allow-missing-scenes is given (only for a builder's own test of the mechanism: such a story opens on "This story is not in the new app
yet."). A story's `place` must be the place's `nombre` in historia/datos/curso.json.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
HISTORIA = os.path.join(ROOT, "historia")
OUT = os.path.join(ROOT, "coqui", "app", "assets", "previa")
OVERLAY = os.path.join(OUT, "curso.json")
STORIES = os.path.join(OUT, "cuentos")
SCENE_PLACES = os.path.join(ROOT, "coqui", "tool", "scene_places.json")
SCENES_SRC = os.path.join(ROOT, "coqui", "packages", "core", "coqui_scenes", "lib", "src")


def load_places(path=SCENE_PLACES):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return [(p["id"], list(p["scenes"])) for p in data["places"]]


# page 13, "From the content lane": the places 4 to 10 and their generators, in the order they must run
PLACES = load_places()
PLACE_IDS = [p for p, _ in PLACES]


class Refused(Exception):
    pass


def git(*args):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)
    if r.returncode != 0:
        raise Refused("git %s failed: %s" % (" ".join(args), r.stderr.strip()))
    return r.stdout


def status():
    """`git status --porcelain historia/`, as lines (every untracked file listed by itself)."""
    return [l for l in git("status", "--porcelain", "--untracked-files=all", "historia/").splitlines() if l.strip()]


def ignored():
    """The ignored paths under historia/ (`!! <path>` lines of `git status --porcelain --ignored`)."""
    out = git("status", "--porcelain", "--ignored", "--untracked-files=all", "historia/")
    return {l[3:] for l in out.splitlines() if l.startswith("!! ")}


_SCENE_FACTORY_RE = re.compile(r"^Scene\s+(create[A-Za-z0-9_]+)\s*\(([^)]*)\)", re.M)
_RNG_PARAM_RE = re.compile(r"^\s*\{\s*Rng\?\s+rng\s*,?\s*\}\s*$")


def registry_scenes(scenes_src=SCENES_SRC):
    if not os.path.isdir(scenes_src):
        raise Refused("scene folder root not found: %s" % os.path.relpath(scenes_src, ROOT))
    found = set()
    for entry in sorted(os.listdir(scenes_src)):
        d = os.path.join(scenes_src, entry)
        if not os.path.isdir(d):
            continue
        main_dart = os.path.join(d, "%s.dart" % entry)
        if not os.path.isfile(main_dart):
            continue
        with open(main_dart, encoding="utf-8") as f:
            src = f.read()
        m = _SCENE_FACTORY_RE.search(src)
        if not m:
            raise Refused("scene file has no Scene create... factory: %s" % os.path.relpath(main_dart, ROOT))
        params = m.group(2)
        if params.strip() and not _RNG_PARAM_RE.match(params):
            raise Refused("scene file has unsupported factory parameters (%s): %s"
                          % (params, os.path.relpath(main_dart, ROOT)))
        found.add(entry)
    return found


def course_places():
    j = json.load(open(os.path.join(HISTORIA, "datos", "curso.json"), encoding="utf-8"))
    return {l["id"]: l for l in j["lugares"]}


def written_by(scene):
    """The story ids a generator writes, in the order it writes them (its json.dump calls)."""
    src = open(os.path.join(HISTORIA, "tools", "gen_%s.py" % scene), encoding="utf-8").read()
    ids = re.findall(r'json\.dump\(\w+,open\("cuentos/([a-z0-9-]+)\.json","w"', src)
    if len(ids) != 3:
        raise Refused("gen_%s.py: expected three story files, found %d json.dump calls" % (scene, len(ids)))
    return ids


def generate(last_place):
    """Runs every generator up to the last one of [last_place]; returns {scene: [story ids]} and each generator's summary line.
    The files are left in historia/cuentos/ (the caller cleans)."""
    stop = PLACE_IDS.index(last_place)
    made, summary = {}, []
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
    for place, scenes in PLACES[: stop + 1]:
        for scene in scenes:
            before = set(status())
            r = subprocess.run([sys.executable, os.path.join(HISTORIA, "tools", "gen_%s.py" % scene)], cwd=ROOT,
                               capture_output=True, text=True, env=env)
            if r.returncode != 0:
                raise Refused("gen_%s.py failed:\n%s%s" % (scene, r.stdout, r.stderr))
            ids = written_by(scene)
            new = {l[3:] for l in set(status()) - before}
            want = {"historia/cuentos/%s.json" % i for i in ids}
            if new != want:
                raise Refused("gen_%s.py: changed %s under historia/, expected the new files %s" % (scene, sorted(new), sorted(want)))
            made[scene] = ids
            lines = [l for l in r.stdout.splitlines() if l.strip()]
            counts = [l for l in lines if "characters to record" in l]
            other = [l for l in lines if "characters to record" not in l]
            summary.append("gen_%s.py (%s): %s%s" % (scene, place, counts[-1] if counts else "(no count line)",
                                                     "".join("\n    " + l for l in other)))
    return made, summary


def clean(ignored_before):
    """Removes every file that appeared under historia/, puts back every file of it that was changed or removed, and removes any new
    ignored file (a __pycache__, say). Never git add, commit or push."""
    restore = []
    for line in status():
        code, path = line[:2], line[3:]
        full = os.path.join(ROOT, path)
        if code == "??":
            os.remove(full)
        else:
            restore.append(path)
    if restore:
        git("checkout", "HEAD", "--", *restore)
    for path in sorted(ignored() - ignored_before, reverse=True):
        full = os.path.join(ROOT, path)
        if os.path.isdir(full):
            shutil.rmtree(full)
        elif os.path.exists(full):
            os.remove(full)
    # directories the generators made and left empty
    for dirpath, dirnames, filenames in os.walk(HISTORIA, topdown=False):
        if not dirnames and not filenames and not os.listdir(dirpath):
            tracked = git("ls-files", "--", os.path.relpath(dirpath, ROOT)).strip()
            if not tracked:
                os.rmdir(dirpath)


def read(path):
    return open(path, "rb").read()


def overlay_text(places, made, stories):
    """The overlay's bytes: 2-space indent, the places in course order, one final newline."""
    lug, metas = {}, {}
    for place, scenes in PLACES:
        if place not in places:
            continue
        ids = [i for s in scenes for i in made[s]]
        lug[place] = ids
        for i in ids:
            st = stories[i]
            dots = st.get("dots")
            metas[i] = {"t": st["title"], "min": max(2, int(dots) - 3) if isinstance(dots, (int, float)) else 5}
    return (json.dumps({"lugares": lug, "cuentos": metas}, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def bundled():
    """The bundle as it is: the overlay's places and the story files in the folder."""
    j = json.load(open(OVERLAY, encoding="utf-8")) if os.path.exists(OVERLAY) else {"lugares": {}, "cuentos": {}}
    files = sorted(f for f in os.listdir(STORIES) if f.endswith(".json")) if os.path.isdir(STORIES) else []
    return j, files


def check_stories(places, made, stories, course, allow_missing):
    have = registry_scenes()
    problems, missing = [], []
    for place, scenes in PLACES:
        if place not in places:
            continue
        ids = [i for s in scenes for i in made[s]]
        name = course[place]["nombre"]
        for k, i in enumerate(ids):
            st = stories[i]
            if st.get("id") != i:
                problems.append("%s: its id is %r" % (i, st.get("id")))
            if st.get("place") != name:
                problems.append("%s: its place is %r, not %r" % (i, st.get("place"), name))
            if k + 1 < len(ids) and st.get("next") != ids[k + 1]:
                problems.append("%s: its next is %r, not %r" % (i, st.get("next"), ids[k + 1]))
            if not isinstance(st.get("title"), str) or not st["title"]:
                problems.append("%s: no title" % i)
            if st.get("scene") not in have:
                missing.append("%s (%s): scene %r is not in coqui_scenes scene folders" % (i, place, st.get("scene")))
    if problems:
        raise Refused("the generated stories do not fit the course:\n  " + "\n  ".join(problems))
    if missing and not allow_missing:
        raise Refused("scenes not ported yet (coqui_scenes scene folders have %s); --allow-missing-scenes for a test only:\n  %s"
                      % (", ".join(sorted(have)), "\n  ".join(missing)))
    return missing


def run(places, check, allow_missing):
    course = course_places()
    for p in places:
        if p not in PLACE_IDS:
            raise Refused("unknown place %r (one of %s)" % (p, ", ".join(PLACE_IDS)))
        if p not in course:
            raise Refused("place %r is not in historia/datos/curso.json" % p)
    places = [p for p in PLACE_IDS if p in places]

    if not places:
        if check:
            j, files = bundled()
            ok = j == {"lugares": {}, "cuentos": {}} and not files
            print("the bundle is empty: nothing to generate" if ok else "the overlay lists no place but %s" % (files or j))
            return 0 if ok else 1
        write_bundle(b'{\n  "lugares": {},\n  "cuentos": {}\n}\n', {})
        print("wrote the empty overlay; no bundled story")
        return 0

    dirty = status()
    if dirty:
        raise Refused("historia/ is not clean; commit, stash or remove these first (git status --porcelain historia/):\n  "
                      + "\n  ".join(dirty))
    ign = ignored()
    hidden = sorted(p for p in ign if p.startswith("historia/cuentos/"))
    if hidden:
        raise Refused("story files under historia/cuentos/ are hidden by an ignore rule; they would change what the generators see:\n  "
                      + "\n  ".join(hidden))

    code = 0
    try:
        made, summary = generate(places[-1])
        stories, raw = {}, {}
        for ids in made.values():
            for i in ids:
                path = os.path.join(HISTORIA, "cuentos", "%s.json" % i)
                raw[i] = read(path)
                stories[i] = json.loads(raw[i].decode("utf-8"))
        for line in summary:
            print(line)
        missing = check_stories(places, made, stories, course, allow_missing)
        for m in missing:
            print("NOT PORTED%s: %s" % ("" if check else " (allowed for this run)", m))
        text = overlay_text(places, made, stories)
        keep = {i: raw[i] for p, scenes in PLACES if p in places for s in scenes for i in made[s]}
        if check:
            code = compare(text, keep)
        else:
            write_bundle(text, keep)
            for i in keep:
                print("bundled cuentos/%s.json (%d bytes)" % (i, len(keep[i])))
            print("wrote %s: %s" % (os.path.relpath(OVERLAY, ROOT),
                                    ", ".join("%s %d" % (p, len(json.loads(text)["lugares"][p])) for p in places)))
    finally:
        clean(ign)
        left = status()
        if left:
            print("FAILED: historia/ is not clean after the run:\n  " + "\n  ".join(left), file=sys.stderr)
            code = 1
        else:
            print("historia/ is clean again (git status --porcelain historia/ is empty)")
    return code


def write_bundle(text, keep):
    os.makedirs(STORIES, exist_ok=True)
    for f in os.listdir(STORIES):
        if f.endswith(".json") and f[:-5] not in keep:
            os.remove(os.path.join(STORIES, f))
    for i, b in keep.items():
        with open(os.path.join(STORIES, "%s.json" % i), "wb") as f:
            f.write(b)
    with open(OVERLAY, "wb") as f:
        f.write(text)


def compare(text, keep):
    j, files = bundled()
    diffs = []
    if not os.path.exists(OVERLAY) or read(OVERLAY) != text:
        diffs.append("the overlay curso.json is not what the generators give now")
    for i, b in keep.items():
        path = os.path.join(STORIES, "%s.json" % i)
        if not os.path.exists(path):
            diffs.append("cuentos/%s.json is not bundled" % i)
        elif read(path) != b:
            diffs.append("cuentos/%s.json differs from what gen_*.py makes now" % i)
    for f in files:
        if f[:-5] not in keep:
            diffs.append("cuentos/%s is bundled but no listed place has it" % f)
    if diffs:
        print("STALE:\n  " + "\n  ".join(diffs))
        return 1
    print("the bundle is what the generators make now (%d stories)" % len(keep))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0], formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--places", help="comma-separated place ids (%s), or none" % ",".join(PLACE_IDS))
    g.add_argument("--check", action="store_true", help="say whether the bundled files are what the generators make now")
    ap.add_argument("--allow-missing-scenes", action="store_true",
                    help="bundle a place whose scenes are not in coqui_scenes scene folders (a test of the mechanism only)")
    a = ap.parse_args()
    if a.check:
        j, _ = bundled()
        places = list(j.get("lugares", {}).keys())
    else:
        places = [] if a.places.strip() == "none" else [p.strip() for p in a.places.split(",") if p.strip()]
    try:
        return run(places, a.check, a.allow_missing_scenes or a.check)
    except Refused as e:
        print("make_previa: " + str(e), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
