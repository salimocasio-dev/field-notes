#!/usr/bin/env node
'use strict';
/* El patio's sheet (order 32a, rounds 2 to 4: the yard built on the world's axes, the house wall on the left, the fence on the far right): writes docs/proyecto/pixel/patio-sheet.json from patio-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/patio-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.PATIO_SET) and its part map from patio-set.html in headless Chrome, for every baked state; measures the old
   sprite layer's bubbles and people (historia/ engine.js, juego.js, kit.js, escenas/patio.js, as they are); projects every world point with the
   engine's own formula; and checks the sheet against coqui/ref/escenas/patio/ (positions.json, inventory.json, pairs.json) and against every
   moment of every recorded run of the scene's stories (coqui/tool/ref/trazas/juega.mjs --states, into a temp folder; nothing in the repo is
   written but the sheet). A second run writes the same bytes. Every name a builder needs for a screen position of historia/escenas/patio.js is
   in `code`, by line. La sala's maker (sala-sheet-make.js) is the model: the same rules, the same way of checking. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'patio-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/patio');
// the baked states: hora-door-gate (setKey.baked). Every state a story, a review pair or a level picture reaches is one of these (checked)
const STATES = ['dia-shut-shut', 'dia-open-shut', 'dia-shut-open', 'tarde-shut-shut', 'tarde-open-shut', 'tarde2-shut-shut', 'tarde2-open-shut',
  'ocaso-shut-shut', 'ocaso-open-shut', 'ocaso-open-open', 'crepusculo-shut-shut', 'crepusculo-open-shut', 'noche-shut-shut', 'noche-open-shut', 'noche-open-open'];
const keyOf = w => { const n = Math.min(3, w.sol || 0), hora = w.noche ? 'noche' : n < 3 ? ['dia', 'tarde', 'tarde2'][n] : (w.osc || 0) >= .25 ? 'crepusculo' : 'ocaso';
  return hora + '-' + (w.pdoor ? 'open' : 'shut') + '-' + (w.porton ? 'open' : 'shut'); };
const queryOf = k => { const [hora, door, gate] = k.split('-'); return 'hora=' + hora + '&door=' + door + '&gate=' + gate; };

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  const G = { parts: {}, z: {}, kinds: {}, leafZ: {}, rgb: {} };
  for (const key of STATES) {
    await page.goto('file://' + path.join(__dirname, 'patio-set.html') + '?tags=1&' + queryOf(key));
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(PATIO_SET)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
      const parts = {}; TAGS.forEach((t, i) => { if (t) (parts[t] = parts[t] || []).push(i); });
      // the leaves' reach: every pixel a swaying leaf of the crown can take, at any wind step (drawLeaves moves them up to 2 px across, 1 down)
      const reach = []; for (const L of leaves) for (let n = 0; n < L.pixels.length; n += 4) reach.push(L.pixels[n] + L.pixels[n + 1] * W);
      const cd = document.getElementById('c').getContext('2d').getImageData(0, 0, W, H).data, rgb = []; for (let i = 0; i < W * H; i++) rgb.push(cd[i * 4], cd[i * 4 + 1], cd[i * 4 + 2]);
      return { F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(DEPTH.z), kinds: Array.from(kinds), leaves: [...new Set(reach)], K: { road: KIND_ROAD, grass: KIND_GRASS }, rgb };
    });
    if (!G.F) Object.assign(G, { F: g.F, scene: g.scene, W: g.W, H: g.H, S: g.S, K: g.K, leafPix: g.leaves });
    G.parts[key] = g.parts; G.z[key] = g.z; G.kinds[key] = g.kinds; G.rgb[key] = g.rgb;
  }
  if (errs.length) throw new Error(errs.join('; '));
  G.M = await measure(await browser.newPage());
  await browser.close();
  if (errs.length) throw new Error(errs.join('; '));
  const sheet = make(G);
  const problems = check(sheet, G);
  const text = JSON.stringify(sheet, null, 1).replace(/\[\n\s+([-\d.,\s"a-z]+?)\n\s+\]/g, (m, a) => '[' + a.replace(/\s+/g, ' ').replace(/ ?, ?/g, ', ') + ']') + '\n';
  fs.writeFileSync(OUT, text);
  console.log('wrote ' + path.relative(REPO, OUT) + ' (' + text.length + ' bytes)');
  for (const n of sheet.checks.notes) console.log('  ' + n);
  if (problems.length) { console.log('CHECK FAILED (' + problems.length + '):\n  ' + problems.slice(0, 150).join('\n  ')); process.exit(1); }
  console.log('check: ok (every rule above)');
})().catch(e => { console.error(e); process.exit(1); });

/* ---------- the old sprite layer, measured in the browser: every bubble's rectangle, the people's sizes ---------- */
// historia/ engine.js, palabras.js, juego.js, escenas/kit.js and escenas/patio.js loaded as they are into a blank page. A bubble is drawn as
// patio.js bub2 draws it (twice its size, its tail's tip at the origin), on both frames of its bob
const QUIEN = { luis: 'hermano', carmen: 'hermana', mama: 'mama', papa: 'papa', abuelo: 'abuelo' };
async function measure(page) {
  await page.setContent('<canvas id="cv" width="196" height="216"></canvas>');
  for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js', 'escenas/patio.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
  return page.evaluate(QUIEN => {
    const keys = Object.keys(BUB).concat(Object.keys(BUBL)), bubbles = {};
    for (const k of keys) {
      let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      for (const a of [0, 1]) {
        const cv = document.createElement('canvas'); cv.width = 400; cv.height = 300; const g = cv.getContext('2d');
        g.translate(200, 250); g.scale(2, 2); bub(g, k, 0, 0, a);
        const d = g.getImageData(0, 0, 400, 300).data;
        for (let i = 0; i < 400 * 300; i++) if (d[i * 4 + 3]) { const x = i % 400 - 200, y = (i / 400 | 0) - 250; x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
      }
      bubbles[k] = [x0, y0, x1 - x0 + 1, y1 - y0 + 1];
    }
    const opaque = (cv, ox, oy) => { const g = cv.getContext('2d'), d = g.getImageData(0, 0, cv.width, cv.height).data; let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      for (let i = 0; i < cv.width * cv.height; i++) if (d[i * 4 + 3]) { const x = i % cv.width, y = i / cv.width | 0; x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
      let hx0 = 1e9, hx1 = -1e9; for (let i = 0; i < cv.width * cv.height; i++) { const x = i % cv.width, y = i / cv.width | 0; if (d[i * 4 + 3] && y < y0 + 10) { hx0 = Math.min(hx0, x); hx1 = Math.max(hx1, x); } }
      return { box: [x0 - ox, y0 - oy, x1 - x0 + 1, y1 - y0 + 1], head: (hx0 + hx1 + 1) / 2 - ox }; };
    const rowsOf = (cv, ox, oy) => { const d = cv.getContext('2d').getImageData(0, 0, cv.width, cv.height).data, out = [];
      for (let y = 0; y < cv.height; y++) { let a = -1, b = -1; for (let x = 0; x < cv.width; x++) if (d[(y * cv.width + x) * 4 + 3]) { if (a < 0) a = x; b = x; } if (a >= 0) out.push([y - oy, a - ox, b - ox]); }
      return out; };
    const people = {}, masks = {};
    for (const [id, fam] of Object.entries(QUIEN)) for (const sent of [0, 1]) {
      const im = KIT.mkPersona(KIT.FAM[fam], 'idle', 0, sent); people[id + (sent ? '.sent' : '')] = Object.assign(opaque(im, KIT.PX, im.height - 1), { h: im.height });
      for (const pose of ['idle', 'wave0', 'wave1', 'ojos', 'offer']) { const m = KIT.mkPersona(KIT.FAM[fam], pose.replace(/\d$/, ''), 0, sent); masks[id + '.' + pose + (sent ? '.sent' : '')] = rowsOf(m, KIT.PX, m.height - 1); }
    }
    { const im = mkAbuela('idle', 0); people.abuela = Object.assign(opaque(im, 30, 50), { h: 51 }); }
    { const im = KIT.mkBebe('idle', 0); people.bebe = Object.assign(opaque(im, 13, 28), { h: 28 }); }
    for (const pose of ['idle', 'wave0', 'wave1']) masks['abuela.' + pose] = rowsOf(mkAbuela(pose, 0), 30, 50);
    for (const e of ['idle', 'clap']) masks['bebe.' + e] = rowsOf(KIT.mkBebe(e, 0), 13, 28);
    // the bird sitting (kit.js drawAve: 1.6 times its 18 x 14 sprite, its feet the given point): its opaque rows, relative to (x, y), facing left and right
    const ave = {}; for (const dir of [-1, 1]) { const cv = document.createElement('canvas'); cv.width = 80; cv.height = 60; const g = cv.getContext('2d');
      KIT.drawAve(g, { mode: 'sit', x: 40, y: 40, dir, st: 'n' }); ave[dir] = rowsOf(cv, 40, 40); }
    return { bubbles, FAM: KIT.FAM, PX: KIT.PX, people, masks, ave };
  }, QUIEN);
}

/* ---------- the engine's projection, as pp-engine.js has it ---------- */
function engine(G) {
  const W = G.W, H = G.H, S = G.S, SIN = .5, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
  const OX = W / 2 + (G.scene.originX || 0), OY = H / 2 + (G.scene.originY || 0);
  const project = (x, y, z) => { const u = (x - y) / R2, v = (x + y) / R2; return { sx: OX + u * S, sy: OY + (v * SIN - z * COS) * S, d: v * COS + z * SIN }; };
  const atZ = (sx, sy, z) => { const u = (sx - OX) / S, v = (sy - OY + z * COS * S) / (S * SIN); return [(u + v) / R2, (v - u) / R2, z]; };
  const UVW = (u, v, z = 0) => [(u + v) / R2, (v - u) / R2, z];
  return { W, H, S, R2, SIN, COS, OX, OY, project, atZ, UVW };
}
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);
const hop = d => d < 3 ? 0 : Math.max(1, Math.min(4, Math.round(d / 30)));   // kit.js acts.ir

/* ---------- the old scene's numbers (historia/escenas/patio.js, read as text: they must be what the file says) ---------- */
const PATIO_JS = fs.readFileSync(path.join(REPO, 'historia/escenas/patio.js'), 'utf8');
const LINES = PATIO_JS.split('\n');
const lineOf = s => { const i = LINES.findIndex(l => l.includes(s)); if (i < 0) throw new Error('patio.js changed: ' + s); return i + 1; };
function fixJson(s) { return s.replace(/\s+/g, '').replace(/([{,])(\w+):/g, '$1"$2":').replace(/:\./g, ':0.').replace(/,\./g, ',0.').replace(/\[\./g, '[0.'); }
const OLD = (() => { const g = (re, w) => { const m = PATIO_JS.match(re); if (!m) throw new Error('patio.js changed: ' + w); return JSON.parse(fixJson(m[1])); };
  return { LUGAR: g(/const LUGAR=(\{[^;]*\})/, 'LUGAR'), DETRAS: g(/const DETRAS=(\{[^}]*\})/, 'DETRAS'), ESPERA: g(/ESPERA=(\{[^}]*\})/, 'ESPERA'), LADOS: g(/LADOS=(\[\[[^\]]*\],\[[^\]]*\]\])/, 'LADOS'),
    CAMA: g(/const CAMA=(\{[^}]*\})/, 'CAMA'), SOLX: g(/SOLX=(\d+)/, 'SOLX'), SOLY: g(/SOLY=(\[[^\]]*\])/, 'SOLY') }; })();

// the places a bubble's tail may go, in order (as La sala's): over the head (the old), beside the head on the right, on the left, beside the shoulder ...
const TALK = [[0, 0], [1, 7], [-1, 7], [1, 30], [-1, 30], [1, 44], [-1, 44], [2, 7], [-2, 7], [2, 30], [-2, 30], [2, 44], [-2, 44], [1, 58], [-1, 58], [2, 58], [-2, 58]];
// the corner cards patio.js hud draws, in the 196 x 216 display (tarjeta(x, y, w, h) covers [x - 1, y - 1, w + 2, h + 2])
const boardsOf = (w, x0) => { const b = [];
  if (w.tarjeta === 'sol') b.push(['the sun card', [2, 2, 36, 54]]);
  if (w.tarjeta === 'luces') b.push(['the fireflies card', [2, 2, 86, 32]]);
  if (w.tanteo) { const n = Math.max(3, (w.canasta || []).length); b.push(['the basket card', [2, 2, 26 + n * 15, 28]], ['the nest card', [196 - 76 - 1, 2, 75, 28]]); }
  return b.map(([n, r]) => [n, [r[0] + x0, r[1], r[2], r[3]]]); };

function make(G) {
  const E = engine(G), F = G.F, P = p => { const q = E.project(p[0], p[1], p[2]); return [r2(q.sx), r2(q.sy)]; };
  const corners = w => { const out = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) out.push(E.project(x, y, z)); return out; };
  const box = w => { const c = corners(w), x0 = Math.floor(Math.min(...c.map(q => q.sx))), y0 = Math.floor(Math.min(...c.map(q => q.sy)));
    return [x0, y0, Math.ceil(Math.max(...c.map(q => q.sx))) - x0, Math.ceil(Math.max(...c.map(q => q.sy))) - y0]; };
  const floor = (sx, sy) => W4(E.atZ(sx, sy, 0));
  // the box (square on the ground) whose 8 projected corners have the screen box [sx0, sy0] - [sx1, sy1] (set-kit.js boxAround)
  const boxAround = (sx0, sy0, sx1, sy1) => { const S = E.S, d = (sx1 - sx0) / S, uc = ((sx0 + sx1) / 2 - E.OX) / S;
    const vmax = (sy1 - E.OY) / (S * .5), vmin = vmax - d, z1 = (vmin * .5 - (sy0 - E.OY) / S) / E.COS;
    const xc = (uc + (vmin + vmax) / 2) / E.R2, yc = ((vmin + vmax) / 2 - uc) / E.R2, e = d * E.R2 / 4; return [xc - e, yc - e, 0, xc + e, yc + e, z1]; };
  // a thing made of several world boxes (a gate's posts and its leaf, shut and open; a house's wall and roof): the screen box round all their
  // corners, and the square world box with that screen box (set-kit.js boxAround), so the sheet's thing is one box as page 12 asks
  const screenOf = boxes => { const xs = [], ys = []; for (const w of boxes) for (const q of corners(w)) { xs.push(q.sx); ys.push(q.sy); } return [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)]; };
  const worldThing = (...boxes) => { const s = screenOf(boxes); return boxAround(s[0], s[1], s[2], s[3]); };
  // the same, cut to the picture (a wall that runs off the picture: its touch box is the part on the screen)
  const worldThingIn = (...boxes) => { const s = screenOf(boxes); return boxAround(Math.max(0, s[0]), Math.max(0, s[1]), Math.min(E.W, s[2]), Math.min(E.H, s[3])); };

  /* ---- the floor rule: the yard is built round the old picture, so a place on its lawn stays where it was on the screen ---- */
  // a frog place q (juego.js frogBox: his middle q.x + 16, his feet row q.y + 25): the ground point under (q.x + 16, q.y + 25); new q = old q.
  // a person's place (x, y) (their feet, patio.js gente): the ground point under (x, y - 1); new = old
  const frogW = q => floor(q[0] + 16, q[1] + 25), personW = p => floor(p[0], p[1] - 1);
  const frogQ = w => { const s = P(w); return [Math.round(s[0]) - 16, Math.round(s[1]) - 25]; };
  const personQ = w => { const s = P(w); return [Math.round(s[0]), Math.round(s[1]) + 1]; };

  /* ---- the places that move (the floor rule keeps every other one). Each is an exact piece of patio.js source and its replacement ---- */
  // whoever goes in (acts.seva) walks to the step's front, in the door's middle, and is gone
  // round 3: abuela stands IN the doorway, on its threshold (the house floor, just inside the wall's face), the dark room round her head and
  // shoulders (round 2's, on the step's front edge, stood in front of the wall: "she is no longer at an open door")
  const ASOMA_W = [F.CX - .1, F.DM - .1, F.FLOOR], SEVA_W = [F.STEP[1] + .1, F.DM, 0];
  const ASOMA = personQ(ASOMA_W), SEVA = personQ(SEVA_W);
  // the gate: whoever walks there with the frog (acts.juntos, acts.luiscorre) ends right of it, before its right post, as the old one
  const JUNTOS = [165, 116];
  const STAR6 = '[100,44]';
  // round 4: the frog's two places at the gate follow the gate (LUGAR, frog points q: his middle q.x + 16, his feet row q.y + 25). PORTON: on the
  // lawn before the opening, 17.5 rows before the fence's line (the old picture: 17), his middle at x 142, inside the opening's columns, left of
  // its middle so that Luis (juntos, right of the gate) has his own ground. SALE: through the opening, on the path 2.5 rows past the fence's line
  // (the old: 3), his box (at .5) wholly between the posts, a pixel clear of each. Of every such pair of points, 7 hop counts change at the least (with him at x 137, the opening's left edge); here 8, with him before the opening
  const PORTON4 = [126, 86], SALE4 = [130, 68];
  const gap4 = q => r2((q[1] + 25) - E.project(F.CY + (q[0] + 16 - E.OX) / E.S * E.R2, F.CY, 0).sy);   // rows his feet are before the fence's line (< 0: past it)
  const MOVES = [
    { line: lineOf('const CAMA='), act: '*', src: 'SOLY=[24,40,56,73]', to: 'SOLY=[26,40,56,73]', sky: [['soly', 24, 26]],
      why: 'the sun at its highest 2 px lower: its touch box ([SOLX - 14, soly - 14, 28, 28]) and so its hint frame (12 px round it) wholly inside the view (las-flores and h-patio ask for the sun; at soly 24 the frame reached 2 px over the picture\'s top). W.soly 24 in a recorded run is 26' },
    { line: lineOf('const ESTRELLAS='), act: '*', src: 'ESTRELLAS=[[60,18],[84,40],[124,12],[150,36],[40,46],[112,58],[72,64],[140,60]]', to: 'ESTRELLAS=[[60,18],[84,40],[124,12],[150,36],[40,46],' + STAR6 + ',[72,64],[140,60]]',
      why: 'round 3: the sixth star (112, 58) sat half hidden on the top of the fence\'s first post (raised with the fence) and read as a lamp on it; it goes up and left into the open sky over the gap between the house and the fence. The others are as before: in the sky, or wholly behind the set (60, 18, 40, 46 and 72, 64 behind the house, 140, 60 behind the gate\'s left post)' },
    { line: lineOf('async asoma()'), act: 'asoma', src: 'W.gente.abuela={x:42,y:116,pose:"wave",dir:1}', to: 'W.gente.abuela={x:' + ASOMA[0] + ',y:' + ASOMA[1] + ',pose:"wave",dir:1}', pts: [['abuela', [42, 116], ASOMA]],
      why: 'acts.asoma: abuela in the back door, in the doorway: on its threshold (the house floor, just inside the wall\'s face), in its middle, the dark room round her head and shoulders, as the old one stood in the old door (round 3: round 2 had her on the step\'s front edge, and she read as standing in front of the wall). The door stands on the house wall, seen at the angle: its middle is 10 px right of the old one (the whole door, its hint frame and who stands in it inside the wide view with a margin, as El balcón and La sala keep it): ' + (ASOMA[0] - 42) + ' px right, ' + (ASOMA[1] - 116) + ' rows' },
    { line: lineOf('async seva(o)'), act: 'seva', src: 'await mueve(id,44,118)', to: 'await mueve(id,' + SEVA[0] + ',' + SEVA[1] + ')', pts: [[null, [44, 118], SEVA]],
      why: 'acts.seva: whoever goes in walks to the back door (the step\'s front, in the door\'s middle: moved with it), then is gone' },
    { line: lineOf('async juntos(o)'), act: 'juntos', src: 'await Promise.all([mueve(id,170,124),acts.ir({a:"porton"})])', to: 'await Promise.all([mueve(id,' + JUNTOS + '),acts.ir({a:"porton"})])', pts: [[null, [170, 124], JUNTOS]],
      why: 'acts.juntos: two go to the gate together: the one who walks ends right of the gate, before its right post. The fence runs up towards the far corner, so the gate stands ' + Math.round(112 - E.project((F.GX0 + F.GX1) / 2, F.CY, 0).sy) + ' rows further back than the old one; the walk follows it ' + (124 - JUNTOS[1]) + ' rows up and ' + (170 - JUNTOS[0]) + ' px left (as far as the fence behind them allows: 5 rows of lawn between the feet and the fence\'s foot, round 3). The frog\'s place at the gate (LUGAR.porton) went up with the gate too (round 4, below): he stands left of the one who walks, before the opening' },
    { line: lineOf('async luiscorre()'), act: 'luiscorre', src: 'await mueve("luis",170,124,8)', to: 'await mueve("luis",' + JUNTOS + ',8)', pts: [['luis', [170, 124], JUNTOS]],
      why: 'acts.luiscorre: Luis runs to the gate (then opens it, acts.abre): to the same place as acts.juntos' },
    { line: lineOf('porton:[128,104,.85]'), act: '*', src: 'porton:[128,104,.85]', to: 'porton:[' + PORTON4 + ',.85]', pts: [['cq', [128, 104], PORTON4]],
      why: 'round 4: LUGAR.porton, the frog at the gate (acts.ir a porton; acts.juntos), follows the gate: on the lawn before its opening, ' + gap4(PORTON4) + ' rows before the fence\'s line (the old picture: 17; round 3 left him ' + gap4([128, 104]) + ' rows before it, where the old hop counts put him), his middle at x ' + (PORTON4[0] + 16) + ' inside the opening\'s columns. ' + (PORTON4[0] - 128) + ' px, ' + (PORTON4[1] - 104) + ' rows. W.cq at (128, 104) in a recorded run is here (places: who cq). Some hop counts change: hops' },
    { line: lineOf('sale:[134,84,.5]'), act: '*', src: 'sale:[134,84,.5]', to: 'sale:[' + SALE4 + ',.5]', pts: [['cq', [134, 84], SALE4]],
      why: 'round 4: LUGAR.sale, where the frog fades (acts.sevan: three hops from the gate), is through the opening, on the path ' + (-gap4(SALE4)) + ' rows past the fence\'s line (the old picture: 3; round 3: ' + gap4([134, 84]) + ' rows before it, on the lawn), his box wholly between the posts: he is seen to go out through the gate before he fades. ' + (SALE4[0] - 134) + ' px, ' + (SALE4[1] - 84) + ' rows. Some hop counts change: hops' },
    { line: lineOf('async inicio9()'), act: 'inicio9', src: 'carmen:{x:86,y:136,pose:"idle"}}', to: 'carmen:{x:94,y:137,pose:"idle"}}', pts: [['carmen', [86, 136], [94, 137]]],
      why: 'acts.inicio9: Carmen 8 px further right, in front of the crate\'s left corner: the hint hand pointing at her (las-flores beats.12) was on the frog\'s face, at the door\'s place (LUGAR.inicio)' },
    { line: lineOf('async inicio10()'), act: 'inicio10', src: 'carmen:{x:50,y:160,pose:"idle",dir:1}', to: 'carmen:{x:37,y:178,pose:"idle",dir:1}', pts: [['carmen', [50, 160], [37, 178]]],
      why: 'acts.inicio10: Carmen at the left, lower, beside bed L: the answer cards over the frog at the door and by her (que-es-esto beats.3, 10) covered her head, and the hand at the left card her face' },
    { line: lineOf('async inicio11()'), act: 'inicio11', src: 'W.gente={abuela:{x:34,y:136,pose:"idle",dir:1},abuelo:{x:60,y:126,pose:"ojos",lleva:"bizcocho",dir:1},mama:{x:86,y:136,pose:"idle"},bebe:{x:97,y:109,z:137,est:"idle"},papa:{x:112,y:126,pose:"idle"},',
      to: 'W.gente={abuela:{x:46,y:136,pose:"idle",dir:1},abuelo:{x:70,y:129,pose:"ojos",lleva:"bizcocho",dir:1},mama:{x:92,y:136,pose:"idle"},bebe:{x:103,y:109,z:137,est:"idle"},papa:{x:114,y:136,pose:"idle"},',
      pts: [['abuela', [34, 136], [46, 136]], ['abuelo', [60, 126], [70, 129]], ['mama', [86, 136], [92, 136]], ['bebe', [97, 109], [103, 109], 137], ['papa', [112, 126], [114, 136]]],
      why: 'acts.inicio11: the family by the back door, a little further right and closer together, in one row (abuelo 3 px, papá 10 px lower): abuela\'s hint frame (hasta-manana beats.8) reached 11 px past the view\'s left side; abuelo\'s and papá\'s bubbles ("amor", when touched) lay over the fireflies card; the hand at an answer card in the sky (below) was on papá\'s face. The baby stays in mamá\'s arms (moved with her)' },
    { line: lineOf('luis:{x:150,y:160,pose:"idle",dir:-1}'), act: 'inicio11', src: 'luis:{x:150,y:160,pose:"idle",dir:-1},carmen:{x:188,y:158,pose:"alto",dir:-1}};W.pdoor=1;', to: 'luis:{x:178,y:126,pose:"idle",dir:-1},carmen:{x:200,y:168,pose:"alto",dir:-1}};W.pdoor=1;W.respEn=[164,4];', pts: [['luis', [150, 160], [178, 126]], ['carmen', [188, 158], [200, 168]]],
      respEn: [164, 4],
      why: 'acts.inicio11: Luis waits right of the gate, by the fence, Carmen in front of the tree: the hint hand pointing at the gate (hasta-manana beats.5) was on Luis\'s face. And the answer cards stand in the sky at the top right (W.respEn, juego.js: "a scene that needs its people seen while he chooses puts the bubbles elsewhere", as banco, mesa, estufa, nevera and comer do): over the frog, at abuela\'s place and in the middle, they covered the family and Luis (hasta-manana beats.10, 25)' },
  ];
  for (const m of MOVES) for (const q of m.pts || []) q.push(q[0] === 'cq' ? frogW(q[2]) : W4(personW(q[2])));   // (the baby's: the ground under its place in mamá's arms; it is not on the ground; the frog's: under his feet, rules.floor)

  const SPOTS = {};
  for (const [k, v] of Object.entries(OLD.LUGAR)) SPOTS['frog.' + k] = { world: frogW(v), scale: v[2], old: v.slice(0, 2), what: 'LUGAR.' + k + ': the frog' };
  for (const k of ['L', 'R']) SPOTS['detras.' + k] = { world: personW(OLD.DETRAS[k]), old: OLD.DETRAS[k], what: 'DETRAS.' + k + ': a child behind bed ' + k + ', planting (acts.dale, final9)' };
  for (const k of ['luis', 'carmen']) SPOTS['espera.' + k] = { world: personW(OLD.ESPERA[k]), old: OLD.ESPERA[k], what: 'ESPERA.' + k + ': ' + k + ' waits (acts.anda a = espera)' };
  OLD.LADOS.forEach((p, i) => { SPOTS['lados.' + i] = { world: personW(p), old: p, what: 'LADOS[' + i + ']: a child either side of the crate, hands out (acts.lados)' }; });
  const MV = a => MOVES.find(m => m.act === a);
  SPOTS.asoma = { world: MV('asoma').pts[0][3], old: [42, 116], what: 'acts.asoma: abuela in the back door, on its threshold, in the doorway (moved: see moves)' };
  SPOTS.seva = { world: MV('seva').pts[0][3], old: [44, 118], what: 'acts.seva: before the back door\'s step, where whoever goes in is last seen (moved: see moves)' };
  SPOTS.juntos = { world: MV('juntos').pts[0][3], old: [170, 124], what: 'acts.juntos, acts.luiscorre: right of the gate, before its right post (moved: see moves)' };
  for (const s of Object.values(SPOTS)) { s.new = s.scale != null ? frogQ(s.world) : personQ(s.world); }
  SPOTS.asoma.new = MV('asoma').pts[0][2]; SPOTS.seva.new = MV('seva').pts[0][2]; SPOTS.juntos.new = MV('juntos').pts[0][2];
  // round 4: the frog's two places at the gate (moves)
  Object.assign(SPOTS['frog.porton'], { world: frogW(PORTON4), new: PORTON4, what: 'LUGAR.porton: the frog at the gate, on the lawn before its opening (moved: see moves)' });
  Object.assign(SPOTS['frog.sale'], { world: frogW(SALE4), new: SALE4, what: 'LUGAR.sale: the frog through the gate, on the path just past the fence\'s line, where he fades (moved: see moves)' });

  /* ---- the named points of the set ---- */
  const PTS = {}, pt = (k, o) => { PTS[k] = o; };
  const nestTop = E.project(...E.UVW(F.NEST[0], F.NEST[1], F.NEST_Z));
  pt('nido', { screen: [181, 66], old: [181, 66], world: W4(E.UVW(F.NEST[0], F.NEST[1], F.NEST_Z)), what: 'the bird on its nest (W.ave x, y: its feet): fresh(), aveVa(181, 66) in aveloop, avenido, alnido. The nest (the set) is on a branch of the flamboyán, its rim under the bird\'s feet, as the old one; its middle on the screen at ' + [Math.round(nestTop.sx), Math.round(nestTop.sy)] });
  pt('cerca.ave', { screen: [178, 83], old: [178, 83], what: 'inicio11: the bird sits on the fence, right of the gate (W.ave x 178, y 83): on the cap of a fence post there, whose top is under its feet (the fence\'s boards run down to the right, a flat cap takes both feet)' });
  pt('sol', { screen: [OLD.SOLX, null], old: [OLD.SOLX, OLD.SOLY], heights: [26, 40, 56, 73], what: 'the sun (sol(c, SOLX, soly, n, brilla)): drawn by the sprite layer behind the set (sheet: behind); SOLX unchanged, SOLY[0] 2 px lower (moves); it goes down where the old one did, now in the gap between the house and the fence, behind the field and the low hills (soly 109: hidden)' });
  pt('luna', { screen: [150, 26], old: [150, 26], what: 'luna(c, 150, 26): the moon, behind the set (sheet: behind)' });
  pt('estrellas', { screen: [[60, 18], [84, 40], [124, 12], [150, 36], [40, 46], JSON.parse(STAR6), [72, 64], [140, 60]], old: [[60, 18], [84, 40], [124, 12], [150, 36], [40, 46], [112, 58], [72, 64], [140, 60]], what: 'ESTRELLAS: the stars, behind the set (sheet: behind): the house hides the ones at 40, 46 (as the old picture did), 60, 18 and 72, 64 (the house now reaches further up and right), the gate\'s left post the one at 140, 60; the sixth moved from 112, 58 (moves); the other four are in the sky, none touching the set' });
  pt('corazon', { screen: [118, 36], old: [118, 36], what: 'heartAt: the heart of a happy ending: in the sky between the house and the tree (unchanged)' });
  pt('caja', { screen: [104, 112], old: [104, 112], what: 'mkCaja at (104, 112): the crate of potted flowers on the lawn (the sprite layer, its sort y 136): its bottom row 135 on the lawn, the lawn behind it up to the far corner' });
  for (const k of ['L', 'R']) pt('hoyos.' + k, { screen: F.HOLES[k], old: F.HOLES[k], what: 'hoyo(' + k + ', i): the five holes of bed ' + k + ' (the set draws them at the old points): a flower (florEn) stands in each' });

  /* ---- things: the 21 touch keys ---- */
  const T = (world, what, extra = {}) => Object.assign({ set: true, world: W4(world), box: box(world), what }, extra);
  const person = id => ({ sprite: true, why: 'a person (today\'s sprite, drawn 1:1). caja(id) (patio.js:89): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged' });
  const sh = (x0, y0, x1, y1) => boxAround(x0, y0, x1, y1);
  const LAWN_TOP = Math.floor(E.project(F.CX, F.CY, 0).sy);                // the far corner's row: the lawn's highest
  const crown = (() => { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9; for (const i of G.leafPix) { const x = i % 240, y = Math.floor(i / 240); x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } return [x0, y0, x1 + 1, y1 + 1]; })();
  const trunkFoot = E.project(...E.UVW(F.TREE[0], F.TREE[1], 0)), gw = F.GX1 - F.GX0;
  const gatePosts = [F.GP0, F.GP1].map(x => [x - F.GPW - .04, F.CY + .02 - F.GPW - .04, 0, x + F.GPW + .04, F.CY + .02 + F.GPW + .04, F.GPH + .07]);
  // the leaf, shut and open: its two sides (GH high) and its arched top's middle (GH + GARCH), so the box follows the arch
  const leafAt = (x0, y0, x1, y1) => [[x0, y0, 0, x0, y0, .05 + F.GH], [(x0 + x1) / 2, (y0 + y1) / 2, 0, (x0 + x1) / 2, (y0 + y1) / 2, .05 + F.GH + F.GARCH], [x1, y1, 0, x1, y1, .05 + F.GH]];
  const gateShut = leafAt(F.GX0, F.CY - .03, F.GX1, F.CY - .03), gateOpen = leafAt(F.GX0, F.CY + .02, F.GX0 + Math.cos(F.GATE_OPEN) * gw, F.CY + .02 + Math.sin(F.GATE_OPEN) * gw);
  const doorBox = [F.CX - .06, F.D0 - F.DF, 0, F.CX + .03, F.D1 + F.DF, F.FLOOR + F.DH + F.DF];
  const xe = F.CX + F.EAVE, xw = F.CX - F.HDEPTH - F.EAVE, ye = F.YH - F.EAVE;
  const houseBoxes = [[F.CX, F.YH, 0, F.CX, F.YW, F.HH], [xw, ye, F.HH, xe, F.YW + 1, F.HH + F.RISE], [F.STEP[0], F.STEP[2], 0, F.STEP[1], F.STEP[3], F.FLOOR]];
  const fenceBox = [F.FX0, F.CY - .07, 0, F.FX1, F.CY + .07 + .15, F.FH + .11];
  const bedBox = k => { const b = F.BEDS[k]; return sh(b.sx - F.BED_RX, b.sy - F.BED_RY - 16, b.sx + F.BED_RX, b.sy + F.BED_RY + 2); };
  const things = {
    luis: person('luis'), carmen: person('carmen'), bebe: person('bebe'), abuela: person('abuela'), abuelo: person('abuelo'), mama: person('mama'), papa: person('papa'),
    bola: { sprite: true, prop: true, why: 'the ball (sprite layer): box [x - 7, y - 13, 14, 14] at W.bola, unchanged' },
    saco: { sprite: true, prop: true, why: 'the sack (sprite layer): box [x - 13, y - 23, 26, 24] at W.saco, unchanged' },
    caja: { sprite: true, prop: true, why: 'the crate of potted flowers (sprite layer, mkCaja at points.caja): box [104, 112, 32, 24], unchanged', box: [104, 112, 32, 24] },
    camaL: T(bedBox('L'), 'bed L: the earth (the set, painted on the lawn at the old ellipse) and the flowers over it (the sprite layer): the box round both, as the old one', { old: { box: [40, 160, 56, 38] } }),
    camaR: T(bedBox('R'), 'bed R, as bed L', { old: { box: [144, 160, 56, 38] } }),
    sol: { sprite: true, prop: true, why: 'the sun (the sprite layer, drawn behind the set: sheet behind): box [SOLX - 14, soly - 14, 28, 28] while !W.noche and soly < 80, unchanged (SOLY[0] 26: moves)' },
    porton: T(worldThing(...gatePosts, ...gateShut, ...gateOpen), 'the garden gate in the fence: its two posts and the leaf, shut and open (open, round 3: the leaf swung into the yard on its left post, ' + Math.round(F.GATE_OPEN * 180 / Math.PI) + ' degrees, its face seen; the opening empty, the path through it)', { old: { box: [127, 70, 40, 43] },
      hand: (() => { const q = E.project(F.GP0, F.CY + .02, F.GPH + .07); return [Math.round(q.sx), Math.round(q.sy) + 1]; })(), handWhy: 'the hint hand\'s point (kit.js cosas: hand, as El frente\'s house has one): the near post\'s cap, the gate\'s top left. The hand hangs 54 rows below its point; Luis waits before the gate (hasta-manana beats.32, at 138, 138), right of it (beats.5, 178, 126) and further right (h-patio beats.12, 180, 150): from the cap the hand ends over his head and left of him (lower on the leaf, or at its middle, it is on his face)' }),
    nido: T(sh(170, 60, 192, 76), 'the nest on its branch (the box round it and the bird on it, as the old one)', { old: { box: [170, 60, 22, 16] } }),
    arbol: T(sh(crown[0], crown[1], crown[2], Math.ceil(trunkFoot.sy) + 3), 'the flamboyán: its crown (every pixel its leaves take at any wind step) down to the foot of its trunk', { old: { box: [168, 8, 60, 106] } }),
    pajaro: { sprite: true, why: 'the bird (kit.js drawAve, sprite layer): box [p.x - 10, p.y - 20, 20, 22] at avePos, unchanged' },
    puerta: T(worldThing(doorBox), 'the back door in its white frame, on the house wall', { old: { box: [27, 57, 30, 56] } }),
    casa: T(worldThingIn(...houseBoxes), 'the back of the house: its wall (from its far corner down off the picture\'s left edge), its step and its roof; the box is the part on the picture', { old: { box: [0, 14, 61, 100] } }),
    cerca: T(worldThingIn(fenceBox), 'the fence, from the far corner to the picture\'s right edge (the box is the part on the picture)', { old: { box: [60, 80, 180, 33] } }),
    patio: T((() => { const s = [0, LAWN_TOP, 240, 216]; return boxAround(s[0], s[1], s[2], s[3]); })(), 'the lawn, from the far corner (row ' + LAWN_TOP + ') to the bottom, the whole width: last in the hit order', { old: { box: [0, 113, 240, 103] } }),
  };
  // the yard's box is the lawn's own screen rectangle (a square world box can only reach it so: the lawn is a plane)
  things.patio.box = [0, LAWN_TOP, 240, 216 - LAWN_TOP];

  /* ---- views: one, zoom 1, the old wide window ---- */
  const views = { wide: { zoom: 1, x0: 22, world: floor(120, 150), region: null, old: [22, 0, 196, 216], what: 'the yard: the back of the house with its door, the fence with the gate, the flamboyán with the nest, the two beds, the sky' } };

  /* ---- the review and level pictures ---- */
  const pic = (cx, cy, zoom, what) => { const crop = zoom === 1
      ? [Math.max(0, Math.min(44, Math.round(cx - 98))), Math.max(0, Math.min(112, Math.round(cy - 52))), 196, 104]
      : [Math.max(0, Math.min(142, Math.round(cx - 49))), Math.max(0, Math.min(164, Math.round(cy - 26))), 98, 52];
    return { world: floor(cx, cy), screen: [cx, cy], zoom, crop, what }; };
  const PICS = PICTURES(pic);
  const deacc = s => s.replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');
  const LEVEL = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8')).level.flatMap(L => L.pictures.map((p, i) => p.scene === 'patio' ? { w: L.w, index: i, picture: deacc(p.pair) + '.' + p.side, old: p.crop } : null).filter(Boolean));
  for (const l of LEVEL) { const pc = PICS[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }

  /* ---- remap: every distinct position of positions.json ---- */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  // story-file positions that move (the files are not edited: the host passes the point through remap, which gives the new one)
  const STORY_MOVES = [
    { old: [150, 150], new: [180, 150], why: 'Luis at the start of d-la-bola and h-patio: right of the gate, not before it (the hint hand pointing at the gate, h-patio beats.12, was on his face)' },
    { old: [84, 150], new: [80, 150], why: 'Carmen at the start of d-la-bola and h-patio (and h-patio beats.20): 4 px further left (the hint hand pointing at her, h-patio beats.23, reached the frog\'s face at the crate\'s place)' },
  ];
  const remap = POS.positions.map(p => {
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (p.kind === 'cam') { const names = [...new Set(p.uses.map(u => { const m = u.at.match(/^(.+)\.(si|no)\.cam$/); return m ? deacc(m[1]) + '.' + m[2] : null; }).filter(Boolean))];
      e.to = { pictures: names }; e.crops = Object.fromEntries(names.map(n => [n, PICS[n] ? { crop: PICS[n].crop, zoom: PICS[n].zoom } : { scene: 'camino', what: 'drawn by El camino (its sheet\'s picture): listed here because the pair\'s other side is this scene\'s' }])); }
    else if (p.kind === 'crop') { const names = [...new Set(LEVEL.filter(l => l.old && Math.abs(l.old[0] - p.x) < .01 && Math.abs(l.old[1] - p.y) < .01).map(l => l.picture))]; e.to = { pictures: names, level: true }; }
    else if (p.kind === 'x') e.to = { level: true, what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])' };
    else {
      const ats = p.uses.map(u => u.at), cq = ats.every(a => /\.cq$/.test(a)), sky = ats.every(a => /\.(ave|rizo)$/.test(a)), eyes = p.x === 1 && (p.y === -1 || p.y === 0);
      if (p.x === -16 && p.y === -27) { e.to = { none: true }; e.what = 'the frog out of the picture (vis 0): not a place'; }
      else if (eyes) { e.to = { none: true }; e.what = 'acts.ojos x, y: where the frog\'s eyes look (a direction), not a place'; }
      else if (sky) { e.to = { screen: [p.x, p.y] }; e.what = 'in the air (the bird, the loop it flew): a screen point over the yard, unchanged'; }
      else { const mv = STORY_MOVES.find(m => m.old[0] === p.x && m.old[1] === p.y), at = mv ? mv.new : [p.x, p.y];
        const w = cq ? frogW(at) : personW(at); e.to = { floor: w }; e.new = cq ? frogQ(w) : personQ(w); if (mv) { e.moved = true; e.why = mv.why; }
        e.what = cq ? 'the frog (cq x, y): the ground under his feet; the same screen place' : ats.every(a => /\.(bola|polvo)$/.test(a)) ? 'on the lawn (the ball, the dust of a hop): the ground under it; the same screen place' : 'a person\'s feet (x, y): the ground under them; the same screen place'; }
    }
    return e;
  });

  // hop counts: every pair of LUGAR places, old against new
  const lugar = {}; for (const [k, v] of Object.entries(OLD.LUGAR)) lugar[k] = { spot: 'frog.' + k, q: SPOTS['frog.' + k].new, scale: v[2], old: v.slice(0, 2) };
  const hopsAll = [], names = Object.keys(lugar);
  for (let i = 0; i < names.length; i++) for (let j = i + 1; j < names.length; j++) {
    const a = lugar[names[i]], b = lugar[names[j]], dOld = Math.hypot(a.old[0] - b.old[0], a.old[1] - b.old[1]), dNew = Math.hypot(a.q[0] - b.q[0], a.q[1] - b.q[1]);
    hopsAll.push({ a: names[i], b: names[j], old: hop(dOld), new: hop(dNew), dOld: r2(dOld), dNew: r2(dNew) });
  }
  // round 4: the pairs whose count is not the old one (each has porton or sale: their places followed the gate)
  const hops = hopsAll.filter(h => h.old !== h.new);

  const setKey = {
    params: {
      hora: { values: ['dia', 'tarde', 'tarde2', 'ocaso', 'crepusculo', 'noche'], fromW: 'W.noche ? "noche" : n = min(3, W.sol || 0): n < 3 ? ["dia", "tarde", "tarde2"][n] : (W.osc >= .25 ? "crepusculo" : "ocaso"). The sky (the old cielo(n)) and the light of the hour on the set (the old overlays of patio.js:147-148, W.osc) are baked, as El frente\'s dusk; the characters are not dimmed' },
      door: { values: ['shut', 'open'], fromW: 'W.pdoor ? "open" : "shut" (the back door)' },
      gate: { values: ['shut', 'open'], fromW: 'W.porton ? "open" : "shut" (the garden gate)' },
    },
    key: 'hora + "-" + door + "-" + gate, e.g. "dia-shut-shut"',
    baked: STATES.map(k => ({ key: k, query: '?' + queryOf(k) })),
    bakedWhy: 'order 06 found 73 states: what makes them is the sky (W.sol, W.noche, W.osc), the back door, the gate, the crate, the flowers in the beds and the sack. Only the hour, the door and the gate are the set\'s; the crate, the flowers, the sack, the ball, the sun, the moon and the stars are drawn by the sprite layer, so these 15 baked states draw all 73 (and every review and level picture)',
  };

  /* ---- where the lines run, and what moved from its old screen point ---- */
  const wallRow = sx => r2(E.project(F.CX, F.CX - (sx - E.OX) / E.S * E.R2, 0).sy), fenceRow = sx => r2(E.project(F.CY + (sx - E.OX) / E.S * E.R2, F.CY, 0).sy);
  const corner = E.project(F.CX, F.CY, 0), houseEnd = E.project(F.CX, F.YH, 0), gateMid = E.project((F.GX0 + F.GX1) / 2, F.CY, 0);
  const LINES_WHAT = {
    corner: [r2(corner.sx), r2(corner.sy)], cornerWhat: 'the far corner (where the two lines meet), on the screen',
    wall: { foot: 'row = ' + r2(wallRow(0)) + ' - x / 2', leftEdge: [0, wallRow(0)], viewLeft: [22, wallRow(22)], farEnd: [r2(houseEnd.sx), r2(houseEnd.sy)], what: 'the house wall\'s foot: from the house\'s far corner down to the left; it leaves the picture at its left edge (and the view at x 22)' },
    fence: { foot: 'row = ' + r2(fenceRow(0)) + ' + x / 2', rightEdge: [240, fenceRow(240)], viewRight: [218, fenceRow(218)], what: 'the fence\'s foot: from the far corner down to the right; it leaves the picture at its right edge (and the view at x 218)' },
    gap: 'between the house\'s far corner (x ' + r2(houseEnd.sx) + ') and the fence\'s first post (x ' + Math.round(E.project(F.POSTS[0], F.CY + .07, 0).sx - 4) + '): the field and the hills, where the sun goes down',
  };
  // the frog's two places at the gate (round 4: they follow the gate): where they are against the fence's line, the old picture's and round 3's
  const feetGap = q => (q[1] + 25) - fenceRow(q[0] + 16);                   // rows his feet are in front of the fence's line (< 0: past it)
  const GATE9 = Object.fromEntries([['porton', PORTON4, 17], ['sale', SALE4, -3]].map(([k, q, o]) => [k, { at: q, before: r2(feetGap(q)), oldPicture: o, round3: { at: OLD.LUGAR[k].slice(0, 2), before: r2(feetGap(OLD.LUGAR[k])) } }]));
  const MOVED_WHAT = [
    'the back door: its middle 10 px right of the old one (x 42 to 52), 1.5 units wide (round 3; the old opening 30 px), its threshold on the house wall\'s foot (row ' + Math.round(wallRow(52) - F.FLOOR * E.COS * E.S) + ', the old 112); box ' + JSON.stringify(things.puerta.box) + ' (old [27, 57, 30, 56]). Follow it: abuela in the door (asoma) and whoever goes in (seva), in moves',
    'the gate: its middle 1 px left of the old one (x 147 to ' + Math.round(gateMid.sx) + '), its posts at x 133 and 159, its foot on the fence\'s line, ' + Math.round(112 - gateMid.sy) + ' rows further back (row 112 to ' + Math.round(gateMid.sy) + '); box ' + JSON.stringify(things.porton.box) + ' (old [127, 70, 40, 43]; it holds the leaf shut and swung open into the yard). Follow it: the walk to the gate (juntos, luiscorre) and (round 4) the frog\'s two places there, LUGAR.porton and LUGAR.sale (layout.gate), in moves',
    'the flamboyán: its trunk\'s foot ' + Math.round(trunkFoot.sy - 114) + ' rows lower (row 114 to ' + Math.round(trunkFoot.sy) + '), at the same x (204), against the fence (round 3: ' + F.TREE_OFF + ' in front of it, round 2 .35): the trunk is longer; its crown where the old one was (its left lobe 4 px right, clear of the gate\'s box). Nothing follows: the frog at the tree (LUGAR.arbol) is before the trunk, 5 rows of lawn and more between them',
    'the sixth star: from (112, 58) to ' + STAR6 + ' (moves)',
    'unchanged: the nest (181, 66) and every landing of the bird on it; the bird on the fence (178, 83), on a post\'s cap; the ball in the tree (196, 64); the sun (SOLX 100), the moon (150, 26)',
  ];

  return {
    scene: 'patio',
    made: 'node docs/proyecto/pixel/patio-sheet-make.js, from patio-set.html (window.PATIO_SET) and coqui/ref/escenas/patio/. Order 32a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]',
      floor: 'the yard is built round the old picture: a place on its lawn keeps its screen place. A frog place q: the ground point under (q.x + 16, q.y + 25), new q = old q. A person\'s place (x, y): the ground point under (x, y - 1), new (x, y) = old. So every ground position of patio.js, its stories and its pairs keeps its numbers, but for the few in moves; the sheet names each one (spots, remap, code, moves) with its world point',
      relative: 'what the old code draws or moves relative to a person, the frog or a point (what they carry, the flower in Carmen\'s hair, the fireflies "with" someone, the bubbles, the ball at p.x + 12) keeps its offsets',
      sky: 'screen-space effects keep their old numbers: the stars of the happy endings (final9, final10, final11), the heart (heartAt), the bird\'s loop (aveloop) and its flights, the fireflies\' way out (stake: 226, 58)',
      view: 'one view, zoom 1: the 196 x 216 window from x0 22, the old wide one',
      pair: 'a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window crop; zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2. The old rectangles (remap cam and crop) say which pictures they were',
    },
    layout: {
      what: 'the yard built as La sala is: two walls on the world\'s axes, seen at the engine\'s 30 degrees (shadows to screen right), coming together in a far corner over the middle of the picture, the lawn running off the picture\'s sides and bottom. On the LEFT the back of the house: its back wall on x = ' + F.CX + ' (it faces +x, in shade, teal siding as El frente\'s side wall), from its far corner (a white corner board, screen x ' + Math.round(E.project(F.CX, F.YH, 0).sx) + ') down off the picture\'s left edge; in it the back door in its white frame on a stone step (screen x ' + things.puerta.box[0] + ' to ' + (things.puerta.box[0] + things.puerta.box[2]) + '); over it a hip roof of red tiles, the hip over the far corner. On the FAR RIGHT the wooden fence on y = ' + F.CY + ' (it faces +y, lit), from the far corner off the picture\'s right edge, posts with caps along it; in it, near the corner, the cream garden gate between two taller posts (screen x ' + things.porton.box[0] + ' to ' + (things.porton.box[0] + things.porton.box[2]) + '); right of the gate the flamboyán, its trunk a little in front of the fence, its crown where the old one was, the nest on a branch at its left. The lawn before them, the two beds of earth at the old ellipses. The house stops 2 units short of the corner: between its far corner and the fence\'s first post the yard opens on a field and low hills (the horizon at row ' + F.HZ + '), where the sun goes down. The gate opens into the yard: its leaf swung on its left post, its face seen; through the empty opening a path of trodden earth goes out over the field and winds up the hill behind. Through the open door a dark room (no story lights it): abuela stands in the doorway, on its threshold. The lawn is the same grass as El frente\'s and El balcón\'s (round 4: the engine\'s GRASS ramp, centred where El frente\'s lawn is), calm (mostly one tone, Bayer-mixed with its neighbours), no blooms in its grass round the beds, the crate and the ball; round each bed the grass is darker, most behind its row of flower heads, with no blades (round 4: each head seen against dark lawn); the beds are turned earth in lumps, a hole for each flower',
      lines: LINES_WHAT,
      gate: Object.assign(GATE9, { what: 'the frog\'s two places at the gate (LUGAR.porton: he stops at it; LUGAR.sale: he goes out through it and fades), in rows his feet are in front of the fence\'s line at his column (< 0: past it). The old picture: porton 17 rows before its gate, sale 3 rows past it. Round 4: they follow the gate (moves): porton ' + GATE9.porton.before + ' rows before it, his middle at x ' + (PORTON4[0] + 16) + ' (the opening x 135 to 157); sale ' + (-GATE9.sale.before) + ' rows past it, on the path, his box between the posts. Round 3 had left them where the old hop counts put them: porton ' + GATE9.porton.round3.before + ' rows before, sale ' + GATE9.sale.round3.before + ' rows before (on the lawn). So some hop counts of pairs with porton or sale are not the old ones: hops lists them' }),
      why: 'page 11 decision 9 and the owner\'s three approved sets (El frente, El balcón, La sala): walls run along the world\'s axes and are seen at the engine\'s angle. Every place on the lawn keeps its old screen point (rules.floor). Round 3: everyone on the lawn has at least 5 rows of lawn between their feet and the foot of what stands behind them (round 2 put the lines as low as the places allowed, and the frog read as standing on the wall\'s base, the boy on the fence\'s): the wall\'s line went up ' + F.LIFT_W + ' row, held by the frog at the door (LUGAR.puerta) before the door\'s step; the fence\'s ' + F.LIFT_F + ' row, held by Carmen at the open gate (pair vamos, 168, 120) and the walk to the gate; the trunk stands against the fence, held by the frog at the tree. The old sun sank at x 100, right where the corner rises: a house wall there would hide it at every height, so the house ends short of the corner and the sun goes down in the gap, behind the field and the hills',
      moved: MOVED_WHAT,
    },
    behind: {
      what: 'the sky is the set\'s (baked per hour); what moves or twinkles in it is the sprite layer\'s, drawn behind the set: the sun (sol(), its rays turning with F, sinking with W.soly), the moon (luna()) and the stars (ESTRELLAS, twinkling). Each is drawn first in the sprite layer, then the set\'s own pixels are drawn again inside its box wherever the set has drawn anything (bakedZ > -1e8, and the leaves of that frame): the sky objects are farther than everything (depth -1e9, SetOverSprites). The hills are the set\'s, at depth ' + F.HILL_Z + ' (farther than any of the set\'s things, nearer than the sky objects). So the sun goes down behind the field and the hills in the gap between the house and the fence, and the house hides the stars at 40, 46 (as the old picture did), 60, 18 and 72, 64',
      items: [
        { at: 'patio.js:131', what: 'the stars (W.estrella, W.noche)', boxes: 'each star [x - 1, y - 1, 4, 4]' },
        { at: 'patio.js:132', what: 'the moon (W.luna) at 150, 26; the sun at SOLX, soly (W.soly < 110)', boxes: 'moon [139, 15, 24, 22]; sun [SOLX - 21, soly - 21, 42, 42] (its rays)' },
      ],
    },
    setKey,
    things,
    spots: Object.fromEntries(Object.entries(SPOTS).map(([k, s]) => [k, Object.assign({ world: s.world, new: s.new }, s.scale != null ? { scale: s.scale } : {}, { old: s.old, what: s.what })])),
    lugar,
    hops,
    hopsWhat: 'round 4: each pair of LUGAR places whose hop count (kit.js acts.ir: round(d / 30), 1 to 4, d the screen distance between the two frog points) is not the old one, with the old and the new count and distance; every one has porton or sale (their places followed the gate: moves). Every other pair keeps its count (hopsAll: all ' + hopsAll.length + ' pairs). acts.sevan hops 3 times to sale from wherever he is, whatever the distance',
    hopsAll,
    points: PTS,
    views,
    remap,
    pictures: PICS,
    level: LEVEL,
    clips: {},
    clipsWhat: 'patio.js never calls clip()',
    front: {
      how: 'nothing of the set covers a character: in the old picture the background (fondo: the house, the fence, the gate, the tree, the nest, the beds) was drawn before everyone, and every place is on the lawn before the house, the fence and the tree (checked: floor). The crate, the flowers, the sack and the ball stay in the sprite layer, in its list sorted by y, as before',
      parts: {},
    },
    shadows: {
      bola: { radius: .28, at: 'the ground point under it on screen (unproject(x, y - 1)), whether it lies there or is in the air over it (W.bola.h > 0: the shadow stays on the ground under it)', when: 'W.bola, and that ground point is on the lawn (x > CX, y > CY: not the ball in the tree, 196, 64, nor its flight there)', cast: 'castShadow(g.x, g.y, .05, .28)', why: 'round 3: the ball had no shadow and read as hanging in the air in front of the fence' },
      coqui: { radius: .45, at: 'the ground point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25))', when: 'W.cq.vis and al > .5', cast: 'castShadow(g.x, g.y, .3, .45)' },
      people: { radius: { grown: .35, nino: .3, bebe: .25 }, at: 'the ground point under their feet on screen (unproject(x, y - 1))', when: 'visible (vis !== 0, al > .5); the baby only on the ground, not in mamá\'s arms (bebe.z)', cast: 'standing: for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, r); sitting on the grass (sent): castShadow(g.x, g.y, .3, r)' },
      dropped: 'patio.js:108 rana()\'s dotted shadow under the frog is not drawn: the engine casts his',
    },
    dropped: [
      'patio.js:129 c.drawImage(spr("cielo" + n)) and patio.js:132 c.drawImage(spr("patio"...), fondo()) -> the set, for setKey(W)',
      'patio.js:147 the light of the hour (orange .10 at sol 2, red .17 at 3) and patio.js:148 W.osc (dark blue over everything) -> baked into the set (setKey hora); the characters, the props and the fireflies are not dimmed (El frente\'s rule)',
      'patio.js:108 the frog\'s dotted shadow -> the engine\'s cast shadow',
    ],
    moves: MOVES.map(m => Object.assign({ line: m.line, act: m.act, src: m.src, to: m.to }, m.respEn ? { respEn: m.respEn } : {}, m.pts ? { places: m.pts.map(q => Object.assign({ who: q[0] || 'whoever', old: q[1], new: q[2] }, q.length > 4 ? { z: q[3], world: q[4] } : { world: q[3] })) } : {}, m.sky ? { values: m.sky.map(s => ({ key: 'W.' + s[0], old: s[1], new: s[2] })) } : {}, { why: m.why })),
    bubbles: { what: 'each bubble\'s rectangle relative to its tail\'s tip, as patio.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]', rects: G.M.bubbles },
    talk: {
      what: 'where a bubble goes (patio.js draw: line 150 for a person, 151 for the frog). The first of these places whose bubble is wholly inside the view, clear of the corner cards shown (hud: the sun card, the basket and the nest, the fireflies) and of every face (each visible person\'s and the frog\'s, its own too); if none is, the first (the old)',
      top: 'a person: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2 - (W.lleva ? 18 : 0))',
      places: TALK, placesWhat: '[side, dy]: the tail\'s tip at (top.x + side * (h + 16), top.y + dy), h the head\'s half width: a person 6, the frog b.w >> 1',
      faces: 'a person\'s face: [hx - 6, y + top + 5 (the baby: + 4), 12, 10] (eyes to chin, not the hair), hx the head\'s middle; the frog\'s: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]',
      heads: Object.fromEntries(Object.entries(G.M.people).map(([k, v]) => [k, { top: v.box[1], head: v.head }])),
      headsWhat: 'each sprite (idle; .sent: sitting): top, the first opaque row relative to the feet row y; head, the middle of its top 10 rows relative to x (facing right; facing left: x - head, + 1 for the family sprites drawn at -PX)',
      boards: 'in the 196 x 216 display, then + the view\'s x0: W.tarjeta sol [2, 2, 36, 54]; W.tarjeta luces [2, 2, 86, 32]; W.tanteo: [2, 2, 26 + 15 max(3, canasta.length), 28] and [119, 2, 75, 28]',
    },
    code: CODE(),
    checks: { notes: [] },
  };

  function PICTURES(pic) {
    // each picture's centre is a screen point; both sides of a pair the same window. An old 113 x 60 view (1.73 x) is zoom 2 when its subject is
    // whole in 98 x 52 (niño, flor, amigo); niña is zoom 1 (mamá, 56 rows tall, is not whole in 52)
    return {
      'nino.si': pic(120, 148, 2, 'Luis on the lawn, close'), 'nino.no': pic(120, 148, 2, 'Carmen there, close'),
      'nina.si': pic(96, 132, 1, 'Carmen by the crate'), 'nina.no': pic(96, 132, 1, 'mamá there'),   // round 3: the top at the old window's (row 80): mamá's head at the top, Carmen's 12 rows lower, as in the old
      'juega.si': pic(105, 164, 1, 'Luis kicks the ball up'), 'juega.no': pic(105, 164, 1, 'Luis holds a pot, the ball at his feet'),
      'flor.si': pic(72, 176, 2, 'one red flower in bed L, close'), 'flor.no': pic(72, 176, 2, 'the ball by bed L, no flower, close'),
      'sol.si': pic(115, 45, 1, 'the sun over the fence, by day'), 'sol.no': pic(115, 45, 1, 'the moon, at night'),
      'aqui.si': pic(120, 159, 1, 'Carmen beside bed L, a flower in it'), 'aqui.no': pic(120, 159, 1, 'Carmen beside bed L, the flower in bed R'),
      'alla.si': pic(120, 159, 1, 'Luis beside bed L, the flower in bed R'), 'alla.no': pic(120, 159, 1, 'Luis beside bed L, a flower in it'),
      'amigo.si': pic(107, 160, 2, 'Luis, the frog beside him, close'), 'amigo.no': pic(107, 160, 2, 'Luis, the ball beside him, close'),
      'ven.si': pic(125, 145, 1, 'Carmen calls, the frog hops to her'), 'ven.no': pic(125, 145, 1, 'Carmen points up, the frog looks at the bird'),
      'mira.si': pic(125, 145, 1, 'Luis points up, the frog looks at the bird'), 'mira.no': pic(125, 145, 1, 'Luis calls, the frog hops to him'),
      'vamos.si': pic(145, 94, 1, 'Carmen at the open gate, the frog hops after her'), 'vamos.no': pic(145, 94, 1, 'Carmen sits with a glass, the frog holds one'),   // round 3: the gate whole, its posts' caps in
      'hasta_manana.si': pic(114, 88, 1, 'the family at the back door waves, sunset, the gate open, the frog going'), 'hasta_manana.no': pic(114, 88, 1, 'the family at the back door waves, by day, the frog stays'),
      'parque.no': pic(120, 82, 1, 'cual-camino\'s "parque" pair, its "no" side: the yard, not the park (the old window [22, 30, 196, 104])'),
    };
  }

  function CODE() {
    const C = [], c = (line, old, to, note) => C.push(note ? { line, old, to, note } : { line, old, to });
    const L = s => lineOf(s), fl = p => ({ floor: personW(p), new: personQ(personW(p)) });
    c(L('const CAMA='), 'CAMA L [40,176,56,20], R [144,176,56,20]', 'the beds (the set paints each at the old ellipse: middle (c[0] + 28, c[1] + 10), radii 28, 10); hoyo() unchanged', 'points.hoyos.L, hoyos.R');
    c(L('const CAMA='), 'SOLX=100, SOLY=[24,40,56,73]', { moved: 'SOLY=[26,40,56,73]' }, 'see moves');
    c(L('const ESTRELLAS='), 'ESTRELLAS [60,18] [84,40] [124,12] [150,36] [40,46] [112,58] [72,64] [140,60]', { moved: 'the sixth, [112,58], to ' + STAR6, point: 'estrellas' }, 'behind the set (sheet behind); see moves');
    for (const [k, v] of Object.entries(OLD.LUGAR)) c(LINES.findIndex(l => l.includes(k + ':' + JSON.stringify(v).replace(/0\./g, '.'))) + 1, 'LUGAR.' + k + ' ' + JSON.stringify(v), Object.assign({ spot: 'frog.' + k, new: SPOTS['frog.' + k].new.concat([v[2]]) }, k === 'porton' || k === 'sale' ? { moved: 'round 4: follows the gate (see moves; hop counts: hops)' } : {}));
    for (const k of ['L', 'R']) c(L('const DETRAS='), 'DETRAS.' + k + ' ' + JSON.stringify(OLD.DETRAS[k]), { spot: 'detras.' + k, new: SPOTS['detras.' + k].new });
    for (const k of ['luis', 'carmen']) c(L('const DETRAS='), 'ESPERA.' + k + ' ' + JSON.stringify(OLD.ESPERA[k]), { spot: 'espera.' + k, new: SPOTS['espera.' + k].new });
    OLD.LADOS.forEach((p, i) => c(L('const DETRAS='), 'LADOS[' + i + '] ' + JSON.stringify(p), { spot: 'lados.' + i, new: SPOTS['lados.' + i].new }));
    c(L('const caja=id=>'), 'caja(id): [x - 11, y - alto(id), 22, alto(id)]', 'relative to the person: unchanged');
    c(L('{id:"caja",si:'), 'box caja [104,112,32,24]', { thing: 'caja', box: things.caja.box }, 'the sprite layer\'s crate: unchanged');
    c(L('{id:"caja",si:'), 'box camaL [40,160,56,38]', { thing: 'camaL', box: things.camaL.box });
    c(L('{id:"caja",si:'), 'box camaR [144,160,56,38]', { thing: 'camaR', box: things.camaR.box });
    c(L('{id:"caja",si:'), 'box bola [x - 7, y - 13, 14, 14]; saco [x - 13, y - 23, 26, 24]', 'relative: unchanged');
    c(L('{id:"sol",si:'), 'box sol [SOLX-14, soly-14, 28, 28]', 'relative to the sun: unchanged (SOLY: moves)');
    c(L('{id:"sol",si:'), 'box porton [127,70,40,43]', { thing: 'porton', box: things.porton.box, hand: things.porton.hand }, 'and hand: the hint hand\'s point (new: the old had none, so the box\'s middle)');
    c(L('{id:"sol",si:'), 'box nido [170,60,22,16]', { thing: 'nido', box: things.nido.box });
    c(L('{id:"sol",si:'), 'box arbol [168,8,60,106]', { thing: 'arbol', box: things.arbol.box });
    c(L('{id:"pajaro",si:'), 'box pajaro [p[0]-10, p[1]-20, 20, 22]', 'relative to the bird: unchanged');
    c(L('{id:"pajaro",si:'), 'box puerta [27,57,30,56]', { thing: 'puerta', box: things.puerta.box });
    c(L('{id:"pajaro",si:'), 'box casa [0,14,61,100]', { thing: 'casa', box: things.casa.box });
    c(L('{id:"pajaro",si:'), 'box cerca [60,80,180,33]', { thing: 'cerca', box: things.cerca.box });
    c(L('{id:"pajaro",si:'), 'box patio [0,113,240,103]', { thing: 'patio', box: things.patio.box });
    c(L('if(id==="bebe"){const e='), 'gente bebe: drawImage at x - 13, y - 28', 'relative to the baby: unchanged');
    c(L('else if(id==="abuela"){const pose'), 'gente abuela: translate(x, y - 50), scale(-1,1) when dir < 0; drawImage(im,-30,0)', 'relative to her: unchanged');
    c(L('c.translate(x,y-im.height+1'), 'gente: scale(-1,1) when dir < 0; drawImage(im, -PX, 0) at x, y - im.height + 1', 'relative to the person: unchanged');
    c(L('if(p.pelo){'), 'the flower in her hair at x + 3, y - h + 2', 'relative: unchanged');
    c(L('if(p.lleva){if(p.pose==="alto")'), 'what a person holds: cosa at x + d * 14, y - h + 13 (alto, 2 x); x - d * 20, y - h + 30 (offer, 1.4 x); x, y - h + 34 / 38 (1.4 x)', 'relative: unchanged (the old code\'s own 1.4 x and 2 x drawings of the small things, kept as they are)');
    c(L('for(let j=0;j<3;j++)for(let i=j===1?0:2;i<b.w-5'), 'rana: the dotted shadow at b.x + 2, q.y + 25', 'dropped: the engine casts his shadow (shadows.coqui)');
    c(L('if(q.ojos)[.3,.7].forEach'), 'rana: the eyes at b.x + b.w * .3, .7', 'relative to the frog: unchanged');
    c(L('if(W.lleva)cosa(g,W.lleva'), 'rana: what he carries at b.x + b.w / 2, b.y + dy + 1; the basket at b.x + b.w - 6, b.y + b.h - 17', 'relative: unchanged');
    c(L('function bub2('), 'bub2: c.scale(2,2), bub(c,k,0,0,a)', 'relative: unchanged (the bubbles are drawn at twice their size)');
    c(L('c.drawImage(spr("cielo"+n'), 'c.drawImage(spr("cielo"+n,...),0,0)', 'dropped: the set\'s sky, for setKey(W)');
    c(L('if(W.estrella||W.noche)ESTRELLAS'), 'the stars at ESTRELLAS', 'behind the set (sheet behind)');
    c(L('if(W.luna)luna(c,150,26)'), 'luna(c,150,26); sol(c, SOLX, soly, n, brilla)', { points: ['luna', 'sol'] }, 'behind the set (sheet behind): unchanged places');
    c(L('c.drawImage(spr("patio"+'), 'c.drawImage(spr("patio"+...,()=>fondo(W.porton,W.pdoor)),0,0)', 'dropped: the set, for setKey(W) (then the sky objects\' box redrawn from the set: behind)');
    c(L('if(W.caja)L.push('), 'if(W.caja) c.drawImage(spr("caja",mkCaja),104,112) (sort y 136)', { point: 'caja', new: PTS.caja.screen }, 'the sprite layer: unchanged');
    c(L('for(const k in CAMA){const fl='), 'the flowers in the beds: florEn at hoyo(k, i), sort y CAMA[k][1] + 12', 'the sprite layer: unchanged (the set\'s holes are at hoyo())');
    c(L('if(W.rizo&&'), 'the loop the bird flew: setLineDash([2,3]) arc at z.x, z.y', 'screen: unchanged');
    c(L('if(!W.noche&&n>=2){c.fillStyle='), 'the light of the hour: c.fillRect(0,0,SW,SH)', 'dropped: baked into the set (setKey hora)');
    c(L('if(W.osc){c.fillStyle='), 'W.osc: c.fillRect(0,0,SW,SH)', 'dropped: baked into the set (setKey hora); the characters are not dimmed');
    c(L('Object.keys(G).forEach(id=>{const p=G[id];if(p&&p.bub'), 'a person\'s bubble at x, y - alto - 1', { talk: true }, 'sheet talk: the first free place');
    c(L('if(q.vis&&q.bub){const b=frogBox(q);bub2'), 'the frog\'s bubble at b.x + (b.w >> 1), b.y + 2 - (W.lleva ? 18 : 0)', { talk: true }, 'sheet talk: the first free place');
    c(L('function talkAt('), 'talkAt: [x, y - alto - 1 - (bub ? 38 : 0)]', 'relative to the person: unchanged');
    c(L('if(k==="ir"){const up='), 'respIcon ir: [13,27] ...', 'the answer card\'s own drawing: unchanged');
    c(L('else{[13,27].forEach(ex=>'), 'respIcon ver: the eyes at x + 13, x + 27', 'the answer card\'s own drawing: unchanged');
    c(L('[[4,6],[20,3],[36,6]]'), 'respIcon ver: the rays [4,6] [20,3] [36,6]', 'the answer card\'s own drawing: unchanged');
    c(L('if(W.tarjeta==="sol"){const k='), 'hud sun card tarjeta(g,3,3,34,52); g.fillRect(5,5,30,40)', 'display: unchanged');
    c(L('for(let x=5;x<35;x+=5){g.fillStyle'), 'hud sun card: the fence g.fillRect(5,42,30,1)', 'display: unchanged');
    c(L('if(W.tanteo){const mio='), 'hud tanteo tarjeta(g,3,3,...,26); the basket at 5,7', 'display: unchanged');
    c(L('if(W.tarjeta==="luces"){tarjeta(g,3,3,84,30)'), 'hud fireflies card tarjeta(g,3,3,84,30); the frog at 5,9', 'display: unchanged');
    c(L('async inicio9()'), 'inicio9: luis {x:160,y:128}, carmen {x:86,y:136}, bola {x:174,y:128}', { floor: [personW([160, 128]), personW([86, 136]), personW([174, 128])], new: [[160, 128], [86, 136], [174, 128]] }, 'the floor rule: the same screen places');
    c(L('async ensena()'), 'ensena: for(const k of [0,1,2,3])', 'not a place: the sun card\'s four steps');
    c(L('async asoma()'), 'asoma: W.gente.abuela={x:42,y:116,...}', { spot: 'asoma', new: SPOTS.asoma.new }, 'moved (see moves)');
    c(L('if(!n){W.mari=[];'), 'final9: the stars [60,150] [180,150] [120,120] [90,170] [150,170]; the butterflies at 48 + i * 24 + (i % 2) 6, 150 + (i % 3) 8', 'screen effect: unchanged (over the lawn)');
    c(L('else if(n>=3){W.luces=[{id:"medio"'), 'final9: a firefly at 150, 150', 'over the lawn: unchanged');
    c(L('async pelota(){'), 'pelota: mueve("luis",166,150), mueve("carmen",60,150)', { floor: [personW([166, 150]), personW([60, 150])], new: [[166, 150], [60, 150]] }, 'the floor rule: the same screen places');
    c(L('async bolaarbol()'), 'bolaarbol: the ball to 196, 64 (in the tree, by the nest)', 'the crown is where it was: unchanged');
    c(L('async avesale()'), 'avesale: KIT.aveVa(184,60,5,1)', 'by the nest, in the air: unchanged');
    c(L('async seva(o)'), 'seva: mueve(id,44,118)', { spot: 'seva', new: SPOTS.seva.new }, 'moved (see moves)');
    c(L('async luzsale(o)'), 'luzsale: P [70,160] [150,150] [112,190]', fl([70, 160]), 'over the lawn: the same screen places');
    c(L('async inicio10()'), 'inicio10: luis {x:190,y:160} (sitting), carmen {x:50,y:160}, saco {x:164,y:165}', { floor: [personW([190, 160]), personW([50, 160]), personW([164, 165])], new: [[190, 160], [50, 160], [164, 165]] }, 'the floor rule: the same screen places');
    c(L('async aveloop()'), 'aveloop: the loop round 150, 40, r 18; KIT.aveVa(181,66,7,-1)', { point: 'nido', new: PTS.nido.screen }, 'the loop: screen, unchanged; the nest where it was');
    c(L('async avenido()'), 'avenido: KIT.aveVa(181,66,8,-1)', { point: 'nido', new: PTS.nido.screen });
    c(L('async prepA()'), 'prepA: mueve("carmen",150,140)', fl([150, 140]), 'the floor rule: the same screen place');
    c(L('async alnido()'), 'alnido: KIT.aveVa(181,66,9,-1)', { point: 'nido', new: PTS.nido.screen });
    c(L('if(mio>=3){W.heart=1;SFX.win();fx({t:"star",n:36,pts:[[60,40]'), 'final10: the stars [60,40] [150,44] [104,30] [80,60] [130,56]', 'screen effect: unchanged (in the sky)');
    c(L('async inicio11()'), 'inicio11: abuela {x:34,y:136}, abuelo {x:60,y:126}, mama {x:86,y:136}, bebe {x:97,y:109,z:137} (in mamá\'s arms), papa {x:112,y:126}', { floor: [[34, 136], [60, 126], [86, 136], [112, 126]].map(personW), new: [[34, 136], [60, 126], [86, 136], [112, 126]] }, 'the floor rule: the same screen places; the baby relative to mamá');
    c(L('luis:{x:150,y:160,pose:"idle",dir:-1}'), 'inicio11: luis {x:150,y:160}, carmen {x:188,y:158}; ave {x:178,y:83} on the fence', { floor: [personW([150, 160]), personW([188, 158])], new: [[150, 160], [188, 158]], point: 'cerca.ave' }, 'the floor rule; the bird on the fence, on a post\'s cap (points cerca.ave)');
    c(L('async juntos(o)'), 'juntos: mueve(id,170,124)', { spot: 'juntos', new: SPOTS.juntos.new }, 'moved (see moves): right of the gate');
    c(L('async vuelveluis()'), 'vuelveluis: mueve("luis",138,138)', fl([138, 138]), 'the floor rule: the same screen place');
    c(L('async alcentro(o)'), 'alcentro: +o.x || 160, +o.y || 190', fl([160, 190]), 'the floor rule: the same screen place');
    c(L('async viene(o)'), 'viene: mueve("carmen",186,174), mueve("abuelo",52,174)', { floor: [personW([186, 174]), personW([52, 174])], new: [[186, 174], [52, 174]] }, 'the floor rule: the same screen places');
    c(L('async luiscorre()'), 'luiscorre: mueve("luis",170,124,8)', { spot: 'juntos', new: SPOTS.juntos.new }, 'moved (see moves): right of the gate');
    c(L('if(con>=3){W.aro=1;'), 'final11: the stars [110,70] [170,66] [140,56] [124,96] [160,96]', 'screen effect: unchanged');
    c(L('else{const l={id:"nueva",est:"mov",x:214,y:120'), 'final11: a firefly comes from 214,120; luzA(l, f[0]+12, f[1]-8, 14, 1)', 'over the yard: unchanged; relative to the frog');
    c(L('async sevan()'), 'sevan: KIT.aveA(150,70,10); hopTo(LUGAR.sale)', 'the bird in the air: unchanged; the frog out through the gate (LUGAR.sale, moved: see moves), where he fades');
    c(L('if(t==="luces"){const l='), 'stake: luzA(l,226,58,14,0)', 'screen: the firefly leaves to the top right, unchanged');
    c(L('KIT.escena({id:"patio"'), 'CAM.wide [22,0,196,216]', { view: 'wide', zoom: 1, x0: views.wide.x0 });
    c(L('KIT.escena({id:"patio"'), 'heartAt [118,36]', { point: 'corazon', new: PTS.corazon.screen });
    c(L('polvo:null,rizo:null,brilla:0,ave:{mode:"sit",x:181'), 'fresh(): ave {x:181,y:66}; soly: SOLY[0]', { point: 'nido', new: PTS.nido.screen }, 'the nest where it was; SOLY: moves');
    c('juego.js:16', 'fresh(): cq x 150 y 178 s 1', 'not used here: patio\'s fresh() puts him at LUGAR.centro');
    c('cual.js:21', 'panelW(): cq x 123 y 150 s .86', 'a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)');
    return C;
  }
}

/* ---------- the checks ---------- */
const FRAME_OUT = 12;                 // juego.js spot(): the frame is box +- 5 (+ 2 when it pulses), and its rings reach 5 further out
const HANDR = [-12, 0, 36, 54];        // juego.js hand(): 12 x 15 cells of 3 px, drawn from (p.x - 12, p.y), 9 px lower on the down beat
const HAND = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/juego.js'), 'utf8').match(/const HAND=(\[[^\]]*\])/)[1]);   // its rows of cells: o ink, w white
const handOn = (hp, r) => { for (const o of [0, 9]) for (let j = 0; j < HAND.length; j++) for (let i = 0; i < 12; i++) if (HAND[j][i] !== '.' && meets([Math.round(hp[0]) - 12 + i * 3, Math.round(hp[1]) + j * 3 + o, 3, 3], r)) return true; return false; };   // its drawn cells, both beats
const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
const within = (r, c) => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
const gapTo = (a, b) => Math.max(b[0] - (a[0] + a[2]), a[0] - (b[0] + b[2]), b[1] - (a[1] + a[3]), a[1] - (b[1] + b[3]));
const frogBox = q => { const w = Math.round(30 * q.s) + 2, h = Math.round(25 * q.s) + 2; return { x: Math.round(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };

function storyStates() {
  const os = require('os'), { execFileSync } = require('child_process');
  const dir = path.join(REPO, 'historia/cuentos'), stories = [];
  for (const f of fs.readdirSync(dir).sort()) { if (!f.endsWith('.json') || f.startsWith('cual-')) continue;
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'patio') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'patio-sheet-'));
  try {
    const runs = [];
    for (const st of stories) {
      execFileSync(process.execPath, [path.join(REPO, 'coqui/tool/ref/trazas/juega.mjs'), '--only', st.id, '--out', path.join(tmp, 'trazas', st.id), '--states', path.join(tmp, 'states')], { cwd: REPO, stdio: 'pipe' });
      for (const plan of ['right', 'wrong', 'alternate']) {
        const lines = fs.readFileSync(path.join(tmp, 'states', st.id, plan + '.states.jsonl'), 'utf8').split('\n').filter(Boolean).map(l => JSON.parse(l));
        runs.push({ story: st, plan, lines });
      }
    }
    return runs;
  } finally { fs.rmSync(tmp, { recursive: true, force: true }); }
}

function check(sh, G) {
  const P = [], notes = sh.checks.notes, inv = JSON.parse(fs.readFileSync(path.join(REF, 'inventory.json'), 'utf8')), pos = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const E = engine(G), F = G.F, COS = E.COS, T30 = Math.tan(Math.PI / 6), FAM = G.M.FAM;
  const deacc = s => s.replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_');
  /* the inventory: every thing, place, view, position, pair and level picture */
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to || (r.to.pictures && !r.to.pictures.length)) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  const pairs = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8'));
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-patio.json'), 'utf8'));
  const pairSides = pairs.pairs.flatMap(p => ['si', 'no'].filter(s => p[s].scene === 'patio').map(s => ({ w: p.w, side: s, file: p.file, spec: p[s] })));
  for (const ps of pairSides) if (!sh.pictures[deacc(ps.w) + '.' + ps.side]) P.push('picture missing: ' + ps.w + '.' + ps.side);
  let nLevel = 0; for (const L of pairs.level) for (const p of L.pictures) if (p.scene === 'patio') { nLevel++; if (!sh.pictures[deacc(p.pair) + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side); }
  if (sh.level.length !== nLevel) P.push('level: ' + sh.level.length + ' pictures, pairs.json ' + nLevel);
  const lines = new Set(sh.code.map(e => String(e.line)));
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1]; if (!lines.has(L)) P.push('patio.js line ' + L + ' (' + p.what + ' ' + JSON.stringify(p.nums) + ') has no entry in code'); }
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1], es = sh.code.filter(e => String(e.line) === L), nums = p.nums.slice(0, 2).map(String);
    if (!es.some(e => nums.every(n => e.old.replace(/\s/g, '').includes(n.replace(/^0\./, '.')) || e.old.replace(/\s/g, '').includes(n)))) P.push('patio.js:' + L + ' ' + JSON.stringify(p.nums) + ' (' + p.what + '): no code entry names these numbers'); }
  notes.push('inventory: ' + Object.keys(sh.things).length + ' things (old ' + inv.thingIds.length + '), ' + Object.keys(sh.lugar).length + ' frog places (old ' + Object.keys(inv.given.lugar).length + '), ' + Object.keys(sh.views).length + ' view (old ' + Object.keys(inv.given.CAM).length + '), ' + sh.remap.length + ' positions (old ' + pos.positions.length + '), ' + cual.items.length + ' review pairs of cual-patio and cual-camino\'s parque.no (' + pairSides.length + ' pictures), ' + sh.level.length + ' level pictures (old ' + nLevel + '), ' + pos.inSceneFile.length + ' places of patio.js named in code');

  /* hops */
  // round 4: every pair counted again from the places (old points: patio.js; new: lugar); the pairs whose count changed are exactly sh.hops, and
  // each of them has porton or sale (the places that followed the gate). (The frog's walks in the recorded runs: after the runs, below)
  { const L = sh.lugar, ks = Object.keys(L), changed = [];
    for (let i = 0; i < ks.length; i++) for (let j = i + 1; j < ks.length; j++) { const a = L[ks[i]], b = L[ks[j]];
      const o = hop(Math.hypot(a.old[0] - b.old[0], a.old[1] - b.old[1])), n = hop(Math.hypot(a.q[0] - b.q[0], a.q[1] - b.q[1]));
      if (o !== n) { changed.push(ks[i] + '-' + ks[j] + ' ' + o + ' ' + n); if (![ks[i], ks[j]].some(k => k === 'porton' || k === 'sale')) P.push('hops ' + ks[i] + ' - ' + ks[j] + ': old ' + o + ', new ' + n + ' (neither is porton nor sale)'); } }
    const listed = sh.hops.map(h => h.a + '-' + h.b + ' ' + h.old + ' ' + h.new);
    for (const c of changed) if (!listed.includes(c)) P.push('hops: ' + c + ' changed and is not in sheet hops');
    for (const c of listed) if (!changed.includes(c)) P.push('hops: sheet hops lists ' + c + ', which is not what the places give');
    if (sh.hopsAll.length !== ks.length * (ks.length - 1) / 2) P.push('hopsAll: ' + sh.hopsAll.length + ' pairs');
    for (const k of Object.keys(L)) if (k !== 'porton' && k !== 'sale' && (L[k].q[0] !== L[k].old[0] || L[k].q[1] !== L[k].old[1])) P.push('lugar ' + k + ': moved from ' + L[k].old + ' to ' + L[k].q);
    notes.push('hops: ' + sh.hopsAll.length + ' pairs of LUGAR places (round(d / 30), 1 to 4, kit.js acts.ir): every count as the old one but these ' + sh.hops.length + ', each with porton or sale (round 4: their places followed the gate; the other 12 places keep their points), exactly sheet hops: ' + sh.hops.map(h => h.a + ' - ' + h.b + ' ' + h.old + ' -> ' + h.new).join(', ')); }

  /* the set's pixels: which part drew each, its depth */
  const tagMap = key => { const m = new Array(240 * 216).fill(null); for (const [k, list] of Object.entries(G.parts[key])) for (const i of list) m[i] = k; return m; };
  const TAGS = Object.fromEntries(Object.keys(G.parts).map(k => [k, tagMap(k)]));
  const countIn = (tag, r, names) => { let n = 0; for (let y = Math.max(0, r[1]); y < Math.min(216, r[1] + r[3]); y++) for (let x = Math.max(0, r[0]); x < Math.min(240, r[0] + r[2]); x++) if (names.includes(tag[y * 240 + x])) n++; return n; };
  const x0 = sh.views.wide.x0, VIEW = [x0, 0, 196, 216];

  /* greenery off touch targets: no pixel any leaf of the crown can take (at any wind step: 2 px across, 1 down) inside another set thing's box, or the
     sun's at any height, or the bird's on its nest or on the fence; nothing decorative in the set at all (every part is a touch key's) */
  { const reach = new Set(); for (const i of G.leafPix) { const x = i % 240, y = Math.floor(i / 240); for (let dx = -2; dx <= 2; dx++) for (let dy = -1; dy <= 1; dy++) if (x + dx >= 0 && x + dx < 240 && y + dy >= 0 && y + dy < 216) reach.add((y + dy) * 240 + x + dx); }
    const boxes = Object.entries(sh.things).filter(([k, t]) => t.set && !['arbol', 'cerca', 'patio'].includes(k)).map(([k, t]) => [k, t.box]);
    for (const s of [26, 40, 56, 73]) boxes.push(['the sun at ' + s, [86, s - 14, 28, 28]]);
    const bird = (p, k) => boxes.push([k, [p[0] - 10, p[1] - 20, 20, 22]]); bird([181, 66], 'the bird on its nest'); bird([178, 83], 'the bird on the fence');
    for (const [k, b] of boxes) { let n = 0; for (const i of reach) { const x = i % 240, y = Math.floor(i / 240); if (x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3]) n++; }
      if (n && !/bird on its nest/.test(k)) P.push('greenery: ' + n + ' px the crown\'s leaves can take are inside the box of ' + k + ' ' + JSON.stringify(b));
      if (/bird on its nest/.test(k)) notes.push('greenery: the crown\'s lower left lobe reaches ' + n + ' px into the bird\'s box on its nest (behind the bird: the sprite layer draws the bird over it, as the old picture did)'); }
    const parts = new Set(Object.values(G.parts).flatMap(p => Object.keys(p)));
    const keyParts = ['casa', 'puerta', 'escalon', 'cerca', 'porton', 'arbol', 'nido'];
    for (const p of parts) if (!keyParts.includes(p)) P.push('decor: the set has a part ' + p + ' that is no touch key\'s');
    notes.push('greenery: no pixel the crown\'s leaves can take (at any wind step) inside the box of the gate, the nest, the door, the house, the beds, the sun at any of its heights or the bird on the fence; the set\'s parts are ' + [...parts].sort().join(', ') + ' (the step is the door\'s): nothing decorative'); }

  /* the door: whole (and who stands in it) in the wide view with a margin; a strip of wall over it */
  { const d = sh.things.puerta.box, who = [d];
    for (const k of ['asoma', 'seva']) { const p = sh.spots[k].new, m = G.M.people.abuela.box; who.push([p[0] + m[0], p[1] + m[1], m[2], m[3]]); }
    { const b = frogBox({ x: sh.lugar.puerta.q[0], y: sh.lugar.puerta.q[1], s: sh.lugar.puerta.scale }); who.push([b.x, b.y, b.w, b.h]); }
    const L = Math.min(...who.map(r => r[0])), R = Math.max(...who.map(r => r[0] + r[2])), T = Math.min(...who.map(r => r[1]));
    if (L - x0 < 8 || x0 + 196 - R < 8 || T < 8) P.push('wide view: the door or who stands in it is ' + Math.min(L - x0, x0 + 196 - R, T) + ' px from its edge (keep 8)');
    notes.push('wide view (x0 ' + x0 + '): the door, its frame and abuela in it from x ' + L + ' to ' + R + ' (' + (L - x0) + ' px from the left side), from row ' + T);
    // the strip: the wall's rows between the frame's top and the wall's top (the fascia's foot), in the door's middle column, all the house's
    const tag = TAGS['dia-shut-shut'], top = E.project(F.CX + .03, F.DM, F.FLOOR + F.DH + F.DF), wtop = E.project(F.CX, F.DM, F.HH - .12), x = Math.floor(top.sx); let n = 0, bad = 0;
    for (let y = Math.floor(top.sy) - 1; y >= Math.ceil(wtop.sy); y--) { n++; if (tag[y * 240 + x] !== 'casa') bad++; }
    if (n < 6 || bad) P.push('a strip of wall: over the door ' + n + ' px, ' + bad + ' of them not the wall');
    notes.push('a strip of wall: ' + n + ' px of wall over the door\'s frame, under the roof\'s fascia'); }

  /* the hint frames of the things on the walls and in the sky (box +- 12): the door, the gate (its box holds the leaf shut and open), the nest,
     the sun at each height wholly inside the view, asked or not; the tree's is reported (its crown is the old one, wider than the view allows) */
  { const fr = b => [b[0] - FRAME_OUT, b[1] - FRAME_OUT, b[2] + 2 * FRAME_OUT, b[3] + 2 * FRAME_OUT], out = [];
    const items = [['the door', sh.things.puerta.box], ['the gate', sh.things.porton.box], ['the nest', sh.things.nido.box]].concat([26, 40, 56, 73].map(y => ['the sun at ' + y, [86, y - 14, 28, 28]]));
    for (const [k, b] of items) { const f = fr(b); if (!within(f, VIEW)) P.push('hint frame: ' + k + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not inside the view'); else out.push(k + ' ' + Math.min(f[0] - x0, x0 + 196 - f[0] - f[2], f[1], 216 - f[1] - f[3])); }
    const t = fr(sh.things.arbol.box);
    notes.push('hint frames, asked or not: the door, the gate, the nest and the sun at each height inside the view (px from its edge: ' + out.join(', ') + '); the tree\'s ' + JSON.stringify(t) + ' is not (' + (x0 + 196 - t[0] - t[2]) + ' px on the right, ' + t[1] + ' at the top), as the old one: no story or pair asks for the tree'); }

  /* the walk to the door and to the gate ends there: seva on the door's step, in the door's width; juntos right of the gate, before its right post */
  { const d = sh.things.puerta.box, sv = sh.spots.seva.new, as = sh.spots.asoma.new, j = sh.spots.juntos.new, g = sh.things.porton.box;
    if (sv[0] < d[0] || sv[0] > d[0] + d[2] || sv[1] < d[1] + d[3] - 6 || sv[1] > d[1] + d[3] + 6) P.push('the walk to the door: seva ' + sv + ' is not at the door ' + JSON.stringify(d));
    // abuela in the door (round 3): on the threshold, her feet within 2 rows of the doorway's foot in her column, between its jambs
    { const thr = E.project(F.CX, F.CX - (as[0] - E.OX) / E.S * E.R2, F.FLOOR).sy, j0 = E.project(F.CX, F.D1, 0).sx, j1 = E.project(F.CX, F.D0, 0).sx;
      if (Math.abs(as[1] - 1 - thr) > 2 || as[0] < j0 + 6 || as[0] > j1 - 6) P.push('abuela in the door: ' + as + ' is not on its threshold (row ' + r2(thr) + ' at her column, the jambs at x ' + r2(j0) + ', ' + r2(j1) + ')');
      // the dark doorway seen round her: at the rows of her head, opening pixels left and right of her sprite (idle and both frames of her
      // wave); over her head, rows of opening
      const open = new Set(); for (let a = F.D0 + .02; a <= F.D1 - .02; a += .02) for (let z = F.FLOOR; z <= F.FLOOR + F.DH; z += .02) { const q = E.project(F.CX, a, z); open.add(Math.floor(q.sy) * 240 + Math.floor(q.sx)); }
      let least = [99, 99, 99];
      for (const pose of ['idle', 'wave0', 'wave1']) { const m = G.M.masks['abuela.' + pose], top = Math.min(...m.map(r => r[0]));
        let above = 0; for (let y = as[1] + top - 1; open.has(y * 240 + as[0]); y--) above++;
        let L = 99, Rr = 99; for (const [dy, a0, b0] of m) { if (dy > top + (pose === 'idle' ? 16 : 6)) continue; const y = as[1] + dy; let l = 0, rr = 0;
          for (let x = as[0] + a0 - 1; open.has(y * 240 + x); x--) l++; for (let x = as[0] + b0 + 1; open.has(y * 240 + x); x++) rr++; L = Math.min(L, l); Rr = Math.min(Rr, rr); }
        least = [Math.min(least[0], above), Math.min(least[1], L), Math.min(least[2], Rr)]; }
      if (least[0] < 3 || least[1] < 1 || least[2] < 1) P.push('abuela in the door: the doorway round her head: ' + least[0] + ' rows over it, ' + least[1] + ' px on her left, ' + least[2] + ' on her right (keep 3, 1, 1)');
      notes.push('abuela in the door: her feet (' + as + ') on the threshold (row ' + r2(thr) + ' in her column), between the jambs (x ' + Math.round(j0) + ' to ' + Math.round(j1) + '); the dark doorway round her head: ' + least[0] + ' rows over it, at least ' + least[1] + ' px on her left and ' + least[2] + ' on her right at every row of her head (idle; waving, over her raised arm)'); }
    const postFoot = E.project(F.GP1, F.CY, 0);
    if (j[0] - postFoot.sx > 12 || j[0] < postFoot.sx || j[1] - postFoot.sy > 16) P.push('the walk to the gate: juntos ' + j + ' is not at the gate (its right post\'s foot ' + [Math.round(postFoot.sx), Math.round(postFoot.sy)] + ')');
    notes.push('walks: whoever goes in ends at ' + sv + ', on the door\'s step in its width (the door ' + d[0] + ' to ' + (d[0] + d[2]) + ', its foot row ' + (d[1] + d[3]) + '); abuela in the door at ' + as + '; the walk to the gate ends at ' + j + ', ' + Math.round(j[0] - postFoot.sx) + ' px right of its right post\'s foot and ' + Math.round(j[1] - postFoot.sy) + ' rows before it'); }

  /* the nest: the bird on it rests on it (the nest's rim under its feet, seen); the bird on the fence stands on the boards' tops */
  { const tag = TAGS['dia-shut-shut'], ave = G.M.ave;
    const feetOn = (p, part, where) => { const rows = ave[-1], last = Math.max(...rows.map(r => r[0])), feet = rows.filter(r => r[0] === last); let under = 0, cols = 0;
      for (const [dy, a, b] of feet) for (let x = p[0] + a; x <= p[0] + b; x++) { cols++; for (let y = p[1] + dy + 1; y <= p[1] + dy + 2; y++) if (tag[y * 240 + x] === part) { under++; break; } }
      if (under < cols) P.push('perch: ' + where + ': ' + under + ' of ' + cols + ' columns under its feet are ' + part);
      return [under, cols, p[1] + last]; };
    const a = feetOn(sh.points.nido.screen, 'nido', 'the bird on its nest'), b = feetOn(sh.points['cerca.ave'].screen, 'cerca', 'the bird on the fence');
    notes.push('perch: the bird on its nest has the nest under its feet (' + a[0] + ' of ' + a[1] + ' columns, its feet row ' + a[2] + '); on the fence (inicio11), the boards\' tops under its feet (' + b[0] + ' of ' + b[1] + ')');
    // what is behind the bird on the nest: sky and leaves, no other part (the old: the crown)
    const behind = countIn(tag, [171, 46, 20, 20], ['casa', 'cerca', 'porton', 'puerta']);
    if (behind) P.push('perch: ' + behind + ' px of the house, fence or gate behind the bird on its nest'); }

  /* the beds: the five holes of each where the old ones were (a flower stands in each); behind the flowers' heads (rows y - 18 .. y - 9) the lawn,
     nothing of the set (plain ground); the crate on the lawn with the lawn behind its flowers; the ball on the lawn at its old places */
  { for (const key of Object.keys(TAGS)) { const tag = TAGS[key], K = G.kinds[key];
      for (const k of ['L', 'R']) for (const h of F.HOLES[k]) { const head = [h[0] - 4, h[1] - 18, 9, 9];
        const n = countIn(tag, head, ['casa', 'puerta', 'escalon', 'cerca', 'porton', 'arbol', 'nido']); if (n) P.push('beds ' + key + ': ' + n + ' px of the set behind the flower at ' + h);
        if (K[h[1] * 240 + h[0]] !== G.K.road) P.push('beds ' + key + ': the hole at ' + h + ' is not in the earth'); }
      const crate = [104, 113, 32, 23], n = countIn(tag, crate, ['casa', 'puerta', 'escalon', 'porton', 'arbol', 'nido']); if (n) P.push('crate ' + key + ': ' + n + ' px of the set behind the crate');
      let lawn = 0; for (let x = 105; x < 135; x++) if (K[135 * 240 + x] === G.K.grass) lawn++; if (lawn < 28) P.push('crate ' + key + ': its bottom row is on ' + lawn + ' px of lawn'); }
    notes.push('beds: each of the ten holes is in its bed\'s earth where the old one was; behind every flower\'s head (9 x 9 over its hole) only the lawn, in every baked state; the crate\'s bottom row on the lawn, nothing of the set behind it'); }

  /* round 4: the lawn is El frente's grass (the engine's GRASS ramp) and green at every hour (its mean colour: green over red and over blue, its
     hue 65 degrees or more, yellow green to green, as El frente\'s by day (76); not olive or brown, hue 20 to 60, at dusk or at night); each flower head stands out on the lawn right over and beside it (the yellow petal, the old
     picture's least: its mean CIE76 difference to the lawn pixels 2 to 7 rows over the head, 4 px either side, as flowers.py measures it, by
     day, at least the old picture's 57) */
  { const lab = c => { const f = u => { u /= 255; return u > .04045 ? ((u + .055) / 1.055) ** 2.4 : u / 12.92; }, [r, g, b] = c.map(f), X = (.4124 * r + .3576 * g + .1805 * b) / .9505, Y = .2126 * r + .7152 * g + .0722 * b, Z = (.0193 * r + .1192 * g + .9505 * b) / 1.089, h = t => t > .008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116; return [116 * h(Y) - 16, 500 * (h(X) - h(Y)), 200 * (h(Y) - h(Z))]; };
    const dE = (a, b) => Math.hypot(...lab(a).map((v, k) => v - lab(b)[k])), hours = [];
    for (const key of STATES.filter(k => k.endsWith('-shut-shut'))) { const C = G.rgb[key], K = G.kinds[key]; let n = 0, m = [0, 0, 0];
      for (let y = 120; y < 216; y++) for (let x = 0; x < 240; x++) { const i = y * 240 + x; if (K[i] !== G.K.grass) continue; n++; for (let k = 0; k < 3; k++) m[k] += C[i * 3 + k]; }
      m = m.map(v => Math.round(v / n)); const hue = Math.round(60 * (2 + (m[2] - m[0]) / (m[1] - Math.min(m[0], m[2])))); hours.push(key.split('-')[0] + ' ' + m.join(',') + ' (hue ' + hue + ')');
      if (!(m[1] > m[0] && m[1] > m[2] && hue >= 65)) P.push('lawn ' + key + ': its mean colour ' + m + ' (hue ' + hue + ') is not green'); }
    const C = G.rgb['dia-shut-shut'], YEL = [255, 224, 112], least = [];
    for (const k of ['L', 'R']) for (const h of F.HOLES[k]) { let s = 0, n = 0; for (let y = h[1] - 25; y < h[1] - 19; y++) for (let x = h[0] - 4; x <= h[0] + 4; x++) { const i = y * 240 + x; s += dE(YEL, [C[i * 3], C[i * 3 + 1], C[i * 3 + 2]]); n++; }
      least.push(Math.round(s / n)); if (s / n < 57) P.push('flowers: a yellow head at ' + h + ' stands out ' + Math.round(s / n) + ' from the lawn over it (the old picture: 57)'); }
    notes.push('lawn (round 4): El frente\'s grass (GRASS), green at every hour (mean colour of the lawn, El frente\'s by day hue 76: ' + hours.join('; ') + '); a yellow flower head at each hole stands out from the lawn over it by ' + Math.min(...least) + ' at the least (mean CIE76, flowers.py\'s measure; the old picture 57 at every hole, round 3 58)'); }

  /* the sun sets behind the fence: its disc (r 11 at SOLX, soly) wholly in the sky at its first three heights, nearly at the fourth (on the fence,
     as the old), and wholly behind the set at 109 (after puesta); in every hour it is drawn in */
  { const sunNotes = [];
    for (const key of Object.keys(G.z)) { const Z = G.z[key], hora = key.split('-')[0]; if (hora === 'noche') continue;
      for (const sy of [26, 40, 56, 73, 109]) { let n = 0, sky = 0; for (let y = sy - 11; y <= sy + 11; y++) for (let x = 89; x <= 111; x++) { if ((x + .5 - 100) ** 2 + (y + .5 - sy) ** 2 > 121) continue; n++; if (Z[y * 240 + x] < -1e8) sky++; }
        const f = sky / n; if ((sy <= 56 && f < 1) || (sy === 73 && f < .85) || (sy === 109 && f > 0)) P.push('sun ' + key + ': at soly ' + sy + ' ' + Math.round(f * 100) + '% of its disc is in the sky');
        if (key.startsWith('ocaso-shut-shut') || key === 'dia-shut-shut') sunNotes.push(sy + ': ' + Math.round(f * 100) + '%'); } }
    notes.push('sun: the part of its disc in the sky at soly ' + [...new Set(sunNotes)].join(', ') + ' (the old: the fence hid 2 rows at 73, all at 109; now the field, the hills and the far corner\'s lawn)'); }

  /* round 3: the open gate reads as open, the shut one as shut, at a glance. The opening (between the posts, from the foot up to the leaf's
     arch): shut, the leaf fills it; open, no pixel of the gate or the fence in it, the path seen in it. Open, the leaf's face is seen (its
     width on the screen), standing in the yard beside the opening */
  const openingPx = (() => { const out = [], a0 = E.project(F.GX0 + .1, F.CY, 0).sx, a1 = E.project(F.GX1 - .1, F.CY, 0).sx;   // (2 px clear of the posts)
    for (let x = Math.ceil(a0); x < Math.floor(a1); x++) { const t = (x + .5 - a0) / (a1 - a0), foot = E.project(F.GX0 + t * (F.GX1 - F.GX0), F.CY, 0).sy, top = foot - (F.GH + F.GARCH * Math.sin(Math.PI * t)) * COS * E.S;
      for (let y = Math.ceil(top + 1); y < Math.floor(foot - 1); y++) out.push(y * 240 + x); }
    return out; })();
  { const res = {};
    for (const key of Object.keys(TAGS)) { const tag = TAGS[key], K = G.kinds[key], open = key.endsWith('-open');
      let gate = 0, path = 0; for (const i of openingPx) { if (tag[i] === 'porton' || tag[i] === 'cerca') gate++; if (K[i] === G.K.road) path++; }
      const fg = gate / openingPx.length;
      if (open ? (gate > 0 || path < 40) : fg < .9) P.push('gate ' + key + ': in its opening (' + openingPx.length + ' px) ' + gate + ' px of the gate or the fence, ' + path + ' of the path' + (open ? ' ' + JSON.stringify(openingPx.filter(i => tag[i] === 'porton' || tag[i] === 'cerca').map(i => [i % 240, Math.floor(i / 240), tag[i]])).slice(0, 300) : ''));
      res[key] = [Math.round(fg * 100), path]; }
    const w = Math.abs(E.project(F.GX0 + Math.cos(F.GATE_OPEN) * (F.GX1 - F.GX0), F.CY + Math.sin(F.GATE_OPEN) * (F.GX1 - F.GX0), 0).sx - E.project(F.GX0, F.CY, 0).sx);
    if (w < 14) P.push('gate: open, its leaf is ' + r2(w) + ' px wide on the screen (edge on; keep 14)');
    notes.push('gate (round 3): shut, its leaf fills ' + res['dia-shut-shut'][0] + '% of the opening (' + openingPx.length + ' px); open, the opening has no pixel of the gate or the fence, and ' + res['dia-shut-open'][1] + ' px of the path (day; ' + res['noche-open-open'][1] + ' at night); the open leaf stands in the yard beside it, its face ' + r2(w) + ' px wide on the screen (round 2: edge on)'); }

  /* round 3: the open door shows a dim room (no story lights it): the doorway, shut, is the door's wood; open, every pixel in it dark (as the
     old picture's open door), by day and at night */
  { const dpx = []; const z0 = F.FLOOR + .05, z1 = F.FLOOR + F.DH - .05;
    for (let a = F.D0 + .04; a <= F.D1 - .04; a += .02) for (let z = z0; z <= z1; z += .02) { const q = E.project(F.CX, a, z); dpx.push(Math.floor(q.sy) * 240 + Math.floor(q.sx)); }
    const uniq = [...new Set(dpx)], lum = c => .3 * c[0] + .59 * c[1] + .11 * c[2]; const res = [];
    for (const key of Object.keys(G.rgb)) if (key.includes('-open-')) { const C = G.rgb[key]; let mx = 0, sum = 0; for (const i of uniq) { const l = lum([C[i * 3], C[i * 3 + 1], C[i * 3 + 2]]); mx = Math.max(mx, l); sum += l; }
      if (mx > 75) P.push('door ' + key + ': the open doorway is not dim (its brightest pixel ' + Math.round(mx) + ')'); res.push(key.split('-')[0] + ' ' + Math.round(sum / uniq.length) + '/' + Math.round(mx)); }
    notes.push('door (round 3): open, the doorway is a dim room: its pixels\' mean / brightest luminance ' + res.join(', ') + ' (0 to 255; El frente\'s dim room is about 60)'); }

  /* round 3: the stars (night) are behind the set and seen as stars in the sky: each one (its cross, 4 x 4) wholly in the sky with no pixel of
     the set within 2 px of it, or wholly hidden by the set (a star half cut by a post, or one touching a post's top, reads as a lamp on it) */
  { const out = [];
    for (const key of Object.keys(G.z).filter(k => k.startsWith('noche'))) { const Z = G.z[key];
      for (const [sx, sy] of sh.points.estrellas.screen) { let cov = 0, n = 0, near = 0;
        for (let y = sy - 1; y <= sy + 2; y++) for (let x = sx - 1; x <= sx + 2; x++) { n++; if (Z[y * 240 + x] > -1e8) cov++; }
        for (let y = sy - 3; y <= sy + 4; y++) for (let x = sx - 3; x <= sx + 4; x++) if (y >= 0 && x >= 0 && Z[y * 240 + x] > -1e8 && Z[y * 240 + x] !== F.HILL_Z) near++;
        if (cov && cov < n) P.push('stars ' + key + ': the star at ' + [sx, sy] + ' is half hidden by the set (' + cov + ' of ' + n + ' px)');
        else if (!cov && near) P.push('stars ' + key + ': the star at ' + [sx, sy] + ' has ' + near + ' px of the set within 2 px (it sits on it)');
        else if (key === 'noche-shut-shut') out.push([sx, sy] + (cov ? ' hidden' : ' in the sky')); } }
    notes.push('stars: ' + out.join(', ') + ' (none half hidden, none touching the set, in the night states)'); }

  /* every moment of every run */
  const runs = storyStates();
  // round 4: the frog's walks between LUGAR places in the recorded runs (the old code's): which of them take a hop more or less now (sheet hops)
  { const L = sh.lugar, ks = Object.keys(L), at = {}; for (const k of ks) at[L[k].old.join(',')] = k; const walks = new Map();
    for (const r of runs) { let prev = null;
      for (const ln of r.lines) { const q = ln.W.cq; if (!q || !q.vis) continue; const k = at[q.x + ',' + q.y]; if (!k) { prev = null; continue; }
        if (prev && prev !== k) { const pr = [prev, k].sort((x, y) => ks.indexOf(x) - ks.indexOf(y)).join(' - '); walks.set(pr, (walks.get(pr) || 0) + 1); } prev = k; } }
    const hit = [...walks.keys()].filter(w => sh.hops.some(h => h.a + ' - ' + h.b === w));
    notes.push('hops in the recorded runs: the frog walks from place to place ' + [...walks.entries()].map(([k, n]) => k + ' (' + n + ')').join(', ') + '; ' + (hit.length ? 'a hop more or less in ' + hit.join(', ') : 'none of these takes a hop more or less') + ' (sevan, porton to sale, hops 3 times, as before)'); }
  const at =(st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;
  const alto = (id, p) => id === 'abuela' ? 51 : id === 'bebe' ? 28 : (['luis', 'carmen'].includes(id) ? (p && p.sent ? 40 : 44) : (p && p.sent ? 49 : 56));
  const shown = p => p && p.vis !== 0 && !(p.al != null && p.al <= .3);
  const people = w => Object.entries(w.gente || {}).filter(([id, p]) => shown(p));
  const spr = (id, p) => G.M.people[id + (p.sent && id !== 'abuela' && id !== 'bebe' ? '.sent' : '')];
  const body = (id, p) => { const m = spr(id, p), b = m.box, x = Math.round(p.x), y = Math.round(p.y);
    return p.dir < 0 && id !== 'bebe' ? [x - (b[0] + b[2]) + (id === 'abuela' ? 0 : 1), y + b[1], b[2], b[3]] : [x + b[0], y + b[1], b[2], b[3]]; };
  const faceOf = (id, p) => { const m = spr(id, p), b = body(id, p), hx = p.dir < 0 && id !== 'bebe' ? Math.round(p.x) - m.head + (id === 'abuela' ? 0 : 1) : Math.round(p.x) + m.head;
    return [Math.round(hx - 6), b[1] + (id === 'bebe' ? 4 : 5), 12, 10]; };
  const frogFace = q => { const b = frogBox(q); return [b.x + 2, b.y + Math.round(q.dy || 0), b.w - 4, Math.round(b.h * .6)]; };
  const BUBR = G.M.bubbles, bubRect = (k, tx, ty) => { const r = BUBR[k]; if (!r) throw new Error('no bubble ' + k); return [tx + r[0], ty + r[1], r[2], r[3]]; };
  // the old runs' W in the new places (sheet moves): a person at a moved place of an act the story uses goes to its new one; soly 24 is 26
  const MVall = sh.moves.flatMap(m => (m.places || []).map(q => Object.assign({ act: m.act }, q)));
  const RMall = sh.remap.filter(e => e.moved).map(e => ({ old: e.old, new: e.new, files: e.uses.map(u => u.split(' ')[0].replace(/\.json$/, '')) }));
  let MV = MVall, RM = RMall, EN = null;
  const remapW = w0 => { const w = JSON.parse(JSON.stringify(w0));
    for (const [id, p] of Object.entries(w.gente || {})) { if (!p || p.x == null) continue; const m = MV.find(q => (q.who === 'whoever' || q.who === id) && q.old[0] === Math.round(p.x) && q.old[1] === Math.round(p.y));
      if (m) { p.x = m.new[0]; p.y = m.new[1]; if (m.z != null) p.z = m.z; } }
    for (const [id, p] of Object.entries(w.gente || {})) { if (!p || p.x == null) continue; const m = RM.find(q => q.old[0] === Math.round(p.x) && q.old[1] === Math.round(p.y)); if (m) { p.x = m.new[0]; p.y = m.new[1]; } }
    if (w.cq) { const m = MV.find(q => q.who === 'cq' && q.old[0] === Math.round(w.cq.x) && q.old[1] === Math.round(w.cq.y)); if (m) { w.cq.x = m.new[0]; w.cq.y = m.new[1]; } }   // round 4: the frog at the gate
    if (w.soly === 24) w.soly = 26;
    if (EN && w.gente && w.gente.abuela && w.gente.mama) w.respEn = EN;   // after inicio11 (the family is there)
    return w; };
  let nM = 0, nB = 0, worstView = 99, worstBoard = 99; const seen = new Set(), reached = new Set(), ballSeen = new Set();
  const facesOf = w => { const f = people(w).filter(([id, p]) => !(p.al != null && p.al < .5)).map(([id, p]) => [id + '\'s face', faceOf(id, p)]); if (w.cq && w.cq.vis && !(w.cq.al < .5)) f.push(['the frog\'s face', frogFace(w.cq)]); return f; };
  const talk = (k, top, view, boards, faces, h = 6) => { for (const [side, dy] of sh.talk.places) { const r = bubRect(k, top[0] + side * (h + 16), top[1] + dy);
      if (within(r, view) && !boards.some(b => meets(r, b[1])) && !faces.some(f => meets(r, f[1]))) return r; } return bubRect(k, top[0], top[1]); };
  // each person's recorded bubble and the ones an act can show at any moment: "amor" (poke: anyone touched), "q" (duda, encoge: Carmen, abuelo,
  // Luis); the frog's recorded one, his "amor" (abrazo) and "q" (turno, duda)
  const bubblesOf = (w, acts = true, view = VIEW) => {
    const out = [], boards = boardsOf(w, view[0]), faces = facesOf(w);
    for (const [id, p] of people(w)) { if (p.al != null && p.al < .5) continue;
      const ks = new Set(p.bub ? [p.bub] : []); if (acts) { ks.add('amor'); if ((w.__q || []).includes(id)) ks.add('q'); }
      for (const k of ks) out.push([id + ' (' + Math.round(p.x) + ',' + Math.round(p.y) + (p.sent ? ' sitting' : '') + ') "' + k + '"', talk(k, [Math.round(p.x), Math.round(p.y) - alto(id, p) - 1], view, boards, faces)]); }
    const q = w.cq; if (q && q.vis && !(q.al < .5)) { const b = frogBox(q); for (const k of new Set((acts ? [q.bub, 'amor', (w.__q || []).includes('cq') ? 'q' : null] : [q.bub]).filter(Boolean))) out.push(['the frog (' + q.x + ',' + q.y + ') "' + k + '"', talk(k, [b.x + (b.w >> 1), b.y + 2 - (w.lleva ? 18 : 0)], view, boards, faces, b.w >> 1)]); }
    return out; };
  const judge = (where, rect, box, boards, faces) => {
    if (!within(rect, box)) { P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is not wholly inside ' + JSON.stringify(box)); return; }
    worstView = Math.min(worstView, rect[0] - box[0], box[0] + box[2] - rect[0] - rect[2], rect[1] - box[1], box[1] + box[3] - rect[1] - rect[3]);
    for (const [bn, b] of boards) { if (meets(rect, b)) P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is over ' + bn + ' ' + JSON.stringify(b)); else worstBoard = Math.min(worstBoard, gapTo(rect, b)); }
    for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is on ' + fn + ' ' + JSON.stringify(f));
  };
  // standing on clear ground: no set pixel nearer than a character inside its body (the house, the door and its step, the fence, the gate, the tree, the nest)
  const NEAR = .08;
  const SOLID = ['casa', 'puerta', 'escalon', 'cerca', 'porton', 'arbol', 'nido'];
  const vAt = (sx, sy) => { const g = E.atZ(sx, sy, 0); return (g[0] + g[1]) / E.R2; };
  const nearer = (key, r, v, names) => { const Z = G.z[key], tag = TAGS[key]; let n = 0;
    for (let y = Math.max(0, r[1]); y < Math.min(216, r[1] + r[3]); y++) for (let x = Math.max(0, r[0]); x < Math.min(240, r[0] + r[2]); x++) { const i = y * 240 + x; if (names.includes(tag[i]) && Z[i] > (v + NEAR) / COS - (y + .5 - E.OY) * T30 / E.S) n++; }
    return n; };
  const floorSeen = new Set(); let nFloor = 0, nSit = 0;
  /* round 3: clear lawn behind the feet. At every column of someone's feet (the frog's: his bottom row less 2 px each side), between the feet
     row and the lowest pixel of the set's standing things in that column (the house wall, the door's step, the fence, the gate, the trunk:
     the foot of whatever is behind them) at least CLEAR rows of lawn. Not abuela in the doorway (asoma: on the threshold), not the baby in arms */
  const CLEAR = 5, footOf = {}, clearLeast = { wall: [99], fence: [99], tree: [99] };
  const footRows = key => footOf[key] || (footOf[key] = (() => { const tag = TAGS[key], out = new Array(240).fill(null);
    for (let x = 0; x < 240; x++) for (let y = 215; y >= 0; y--) { const t = tag[y * 240 + x]; if (['casa', 'puerta', 'escalon', 'cerca', 'porton', 'arbol'].includes(t)) { out[x] = [y, t]; break; } }
    return out; })());
  const lineOf3 = t => t === 'arbol' ? 'tree' : t === 'cerca' || t === 'porton' ? 'fence' : 'wall';
  const clearCheck = (where, who, key, x0f, x1f, feet) => { const fr = footRows(key); let least = 99, at = null;
    for (let x = Math.max(0, x0f); x <= Math.min(239, x1f); x++) { const f = fr[x]; if (!f) continue; const g = feet - f[0] - 1; if (g < least) { least = g; at = [x, f[1]]; } }
    if (!at) return; const ln = lineOf3(at[1]); if (least < clearLeast[ln][0]) clearLeast[ln] = [least, where + ' ' + who];
    if (least < CLEAR) P.push('clear lawn: ' + where + ' ' + who + ': ' + least + ' rows of lawn between the feet (row ' + feet + ') and the foot of the ' + ln + ' (' + at[1] + ') at x ' + at[0] + ' (keep ' + CLEAR + ')'); };
  const feetCols = (id, p) => { const pose0 = id === 'bebe' ? (p.est || 'idle') : (p.pose === 'alto' ? 'wave0' : p.pose || 'idle'), sent = p.sent && id !== 'abuela' && id !== 'bebe' ? '.sent' : '';
    const k = G.M.masks[id + '.' + pose0 + sent] ? id + '.' + pose0 + sent : G.M.masks[id + '.' + pose0 + '0' + sent] ? id + '.' + pose0 + '0' + sent : id + '.idle' + sent;
    const m = G.M.masks[k], last = Math.max(...m.map(r => r[0])), rows = m.filter(r => r[0] >= last - 1), x = Math.round(p.x), flip = p.dir < 0 && id !== 'bebe', o = id === 'abuela' ? 0 : 1;
    const a = Math.min(...rows.map(r => r[1])), b = Math.max(...rows.map(r => r[2]));
    return flip ? [x - b + o, x - a + o, Math.round(p.y) + last] : [x + a, x + b, Math.round(p.y) + last]; };
  const floorCheck = (where, w) => {
    const key = keyOf(w); reached.add(key);
    if (!STATES.includes(key)) P.push('state: ' + where + ' reaches ' + key + ', which is not baked');
    for (const [id, p] of people(w)) {
      if (p.z) continue;                                                       // the baby in mamá's arms
      const k = JSON.stringify([id, Math.round(p.x), Math.round(p.y), !!p.sent, key]); if (floorSeen.has(k)) continue; floorSeen.add(k);
      if (p.sent) nSit++; else nFloor++;
      const v = vAt(Math.round(p.x), Math.round(p.y) - 1), g = E.atZ(Math.round(p.x), Math.round(p.y) - 1, 0);
      const inDoor = id === 'abuela' && g[0] > F.CX - .4 && g[0] < F.CX + .05 && g[1] > F.D0 && g[1] < F.D1;
      if ((g[0] < F.CX + .05 && !inDoor) || g[1] < F.CY + .05) P.push('ground: ' + where + ' ' + id + ' at ' + Math.round(p.x) + ',' + Math.round(p.y) + ' stands ' + (g[1] < F.CY + .05 ? 'behind the fence' : g[1] > F.YH ? 'inside the house' : 'beyond the far corner') + ' (x ' + r2(g[0]) + ', y ' + r2(g[1]) + ')');
      const onStep = g[0] > F.STEP[0] - .05 && g[0] < F.STEP[1] + .15 && g[1] > F.STEP[2] && g[1] < F.STEP[3];   // on the door's step, in the doorway: the step is under them, the frame's foot beside them
      if (!inDoor) { const fc = feetCols(id, p); clearCheck(where, id + ' at ' + Math.round(p.x) + ',' + Math.round(p.y), key, fc[0], fc[1], fc[2]); }
      // in the doorway (abuela, asoma) she is drawn over the door's frame and the wall beside it, as the old picture drew her in its door
      const n = nearer(key, body(id, p), v, inDoor ? SOLID.filter(k => !['escalon', 'puerta', 'casa'].includes(k)) : onStep ? SOLID.filter(k => k !== 'escalon' && k !== 'puerta') : SOLID);
      if (n) P.push('ground: ' + where + ' ' + id + ' at ' + Math.round(p.x) + ',' + Math.round(p.y) + ': ' + n + ' px of the set nearer than them inside their body');
    }
    const q = w.cq; if (q && q.vis) { const k = JSON.stringify(['cq', q.x, q.y, q.s, key]); if (!floorSeen.has(k)) { floorSeen.add(k); nFloor++;
      const b = frogBox(q), n = nearer(key, [b.x, b.y, b.w, b.h], vAt(b.x + b.w / 2, q.y + 25), SOLID), g = E.atZ(b.x + b.w / 2, q.y + 25, 0);
      if (g[0] < F.CX + .05 || g[1] < F.CY + .05) P.push('ground: ' + where + ' the frog at ' + q.x + ',' + q.y + ' is beyond the house or the fence');
      clearCheck(where, 'the frog at ' + q.x + ',' + q.y, key, b.x + 2, b.x + b.w - 3, q.y + 25);
      if (n) P.push('ground: ' + where + ' the frog at ' + q.x + ',' + q.y + ': ' + n + ' px of the set nearer than him inside his box'); } }
  };
  const actsOf = st => new Set((JSON.stringify(st).match(/"act":\s*"[a-z0-9]+"/g) || []).map(a => a.split('"')[3]));
  const forRun = r => { const a = actsOf(r.story); MV = MVall.filter(q => a.has(q.act) || q.act === '*'); RM = RMall.filter(q => q.files.includes(r.story.id)); EN = (sh.moves.find(m => m.respEn && a.has(m.act)) || {}).respEn || null; };
  for (const r of runs) { forRun(r); for (const L of r.lines) {
    if (JSON.stringify(L.cam) !== '[22,0,196,216]') P.push(r.story.id + ' ' + r.plan + ' ' + L.path + ': a view the sheet does not have ' + JSON.stringify(L.cam));
    const w = remapW(L.W), boards = boardsOf(w, x0), faces = facesOf(w); nM++;
    { const st = L.path && at(r.story, L.path); if (st && typeof st === 'object' && ['duda', 'encoge', 'turno'].includes(st.act)) w.__q = [st.act === 'turno' ? 'cq' : st.quien || 'luis']; }
    for (const [who, rect] of bubblesOf(w)) { const key = JSON.stringify([who, rect, boards]); if (seen.has(key)) continue; seen.add(key); nB++; judge(r.story.id + ' ' + r.plan + ' ' + L.path + ': ' + who, rect, VIEW, boards, faces); }
    floorCheck(r.story.id + ' ' + r.plan + ' ' + L.path + ':', w);
    if (w.bola && !(w.bola.h > 0) && !(Math.round(w.bola.x) === 196 && Math.round(w.bola.y) === 64)) { const b = [Math.round(w.bola.x) - 7, Math.round(w.bola.y) - 13, 14, 14], k = JSON.stringify(b);
      if (!ballSeen.has(k)) { ballSeen.add(k); const n = countIn(TAGS[keyOf(w)], b, ['casa', 'puerta', 'escalon', 'cerca', 'porton', 'arbol', 'nido']); if (n) P.push('ball: ' + r.story.id + ' ' + L.path + ' at ' + b + ': ' + n + ' px of the set behind it');
        // round 3: lying on the grass: lawn under it (5 rows clear of what stands behind it, as anyone's feet), and its shadow cast there (shadows.bola)
        clearCheck('ball: ' + r.story.id + ' ' + r.plan + ' ' + L.path + ':', 'the ball at ' + Math.round(w.bola.x) + ',' + Math.round(w.bola.y), keyOf(w), Math.round(w.bola.x) - 5, Math.round(w.bola.x) + 5, Math.round(w.bola.y));
        const g = E.atZ(Math.round(w.bola.x), Math.round(w.bola.y) - 1, 0); if (!(g[0] > F.CX + .05 && g[1] > F.CY + .05)) P.push('ball: ' + r.story.id + ' ' + L.path + ' at ' + b + ': its ground point is not on the lawn (no shadow under it)'); } }
  } }
  notes.push('ball: at its ' + ballSeen.size + ' places on the lawn the lawn alone behind it, at least ' + CLEAR + ' rows of lawn between it and the foot of the fence behind it, its ground point on the lawn, where its shadow is cast (shadows.bola) (in the tree, by the nest, as the old: the crown; no shadow)');

  /* the asks: hint frames inside the view, the hand on no face, the answer cards over no one */
  const cajaBox = (id, p) => [Math.round(p.x) - 11, Math.round(p.y) - alto(id, p), 22, alto(id, p)];
  const boxOf = (w, k) => { const t = sh.things[k];
    if (t && t.set) return t.box;
    if (k === 'caja') return w.caja ? t.box : null;
    if (k === 'bola') return w.bola ? [Math.round(w.bola.x) - 7, Math.round(w.bola.y) - 13, 14, 14] : null;
    if (k === 'saco') return w.saco ? [Math.round(w.saco.x) - 13, Math.round(w.saco.y) - 23, 26, 24] : null;
    if (k === 'sol') return !w.noche && w.soly < 80 ? [86, Math.round(w.soly) - 14, 28, 28] : null;
    if (k === 'pajaro') { const v = w.ave; if (!v || v.mode === 'none') return null; const p = v.mode === 'head' ? (() => { const b = frogBox(w.cq); return [b.x + b.w / 2, b.y + Math.round(w.cq.dy) + 2]; })() : [Math.round(v.x), Math.round(v.y + (v.dip || 0))]; return [p[0] - 10, p[1] - 20, 20, 22]; }
    if (k === 'coqui') { const b = frogBox(w.cq); return [b.x, b.y, b.w, b.h]; }
    const p = w.gente && w.gente[k]; return p && shown(p) ? cajaBox(k, p) : null; };
  const maskMeets = (id, p, r) => { const pose0 = id === 'bebe' ? (p.est || 'idle') : (p.pose === 'alto' ? 'wave0' : p.pose || 'idle'), sent = p.sent && id !== 'abuela' && id !== 'bebe' ? '.sent' : '';
    const key = G.M.masks[id + '.' + pose0 + sent] ? id + '.' + pose0 + sent : G.M.masks[id + '.' + pose0 + '0' + sent] ? id + '.' + pose0 + '0' + sent : id + '.idle' + sent;
    const m = G.M.masks[key], x = Math.round(p.x), y = Math.round(p.y), flip = p.dir < 0 && id !== 'bebe'; let n = 0;
    for (const [dy, a, b] of m) { const row = y + dy; if (row < r[1] || row >= r[1] + r[3]) continue; const xa = flip ? x - b + (id === 'abuela' ? 0 : 1) : x + a, xb = flip ? x - a + (id === 'abuela' ? 0 : 1) : x + b;
      n += Math.max(0, Math.min(xb + 1, r[0] + r[2]) - Math.max(xa, r[0])); }
    return n; };
  const respBox = (w, k) => { const q = w.cq, b = frogBox(q), n = w.resp.length, i = w.resp.indexOf(k), m = n > 2 ? 76 : 60, en = w.respEn, cx = en ? en[0] : Math.max(x0 + m, Math.min(x0 + 196 - m, b.x + b.w / 2)), y = en ? en[1] : Math.max(4, b.y - 46);
    return n > 2 ? [Math.round(cx - 70 + i * 50), y, 40, 36] : i === 0 ? [Math.round(cx - 50), y, 40, 36] : [Math.round(cx + 10), y, 40, 36]; };
  let nF = 0, nC = 0, nH = 0, worstF = 99, worstC = 99; const askSeen = new Set(), cardHand = new Set(), askedFor = new Set();
  for (const r of runs) { const Ls = r.lines; forRun(r);
    Ls.forEach(L => { if (L.kind !== 'ask' && L.kind !== 'decide') return;
      const j = Ls.findIndex(M => M.path === L.path || (M.path || '').startsWith(L.path + '.')); if (j < 1) return;
      const w = remapW(Ls[j - 1].W), st = at(r.story, L.path), V = Ls[j - 1].V;
      const sb = x => sub(x, V);
      w.resp = null; let spot = null;
      if (st.ask) { spot = sb(st.ask); if (st.resp) w.resp = st.resp.map(sb); }
      else if (st.decide) { const ops = st.options.map(sb), bur = (st.burbujas || []).map(sb); spot = sb(st.pick) || ops[0]; if (st.decide === 'say') w.resp = ops; else if (bur.length) w.resp = bur; }
      const where = r.story.id + ' ' + r.plan + ' ' + L.path + ' (' + spot + ')', key = JSON.stringify([spot, w.gente, w.cq, w.resp, w.soly, w.bola, w.ave, w.caja]);
      if (askSeen.has(key)) return; askSeen.add(key); askedFor.add(spot);
      const faces = facesOf(w), bodies = people(w).map(([id, p]) => [id, body(id, p)]);
      if (w.resp) for (const k of w.resp) { const c = respBox(w, k); nC++;
        if (!within(c, VIEW)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' is not inside the view');
        for (const [bn, bb] of boardsOf(w, x0)) if (meets(c, bb)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' is over ' + bn);
        { const v = w.ave; if (v && v.mode !== 'none' && v.mode !== 'head') { const rows = G.M.ave[v.dir < 0 ? -1 : 1]; let n = 0; for (const [dy, a, bb] of rows) { const row = Math.round(v.y) + dy; if (row >= c[1] && row < c[1] + c[3]) n += Math.max(0, Math.min(Math.round(v.x) + bb + 1, c[0] + c[2]) - Math.max(Math.round(v.x) + a, c[0])); } if (n) P.push('cards: ' + where + ' the card ' + k + ' covers ' + n + ' px of the bird'); } }
        for (const [id, b] of bodies) { const p = w.gente[id], n = maskMeets(id, p, c); if (n) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers ' + n + ' px of ' + id + ' ' + JSON.stringify(b)); else worstC = Math.min(worstC, gapTo(c, b)); } }
      const rb = w.resp && w.resp.includes(spot) ? respBox(w, spot) : null, b = rb || boxOf(w, spot) || (() => { const f = frogBox(w.cq); return [f.x, f.y, f.w, f.h]; })();
      nF++;
      const fr = [b[0] - FRAME_OUT, b[1] - FRAME_OUT, b[2] + 2 * FRAME_OUT, b[3] + 2 * FRAME_OUT];
      if (!rb) { if (!within(fr, VIEW)) P.push('hint frame: ' + where + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not wholly inside the view'); else worstF = Math.min(worstF, fr[0] - x0, x0 + 196 - fr[0] - fr[2], fr[1], 216 - fr[1] - fr[3]); }
      const hp = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : (sh.things[spot] && sh.things[spot].hand) || [Math.round(b[0] + b[2] / 2), Math.round(b[1] + b[3] / 2)], hr = [Math.round(hp[0]) + HANDR[0], Math.round(hp[1]) + HANDR[1], HANDR[2], HANDR[3]]; nH++;
      for (const [fn, f] of faces) if (handOn(hp, f)) { if (rb && fn === 'the frog\'s face') { cardHand.add(spot); continue; } P.push('hand: ' + where + ' the hand ' + JSON.stringify(hr) + ' is on ' + fn + ' ' + JSON.stringify(f)); }
    }); }
  notes.push('asks: ' + nF + ' distinct asks (for ' + [...askedFor].sort().join(', ') + '): every hint frame (box +- ' + FRAME_OUT + ') wholly inside the view (' + worstF + ' px from its edge at the least), the hint hand on no face; ' + nC + ' answer cards inside the view, over no one\'s body (no opaque pixel of anyone\'s sprite, in their pose, under a card)');
  if (cardHand.size) notes.push('NOT the scene\'s: the hand juego.js draws at an answer card (the left one) reaches onto the frog\'s face, 46 px under it, in every scene (the card\'s place and the hand are the game\'s, respBox and hand()): at the asks for ' + [...cardHand].join(', '));
  notes.push('bubbles: ' + nB + ' bubbles at ' + nM + ' moments of ' + runs.length + ' runs (' + [...new Set(runs.map(r => r.story.id))].join(', ') + '), each its recorded one and the ones an act can show there (anyone\'s "amor" when touched, at any moment; the "q" of duda, encoge and turno at their steps; the frog\'s "amor"): wholly inside the view (' + worstView + ' px from its edge at the least), clear of the cards shown in the corners (' + worstBoard + ' px), on no face');
  notes.push('clear lawn (round 3): at every place where someone stands, at every column of their feet, at least ' + CLEAR + ' rows of lawn between their feet and the foot of what stands behind them; the least: behind the wall or the step ' + clearLeast.wall.join(' rows, ') + '; the fence or the gate ' + clearLeast.fence.join(' rows, ') + '; the trunk ' + clearLeast.tree.join(' rows, '));
  notes.push('ground: ' + nFloor + ' distinct places where someone stands (and the frog), ' + nSit + ' where someone sits on the grass: on the lawn of the yard (x > CX, y > CY; abuela in the doorway), none behind the fence or inside the house, nothing of the house, the fence, the gate or the tree nearer than them inside their body');

  /* round 4: the frog at the gate and out through it. LUGAR.porton: 15 to 19 rows before the fence's line, his middle inside the opening's
     columns; LUGAR.sale: 2 to 5 rows past it, on the path, his whole box inside the opening's columns. His way out (acts.sevan: hopTo(sale, 3 hops)
     from the gate, every step as juego.js hopTo makes it, his box raised by dy): no pixel of the gate's leaf, its posts, the fence or anything of
     the set nearer than him inside his box, in every state with the gate open. At sale his bubbles (his "amor") inside the view, on no face. And
     nobody stands where he stands: at the gate at every moment of every run, and at each step of his way out, his ground point and anyone's at
     least the sum of their shadows' radii apart (sheet shadows: .45 and .35, a child .3) */
  { const L = sh.lugar, PT = L.porton.q, SA = L.sale.q, opX = openingPx.map(i => i % 240), o0 = Math.min(...opX), o1 = Math.max(...opX);
    const fenceAt = sx => E.project(F.CY + (sx - E.OX) / E.S * E.R2, F.CY, 0).sy, gapOf = q => r2((q.y + 25) - fenceAt(q.x + 16));   // (rules.floor: his middle q.x + 16)
    const qP = { x: PT[0], y: PT[1], s: L.porton.scale, dy: 0, al: 1, vis: 1 }, qS = { x: SA[0], y: SA[1], s: L.sale.scale, dy: 0, al: 1, vis: 1 }, bP = frogBox(qP), bS = frogBox(qS);
    const gP = gapOf(qP), gS = gapOf(qS);
    if (gP < 15 || gP > 19 || bP.x + bP.w / 2 < o0 || bP.x + bP.w / 2 > o1) P.push('the frog at the gate (porton ' + PT + '): ' + gP + ' rows before the fence\'s line, his middle at x ' + (bP.x + bP.w / 2) + ' (keep 15 to 19 rows, x ' + o0 + ' to ' + o1 + ')');
    if (gS > -2 || gS < -5) P.push('the frog leaving (sale ' + SA + '): ' + (-gS) + ' rows past the fence\'s line (keep 2 to 5)');
    const OPEN = STATES.filter(k => k.endsWith('-open'));
    // between the posts: no pixel of the gate or the fence in the columns of his box, one more each side, at the rows of his box (with the gate open)
    let postL = -1, postR = 999; for (const key of OPEN) { const tag = TAGS[key];
      for (let y = bS.y; y < bS.y + bS.h; y++) for (let x = bS.x - 12; x < bS.x + bS.w + 12; x++) if (tag[y * 240 + x] === 'porton' || tag[y * 240 + x] === 'cerca') { if (x < bS.x + bS.w / 2) postL = Math.max(postL, x); else postR = Math.min(postR, x); } }
    if (postL >= bS.x - 1 || postR <= bS.x + bS.w) P.push('the frog leaving (sale ' + SA + '): his box x ' + bS.x + ' to ' + (bS.x + bS.w - 1) + ' is not between the posts (x ' + postL + ' and ' + postR + ', a pixel clear)');
    for (const key of OPEN) { const K = G.kinds[key], fx = Math.round(bS.x + bS.w / 2), fy = SA[1] + 25; if (K[fy * 240 + fx] !== G.K.road) P.push('the frog leaving ' + key + ': his feet (' + fx + ',' + fy + ') are not on the path'); }
    // his way out, step by step (juego.js hopTo)
    const steps = []; { const s0 = L.porton.scale, s1 = L.sale.scale; for (let h = 0; h < 3; h++) { const s = Math.round((s0 + (s1 - s0) * (h + 1) / 3) * 100) / 100;
      for (let i = 1; i <= 5; i++) { const t = (h + i / 5) / 3; steps.push({ x: Math.round(PT[0] + (SA[0] - PT[0]) * t), y: Math.round(PT[1] + (SA[1] - PT[1]) * t), s, dy: -7 * Math.sin(Math.PI * i / 5), al: 1, vis: 1 }); } } }
    let worstNear = 0;
    for (const key of OPEN) for (const q of [qP].concat(steps)) { const b = frogBox(q), n = nearer(key, [b.x, b.y + Math.round(q.dy), b.w, b.h], vAt(b.x + b.w / 2, q.y + 25), SOLID);
      if (n) P.push('the frog leaving ' + key + ' at ' + q.x + ',' + q.y + ' (s ' + q.s + ', dy ' + r2(q.dy) + '): ' + n + ' px of the set nearer than him inside his box'); worstNear = Math.max(worstNear, n); }
    // nobody where he stands
    const R0 = .45, rOf = id => id === 'bebe' ? .25 : (id === 'luis' || id === 'carmen') ? .3 : .35, gFrog = q => { const b = frogBox(q); return E.atZ(b.x + b.w / 2, q.y + 25, 0); };
    let least = [99, '']; const apart = (where, w, q) => { const g = gFrog(q);
      for (const [id, p] of people(w)) { if (p.z) continue; const h = E.atZ(Math.round(p.x), Math.round(p.y) - 1, 0), d = Math.hypot(g[0] - h[0], g[1] - h[1]);
        if (d < least[0]) least = [r2(d), where + ': ' + id + ' at ' + Math.round(p.x) + ',' + Math.round(p.y) + ', the frog at ' + q.x + ',' + q.y];
        if (d < R0 + rOf(id)) P.push('nobody where he stands: ' + where + ' ' + id + ' at ' + Math.round(p.x) + ',' + Math.round(p.y) + ' is ' + r2(d) + ' from the frog at ' + q.x + ',' + q.y + ' (keep ' + r2(R0 + rOf(id)) + ')'); } };
    let nAt = 0, nOut = 0;
    for (const r of runs) { forRun(r); for (const ln of r.lines) { const w = remapW(ln.W), q = w.cq;
      if (q && q.vis && ((q.x === PT[0] && q.y === PT[1]) || (q.x === SA[0] && q.y === SA[1]))) { nAt++; apart(r.story.id + ' ' + r.plan + ' ' + ln.path, w, q); }
      const st = ln.path && at(r.story, ln.path);
      if (st && st.act === 'sevan') { nOut++;
        for (const q2 of steps) apart(r.story.id + ' ' + r.plan + ' ' + ln.path + ' (on his way out)', w, q2);
        // at sale, before he fades: his bubbles
        const w2 = JSON.parse(JSON.stringify(w)); w2.cq = Object.assign({}, qS, { bub: null }); const boards = boardsOf(w2, x0), faces = facesOf(w2);
        for (const [who, rect] of bubblesOf(w2)) if (/^the frog/.test(who)) judge(r.story.id + ' ' + r.plan + ' ' + ln.path + ': at sale, ' + who, rect, VIEW, boards, faces); } } }
    if (!nOut) P.push('the frog leaving: no run reaches acts.sevan');
    notes.push('the frog at the gate (round 4): porton ' + PT + ', ' + gP + ' rows before the fence\'s line (the old picture 17, round 3 ' + sh.layout.gate.porton.round3.before + '), his middle at x ' + (bP.x + bP.w / 2) + ' (the opening x ' + o0 + ' to ' + o1 + '); sale ' + SA + ', ' + (-gS) + ' rows past it (the old 3; round 3 ' + sh.layout.gate.sale.round3.before + ' rows before it, on the lawn), on the path, his box x ' + bS.x + ' to ' + (bS.x + bS.w - 1) + ' between the posts (their pixels at x ' + postL + ' and ' + postR + '). On his way out (' + steps.length + ' steps of 3 hops, in ' + OPEN.length + ' open-gate states) no pixel of the leaf, the posts, the fence or the set nearer than him; at sale his bubbles inside the view, on no face (' + nOut + ' runs); nobody where he stands (' + nAt + ' moments at the gate, and his way out): the nearest anyone comes is ' + least[0] + ' (' + least[1] + ')');
  }

  /* standing over sitting: no standing person's sprite covers more of a sitting one's face than the old picture did at that moment */
  let nSO = 0; const soSeen = new Set(), soOld = new Set();
  const drawOrder = w => Object.keys(w.gente || {}).filter(id => shown(w.gente[id])).map((id, k) => [id, w.gente[id].z || w.gente[id].y, k]).sort((a, b) => a[1] - b[1] || a[2] - b[2]).map(e => e[0]);
  const coverFaces = w => { const ord = drawOrder(w), out = {};
    ord.forEach((t, ti) => { const pt = w.gente[t]; if (!pt.sent && !pt.z) return; const face = faceOf(t, pt);
      ord.slice(ti + 1).forEach(sid => { const ps = w.gente[sid]; if (ps.sent || ps.z) return; const n = maskMeets(sid, ps, face); if (n) out[sid + '>' + t] = n; }); });
    return out; };
  for (const r of runs) { forRun(r); for (const L of r.lines) { const wn = remapW(L.W), key = JSON.stringify([wn.gente, L.W.gente]); if (soSeen.has(key)) continue; soSeen.add(key); nSO++;
    const cn = coverFaces(wn), co = coverFaces(L.W);
    for (const [pair, n] of Object.entries(cn)) { if ((co[pair] || 0) < n) P.push('standing over sitting: ' + r.story.id + ' ' + r.plan + ' ' + L.path + ': ' + pair.replace('>', '\'s sprite covers ') + '\'s face, ' + n + ' px (the old picture: ' + (co[pair] || 0) + ')'); else soOld.add(r.story.id + ' ' + pair + ' ' + n); } } }
  notes.push('standing over sitting: at ' + nSO + ' distinct moments no standing person\'s sprite covers more of a sitting person\'s face (the baby in mamá\'s arms, Luis on the grass) than the old picture did there' + (soOld.size ? ' (' + soOld.size + ' covers, each as in the old: ' + [...soOld].join('; ') + ')' : ''));

  /* the review pictures (and the level pictures, the same pictures): everyone and the frog whole in their crop (a zoom 2 crop cuts no one the old one
     did not), every bubble inside, on the ground; the sky things inside; what differs between the two sides */
  let nPic = 0; const pairDiff = [];
  MV = []; RM = []; EN = null;
  const byWord = {}; for (const ps of pairSides) (byWord[ps.w] = byWord[ps.w] || {})[ps.side] = ps;
  for (const [word, sides] of Object.entries(byWord)) {
    const ws = {};
    for (const side of Object.keys(sides)) {
      const spec = sides[side].spec, base = { gente: {}, cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: 0, bub: null }, soly: 24, sol: 0, ave: { mode: 'sit', x: 181, y: 66, dir: -1, st: 'n' } };
      const w = remapW(Object.assign(base, JSON.parse(JSON.stringify(spec.set || {})))), nm = deacc(word) + '.' + side, pc = sh.pictures[nm]; ws[side] = w; nPic++;
      const crop = pc.crop, oc = spec.cam, who = people(w).map(([id, p]) => [id, body(id, p)]); if (w.cq.vis) { const b = frogBox(w.cq); who.push(['the frog', [b.x, b.y + Math.round(w.cq.dy || 0), b.w, b.h]]); }
      if (w.bola) who.push(['the ball', [Math.round(w.bola.x) - 7, Math.round(w.bola.y - (w.bola.h || 0)) - 13, 14, 14]]);
      if (w.luna) who.push(['the moon', [139, 15, 24, 22]]); else if (!w.noche && w.soly < 110) who.push(['the sun', [100 - 21, Math.round(w.soly) - 21, 42, 42]]);
      for (const [id, b] of who) { const cut = !within(b, crop), oldCut = !within(b, [Math.floor(oc[0]), Math.floor(oc[1]), Math.ceil(oc[2]), Math.ceil(oc[3])]);
        if (cut && !(id === 'the sun' && oldCut)) P.push('pair ' + nm + ': ' + id + ' ' + JSON.stringify(b) + ' is cut by the picture ' + JSON.stringify(crop) + (oldCut ? ' (the old one cut it too)' : '')); }
      for (const [who2, rect] of bubblesOf(w, false, crop)) if (!within(rect, crop)) P.push('pair ' + nm + ': ' + who2 + ' bubble is cut');
      // round 3: the gate, where a pair turns on it (vamos: open against shut), whole in the picture, its opening not hidden by anyone
      if (word === 'vamos') { const g = sh.things.porton.box; if (!within(g, crop)) P.push('pair ' + nm + ': the gate ' + JSON.stringify(g) + ' is not whole in ' + JSON.stringify(crop));
        let hid = 0; for (const i of openingPx) { const x = i % 240, y = Math.floor(i / 240); if (who.some(([id, b]) => id !== 'the sun' && id !== 'the moon' && x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3])) hid++; }
        if (hid > openingPx.length * .1) P.push('pair ' + nm + ': ' + hid + ' of the ' + openingPx.length + ' px of the gate\'s opening are hidden by someone');
        notes.push('pair ' + nm + ': the gate whole in the picture, ' + Math.round(100 - hid / openingPx.length * 100) + '% of its opening seen (' + (w.porton ? 'open: the path through it' : 'shut: the leaf in it') + ')'); }
      floorCheck('pair ' + nm + ':', w);
    }
    if (!ws.si || !ws.no) continue;
    if (JSON.stringify(ws.si) === JSON.stringify(ws.no)) P.push('pair ' + word + ': the two pictures are the same');
    const diff = []; const ids = new Set([...Object.keys(ws.si.gente || {}), ...Object.keys(ws.no.gente || {})]);
    for (const id of ids) { const x = (ws.si.gente || {})[id], y = (ws.no.gente || {})[id]; if (JSON.stringify(x) !== JSON.stringify(y)) diff.push(id + (!x ? ' only in no' : !y ? ' only in si' : ' ' + Object.keys(Object.assign({}, x, y)).filter(k => JSON.stringify(x[k]) !== JSON.stringify(y[k])).join('/'))); }
    for (const k of new Set([...Object.keys(ws.si), ...Object.keys(ws.no)])) if (k !== 'gente' && k !== 'cq' && JSON.stringify(ws.si[k]) !== JSON.stringify(ws.no[k])) diff.push(k);
    if (JSON.stringify(ws.si.cq) !== JSON.stringify(ws.no.cq)) diff.push('the frog ' + Object.keys(Object.assign({}, ws.si.cq, ws.no.cq)).filter(k => ws.si.cq[k] !== ws.no.cq[k]).join('/'));
    pairDiff.push(deacc(word) + ': ' + diff.join(', '));
  }
  notes.push('pairs, what differs (the same window both sides): ' + pairDiff.join('; '));
  notes.push('pairs: ' + nPic + ' review pictures (and the ' + sh.level.length + ' level pictures, the same pictures): everyone, the frog, the ball and the sun or moon whole in their crop, on clear ground');
  for (const k of STATES) if (!reached.has(k)) P.push('state ' + k + ' is baked but nothing reaches it');
  notes.push('states: ' + reached.size + ' baked states reached (' + [...reached].sort().join(', ') + ')');
  return P;
}
