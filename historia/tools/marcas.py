"""The start and end marks of every recorded clip: historia/audio/marcas.json.
The marks are made at each file's own sample rate (24 kHz), the one reading every device agrees on. The old page
resampled to the device's rate first, so its marks moved with the device (44.1 against 48 kHz: up to 21 ms).

    {"<clip id>": [startMs, endMs, lengthMs], ...}      sorted by id, one clip per line

The rule is juego.js's trim(), read from the code (the recordings carry silence at both ends):
    d = channel 0 of the decoded clip, sr = its sample rate, th = 0.012
    i = the first sample with abs(d[i]) >= th, j = the last one (when none is, i and j end where the loops stop:
        i = j = the last sample, as in the old loops)
    start = max(0, i/sr - 0.030)          end = min(length, j/sr + 0.100)          length = samples/sr
Each is turned into whole milliseconds, rounded to the nearest (halves up).
The clip is decoded by ffmpeg at its own sample rate, as 32-bit floats, without any other processing.

    python3 historia/tools/marcas.py            the marks of every clip in ready.json that has none;
                                                a clip that is no longer in ready.json loses its marks
    python3 historia/tools/marcas.py a b        those clips again, too
    python3 historia/tools/marcas.py --all      every clip again

A clip is "changed" when voz.py has just made it: voz.py calls update() with the ids it recorded. marcas.json keeps no
fingerprint of the mp3, so a file replaced by hand has to be named here, or use --all.
marcas.json is written only when its text changes.
Needs ffmpeg and ffprobe on the PATH; nothing else.
"""
import json, os, subprocess, sys
from array import array
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # historia/
AUDIO = os.path.join(HERE, "audio")
THRESHOLD = 0.012   # juego.js trim(): th
LEAD_MS = 30        # silence kept before the first loud sample
TAIL_MS = 100       # and after the last one


def _run(cmd):
    try:
        done = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    except FileNotFoundError:
        raise RuntimeError(f"{cmd[0]} is not installed: marks are made by decoding the clips with ffmpeg")
    if done.returncode != 0:
        raise RuntimeError(f"{cmd[0]} failed on {cmd[-1]}: {done.stderr.decode('utf-8', 'replace').strip()[:300]}")
    return done.stdout


def decode(path):
    """(samples of channel 0 as floats, sample rate) of one clip, as the browser's decodeAudioData gives them before any resampling."""
    info = json.loads(_run(["ffprobe", "-v", "error", "-select_streams", "a:0",
                            "-show_entries", "stream=sample_rate,channels", "-of", "json", path]))["streams"][0]
    rate, channels = int(info["sample_rate"]), int(info["channels"])
    raw = _run(["ffmpeg", "-v", "error", "-i", path, "-map", "0:a:0", "-f", "f32le", "-"])
    samples = array("f")
    samples.frombytes(raw[: len(raw) // 4 * 4])
    if sys.byteorder == "big":
        samples.byteswap()
    return samples[0::channels], rate


def rounded(ms):
    return int(ms + 0.5)   # ms is never negative


def marks(path):
    """[startMs, endMs, lengthMs] of one clip."""
    d, sr = decode(path)
    n = len(d)
    if n == 0:
        return [0, 0, 0]
    i, j = 0, n - 1
    while i < j and abs(d[i]) < THRESHOLD:
        i += 1
    while j > i and abs(d[j]) < THRESHOLD:
        j -= 1
    length = n * 1000 / sr
    start = max(0.0, i * 1000 / sr - LEAD_MS)
    end = min(length, j * 1000 / sr + TAIL_MS)
    return [rounded(start), rounded(end), rounded(length)]


def ready_ids(audio=AUDIO):
    return list(json.load(open(os.path.join(audio, "ready.json"), encoding="utf-8"))["clips"])


def text(table):
    lines = [f"  {json.dumps(k, ensure_ascii=False)}: {json.dumps(table[k])}" for k in sorted(table)]
    return "{\n" + ",\n".join(lines) + "\n}\n" if lines else "{}\n"


def update(ids=(), everything=False, audio=AUDIO):
    """Brings marcas.json in line with ready.json: marks for the clips named in ids (again), for every clip when
    everything is true, and for every clip that has none; drops the clips ready.json no longer lists.
    Returns the number of clips that were measured."""
    ready = ready_ids(audio)
    listed, asked = set(ready), set(ids)
    path = os.path.join(audio, "marcas.json")
    try:
        table = json.load(open(path, encoding="utf-8"))
    except FileNotFoundError:
        table = {}
    table = {k: v for k, v in table.items() if k in listed}
    if asked - listed:
        raise RuntimeError("not in ready.json: " + ", ".join(sorted(asked - listed)))
    todo = list(ready) if everything else [c for c in ready if c in asked or c not in table]
    with ThreadPoolExecutor(max_workers=min(8, os.cpu_count() or 2)) as pool:
        for cid, m in zip(todo, pool.map(lambda c: marks(os.path.join(audio, c + ".mp3")), todo)):
            table[cid] = m
    out = text(table)
    try:
        same = open(path, encoding="utf-8").read() == out
    except FileNotFoundError:
        same = False
    if not same:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(out)
    return len(todo)


def main(argv):
    everything = "--all" in argv
    ids = [a for a in argv if not a.startswith("--")]
    if any(a.startswith("--") and a != "--all" for a in argv):
        sys.exit(__doc__)
    try:
        n = update(ids, everything)
    except RuntimeError as e:
        sys.exit(f"marcas: {e}")
    print(f"marks made for {n} clips; {len(json.load(open(os.path.join(AUDIO, 'marcas.json'), encoding='utf-8')))} in marcas.json")


if __name__ == "__main__":
    main(sys.argv[1:])
