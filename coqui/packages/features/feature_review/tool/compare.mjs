// Measures the pairs of tool/shots.mjs: for each screenshot and the old picture it is held against, the same
// numbers (in device pixels, from the pixels themselves): the picture block, the rings, the progress bar, the
// button, each line of text (rows of light pixels) and the colours at fixed points. Prints what differs.
//
//   node tool/compare.mjs [--shots <dir>] [--tol <px>]      (default: build/shots, tolerance 4 device px)
//
// The accepted differences are the reference's Inter against our Roboto (a line of text a little wider or
// narrower, its glyphs a pixel or two apart) and the grey boxes that stand for the pictures. Writes compare.json.
import { createRequire } from 'node:module';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');
const here = dirname(fileURLToPath(import.meta.url));
const pkg = resolve(here, '..');
const args = process.argv.slice(2);
const opt = (n, d) => {
  const i = args.indexOf(n);
  return i >= 0 && args[i + 1] ? args[i + 1] : d;
};
const shots = resolve(opt('--shots', join(pkg, 'build', 'shots')));
const tol = +opt('--tol', 4);
const pairs = JSON.parse(readFileSync(join(shots, 'pairs.json'), 'utf8')).pairs;

const browser = await chromium.launch();
const page = await browser.newPage();
await page.setContent('<body></body>');
const analyse = async (b64, dpr) =>
  page.evaluate(
    async ([b64, dpr]) => {
      const img = new Image();
      await new Promise((ok) => {
        img.onload = ok;
        img.src = 'data:image/png;base64,' + b64;
      });
      const W = img.naturalWidth, H = img.naturalHeight;
      const c = document.createElement('canvas');
      c.width = W; c.height = H;
      const g = c.getContext('2d');
      g.drawImage(img, 0, 0);
      const d = g.getImageData(0, 0, W, H).data;
      const px = (x, y) => { const i = (y * W + x) * 4; return [d[i], d[i + 1], d[i + 2]]; };
      const near = (p, q, t) => Math.abs(p[0] - q[0]) <= t && Math.abs(p[1] - q[1]) <= t && Math.abs(p[2] - q[2]) <= t;
      const BG = [0x1B, 0x1B, 0x1F], GREEN = [0x17, 0x80, 0x3F], BAD = [0xD9, 0x48, 0x0F], BLUE = [0x3B, 0x5B, 0xDB];
      const bbox = (pred, y0 = 0, y1 = H, x0 = 0, x1 = W) => {
        let a = W, b = H, e = -1, f = -1, n = 0;
        for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) if (pred(px(x, y))) { n++; if (x < a) a = x; if (x > e) e = x; if (y < b) b = y; if (y > f) f = y; }
        return n ? { x0: a, y0: b, x1: e, y1: f, n } : null;
      };
      const top = Math.round(56 * dpr);
      // the progress bar: dashes along its centre row
      const by = Math.round(28 * dpr);
      const runs = [];
      let cur = null;
      for (let x = Math.round(70 * dpr); x < W - Math.round(70 * dpr); x++) {
        const p = px(x, by);
        const on = !near(p, BG, 6);
        if (on && !cur) cur = { x0: x, green: near(p, GREEN, 10) };
        if (!on && cur) { cur.x1 = x - 1; runs.push(cur); cur = null; }
      }
      // lines of text: rows with light pixels (luma > 150) between the top bar and the foot
      const lines = [];
      let run = null;
      for (let y = top; y < H - Math.round(100 * dpr); y++) {
        let n = 0, xa = W, xb = -1;
        for (let x = Math.round(8 * dpr); x < W - Math.round(8 * dpr); x++) {
          const p = px(x, y);
          if (p[0] > 150 && p[1] > 150 && p[2] > 150 && Math.abs(p[0] - p[2]) < 40) { n++; if (x < xa) xa = x; if (x > xb) xb = x; }
        }
        if (n > 0 && !run) run = { y0: y, x0: xa, x1: xb };
        else if (n > 0) { run.x0 = Math.min(run.x0, xa); run.x1 = Math.max(run.x1, xb); }
        if (n === 0 && run) { run.y1 = y - 1; lines.push(run); run = null; }
      }
      return {
        W, H,
        bar: { dashes: runs.length, lit: runs.filter((r) => r.green).length, x0: runs[0] && runs[0].x0, x1: runs.length ? runs[runs.length - 1].x1 : null, w0: runs[0] && runs[0].x1 - runs[0].x0 + 1 },
        green: bbox((p) => near(p, GREEN, 8), top, H - Math.round(100 * dpr)),
        bad: bbox((p) => near(p, BAD, 8), top),
        button: bbox((p) => near(p, GREEN, 4) || near(p, BLUE, 4), H - Math.round(100 * dpr)),
        disc: bbox((p) => near(p, GREEN, 4), H - Math.round(100 * dpr)),
        lines: lines.filter((l) => l.y1 - l.y0 >= 4),
        colours: { bg: px(5, Math.round(H / 2)), top: px(Math.round(W / 2), 3) },
      };
    },
    [b64, dpr],
  );

const out = [];
let bad = 0;
for (const p of pairs) {
  const dpr = p.device.startsWith('android') ? 2.625 : 3;
  const a = await analyse(readFileSync(p.reference).toString('base64'), dpr);
  const b = await analyse(readFileSync(p.screenshot).toString('base64'), dpr);
  const diffs = [];
  const cmp = (what, x, y, t = tol) => {
    if (x == null && y == null) return;
    if (x == null || y == null) return diffs.push(`${what}: ${JSON.stringify(x)} vs ${JSON.stringify(y)}`);
    const dd = Math.abs(x - y);
    if (dd > t) diffs.push(`${what}: ${x} vs ${y} (${y - x > 0 ? '+' : ''}${y - x})`);
  };
  if (a.W !== b.W || a.H !== b.H) diffs.push(`size ${a.W}x${a.H} vs ${b.W}x${b.H}`);
  cmp('dashes', a.bar.dashes, b.bar.dashes, 0);
  for (const k of ['x0', 'x1', 'w0']) cmp(`bar ${k}`, a.bar[k], b.bar[k]);
  for (const key of ['bad', 'button', 'disc']) {
    const x = a[key], y = b[key];
    if (x && y) for (const k of ['x0', 'y0', 'x1', 'y1']) cmp(`${key} ${k}`, x[k], y[k]);
    else if (x || y) diffs.push(`${key}: ${x ? 'only in the old' : 'only in the new'}`);
  }
  // text lines of the screens that are text only (a picture has light pixels of its own): matched in order. The
  // caption of a picture screen is the lowest line above the foot.
  const la = a.lines.filter((l) => l.x1 - l.x0 > 20), lb = b.lines.filter((l) => l.x1 - l.x0 > 20);
  const textDiffs = [];
  const textOnly = /^(inicio|explicacion|resultado)/.test(p.state);
  const withPictures = /^(frase|tu-turno|toque|sin-toque|pregunta)/.test(p.state);
  const same = (l, m, i) => {
    for (const k of ['y0', 'y1', 'x0', 'x1']) if (Math.abs(l[k] - m[k]) > tol + 2) textDiffs.push(`line ${i} ${k}: ${l[k]} vs ${m[k]} (${m[k] - l[k] > 0 ? '+' : ''}${m[k] - l[k]})`);
  };
  if (textOnly) {
    if (la.length !== lb.length) textDiffs.push(`${la.length} lines in the old, ${lb.length} in the new`);
    else la.forEach((l, i) => same(l, lb[i], i));
  } else if (withPictures && la.length && lb.length) same(la[la.length - 1], lb[lb.length - 1], 'caption');
  cmp('background', a.colours.bg[0] * 65536 + a.colours.bg[1] * 256 + a.colours.bg[2], b.colours.bg[0] * 65536 + b.colours.bg[1] * 256 + b.colours.bg[2]);
  out.push({ device: p.device, state: p.state, diffs, text: textDiffs, ref: { bar: a.bar, green: a.green, bad: a.bad, button: a.button, lines: la }, mine: { bar: b.bar, green: b.green, bad: b.bad, button: b.button, lines: lb } });
  console.log(`${p.device} ${p.state}: ${diffs.length ? diffs.join('; ') : 'geometry equal'}${textDiffs.length ? '\n    text: ' + textDiffs.join('; ') : ''}`);
  bad += diffs.length;
}
await browser.close();
writeFileSync(join(shots, 'compare.json'), JSON.stringify(out, null, 1) + '\n');
console.log(`${out.length} pairs, ${bad} geometry differences over ${tol} px; ${join(shots, 'compare.json')}`);
