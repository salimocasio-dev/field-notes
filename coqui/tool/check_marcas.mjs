#!/usr/bin/env node
// Order 04, proof: historia/audio/marcas.json against what the old page computes in Chrome, for EVERY clip.
// WHY THE RULE IS TWO RULES: the marks are made at each file's own rate (24 kHz), the one reading every device agrees on.
// The old page resampled to the device's rate first, so its marks moved with the device (44.1 against 48 kHz: up to 21 ms).
//
//   node coqui/tool/check_marcas.mjs [--rates=default,24000]
//
// Serves this worktree on a free local port, opens a page in headless Chrome (Playwright, which is installed
// globally here), decodes every clip of historia/audio/ready.json with AudioContext.decodeAudioData exactly as
// juego.js's loadVoice() does, and applies juego.js's own trim() to each buffer. trim() is not copied: its text is
// cut out of historia/juego.js (from `function trim(` to its closing brace) and run in the page.
// Chrome gives seconds at the AudioContext's sample rate (clips are 24 kHz, decodeAudioData resamples them to the
// context's rate), marcas.json gives whole milliseconds at the clip's own rate. Per clip and per mark the
// difference is  Chrome - marcas.json  in ms; the script prints, for start, end and length, the largest
// difference, the mean, and how many clips fall in each band, then the worst clips.
// Pass rule (exit 1 otherwise; also exit 1 when a clip of ready.json has no marks or marcas.json has an extra one):
//   AudioContext at 24000 Hz (the clips' own rate, nothing is resampled): every clip within 1 ms on start, end and
//     length. Hard fail otherwise.
//   AudioContext at any other rate (the browser's default is 44100 or 48000): the table is printed, and it fails only
//     if any clip differs by more than 40 ms on a mark, or the mean difference of a mark is more than 2 ms from 0.
//     (Misses of 5 to 31 ms are expected: the hiss at some clips' tails sits just under the 0.012 threshold, and
//     resampling moves it across. A mean away from 0 or a 40 ms miss would mean a real decoder offset.)
// --rates: sample rates to try for the AudioContext. Default: `default,24000`: the browser's own rate (a device's
// output rate, 44100 or 48000), and the clips' own rate (24000), where decodeAudioData does not resample.
// With more than one rate it also prints how far the old page's own trim() moves between the rates.
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const arg = (name, dflt) => { const a = process.argv.find((x) => x.startsWith(`--${name}=`)); return a ? a.slice(name.length + 3) : dflt; };
const NATIVE = 24000;       // the clips' own sample rate
const STRICT_MS = 1;        // at NATIVE: every clip, every mark
const RESAMPLED_MAX_MS = 40, RESAMPLED_MEAN_MS = 2;   // at any other rate
const NOTE_MS = 5;          // only for the printed counts
const RATES = arg('rates', 'default,24000').split(',').map((r) => (r === 'default' ? null : Number(r)));

// ---- trim(), as the old page has it ----------------------------------------------------------------------
const juego = fs.readFileSync(path.join(ROOT, 'historia', 'juego.js'), 'utf8');
const at = juego.indexOf('function trim(');
if (at < 0 || juego.indexOf('function trim(', at + 1) >= 0) { console.error('check_marcas: expected exactly one `function trim(` in historia/juego.js'); process.exit(1); }
let depth = 0, end = -1;
for (let i = juego.indexOf('{', at); i < juego.length; i++) { if (juego[i] === '{') depth++; else if (juego[i] === '}' && --depth === 0) { end = i + 1; break; } }
const TRIM = juego.slice(at, end);

const ready = JSON.parse(fs.readFileSync(path.join(ROOT, 'historia', 'audio', 'ready.json'), 'utf8'));
const marcas = JSON.parse(fs.readFileSync(path.join(ROOT, 'historia', 'audio', 'marcas.json'), 'utf8'));

const PAGE = `<!doctype html><meta charset="utf-8"><title>marcas</title>
<script>${TRIM}</script>
<script>
// loadVoice() of juego.js: fetch the mp3, decodeAudioData, trim(). Here the rate of the context can be chosen.
window.measure = async (ids, rate, v) => {
  const A = new (window.AudioContext || window.webkitAudioContext)(rate ? { sampleRate: rate } : undefined);
  const out = [];
  for (let k = 0; k < ids.length; k += 16) {
    out.push(...await Promise.all(ids.slice(k, k + 16).map(async (id) => {
      const b = await (await fetch('/historia/audio/' + id + '.mp3?v=' + v)).arrayBuffer();
      const t = trim(await new Promise((ok, no) => A.decodeAudioData(b, ok, no)));
      return [id, t.t0 * 1000, t.t1 * 1000, t.buf.duration * 1000, t.buf.sampleRate, t.buf.numberOfChannels];
    })));
  }
  const sr = A.sampleRate; await A.close(); return { sr, out };
};
</script>`;

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  if (url.pathname === '/') { res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' }); res.end(PAGE); return; }
  const file = path.normalize(path.join(ROOT, decodeURIComponent(url.pathname)));
  if (!file.startsWith(ROOT + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'content-type': file.endsWith('.mp3') ? 'audio/mpeg' : 'application/octet-stream', 'cache-control': 'no-store' });
  fs.createReadStream(file).pipe(res);
});
await new Promise((ok) => server.listen(0, '127.0.0.1', ok));
const port = server.address().port;

const { chromium } = createRequire(import.meta.url)('playwright');
const browser = await chromium.launch();
let bad = 0;
const byRate = [];
try {
  const page = await browser.newPage();
  await page.goto(`http://127.0.0.1:${port}/`);
  console.log(`Chrome ${browser.version()}; ${ready.clips.length} clips in ready.json, ${Object.keys(marcas).length} in marcas.json`);
  const missing = ready.clips.filter((id) => !marcas[id]);
  if (missing.length) { console.log(`MISSING from marcas.json: ${missing.join(', ')}`); bad++; }
  const extra = Object.keys(marcas).filter((id) => !ready.clips.includes(id));
  if (extra.length) { console.log(`in marcas.json but not in ready.json: ${extra.join(', ')}`); bad++; }
  for (const rate of RATES) {
    const { sr, out } = await page.evaluate(([ids, r, v]) => window.measure(ids, r, v), [ready.clips.filter((id) => marcas[id]), rate, ready.v || 0]);
    byRate.push({ sr, out });
    const fields = [['start', 1], ['end', 2], ['length', 3]];
    const rows = out.map(([id, t0, t1, dur, , ch]) => ({ id, ch, d: [t0 - marcas[id][0], t1 - marcas[id][1], dur - marcas[id][2]] }));
    console.log(`\nAudioContext sample rate ${sr} Hz (${rate ? 'asked for' : 'the browser default'}); ${rows.length} clips decoded; channels seen: ${[...new Set(rows.map((r) => r.ch))].join(',')}`);
    console.log('difference = Chrome - marcas.json, in ms (marcas.json is whole ms, so about 0.5 is rounding)');
    console.log('            max|d|   mean d    <=0.5    <=1      <=2      <=5      >5   (clips per band)');
    const bands = [0.5, 1, 2, 5];
    fields.forEach(([name], f) => {
      const ds = rows.map((r) => r.d[f]), abs = ds.map(Math.abs);
      const cnt = bands.map((b, i) => abs.filter((x) => x <= b && (i === 0 || x > bands[i - 1])).length);
      const over = abs.filter((x) => x > 5).length;
      console.log(`${name.padEnd(8)} ${Math.max(...abs).toFixed(3).padStart(8)} ${(ds.reduce((a, b) => a + b, 0) / ds.length).toFixed(3).padStart(8)}  ${[...cnt, over].map((c) => String(c).padStart(7)).join(' ')}   largest: ${rows[abs.indexOf(Math.max(...abs))].id}`);
    });
    const worst = rows.map((r) => ({ id: r.id, m: Math.max(...r.d.map(Math.abs)), d: r.d })).sort((a, b) => b.m - a.m).slice(0, 5);
    console.log('worst clips: ' + worst.map((w) => `${w.id} (${w.d.map((x) => x.toFixed(2)).join(' / ')})`).join('; '));
    const list = (rs) => rs.slice(0, 10).map((r) => r.id).join(', ') + (rs.length > 10 ? ', ...' : '');
    if (sr === NATIVE) {
      const over = rows.filter((r) => r.d.some((x) => Math.abs(x) > STRICT_MS));
      if (over.length) { bad++; console.log(`FAIL: ${over.length} clips differ by more than ${STRICT_MS} ms at ${NATIVE} Hz: ${list(over)}`); }
      else console.log(`PASS: at ${NATIVE} Hz every clip is within ${STRICT_MS} ms on start, end and length`);
    } else {
      const far = rows.filter((r) => r.d.some((x) => Math.abs(x) > RESAMPLED_MAX_MS));
      const means = fields.map((_, f) => rows.reduce((a, r) => a + r.d[f], 0) / rows.length);
      const offset = means.some((m) => Math.abs(m) > RESAMPLED_MEAN_MS);
      const near = rows.filter((r) => r.d.some((x) => Math.abs(x) > NOTE_MS)).length;
      if (far.length || offset) { bad++; console.log(`FAIL: ${far.length} clips differ by more than ${RESAMPLED_MAX_MS} ms (${list(far)}); mean differences ${means.map((m) => m.toFixed(3)).join(' / ')} ms (limit +-${RESAMPLED_MEAN_MS})`); }
      else console.log(`PASS (resampled rate): no clip differs by more than ${RESAMPLED_MAX_MS} ms, no mean is more than ${RESAMPLED_MEAN_MS} ms from 0 (${near} clips differ by more than ${NOTE_MS} ms: expected, see the header)`);
    }
  }
  for (let a = 0; a < byRate.length; a++) for (let b = a + 1; b < byRate.length; b++) {
    const A = byRate[a], B = byRate[b];
    const d = (f) => A.out.map((r, i) => Math.abs(r[f] - B.out[i][f]));
    const n = (f) => d(f).filter((x) => x > NOTE_MS).length;
    console.log(`\nold trim() at ${A.sr} Hz against old trim() at ${B.sr} Hz: start max ${Math.max(...d(1)).toFixed(3)} ms (${n(1)} clips over ${NOTE_MS}), end max ${Math.max(...d(2)).toFixed(3)} ms (${n(2)} clips over ${NOTE_MS})`);
  }
} finally {
  await browser.close();
  server.close();
}
process.exit(bad ? 1 : 0);
