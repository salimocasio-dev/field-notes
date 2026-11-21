#!/usr/bin/env node
// Every ask of La estufa's recorded runs, as docs/proyecto/pixel/estufa-preview.html shows it, for test/estufa_asks_test.dart:
// the asked thing's box (the hint frame's: juego.js respBox, else the sheet's hint box, else the scene's box), the hint hand's
// point, and how many of the thing's drawn pixels lie outside that box (the frame drawn with the thing, against the frame
// drawn without it). An ask is every `ask` and `decide` step of every run (right, wrong, alternate) of the four stories
// (arroz-con-habichuelas, el-pollo-y-el-huevo, cuidado, h-estufa); its W is the run's W before the step, in old positions,
// with the step's signs set as juego.js sets them (PREVIEW.askW), moved to the new places by the preview's own rule
// (PREVIEW.remapW, the story's id given). And every ask picture of the app's two plays of each story (the frames tool's
// right and wrong learner, which pokes and picks otherwise than the recorded runs): the Dart story's W at that moment, in
// the new places with its signs set, drawn by the preview as it is (no remap).
//
//   node coqui/tool/ref/trazas/juega.mjs --only <story> --states DIR    (for each of the four stories)
//   cd coqui/app && flutter test tool/gate_a_frames_test.dart --dart-define=OUT=PLAYS \
//     --dart-define=STORIES=arroz-con-habichuelas,el-pollo-y-el-huevo,cuidado,h-estufa --dart-define=TXT=no --dart-define=ASKW=yes
//   node tool/estufa_asks_ref.mjs --states DIR --plays PLAYS [--check]  (in this package) writes
//                                                                       test/support/fixtures/estufa_asks_fixture.dart
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const arg = k => { const i = process.argv.indexOf(k); return i < 0 ? null : process.argv[i + 1]; };
const STATES = arg('--states'), PLAYS = arg('--plays'), CHECK = process.argv.includes('--check');
const PKG = process.cwd(), ROOT = path.resolve(PKG, '../../../..');
const OUT = path.join(PKG, 'test/support/fixtures/estufa_asks_fixture.dart');
if (!STATES || !PLAYS || !fs.existsSync(path.join(ROOT, 'docs/proyecto/pixel/estufa-preview.html'))) { console.error('usage (in coqui/packages/core/coqui_scenes): node tool/estufa_asks_ref.mjs --states DIR --plays DIR [--check]'); process.exit(2); }
const STORIES = ['arroz-con-habichuelas', 'el-pollo-y-el-huevo', 'cuidado', 'h-estufa'], PLANS = ['right', 'wrong', 'alternate'];

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
await page.goto(`http://127.0.0.1:${srv.address().port}/docs/proyecto/pixel/estufa-preview.html`);
await page.evaluate(() => window.PREVIEW.done);

const rows = [], missing = [], skipped = [];
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
      // (a decide that leaves the child free, a routine's ask), the thing the learner waits to touch; an option no thing
      // is named for (h-estufa's olla_fria, touched on olla0 by the step's alias) has no box of its own: left out
      w0 = JSON.parse(JSON.stringify(a.W));
      W = w0; cam = [22, 0, 196, 216];
      if (!w0.spot) { if (!respBox(a.waitingFor) && !E.box(a.waitingFor, w0)) return { skip: a.waitingFor }; w0.spot = a.waitingFor; }
      w = w0;
    }
    // the preview's hint frame and hand (PV.render, signs): respBox, else the sheet's hint box, else bx
    W = w; cam = [22, 0, 196, 216];
    const k = w.spot, rb = respBox(k), t = S.things[k];
    // (a thing that is not there yet before the step: its box throws in the old code too; the step's own acts bring it)
    let box;
    try { box = rb || (t && t.hintBox) || bx(k); } catch (e) { return { spot: k, missing: String(e).slice(0, 80) }; }
    const hand = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : t && t.hand ? t.hand : box ? [box[0] + box[2] / 2, box[1] + box[3] / 2] : null;
    // the thing's pixels: the frame drawn with it, against the frame drawn without it (things of the sprite layer only)
    const without = JSON.parse(JSON.stringify(w)), G = without.gente || {};
    const take = {
      olla0: () => { without.fuegos[0] = {}; }, olla1: () => { without.fuegos[1] = {}; }, sarten: () => { without.fuegos[0] = {}; },
      saco: () => { without.izq.saco = 0; }, tazon: () => { without.izq.tazon = 0; }, jarra: () => { without.izq.jarra = 0; }, bandeja: () => { without.izq.bandeja = null; },
      pzpollo: () => { without.plata.items = without.plata.items.filter(o => o.k !== 'muslo'); },
      pzhuevo: () => { without.plata.items = without.plata.items.filter(o => o.k !== 'frito'); },
    };
    let outside = null, drawn = null;
    const pix = async ww => { await PV.render(ww, { F: a.F, remap: false }); return c.getImageData(0, 0, 240, 216).data; };
    if (!rb && (take[k] || (G[k] && G[k].vis !== 0))) {
      if (take[k]) take[k](); else G[k].vis = 0;
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
await browser.close();
srv.close();
if (errs.length) { console.error(errs.join('\n')); process.exit(1); }
const made = [
  '// Made by tool/estufa_asks_ref.mjs from docs/proyecto/pixel/estufa-preview.html in headless Chrome. Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  '/// Every ask of La estufa\'s recorded runs: where, the W before it (old positions, the step\'s signs set), and what the',
  '/// preview shows: the hint frame\'s box, the hand\'s point, the thing\'s drawn pixels and how many of them lie outside the box.',
  'const String estufaAsks =',
  "    r'''" + JSON.stringify(rows) + "''';",
  '',
].join('\n');
if (CHECK) {
  const same = fs.existsSync(OUT) && fs.readFileSync(OUT, 'utf8') === made;
  console.log(same ? 'estufa_asks_fixture.dart: up to date' : 'estufa_asks_fixture.dart: STALE');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(OUT, made);
console.log(`${rows.length} asks (${asks.length} ask and decide steps of the recorded runs, ${plays.length} ask pictures of the app's plays) in ${path.relative(PKG, OUT)}`);
for (const m of missing) console.log('not there before the step: ' + m);
for (const m of skipped) console.log('no thing of its name (left out): ' + m);
