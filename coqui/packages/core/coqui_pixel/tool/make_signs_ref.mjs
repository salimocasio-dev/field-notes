// Makes the reference for the signs and marks of juego.js (and the bird of kit.js) from the OLD code, drawn by headless
// Chrome's canvas into small pictures:
//
//   node tool/make_signs_ref.mjs          (in this package) writes test/support/fixtures/ref_signs.dart
//   node tool/make_signs_ref.mjs --check  says whether that file is the one Chrome gives now
//
// A page loads historia/engine.js and historia/escenas/kit.js as they are, and lines 20 to 64 of historia/juego.js
// (`hand`, `heart`, `star`, `spot`, `twinkle`, `bub`, `bang`, `frogBox`, `frog`, `respBox`, `bx`, `respDraw`) and
// lines 66 to 72 and line 77 of its `draw` (what is drawn over the scene's own drawing, and the hand over the view)
// cut out and unchanged; the globals they read (`W`, `F`, `cam`, `E`, `TALK`, `SW`, `SH`, `DW`) are set for each case.
// Each case below is one call, made on a 64 x 64 (or other) canvas that starts as one flat colour, with the
// browser's own smoothing (on), as the old scene canvas had it. test/signs_test.dart makes the same calls on Ctx
// (test/support/signs_replay.dart) and compares. Needs Node 22 and the pre-installed Node Playwright. A second run
// gives the same file.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../../../..');
const outFile = path.resolve(here, '../test/support/fixtures/ref_signs.dart');
const read = f => fs.readFileSync(path.join(repo, f), 'utf8');
const juego = read('historia/juego.js').split('\n');
const BG = '#6A8CAF';

// ---- the code cut out of juego.js ----
const must = (line, prefix) => { if (!line.startsWith(prefix)) throw new Error(`juego.js has changed: ${prefix}`); return line; };
must(juego[19], '/* ---------- signs and marks');
must(juego[63], '  else{[[x+5,y+4]');
const signs = juego.slice(19, 64).join('\n');
must(juego[65], '  E.draw(c,W,a);if(W.resp)respDraw(c,a);');
const drawLines = [juego[65].replace('E.draw(c,W,a);', ''), ...juego.slice(66, 72)].join('\n');
must(juego[71], '  if(W.heart)heart(c,E.heartAt');
const handLine = must(juego[76], '  if(W.spot){const rb=respBox(W.spot)');

const Q = (s, o = {}) => ({ x: 16, y: 20, s, dy: 0, vis: 1, bub: null, ...o });
const E1 = { box: { puerta: [30, 20, 40, 30], ventana: [100, 10, 20, 16.5], arbol: [90, 90, 30, 30] }, handAt: { puerta: [50, 35], ventana: [110, 18], arbol: [100, 100] }, heartAt: [20, 8], icon: true };
const frame = { F: 0, cam: [0, 0, 196, 216], TALK: null, SW: 200, SH: 80, E: E1 };

const CASES = [];
const add = (kind, size, args, state = {}, note = '') => CASES.push({ kind, size, args, state: { ...frame, ...state }, note });

// hand(g, x, y, down, k)
for (const a of [[10, 12, true, 3], [10, 4, false, 3], [4, 4, false, 2], [14, 10, true, 2], [-6, -4, false, 3], [40, 50, true, 3]]) add('hand', [64, 64], a);
// heart(g, x, y, s)
for (const a of [[5, 5, 3], [4, 4, 2], [-4, 2, 4], [40, 44, 1], [50, 40, 3]]) add('heart', [64, 64], a);
// star(g, x, y, s, hot)
for (const a of [[20, 20, 2, false], [20, 20, 4, true], [5, 5, 3, false], [62, 62, 3, true], [30, 30, 1, true]]) add('star', [64, 64], a);
// spot(g, b, a): SW and SH are the picture's
const small = { SW: 64, SH: 48 };
for (const [b, a] of [[[20, 12, 24, 20], 0], [[20, 12, 24, 20], 2], [[20, 12, 24, 20], 1], [[20, 12, 24, 20], 3], [[-4, 30, 20, 30], 0], [[50, 5, 30, 60], 2], [[10.5, 8.25, 20.5, 14.5], 0], [[0, 0, 64, 48], 2]]) add('spot', [64, 48], [b, a], small);
// twinkle(g, b): F says where the three stars are
for (const F of [0, 5, 13, 20, 33, 100]) add('twinkle', [64, 48], [[20, 16, 24, 16]], { ...small, F });
// bub(g, k, tx, ty, a): BUBL's, and `hola`, `amor`
for (const k of ['como', 'bien', 'mal', 'quien', 'lluvia', 'hola', 'amor']) for (const a of [0, 1]) add('bub', [64, 64], [k, 32, 52, a]);
// bang(g, cx, cy, s)
for (const a of [[32, 32, 1], [32, 32, 2], [10, 10, 2], [58, 30, 1]]) add('bang', [64, 64], a);
// frog(g, q, a): his blink (F % 47 < 2), his mouth (bub "hola" or TALK "coqui" with a odd), the size, dy
for (const [q, F, a, TALK] of [[Q(1), 10, 0, null], [Q(1), 0, 1, null], [Q(1, { bub: 'hola' }), 10, 1, null], [Q(1, { bub: 'hola' }), 10, 0, null],
  [Q(.72, { dy: -5 }), 47, 1, 'coqui'], [Q(.5, { dy: 3.5, x: 20, y: 28 }), 100, 0, null], [Q(.86, { dy: -6.4 }), 48, 1, 'coqui'], [Q(.42, { x: 30, y: 30 }), 3, 0, 'abuela']]) add('frog', [64, 64], [q, a], { F, TALK });
// respDraw(g, a): the answer bubbles
const qf = Q(1, { x: 80, y: 60 });
const R = (resp, extra = {}, st = {}) => [{ cq: qf, resp, ...extra }, st];
for (const [F, a] of [[0, 0], [2, 1], [6, 3], [10, 5], [14, 7]]) { const [W, st] = R(['si', 'no']); add('respDraw', [200, 80], [a], { W, F, ...st }); }
{ const [W] = R(['a', 'b', 'c']); add('respDraw', [200, 80], [0], { W, F: 4 }); }
{ const [W] = R(['a', 'b']); add('respDraw', [200, 80], [1], { W, F: 5, cam: [44, 0, 196, 216] }); }
{ const [W] = R(['si', 'no'], { respEn: [20, 10] }); add('respDraw', [200, 80], [0], { W, F: 2 }); }
{ const [W] = R(['a', 'b'], { respVoz: { a: 1, b: 1 }, respOn: 'a' }); for (const [F, a] of [[3, 1], [4, 2], [8, 0]]) add('respDraw', [200, 80], [a], { W: { ...W }, F }); }
{ const [W] = R(['a', 'b'], { respVoz: { a: 1 }, respOn: 'zz' }); add('respDraw', [200, 80], [0], { W, F: 3 }); }
{ const [W] = R(['si', 'no']); add('respDraw', [200, 80], [0], { W, F: 6, cam: [71, 54, 98, 108] }); }
{ const [W] = R(['a', 'b', 'c']); add('respDraw', [200, 80], [0], { W, F: 6, cam: [71, 54, 98, 108] }); }
// the old kit's bird: drawAve(c, v)
for (const [v, F] of [[{ mode: 'sit', x: 32, y: 50, dir: 1, st: 'n' }, 0], [{ mode: 'sit', x: 32, y: 50, dir: -1, st: 'n' }, 0], [{ mode: 'fly', x: 30, y: 40, dir: 1, st: 'n' }, 0],
  [{ mode: 'fly', x: 30, y: 40, dir: 1, st: 'n' }, 2], [{ mode: 'sit', x: 32, y: 50, dir: 1, st: 'sleep' }, 0], [{ mode: 'sit', x: 32, y: 50, dir: 1, st: 'feliz' }, 4],
  [{ mode: 'sit', x: 32, y: 50, dir: 1, st: 'feliz' }, 0], [{ mode: 'sit', x: 20, y: 56, dir: 1, st: 'round' }, 0], [{ mode: 'sit', x: 20, y: 56, dir: 1, st: 'round' }, 8],
  [{ mode: 'sit', x: 20, y: 56, dir: -1, st: 'round' }, 16], [{ mode: 'fly', x: 30, y: 40, dir: -1, st: 'n', dip: 3 }, 2], [{ mode: 'fly', x: 30.4, y: 40.6, dir: 1, st: 'n' }, 0],
  [{ mode: 'none', x: 30, y: 40 }, 0]]) add('drawAve', [64, 64], [v], { F, W: { cq: Q(1) } });
add('drawAve', [64, 64], [{ mode: 'head', x: 0, y: 0, dir: 1, st: 'n' }], { F: 0, W: { cq: Q(1, { x: 20, y: 30, dy: -3 }) } }, 'on the frog\'s head');
// the signs a frame draws over the scene: respDraw, twinkle, spot, the effects, the heart (juego.js, draw)
{
  const base = { cq: qf, fx: [] };
  const fxs = F => [{ t: 'star', n: 10, f0: F - 2, pts: [[20, 20], [40, 30], [60, 25]] }, { t: 'knock', n: 7, f0: F - 1, x: 150, y: 50 }, { t: 'knock', n: 7, f0: F - 4, x: 120, y: 40 }, { t: 'star', n: 3, f0: F - 9, pts: [[5, 5]] }];
  for (const [F, cam] of [[10, [0, 0, 196, 216]], [11, [0, 0, 196, 216]], [10, [71, 54, 98, 108]], [13, [71, 54, 98, 108]], [14, [0, 0, 196, 216]]]) {
    add('drawSigns', [200, 80], [], { F, cam, W: { ...base, fx: fxs(F), resp: ['si', 'no'], twinkle: 'puerta', spot: 'ventana', heart: 1 } });
  }
  add('drawSigns', [200, 80], [], { F: 7, W: { ...base, fx: [], resp: ['a', 'b', 'c'], twinkle: 'nada', spot: 'si', heart: 0 } });
  add('drawSigns', [200, 80], [], { F: 20, W: { ...base, fx: [{ t: 'knock', n: 7, f0: 17, x: 60, y: 40 }], heart: 1 } });
  add('drawSigns', [200, 80], [], { F: 21, W: { ...base, fx: [{ t: 'knock', n: 9, f0: 16, x: 60, y: 40 }], resp: [] } });
}
// the hand over the view (juego.js, draw, line 77): on the 196 x 216 display
for (const [F, cam, spot, resp] of [[0, [22, 0, 196, 216], 'puerta', null], [4, [22, 0, 196, 216], 'puerta', null], [8, [71, 54, 98, 108], 'arbol', null],
  [4, [71, 54, 98, 108], 'arbol', null], [0, [22, 0, 196, 216], 'si', ['si', 'no']], [4, [71, 54, 98, 108], 'no', ['si', 'no']], [4, [0, 0, 196, 216], 'b', ['a', 'b', 'c']]])
  add('handSign', [196, 216], [], { F, cam, W: { cq: qf, spot, resp } });
// values
for (const q of [Q(1), Q(.72), Q(.5, { x: 3.5, y: 7.25 }), Q(.42), Q(.86, { x: -4 }), Q(.58), Q(.99, { x: 200.5 }), Q(.45, { y: 99 })]) add('frogBox', null, [q]);
for (const [W, cam, k] of [[{ cq: qf, resp: ['si', 'no'] }, [0, 0, 196, 216], 'si'], [{ cq: qf, resp: ['si', 'no'] }, [0, 0, 196, 216], 'no'], [{ cq: qf, resp: ['si', 'no'] }, [0, 0, 196, 216], 'x'],
  [{ cq: qf, resp: ['a', 'b', 'c'] }, [0, 0, 196, 216], 'c'], [{ cq: qf, resp: ['a', 'b', 'c'] }, [71, 54, 98, 108], 'a'], [{ cq: qf, resp: ['a', 'b'] }, [44, 0, 196, 216], 'b'],
  [{ cq: Q(1, { x: 0, y: 0 }), resp: ['a', 'b'] }, [0, 0, 196, 216], 'a'], [{ cq: Q(1, { x: 230, y: 100 }), resp: ['a', 'b'] }, [44, 0, 196, 216], 'b'],
  [{ cq: qf, resp: ['si', 'no'], respEn: [20, 10] }, [0, 0, 196, 216], 'no'], [{ cq: qf }, [0, 0, 196, 216], 'si'], [{ cq: qf, resp: null }, [0, 0, 196, 216], 'si']]) {
  add('respBox', null, [k], { W, cam });
  add('bx', null, [k], { W, cam });
}
for (const k of ['puerta', 'ventana', 'nada']) add('bx', null, [k], { W: { cq: qf, resp: ['si', 'no'] } });

// ---- the page ----
const pageScript = `
const hex = h => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
function signsDraw(c, a) {
${drawLines}
}
function handSign(dc, a) {
${handLine}
}
const b64 = u => { let s = ''; for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode.apply(null, u.subarray(i, i + 0x8000)); return btoa(s); };
window.RUN = cases => cases.map(c => {
  const st = c.state;
  W = JSON.parse(JSON.stringify(st.W || { fx: [] })); F = st.F; cam = st.cam.slice(); TALK = st.TALK; SW = st.SW; SH = st.SH;
  E = { box: (k, w) => st.E.box[k], handAt: st.E.handAt, heartAt: st.E.heartAt, respIcon: st.E.icon ? (g, k, x, y, w, h, a) => fr(g, x + 4, y + 4, w - 8, h - 8, '#C86A10') : undefined };
  let value = null, px = null;
  if (c.size) {
    const cv = document.createElement('canvas'); cv.width = c.size[0]; cv.height = c.size[1];
    const g = cv.getContext('2d', { willReadFrequently: true, colorSpace: 'srgb' });
    g.fillStyle = c.kind === 'handSign' ? '#0E1A24' : '${BG}'; g.fillRect(0, 0, cv.width, cv.height);   // the display starts as juego.js fills it
    const a = c.args;
    switch (c.kind) {
      case 'hand': hand(g, ...a); break;
      case 'heart': heart(g, ...a); break;
      case 'star': star(g, ...a); break;
      case 'spot': spot(g, a[0], a[1]); break;
      case 'twinkle': twinkle(g, a[0]); break;
      case 'bub': bub(g, ...a); break;
      case 'bang': bang(g, ...a); break;
      case 'frog': frog(g, a[0], a[1]); break;
      case 'respDraw': respDraw(g, a[0]); break;
      case 'drawAve': KIT.drawAve(g, a[0]); break;
      case 'drawSigns': signsDraw(g, F >> 1); value = { fx: W.fx }; break;
      case 'handSign': handSign(g, F >> 1); break;
      default: throw new Error('no kind ' + c.kind);
    }
    px = b64(g.getImageData(0, 0, cv.width, cv.height).data);
  } else {
    switch (c.kind) {
      case 'frogBox': value = frogBox(c.args[0]); break;
      case 'respBox': value = respBox(c.args[0]); break;
      case 'bx': value = bx(c.args[0]); break;
      default: throw new Error('no kind ' + c.kind);
    }
  }
  return { px, value };
});
`;

const prelude = 'var W = { fx: [] }, F = 0, cam = [0, 0, 196, 216], E = null, TALK = null, SW = 240, SH = 216, DW = 196, DH = 216, TICK = 70;';
const browser = await chromium.launch();
const page = await (await browser.newContext({ deviceScaleFactor: 1 })).newPage();
const problems = [];
page.on('pageerror', e => problems.push('pageerror: ' + e));
page.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') problems.push('console ' + m.type() + ': ' + m.text()); });
await page.setContent('<!doctype html><html><body></body></html>');
for (const [name, content] of [['prelude', prelude], ['engine.js', read('historia/engine.js')], ['kit.js', read('historia/escenas/kit.js')], ['juego.js 20-64', signs], ['driver', pageScript]]) {
  try { await page.addScriptTag({ content }); } catch (e) { throw new Error(name + ': ' + e.message); }
}
const run = () => page.evaluate(cases => window.RUN(cases), CASES);
const first = await run();
const second = await run();
await browser.close();
if (problems.length) throw new Error(problems.join('; '));
if (JSON.stringify(first) !== JSON.stringify(second)) throw new Error('Chrome drew a case two ways');

const piece = 4000;
const files = { 'cases.json': Buffer.from(JSON.stringify({ background: BG, cases: CASES.map((c, i) => ({ n: i + 1, ...c, value: first[i].value })) })).toString('base64') };
first.forEach((r, i) => { if (r.px) files[`px/${String(i + 1).padStart(3, '0')}.bin`] = r.px; });
let text = '// Made by tool/make_signs_ref.mjs from headless Chrome\'s canvas and the old juego.js, engine.js and kit.js. Do not edit.\n';
text += '// ignore_for_file: lines_longer_than_80_chars\n\n';
text += '/// The reference for test/signs_test.dart: each file as base64 in pieces. Pictures are RGBA, straight alpha.\n';
text += 'const Map<String, List<String>> refSignsFixture = {\n';
for (const [name, data] of Object.entries(files)) {
  text += `  '${name}': [\n`;
  for (let i = 0; i < data.length; i += piece) text += `    '${data.slice(i, i + piece)}',\n`;
  text += '  ],\n';
}
text += '};\n';

if (process.argv.includes('--check')) {
  const same = fs.existsSync(outFile) && fs.readFileSync(outFile, 'utf8') === text;
  console.log(same ? 'the signs reference is current' : 'the signs reference is NOT current: run tool/make_signs_ref.mjs');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(outFile, text);
console.log(`wrote ${outFile}: ${text.length} characters, ${CASES.length} cases`);
