# Puts the stretches of a whole-page picture together (tool/app_shots.mjs).
#   python3 -I tool/stitch_shots.py <out.png> <step in device px> <part0.png> <part1.png> ...
# Each part is the tall view after one more wheel step. The page moves by `step` between parts, except the last,
# which moves by less (the end of the page): its real shift is found by matching rows against the part before.
# The result is the first part's top `step` rows of each part, then the whole last part.
import sys

import numpy as np
from PIL import Image

out, step, paths = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
imgs = [np.asarray(Image.open(p).convert('RGB')).astype(np.int16) for p in paths]
h = imgs[0].shape[0]
# the band to match on: the top half of the view, clear of the tab bar at its foot
band = slice(0, h // 2)


def shift(a, b):
    """How far b is scrolled from a: the d for which b's rows [0, h/2) equal a's rows [d, d + h/2)."""
    exact = np.abs(a[step:step + h // 2] - b[band]).mean() if step + h // 2 <= h else None
    if exact is not None and exact == 0:
        return step, 0.0
    # a row's signature: its colours summed over a few columns; matched as 1-D runs first, then checked whole
    sa = a[:, ::7].sum(axis=(1, 2)).astype(np.int64)
    sb = b[band][:, ::7].sum(axis=(1, 2)).astype(np.int64)
    n = len(sb)
    cands = sorted(range(0, h - n + 1), key=lambda d: np.abs(sa[d:d + n] - sb).sum())[:5]
    best, best_d = None, 0
    for d in cands:
        diff = np.abs(a[d:d + n] - b[band]).mean()
        if best is None or diff < best:
            best, best_d = diff, d
    return best_d, best


rows = []
y = 0
for i in range(len(imgs) - 1):
    d, err = shift(imgs[i], imgs[i + 1])
    rows.append(imgs[i][:d])
    y += d
    if err > 1:
        print(f'part {i + 1}: rows matched with a mean difference of {err:.2f}')
rows.append(imgs[-1])
full = np.concatenate(rows, axis=0).astype(np.uint8)
Image.fromarray(full).save(out)
print(f'{out}: {full.shape[1]} x {full.shape[0]}')
