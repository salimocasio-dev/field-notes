#!/usr/bin/env node
// Every ask of La nevera's recorded runs, as docs/proyecto/pixel/nevera-preview.html shows it, for test/nevera_asks_test.dart:
// the asked thing's box (the hint frame's: juego.js respBox, else the preview's hb: the sheet's hint box by state, or the
// hint box, else the scene's box), the hint hand's point (juego.js: respBox's foot, else E.handAt), and how many of the
// thing's drawn pixels lie outside that box (the frame drawn with the thing, against the frame drawn without it). An ask is
// every `ask` and `decide` step of every run (right, wrong, alternate) of the four stories (no-hay-leche, para-los-pajaros,
// jugo-de-china, h-nevera); its W is the run's W before the step, in old positions, with the step's signs set as juego.js
// sets them (PREVIEW.askW), moved to the new places by the preview's own rule (PREVIEW.remapW, the story's id given). And
// every ask picture of the app's two plays of each story (the frames tool's right and wrong learner, which pokes and picks
// otherwise than the recorded runs): the Dart story's W at that moment, in the new places with its signs set, drawn by the
// preview as it is (no remap).
// Also, for the people outside the window (the sheet's clips.patio), every step's end of every run: each distinct set of
// whoever stands outside (with the yard's things and the set's state), moved by the preview's rule, and how many of the
// pixels they draw lie outside the window's opening (the set's zone o) in the preview: test/nevera_asks_test.dart draws
// each again and counts the same.
//
//   node coqui/tool/ref/trazas/juega.mjs --only <story> --states DIR    (for each of the four stories)
//   cd coqui/app && flutter test tool/gate_a_frames_test.dart --dart-define=OUT=PLAYS \
//     --dart-define=STORIES=no-hay-leche,para-los-pajaros,jugo-de-china,h-nevera --dart-define=TXT=no --dart-define=ASKW=yes
//   node tool/nevera_asks_ref.mjs --states DIR --plays PLAYS [--check]  (in this package) writes
//                                                                       test/support/fixtures/nevera_asks_fixture.dart
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const arg = k => { const i = process.argv.indexOf(k); return i < 0 ? null : process.argv[i + 1]; };
const STATES = arg('--states'), PLAYS = arg('--plays'), CHECK = process.argv.includes('--check');
const PKG = process.cwd(), ROOT = path.resolve(PKG, '../../../..');
const OUT = path.join(PKG, 'test/support/fixtures/nevera_asks_fixture.dart');
if (!STATES || !PLAYS || !fs.existsSync(path.join(ROOT, 'docs/proyecto/pixel/nevera-preview.html'))) { console.error('usage (in coqui/packages/core/coqui_scenes): node tool/nevera_asks_ref.mjs --states DIR --plays DIR [--check]'); process.exit(2); }
const STORIES = ['no-hay-leche', 'para-los-pajaros', 'jugo-de-china', 'h-nevera'], PLANS = ['right', 'wrong', 'alternate'];

const asks = [];
for (const st of STORIES) {
  const story = JSON.parse(fs.readFileSync(path.join(ROOT, `historia/cuentos/${st}.json`), 'utf8'));
  for (const plan of PLANS) {
    const lines = fs.readFileSync(path.join(STATES, st, plan + '.states.jsonl'), 'utf8').trim().split('\n').map(l => JSON.parse(l));
    lines.forEach((s, i) => {
      if (s.kind !== 'ask' && s.kind !== 'decide') return;
      const step = s.path.split('.').reduce((o, k) => o[/^\d+$/.test(k) ? +k : k], story);
      // the state before the step began: the line before its first own line (the step's then and after lines are written
      // before the step's own)
      let j = i;
      while (j > 0 && lines[j - 1].path && lines[j - 1].path.startsWith(s.path + '.')) j--;
      asks.push({ story: st, plan, path: s.path, F: Math.floor(lines[j - 1].t / 70), step, W: lines[j - 1].W, V: lines[j - 1].V });
    });
  }
}

// the app's plays (coqui/app tool/gate_a_frames_test.dart --dart-define=ASKW=yes, the four stories): every ask picture,
// with the Dart story's W at that moment (in the new places, its signs set) and its frame number
const plays = [];
for (const st of STORIES) for (const plan of ['right', 'wrong']) {
  const ix = JSON.parse(fs.readFileSync(path.join(PLAYS, `${st}-${plan}`, 'index.json'), 'utf8'));
  if (!ix.reachedEnd) { console.error(`${st}-${plan}: the play did not reach its end`); process.exit(1); }
  for (const p of ix.pictures) if (p.kind === 'ask') {
    if (!p.askW) { console.error(`${st}-${plan} ${p.file}: no askW (play with --dart-define=ASKW=yes)`); process.exit(1); }
    plays.push({ story: st, plan: 'play-' + plan, path: p.file.replace(/\.png$/, ''), F: p.askF, W: p.askW, waitingFor: p.waitingFor });
  }
}

const srv = http.createServer((req, res) => {
  const f = path.join(ROOT, decodeURIComponent(new URL(req.url, 'http://x').pathname));
  if (!f.startsWith(ROOT + path.sep) || !fs.existsSync(f) || !fs.statSync(f).isFile()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': f.endsWith('.html') ? 'text/html; charset=utf-8' : f.endsWith('.js') ? 'text/javascript' : 'application/json', 'Cache-Control': 'no-store' });
  fs.createReadStream(f).pipe(res);
});
await new Promise(r => srv.listen(0, '127.0.0.1', r));
const browser = await chromium.launch();
const page = await browser.newPage();
const errs = [];
page.on('pageerror', e => errs.push(String(e)));
await page.goto(`http://127.0.0.1:${srv.address().port}/docs/proyecto/pixel/nevera-preview.html`);
await page.evaluate(() => window.PREVIEW.done);

// every step's end of every run: the distinct sets of whoever stands outside the window (with the yard and the set's state)
const outsideCases = [], seenOut = new Set();
for (const st of STORIES) for (const plan of PLANS) {
  const lines = fs.readFileSync(path.join(STATES, st, plan + '.states.jsonl'), 'utf8').trim().split('\n').map(l => JSON.parse(l));
  for (const s of lines) {
    const G = s.W.gente || {}, out = Object.keys(G).filter(id => G[id] && G[id].fuera && G[id].vis !== 0);
    if (!out.length) continue;
    const key = JSON.stringify([st, out.map(id => [id, G[id]]), s.W.patio, s.W.nev, s.W.pila, s.W.banco]);
    if (seenOut.has(key)) continue;
    seenOut.add(key);
    outsideCases.push({ story: st, plan, path: s.path, F: Math.floor(s.t / 70), W: s.W });
  }
}

const rows = [], missing = [], skipped = [], outside = [];
for (const a of [...asks, ...plays]) {
  const r = await page.evaluate(async ([a]) => {
    const PV = window.PREVIEW, S = PV.SHEET, R = Math.round;
    let w0, w;
    if (a.step) {
      w0 = PV.askW(JSON.parse(JSON.stringify(a.W)), a.step, a.V, null);
      if (!w0 || !w0.spot) return null;
      PV.story = { id: a.story };
      w = PV.remapW(w0);
      PV.story = null;
    } else {
      // a play's W is already in the new places with its signs; the asked thing is its spot, or, where no hint shows yet
      // (a decide that leaves the child free, a routine's ask), the thing the learner waits to touch
      w0 = JSON.parse(JSON.stringify(a.W));
      W = w0; cam = [28, 0, 196, 216]; E = ESCENAS.nevera;
      if (!w0.spot) { if (!respBox(a.waitingFor) && !E.box(a.waitingFor, w0)) return { skip: a.waitingFor }; w0.spot = a.waitingFor; }
      w = w0;
    }
    // the preview's hint frame (PV.render, signs: respBox, else hb) and hand (respBox's foot, else E.handAt)
    W = w; cam = [28, 0, 196, 216]; E = ESCENAS.nevera;
    const k = w.spot, rb = respBox(k), t = S.things[k];
    const hb = kk => { const tt = S.things[kk]; if (tt && tt.hintBoxes) { const st = PV.keyOf(W); return tt.hintBoxes[kk === 'nevera' ? +st[0] : st.startsWith('1.2') ? 1 : 0]; } return (tt && tt.hintBox) || bx(kk); };
    // (a thing that is not there yet before the step: its box throws in the old code too; the step's own acts bring it)
    let box, hand;
    try { box = rb || hb(k); hand = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : E.handAt[k]; } catch (e) { return { spot: k, missing: String(e).slice(0, 80) }; }
    // the thing's pixels: the frame drawn with it, against the frame drawn without it (things of the sprite layer only)
    const without = JSON.parse(JSON.stringify(w)), G = without.gente || {};
    const inNev = () => { const h = (without.nev && without.nev.h) || []; h.forEach((o, i) => { if (o && o.k === k) h[i] = null; }); };
    const byId = () => { (without.cosas || []).forEach(o => { if (o && o.id === k) o.vis = 0; }); };
    const take = { leche: inNev, queso: inNev, mantequilla: inNev, cesta: () => { without.cesta = null; } };
    const named = (w.cosas || []).some(o => o && o.id === k);
    let outside = null, drawn = null;
    const pix = async ww => { await PV.render(ww, { F: a.F, remap: false }); return c.getImageData(0, 0, 240, 216).data; };
    if (!rb && (take[k] || named || (G[k] && G[k].vis !== 0))) {
      if (take[k]) take[k](); else if (named) byId(); else G[k].vis = 0;
      const p = await pix(w), q = await pix(without);
      outside = 0; drawn = 0;
      for (let i = 0; i < 240 * 216; i++) {
        const j = i * 4;
        if (p[j] === q[j] && p[j + 1] === q[j + 1] && p[j + 2] === q[j + 2]) continue;
        drawn++;
        const x = i % 240, y = (i / 240) | 0;
        if (!(x >= box[0] && x < box[0] + box[2] && y >= box[1] && y < box[1] + box[3])) outside++;
      }
    }
    return { spot: k, card: !!rb, box, hand: hand && [R(hand[0]), R(hand[1])], drawn, outside, moved: !a.step, W: w0 };
  }, [a]);
  if (!r) continue;
  if (r.skip) { skipped.push(`${a.story} ${a.plan} ${a.path} ${r.skip}`); continue; }
  if (r.missing) { missing.push(`${a.story} ${a.plan} ${a.path} ${r.spot}: ${r.missing}`); continue; }
  rows.push(Object.assign({ story: a.story, plan: a.plan, path: a.path, F: a.F }, r));
}
for (const a of outsideCases) {
  const r = await page.evaluate(async ([a]) => {
    const PV = window.PREVIEW;
    PV.story = { id: a.story };
    const w = PV.remapW(PV.baseW(JSON.parse(JSON.stringify(a.W))));
    PV.story = null;
    // only whoever stands outside, the yard and the set's state: everything else of the sprite layer taken out
    const only = Object.assign(PV.baseW({}), { gente: {}, nev: w.nev, pila: w.pila, banco: w.banco, patio: w.patio });
    only.cq.vis = 0;
    for (const [id, p] of Object.entries(w.gente || {})) if (p && p.fuera && p.vis !== 0) only.gente[id] = p;
    const none = Object.assign(JSON.parse(JSON.stringify(only)), { gente: {} });
    const pix = async ww => { await PV.render(ww, { F: a.F, remap: false }); return c.getImageData(0, 0, 240, 216).data; };
    const p = await pix(only), q = await pix(none);
    const fr = await (async () => { const k = PV.keyOf(only); return k; })();
    let drawn = 0, out = 0;
    for (let i = 0; i < 240 * 216; i++) {
      const j = i * 4;
      if (p[j] === q[j] && p[j + 1] === q[j + 1] && p[j + 2] === q[j + 2]) continue;
      drawn++;
    }
    return { W: only, key: fr, drawn };
  }, [a]);
  outside.push(Object.assign({ story: a.story, plan: a.plan, path: a.path, F: a.F }, r));
}
// the zones of every state the preview baked (nevera-set.html zones(), its iframes'): each state's zone string's length and
// a checksum of it, the outside's pixel count and the sum of their indices
const zones = await page.evaluate(() => [...document.querySelectorAll('iframe')].filter(f => f.ZONES).map(f => {
  const q = new URLSearchParams(f.src.split('?')[1]), z = f.ZONES;
  let sum = 0; for (let i = 0; i < z.zone.length; i++) sum = (sum * 31 + z.zone.charCodeAt(i)) % 1000000007;
  return { key: [q.get('nev'), q.get('cajon'), q.get('pila'), q.get('banco')].join('.'), zone: sum, outside: z.outside.length, outsideSum: z.outside.reduce((a, b) => a + b, 0) };
}).sort((a, b) => a.key < b.key ? -1 : 1));
await browser.close();
srv.close();
if (errs.length) { console.error(errs.join('\n')); process.exit(1); }
const made = [
  '// Made by tool/nevera_asks_ref.mjs from docs/proyecto/pixel/nevera-preview.html in headless Chrome. Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  '/// Every ask of La nevera\'s recorded runs and of the app\'s plays: where, the W before it (the step\'s signs set: old',
  '/// positions, or the play\'s own), and what the preview shows: the hint frame\'s box, the hand\'s point, the thing\'s drawn',
  '/// pixels and how many of them lie outside the box.',
  'const String neveraAsks =',
  "    r'''" + JSON.stringify(rows) + "''';",
  '',
  '/// Every distinct set of whoever stands outside the window at a step\'s end of the recorded runs: their W (moved by the',
  '/// preview\'s rule, nothing else of the sprite layer in it) and how many pixels the preview draws for them.',
  'const String neveraOutside =',
  "    r'''" + JSON.stringify(outside) + "''';",
  '',
  '/// The zones of each state the preview baked (nevera-set.html zones()): a checksum of the zone string, the outside\'s',
  '/// pixel count and the sum of their indices.',
  'const String neveraZones =',
  "    r'''" + JSON.stringify(zones) + "''';",
  '',
].join('\n');
if (CHECK) {
  const same = fs.existsSync(OUT) && fs.readFileSync(OUT, 'utf8') === made;
  console.log(same ? 'nevera_asks_fixture.dart: up to date' : 'nevera_asks_fixture.dart: STALE');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(OUT, made);
console.log(`${rows.length} asks (${asks.length} ask and decide steps of the recorded runs, ${plays.length} ask pictures of the app's plays) and ${outside.length} sets of people outside in ${path.relative(PKG, OUT)}`);
for (const m of missing) console.log('not there before the step: ' + m);
for (const m of skipped) console.log('no thing of its name (left out): ' + m);
