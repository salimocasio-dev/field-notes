#!/usr/bin/env node
'use strict';
/* La sala's sheet (order 31a): writes docs/proyecto/pixel/sala-sheet.json from sala-set.html and the old scene's data, then checks it.
   Run from the repo root:  node docs/proyecto/pixel/sala-sheet-make.js        (needs Node 22 and the pre-installed Playwright)
   It reads the set's plan (window.SALA) and its part map from sala-set.html in headless Chrome, measures the old sprite layer's bubbles and
   people (historia/ engine.js, juego.js, kit.js, escenas/sala.js, as they are), projects every world point with the engine's own formula, and
   checks the sheet against coqui/ref/escenas/sala/ (positions.json, inventory.json, pairs.json) and against every moment of every recorded run
   of the scene's stories (coqui/tool/ref/trazas/juega.mjs --states, into a temp folder; nothing in the repo is written but the sheet).
   A second run writes the same bytes. Every name a builder needs for a screen position of historia/escenas/sala.js is in `code`, by line.
   El balcón's maker (balcon-sheet-make.js) is the model: the same rules, the same way of checking. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../..');
const OUT = path.join(__dirname, 'sala-sheet.json');
const REF = path.join(REPO, 'coqui/ref/escenas/sala');
const STATES = ['000', '100', '110', '111', '010'];          // the frames' crookedness the stories reach (setKey.baked)

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  const G = { parts: {}, z: {} };
  for (const fotos of STATES) {
    await page.goto('file://' + path.join(__dirname, 'sala-set.html') + '?tags=1&fotos=' + fotos);
    const g = await page.evaluate(() => {
      const o = {}; for (const [k, v] of Object.entries(SALA)) if (typeof v !== 'function' && k !== 'SET') o[k] = v;
      const parts = {}; TAGS.forEach((t, i) => { if (t) (parts[t] = parts[t] || []).push(i); });
      return { F: o, scene: PP_SCENE, W, H, S, parts, z: Array.from(DEPTH.z) };
    });
    if (!G.F) Object.assign(G, { F: g.F, scene: g.scene, W: g.W, H: g.H, S: g.S });
    G.parts[fotos] = g.parts; G.z[fotos] = g.z;
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
  if (problems.length) { console.log('CHECK FAILED (' + problems.length + '):\n  ' + problems.slice(0, 120).join('\n  ')); process.exit(1); }
  console.log('check: ok (every rule above)');
})().catch(e => { console.error(e); process.exit(1); });

/* ---------- the old sprite layer, measured in the browser: every bubble's rectangle, the people's sizes ---------- */
// historia/ engine.js, palabras.js, juego.js, escenas/kit.js and escenas/sala.js loaded as they are into a blank page (the elements juego.js
// looks for exist, hidden). A bubble is drawn as sala.js bub2 draws it (twice its size, its tail's tip at the origin), on both frames of its bob
async function measure(page) {
  await page.setContent('<canvas id="cv" width="196" height="216"></canvas>');   // juego.js stops at its first button (not here) after defining all it is read for
  for (const f of ['engine.js', 'palabras.js', 'juego.js', 'escenas/kit.js', 'escenas/sala.js']) await page.addScriptTag({ path: path.join(REPO, 'historia', f) });
  return page.evaluate(() => {
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
    // each person's sprite (idle), its opaque box relative to their feet (x, y), facing right; and the top rows' middle (the head)
    const opaque = (cv, ox, oy) => { const g = cv.getContext('2d'), d = g.getImageData(0, 0, cv.width, cv.height).data; let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      for (let i = 0; i < cv.width * cv.height; i++) if (d[i * 4 + 3]) { const x = i % cv.width, y = i / cv.width | 0; x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
      let hx0 = 1e9, hx1 = -1e9; for (let i = 0; i < cv.width * cv.height; i++) { const x = i % cv.width, y = i / cv.width | 0; if (d[i * 4 + 3] && y < y0 + 10) { hx0 = Math.min(hx0, x); hx1 = Math.max(hx1, x); } }
      return { box: [x0 - ox, y0 - oy, x1 - x0 + 1, y1 - y0 + 1], head: (hx0 + hx1 + 1) / 2 - ox }; };
    const people = {};
    for (const id of Object.keys(KIT.FAM)) for (const sent of [0, 1]) { const im = KIT.mkPersona(KIT.FAM[id], 'idle', 0, sent); people[id + (sent ? '.sent' : '')] = opaque(im, KIT.PX, im.height - 1); }
    { const im = mkAbuela('idle', 0); people.abuela = opaque(im, 30, 50); }
    { const im = KIT.mkBebe('idle', 0); people.bebe = opaque(im, 13, 28); }
    // each person's opaque pixels, row by row ([row, first column, last column] relative to the feet, facing right), for every pose sala.js gives
    const rowsOf = (cv, ox, oy) => { const d = cv.getContext('2d').getImageData(0, 0, cv.width, cv.height).data, out = [];
      for (let y = 0; y < cv.height; y++) { let a = -1, b = -1; for (let x = 0; x < cv.width; x++) if (d[(y * cv.width + x) * 4 + 3]) { if (a < 0) a = x; b = x; } if (a >= 0) out.push([y - oy, a - ox, b - ox]); }
      return out; };
    const masks = {};
    for (const id of Object.keys(KIT.FAM)) for (const sent of [0, 1]) for (const pose of ['idle', 'wave0', 'wave1', 'ojos', 'foto', 'taza', 'yo', 'tu']) {
      const im = KIT.mkPersona(KIT.FAM[id], pose.replace(/\d$/, ''), 0, sent); masks[id + '.' + pose + (sent ? '.sent' : '')] = rowsOf(im, KIT.PX, im.height - 1); }
    for (const pose of ['idle', 'offer', 'dedo0', 'wave0', 'wave1']) masks['abuela.' + pose] = rowsOf(mkAbuela(pose, 0), 30, 50);
    for (const e of ['idle', 'clap', 'llora', 'come']) masks['bebe.' + e] = rowsOf(KIT.mkBebe(e, 0), 13, 28);
    return { bubbles, FAM: KIT.FAM, PX: KIT.PX, people, masks };
  });
}

/* ---------- the engine's projection, as pp-engine.js has it ---------- */
function engine(G) {
  const W = G.W, H = G.H, S = G.S, SIN = .5, COS = Math.sqrt(3) / 2, R2 = Math.SQRT2;
  const OX = W / 2 + (G.scene.originX || 0), OY = H / 2 + (G.scene.originY || 0);
  const project = (x, y, z) => { const u = (x - y) / R2, v = (x + y) / R2; return { sx: OX + u * S, sy: OY + (v * SIN - z * COS) * S, d: v * COS + z * SIN }; };
  const atZ = (sx, sy, z) => { const u = (sx - OX) / S, v = (sy - OY + z * COS * S) / (S * SIN); return [(u + v) / R2, (v - u) / R2, z]; };
  return { W, H, S, R2, SIN, COS, OX, OY, project, atZ };
}
const r4 = v => Math.round(v * 1e4) / 1e4, r2 = v => Math.round(v * 100) / 100;
const W4 = p => p.map(r4);
const hop = d => d < 3 ? 0 : Math.max(1, Math.min(4, Math.round(d / 30)));   // kit.js:128 acts.ir

/* ---------- the old scene's numbers (historia/escenas/sala.js, read as text: they must be what the file says) ---------- */
const SALA_JS = fs.readFileSync(path.join(REPO, 'historia/escenas/sala.js'), 'utf8');
const lit = (re, what) => { const m = SALA_JS.match(re); if (!m) throw new Error('sala.js changed: ' + what); return JSON.parse(m[1]); };
const OLD = {
  PARADOS: lit(/PARADOS=(\[\[[^\]]*\],\[[^\]]*\]\])/, 'PARADOS'), APARTE: lit(/APARTE=(\[\[[^\]]*\],\[[^\]]*\]\])/, 'APARTE'),
  JUNTOS: lit(/JUNTOS=(\[\[[^\]]*\],\[[^\]]*\]\])/, 'JUNTOS'), CAMARA: lit(/CAMARA=(\[[^\]]*\])/, 'CAMARA'),
};
function fixJson(s) { return s.replace(/([{,])(\w+):/g, '$1"$2":').replace(/:\./g, ':0.').replace(/,\./g, ',0.'); }
{ const g = (re, w) => { const m = SALA_JS.match(re); if (!m) throw new Error('sala.js changed: ' + w); return JSON.parse(fixJson(m[1])); };
  OLD.SITIO = g(/const SITIO=(\{[^;]*\})/, 'SITIO'); OLD.LUGAR = g(/const LUGAR=(\{[^;]*\})/, 'LUGAR'); }

// the places a bubble's tail may go, in order (dx, dy from the top point): over the head (the old), beside the head on the right, on the left,
// beside the shoulder on the right, on the left (the tail then points at the head or the shoulder from the side)
const TALK = [[0, 0], [1, 7], [-1, 7], [1, 30], [-1, 30], [1, 44], [-1, 44], [2, 7], [-2, 7], [2, 30], [-2, 30], [2, 44], [-2, 44], [1, 58], [-1, 58], [2, 58], [-2, 58]];   // [side, dy]: dx = side * (h + 16), h the head's half width (a person 6, the frog b.w >> 1)
function make(G) {
  const E = engine(G), F = G.F, P = p => { const q = E.project(p[0], p[1], p[2]); return [r2(q.sx), r2(q.sy)]; };
  const box = w => { const xs = [], ys = []; for (const x of [w[0], w[3]]) for (const y of [w[1], w[4]]) for (const z of [w[2], w[5]]) { const q = E.project(x, y, z); xs.push(q.sx); ys.push(q.sy); }
    const x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys)); return [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0]; };
  const floor = (sx, sy) => W4(E.atZ(sx, sy, 0));
  // the box (square on the ground) whose 8 projected corners have the screen box [sx0, sy0] - [sx1, sy1] (set-kit.js boxAround)
  const boxAround = (sx0, sy0, sx1, sy1) => { const S = E.S, d = (sx1 - sx0) / S, uc = ((sx0 + sx1) / 2 - E.OX) / S;
    const vmax = (sy1 - E.OY) / (S * .5), vmin = vmax - d, z1 = (vmin * .5 - (sy0 - E.OY) / S) / E.COS;
    const xc = (uc + (vmin + vmax) / 2) / E.R2, yc = ((vmin + vmax) / 2 - uc) / E.R2, e = d * E.R2 / 4; return [xc - e, yc - e, 0, xc + e, yc + e, z1]; };
  const turnedScreen = (c, hw, hd, z0, z1) => { const a = F.TURN, ax = Math.cos(a), ay = Math.sin(a), bx = -ay, by = ax, xs = [], ys = [];
    for (const s of [-hw, hw]) for (const t of [-hd, hd]) for (const z of [z0, z1]) { const q = E.project(c[0] + ax * s + bx * t, c[1] + ay * s + by * t, z); xs.push(q.sx); ys.push(q.sy); }
    return [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)]; };

  /* ---- the floor rule: the room is built round the old picture, so a place on its floor stays where it was on the screen ---- */
  // a frog place q (juego.js frogBox: his middle q.x + 16, his feet row q.y + 25): the floor point under (q.x + 16, q.y + 25); new q = old q.
  // a person's place (x, y) (their feet, sala.js gente): the floor point under (x, y - 1); new = old
  const frogW = q => floor(q[0] + 16, q[1] + 25), personW = p => floor(p[0], p[1] - 1);
  const frogQ = w => { const s = P(w); return [Math.round(s[0]) - 16, Math.round(s[1]) - 25]; };
  const personQ = w => { const s = P(w); return [Math.round(s[0]), Math.round(s[1]) + 1]; };
  const SPOTS = {};
  for (const [k, v] of Object.entries(OLD.LUGAR)) SPOTS['frog.' + k] = { world: frogW(v), scale: v[2], old: v.slice(0, 2), what: 'LUGAR.' + k + ': the frog' };
  for (const [k, v] of Object.entries(OLD.SITIO)) SPOTS['sitio.' + k] = { world: personW(v), old: v.slice(0, 2), what: 'SITIO.' + k + (v.length > 2 ? ': ' + k + ' sitting (sent): the floor at the feet, before the seat' : ': ' + k + ' standing' + (k === 'bebe' ? ' (sitting on the blanket)' : '')) };
  OLD.PARADOS.forEach((p, i) => { SPOTS['parados.' + i] = { world: personW(p), old: p, what: 'PARADOS[' + i + ']: two people standing before the sofa (lados parados; espejuelos)' }; });
  OLD.APARTE.forEach((p, i) => { SPOTS['aparte.' + i] = { world: personW(p), old: p, what: 'APARTE[' + i + ']: two people apart, at the front' }; });
  OLD.JUNTOS.forEach((p, i) => { const m = [[80, 196], [160, 196]][i]; SPOTS['juntos.' + i] = { world: personW(m), old: p, what: 'JUNTOS[' + i + ']: two people together, at the front (moved: see moves)' }; });
  SPOTS.camara = { world: personW(OLD.CAMARA), old: OLD.CAMARA, what: 'CAMARA: abuelo with the camera' };
  // the children run in at the door (acts.corren): on its threshold, in the doorway (old 40, 126 and 34, 124: the old door was there; the new
  // doorway is further right, so they come in through it, not through the wall beside it)
  const doorAt = f => W4([.1, F.D0 + (F.D1 - F.D0) * f, 0]);
  SPOTS['puerta.hermano'] = { world: doorAt(.3), old: [40, 126], what: 'acts.corren: a.x = 40, a.y = 126: the brother appears in the doorway, on its threshold' };
  SPOTS['puerta.hermana'] = { world: doorAt(.72), old: [34, 124], what: 'acts.corren: b.x = 34, b.y = 124: the sister appears in the doorway, on its threshold, a step behind him' };
  for (const s of Object.values(SPOTS)) { s.new = s.scale != null ? frogQ(s.world) : personQ(s.world); }

  /* ---- the places that move (the floor rule keeps every other one): where the old picture put someone under the answer cards, under the hint
     hand's way to a face, or on a face with their bubble. Each is an exact piece of sala.js source and its replacement (the preview applies them as
     written; the builder ports them as named positions) ---- */
  const MOVES = [
    { line: 198, act: 'corren', src: 'mueve("hermano",94,198,10),mueve("hermana",66,203,10)', to: 'mueve("hermano",80,200,10),mueve("hermana",60,204,10)', pts: [['hermano', [94, 198], [80, 200]], ['hermana', [66, 203], [60, 204]]],
      why: 'acts.corren: the children stop clear of the frog in the middle (the hint hand, pointing at a child, hung over the frog\'s face: la-foto beats.8)' },
    { line: 214, act: 'solo', src: 'mueve(o.quien,120,146),mueve(otro,72,206)', to: 'mueve(o.quien,120,136),mueve(otro,56,206)', pts: [[null, [120, 146], [120, 136]], [null, [72, 206], [56, 206]]],
      why: 'acts.solo: the child alone stands between the sofa and the low table, the other one at the left: the answer cards over the frog covered both (la-foto beats.41)' },
    { line: 228, act: 'inicio8', src: 'a.x=156;a.y=200;a.dir=-1;b.x=84;b.y=200;', to: 'a.x=184;a.y=200;a.dir=-1;b.x=56;b.y=200;', pts: [['hermano', [156, 200], [184, 200]], ['hermana', [84, 200], [56, 200]]],
      why: 'acts.inicio8: the children stand either side of the frog, out from under the answer cards (quien-eres-tu beats.10, 13, 22, 28)' },
    { line: 236, act: 'suelta', src: 'mueve(o.quien,o.quien==="hermano"?152:86,200)', to: 'mueve(o.quien,o.quien==="hermano"?184:56,200)', pts: [['hermano', [152, 200], [184, 200]], ['hermana', [86, 200], [56, 200]]],
      why: 'acts.suelta: back to their places either side of the frog (as inicio8)' },
    { line: 247, act: 'final8', src: 'mueve("abuelo",150,170)', to: 'mueve("abuelo",172,178)', pts: [['abuelo', [150, 170], [172, 178]]],
      why: 'acts.final8, the cup empty: abuelo asks for more clear of mamá and the baby (his "q" bubble was on their faces)' },
    { line: 247, act: 'final8', src: 'mueve("abuela",182,172)', to: 'mueve("abuela",200,176)', pts: [['abuela', [182, 172], [200, 176]]],
      why: 'acts.final8: abuela fills his cup from his side (moved with him)' },
    { line: 224, act: 'final7', src: 'mueve("abuelo",172,160)', to: 'mueve("abuelo",186,164)', pts: [['abuelo', [172, 160], [186, 164]]],
      why: 'acts.final7: abuelo stands a little further out, so that papá\'s bubble has a place under the photo of everyone (W.retrato) clear of every face' },
    { line: 77, act: 'lados', src: 'JUNTOS=[[96,196],[144,196]]', to: 'JUNTOS=[[80,196],[160,196]]', pts: [[null, [96, 196], [80, 196]], [null, [144, 196], [160, 196]]],
      why: 'JUNTOS: two people together at the front, wider apart: the hint hand, pointing at one of them, hung over the frog\'s face (la-foto beats.18). The frog hops beside them (acts.junto) relative to them, so he moves with them' },
  ];
  for (const m of MOVES) for (const q of m.pts) q.push(W4(personW(q[2])));

  /* ---- the named points of the set ---- */
  const PTS = {}, pt = (k, o) => { PTS[k] = o; };
  // the low table's top: its middle row on the screen; the cake's dish (bizcocho: the dish rows y + 9 .. y + 11) and the camera (rows y .. y + 9)
  // stand on it, their bottom a row in front of the middle, so the top shows round them
  const mesTop = P([F.MES_C[0], F.MES_C[1], F.MES_H]), ty = Math.round(mesTop[1]);
  pt('bizcocho', { screen: [Math.round(mesTop[0]) - 13, ty - 9], old: [107, 138], what: 'bizcocho(c, x, y, n): the cake on its dish on the low table: the dish (x - 4 .. x + 30, rows y + 9 .. y + 11) on the table top, its bottom a row in front of the top\'s middle' });
  pt('camMesa', { screen: [Math.round(mesTop[0]) - 8, ty - 8], old: [113, 139], what: 'W.camMesa: the camera on the low table (16 x 10 at x, y), its bottom a row in front of the top\'s middle' });
  // the frames: each photo is drawn as marco() draws it, translated to point foto.i (the old translate(x + 10, y + 2)), turned by its angle when
  // crooked, clipped to clips foto.i (or foto.i.torcida): the opening of the set's frame
  const FR = [];
  for (let i = 0; i < 3; i++) for (const crooked of [false, true]) {
    const th = crooked ? F.TILT : 0, ny = F.FY[i], nz = F.FZ + F.FH / 2 + .08;
    const toW = (r, q) => { const c = Math.cos(th), s = Math.sin(th); const rr = r * c + q * s, qq = -r * s + q * c; return [.05, ny - rr, nz + qq]; };
    const ow = F.FW / 2 - F.FO, oh = F.FH / 2 - F.FO, mid = -F.FH / 2 - .08;
    const quad = [[-ow, mid + oh], [ow, mid + oh], [ow, mid - oh], [-ow, mid - oh]].map(([r, q]) => W4(toW(r, q)));
    const cs = P(toW(0, mid)), up = P(toW(0, mid + .2)), ang = Math.atan2(up[0] - cs[0], cs[1] - up[1]);   // the screen angle of the frame's up, clockwise
    const o = [Math.round(cs[0] + 12 * Math.sin(ang)), Math.round(cs[1] - 12 * Math.cos(ang))];             // (0, 12) of marco() turned by ang lands on the opening's middle
    FR.push({ i, crooked, quad, screen: quad.map(P), centre: cs, origin: o, angle: r4(crooked ? ang : 0) });
  }
  for (const f of FR) pt('foto.' + f.i + (f.crooked ? '.torcida' : ''), { screen: f.origin, angle: f.angle, old: [86 + f.i * 24, 40], what: 'marco(c, ' + f.i + ', f): translate here (the old translate(x + 10, y + 2)); ' + (f.crooked ? 'rotate(angle) (the old .24 + .05 sin(F / 6 + i): the frame is baked crooked, so it no longer swings)' : 'no rotation') + '; clip to clips.foto.' + f.i + (f.crooked ? '.torcida' : '') });
  pt('corazon', { screen: [107, 6], old: [107, 6], what: 'heartAt: the heart of a happy ending (its top left): over the corner of the room, the backdrop behind it (unchanged)' });
  pt('hud.plato', { screen: [50, 24], old: [50, 24], what: 'vuelaA(..., 50, 24): a slice flies to the plate card in the view\'s top left (hud tarjeta 3, 3): picture x = wide x0 + 28; the wide window is the old one, so unchanged' });
  const dCake = [PTS.bizcocho.screen[0] - 107, PTS.bizcocho.screen[1] - 138];
  pt('destapa.estrellas', { screen: [[108, 134], [132, 134], [120, 128]].map(p => [p[0] + dCake[0], p[1] + dCake[1]]), old: [[108, 134], [132, 134], [120, 128]], what: 'acts.destapa: the stars over the cake (moved with it)' });
  pt('tres.desde', { screen: [120 + dCake[0], 140 + dCake[1]], old: [120, 140], what: 'acts.tres: the slices fly from the cake (moved with it)' });
  pt('retrato', { screen: [22, 88, 198, 124], old: [22, 88, 198, 124], what: 'acts.retrato: the part of the picture the photo of everyone is taken from (drawImage(sc, 22, 88, 198, 124, 0, 0, 128, 80)): the sofa, the floor before it and the family; the room is built round the old picture, so unchanged' });

  /* ---- things: the 16 touch keys ---- */
  const T = (world, what, extra = {}) => Object.assign({ set: true, world: W4(world), box: box(world), what }, extra);
  const turned = (c, hw, hd, z1, what, old) => { const s = turnedScreen(c, hw, hd, 0, z1), w = boxAround(s[0], s[1], s[2], s[3]);
    return T(w, what, { turned: { centre: W4(c), halfWidth: r4(hw), halfDepth: r4(hd), height: z1, angle: r4(F.TURN) }, old }); };
  const person = id => ({ sprite: true, why: 'a person (today\'s sprite, drawn 1:1). caja(id) (sala.js:79): [x - 11, y - alto(id), 22, alto(id)], relative to where they stand: unchanged' });
  // the frames: the box round all three, crooked or not
  const fr3 = FR.flatMap(f => f.quad); const fx = fr3.map(p => p[1]), fz = fr3.map(p => p[2]);
  const frW = [0, Math.min(...fx) - .1, Math.min(...fz) - .1, .1, Math.max(...fx) + .1, Math.max(...fz) + .12];
  const things = {
    hermano: person('hermano'), hermana: person('hermana'), bebe: person('bebe'), abuela: person('abuela'), mama: person('mama'), papa: person('papa'), abuelo: person('abuelo'),
    bizcocho: { sprite: true, prop: true, why: 'the cake on its dish (sprite layer): box [x - 1, y, 30, 16] at points.bizcocho (old [106, 138, 30, 16] at 107, 138)', box: [PTS.bizcocho.screen[0] - 1, PTS.bizcocho.screen[1], 30, 16] },
    mesita: turned(F.MES_C, F.MES_HW, F.MES_HD, F.MES_H, 'the low table, turned to the camera', { box: [98, 148, 46, 18] }),
    sofa: turned(F.SOFA_C, F.SOFA_HW, F.SOFA_HD, 1.32, 'the long sofa, turned to the camera', { box: [68, 84, 92, 44] }),
    butaca: turned(F.BUT_C, F.BUT_HW, F.BUT_HD, 1.22, 'abuelo\'s armchair, turned to the camera', { box: [160, 86, 42, 42] }),
    fotos: T(frW, 'the three picture frames on the left wall, crooked or straight (the box round them all, as the old one)', { old: { box: [64, 34, 82, 30] } }),
    lampara: T([F.LAMP[0] - .34, F.LAMP[1] - .34, 0, F.LAMP[0] + .34, F.LAMP[1] + .34, 2.42], 'the floor lamp, its foot to its shade', { old: { box: [146, 62, 20, 64] } }),
    puerta: (() => { const pts = []; for (const z of [0, F.DH + .14]) { pts.push([.03, F.D0 - .14, z], [.03, F.D1 + .14, z], [.06, F.D1 + .16, z], [F.DOORX1, F.D1 + .16 + F.LEAF_DY, z]); }
      const s = pts.map(p => E.project(...p)), w = boxAround(Math.min(...s.map(q => q.sx)), Math.min(...s.map(q => q.sy)), Math.max(...s.map(q => q.sx)), Math.max(...s.map(q => q.sy)));
      return T(w, 'the doorway with its frame and the open leaf (the box round their real corners, as a square world box: the leaf stands out of the wall)', { old: { box: [20, 42, 42, 80] } }); })(),
    ventana: T([F.W0 - .62, -.1, F.WZ0 - .45, F.W1 + .62, .2, F.WZ1 + .42], 'the window with its curtains and rod', { old: { box: [160, 32, 56, 54] } }),
    sala: T([2.62, 2.62, 0, 8, 10.15, 0], 'the open floor before the furniture (its box is the old floor\'s, from row 122 down, the whole width). Last in the hit order, as before', { old: { box: [0, 122, 240, 94] } }),
  };

  /* ---- clips ---- */
  const clips = {};
  for (const f of FR) clips['foto.' + f.i + (f.crooked ? '.torcida' : '')] = { thing: 'fotos', face: 'the opening of frame ' + f.i + (f.crooked ? ', crooked' : ''), world: f.quad, screen: f.screen, box: (() => { const xs = f.screen.map(p => p[0]), ys = f.screen.map(p => p[1]), x0 = Math.floor(Math.min(...xs)), y0 = Math.floor(Math.min(...ys)); return [x0, y0, Math.ceil(Math.max(...xs)) - x0, Math.ceil(Math.max(...ys)) - y0]; })(),
    what: 'sala.js:54 g.rect(-8, 2, 16, 20); g.clip(): the photo inside frame ' + f.i + ' is drawn clipped to this quad (screen), set before the translate' };

  /* ---- views: both zoom 1, one window (the old wide; the old sofa view was a 1.31x close view, which cannot be: no story uses it) ---- */
  const view = (what, old) => ({ zoom: 1, x0: 22, world: floor(120, 150), region: null, old, what });
  const views = {
    wide: view('the room: the door, the frames, the sofa, the lamp, the armchair and the window, the floor before them', [22, 0, 196, 216]),
    sofa: view('the sofa (old: a 1.31x view of the sofa; no story turns to it): the same window as wide, so a change to it moves nothing', [52, 48, 150, 165.3]),
  };

  /* ---- the review and level pictures ---- */
  const pic = (cx, cy, zoom, what) => { const crop = zoom === 1
      ? [Math.max(0, Math.min(44, Math.round(cx - 98))), Math.max(0, Math.min(112, Math.round(cy - 52))), 196, 104]
      : [Math.max(0, Math.min(142, Math.round(cx - 49))), Math.max(0, Math.min(164, Math.round(cy - 26))), 98, 52];
    return { world: floor(cx, cy), screen: [cx, cy], zoom, crop, what }; };
  const PICS = PICTURES(pic);
  const LEVEL = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8')).level.flatMap(L => L.pictures.map((p, i) => p.scene === 'sala' ? { w: L.w, index: i, picture: p.pair.replace(/[áéíóú]/g, c => 'aeiou'['áéíóú'.indexOf(c)]) + '.' + p.side, old: p.crop } : null).filter(Boolean));
  for (const l of LEVEL) { const pc = PICS[l.picture]; if (pc) { l.crop = pc.crop; l.zoom = pc.zoom; } }

  /* ---- remap: every distinct position of positions.json ---- */
  const POS = JSON.parse(fs.readFileSync(path.join(REF, 'positions.json'), 'utf8'));
  const deacc = s => s.replace(/[áéíóú]/g, c => 'aeiou'['áéíóú'.indexOf(c)]);
  const remap = POS.positions.map(p => {
    const e = { kind: p.kind, old: p.kind === 'point' ? [p.x, p.y] : p.kind === 'x' ? [p.x] : [p.x, p.y, p.w, p.h], uses: p.uses.map(u => u.file.replace(/^cuentos\//, '') + ' ' + u.at) };
    if (p.kind === 'cam') { const names = [...new Set(p.uses.map(u => { const m = u.at.match(/^(.+)\.(si|no)\.cam$/); return m ? deacc(m[1]) + '.' + m[2] : null; }).filter(Boolean))];
      e.to = { pictures: names }; e.crops = Object.fromEntries(names.map(n => [n, { crop: PICS[n] && PICS[n].crop, zoom: PICS[n] && PICS[n].zoom }])); }
    else if (p.kind === 'crop') { const names = [...new Set(LEVEL.filter(l => l.old && Math.abs(l.old[0] - p.x) < .01 && Math.abs(l.old[1] - p.y) < .01).map(l => l.picture))]; e.to = { pictures: names, level: true }; }
    else if (p.kind === 'x') e.to = { level: true, what: 'a level crop\'s centre x: the level pictures take pictures[...] whole (level[])' };
    else {
      const cq = p.uses.every(u => /\.cq$/.test(u.at));
      const w = cq ? frogW([p.x, p.y]) : personW([p.x, p.y]);
      e.to = { floor: w }; e.new = cq ? frogQ(w) : personQ(w);
      e.what = cq ? 'the frog (cq x, y): the floor under his feet; the same screen place' : 'a person\'s feet (x, y): the floor under them; the same screen place';
    }
    return e;
  });

  /* ---- what covers what: the low table ---- */
  const front = {
    how: 'sala.js:114 drew the low table in the list sorted by y (its y 165): everyone whose y is less is drawn before it and covered by it. The table is in the set now; at its place in the list, for each person (and the frog) drawn before it, the set\'s own pixels of the table (sala-set.html part "mesita", PART_TAGS) are drawn again inside that character\'s box, only where that pixel is nearer to the camera than the character: bakedZ[i] > v / COS - (row + .5 - OY) * tan(30 deg) / S, v = (x + y) / R2 of the floor point under the character\'s feet (people: unproject(x, y - 1); the frog: unproject(q.x + 16, q.y + 25)). The cake and the camera are drawn after it, as before. "Behind the table" is that depth test, not the row',
    plane: 'v / COS - (row + .5 - OY) * tan(30 deg) / S',
    parts: { mesita: { line: 114, sortY: 165, replaces: 'c.drawImage(spr("mesita",mkMesita),98,148+(W.golpe&&F-W.golpe<4?-2:0))', boxes: 'people: [x - 24, y - alto - 2, 48, alto + 3]; the frog: frogBox' } },
  };

  // hop counts: every pair of LUGAR places, old against new
  const lugar = {}; for (const [k, v] of Object.entries(OLD.LUGAR)) lugar[k] = { spot: 'frog.' + k, q: SPOTS['frog.' + k].new, scale: v[2], old: v.slice(0, 2) };
  const hops = [], names = Object.keys(lugar);
  for (let i = 0; i < names.length; i++) for (let j = i + 1; j < names.length; j++) {
    const a = lugar[names[i]], b = lugar[names[j]], dOld = Math.hypot(a.old[0] - b.old[0], a.old[1] - b.old[1]), dNew = Math.hypot(a.q[0] - b.q[0], a.q[1] - b.q[1]);
    hops.push({ a: names[i], b: names[j], old: hop(dOld), new: hop(dNew), dOld: r2(dOld), dNew: r2(dNew) });
  }

  const setKey = {
    params: {
      luz: { values: ['1', '0'], fromW: 'W.luz: the floor lamp lit (1) or not (0); every story keeps it lit (the old mkLampara(W.luz) draws both)' },
      fotos: { values: 'three characters, 0 or 1, one a frame, left to right', fromW: 'for i in 0..2: W.fotos[i] && !W.fotos[i].ok ? "1" (crooked) : "0". A photo in a frame (its people, the frog\'s foot, the slippers) is the sprite layer\'s: marco()' },
      top: { values: ['liso', 'patio'], fromW: 'not from W: the look of the room\'s cut-open top (see top); the game uses ' + 'liso' },
    },
    key: 'luz + "-" + fotos, e.g. "1-000"',
    baked: STATES.map(f => ({ query: '?luz=1&fotos=' + f, reached: { '000': 'every story\'s start, la-familia, d-bizcocho-bebe, quien-eres-tu, h-sala, d-foto-familia (all its photos straight), the pairs', '100': 'la-foto wrong (one crooked photo)', '110': 'la-foto wrong (two)', '111': 'la-foto wrong (three: the slippers)', '010': 'la-foto alternate' }[f] })),
    bakedWhy: 'order 06 found 27 states: what makes them is W.fotos (the frames), W.pastel (the cake), W.camMesa, W.gotas (coffee drops), W.relleno and W.luz. Only the frames\' crookedness and the lamp are the set\'s; the cake, the camera, the drops and the photos in the frames are drawn by the sprite layer, so 5 baked states draw all 27',
    notRead: 'W.borroso is an effect over the whole picture (smoothing: see smoothing); W.golpe (the table jumps 2 px when abuelo trips) is not drawn: the table is in the set',
  };

  return {
    scene: 'sala',
    made: 'node docs/proyecto/pixel/sala-sheet-make.js, from sala-set.html (window.SALA) and coqui/ref/escenas/sala/. Order 31a.',
    S: E.S, origin: { originX: G.scene.originX, originY: G.scene.originY }, picture: [E.W, E.H], view: [196, 216], pairPicture: [196, 104],
    rules: {
      project: 'pp-engine.js project(x, y, z) with S 26 and this origin; a box is the screen bounding box of its 8 projected corners [floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]',
      floor: 'the room is built round the old picture: a place on its floor keeps its screen place. A frog place q: the floor point under (q.x + 16, q.y + 25), new q = old q. A person\'s place (x, y): the floor point under (x, y - 1), new (x, y) = old. So every floor position of sala.js, its stories and its pairs keeps its numbers; the sheet names each one (spots, remap, code) with its world point',
      relative: 'what the old code draws or moves relative to a person, the frog or a point (p.x + 22, q.x + 16, h[0] - 2, the bubbles, the trays, the cups, the Z of sleep) keeps its offsets',
      sky: 'screen-space effects keep their old numbers: the flash (W.flash), the blur (W.borroso), the stars of final6 and final8, the heart (heartAt)',
      view: 'both views are zoom 1: the 196 x 216 window from x0 22, the old wide one. A change of view moves nothing',
      pair: 'a review or level picture is pictures[word.side] (level: level[...].picture): zoom 1 = the 196 x 104 window crop; zoom 2 = the 98 x 52 crop shown nearest-neighbour at 2 x 2. The old rectangles (remap cam and crop) say which pictures they were',
    },
    room: {
      what: 'a doll\'s house cut: of the room\'s four walls only the two far ones stand, the left one (facing +x, in shade: the door to the porch and the three frames) and the back one (facing +y, lit: the window). The two near walls are not built. The floor runs past the picture\'s bottom and sides, so no cut edge of it shows; the standing walls are cut at ' + F.WH + ' (a strip of wall over the door and the window), their cut tops a white edge. Furniture is turned to face the camera (as El balcón\'s chairs): the sofa stands across the corner, so the family sits in a row as in the old picture',
      why: 'the old picture is a wall and a floor that fill the frame, every place in it on that floor; a near wall, even cut low, would stand across the frog\'s floor and over feet, and a cut edge of the floor would be a line across the room. The two far walls are where the old door (left) and window (right) were; the corner between them is behind the sofa, as the old wall was',
    },
    top: {
      liso: 'candidate a (the one built on): above the cut walls a flat calm dark grey (' + 'rgb 38, 36, 44' + '), a little lighter than the lesson screen\'s #1B1B1F: the picture reads as a room seen from above, nothing outside competes with it',
      patio: 'candidate b (?top=patio, kept): above the cut walls the lawn round the house, far behind it: the cut-open house stands in its yard, as El frente\'s house. A fresh look reads it as grass where the ceiling would be',
      chosen: 'liso',
    },
    smoothing: {
      what: 'sala.js turns smoothing on in three places; the new canvas (Ctx) does not smooth unless told, so each keeps its smoothing on (Ctx.smoothing = true) exactly there, over the new picture',
      places: [
        { at: 'sala.js:120', what: 'W.borroso (acts.tropieza: what abuelo sees without his glasses): the whole scene picture, the set and the sprite layer drawn so far, is drawn down to 20 x 18 with smoothing on', keep: 'Ctx.snapshot of the 240 x 216 picture, drawImage into a 20 x 18 Sprite with smoothing true. The picture is the new set with the sprites on it: the blur is of the new room' },
        { at: 'sala.js:121', what: 'the 20 x 18 picture drawn back up to 240 x 216 with smoothing on (then off)', keep: 'drawImageRect with smoothing true, then false, as the old' },
        { at: 'sala.js:137', what: 'W.visor without nitido (la-foto: the camera\'s little window, out of focus): the person\'s sprite (22 x 23 of it) drawn down to 5 x 5 and back up to 46 x 46, smoothing on for both (the hud, on the display picture)', keep: 'unchanged: it draws a person\'s sprite in the hud, not the set' },
      ],
      notSmoothing: 'sala.js:190 acts.retrato draws 198 x 124 of the picture into 128 x 80 with smoothing OFF (a nearest-neighbour shrink, as the old): its region is points.retrato',
    },
    setKey,
    things,
    spots: Object.fromEntries(Object.entries(SPOTS).map(([k, s]) => [k, Object.assign({ world: s.world, new: s.new }, s.scale != null ? { scale: s.scale } : {}, { old: s.old, what: s.what })])),
    lugar,
    hops,
    points: PTS,
    views,
    remap,
    pictures: PICS,
    level: LEVEL,
    clips,
    front,
    shadows: {
      coqui: { radius: .45, at: 'the floor point under his feet on screen (unproject(b.x + b.w / 2, q.y + 25))', when: 'W.cq.vis and al > .5', cast: 'castShadow(g.x, g.y, .3, .45)' },
      people: { radius: { grown: .35, nino: .3, bebe: .25 }, at: 'the floor point under their feet on screen (unproject(x, y - 1))', when: 'visible (vis !== 0, al > .5) and standing (not sent); the baby on the floor too, not on mamá\'s lap (bebe.z)', cast: 'grown and children: for (z = .3; z <= 1.7; z += .35) castShadow(g.x, g.y, z, r); the baby: castShadow(g.x, g.y, .2, .25)' },
      dropped: 'sala.js:101 rana()\'s dotted shadow under the frog is not drawn: the engine casts his',
    },
    dropped: [
      'sala.js:107 c.drawImage(spr("sala", bg)) -> the set, for setKey(W)',
      'sala.js:109 the lamp, :110 the sofa and the armchair, :111 manta() (the baby\'s blanket) -> the set (nothing covered anyone in the old: they came before everyone)',
      'sala.js:114 the low table sprite -> the set (and front: its pixels again at that place in the list); its jump on W.golpe is not drawn',
      'sala.js:53 and :60 the frames\' wood, paper and nail -> the set (marco() draws only the photo in each)',
      'sala.js:32 the potted plant in bg() -> the set, on the floor by the back wall, clear of every touch box',
      'sala.js:101 the frog\'s dotted shadow -> the engine\'s cast shadow',
    ],
    moves: MOVES.map(m => ({ line: m.line, act: m.act, src: m.src, to: m.to, places: m.pts.map(q => ({ who: q[0] || 'whoever', old: q[1], new: q[2], world: q[3] })), why: m.why })),
    bubbles: { what: 'each bubble\'s rectangle relative to its tail\'s tip, as sala.js bub2 draws it (twice its size), both frames of its bob: [dx, dy, w, h]', rects: G.M.bubbles },
    talk: {
      what: 'where a bubble goes (sala.js talkAt for a person, line 124 for the frog). The old put it over the head; with the room seen from above, people stand in front of the sofa and a bubble over a head lands on the face of whoever sits behind. So: the first of these places whose bubble is wholly inside the view, clear of the corner cards shown (hud: the slices, the coffee, the camera\'s window, the photo of everyone) and of every face (each visible person\'s and the frog\'s, its own too); if none is, the first',
      top: 'a person: (x, y - alto - 1) as the old tail; the frog: (b.x + (b.w >> 1), b.y + 2)',
      places: TALK, placesWhat: '[side, dy]: the tail\'s tip at (top.x + side * (h + 16), top.y + dy), h the head\'s half width: a person 6, the frog b.w >> 1',
      faces: 'a person\'s face: [x - 6, y - alto + 5 (the baby: + 4), 12, 10] (eyes to chin, not the hair); the frog\'s: [b.x + 2, b.y + dy, b.w - 4, round(b.h * .6)]',
      heads: Object.fromEntries(Object.entries(G.M.people).map(([k, v]) => [k, { top: v.box[1], head: v.head }])),
      headsWhat: 'each sprite (idle; .sent: sitting): top, the first opaque row relative to the feet row y; head, the middle of its top 10 rows relative to x (facing right; facing left: x - head, + 1 for the family sprites drawn at -PX)',
      boards: 'in the 196 x 216 display, then + the view\'s x0: W.plato [2, 2, 80, 31]; W.cafe [2, 2, 46 + 13 * aciertos, 38]; W.visor [2, 2, 52, 52]; W.retrato [29, 5, 138, 90]',
    },
    code: CODE(),
    checks: { notes: [] },
  };

  function PICTURES(pic) {
    // each picture's centre is a screen point; the subject whole, the other side of the pair the same window
    // the three seats at zoom 2 (the person 49 to 51 rows tall, whole in the 52 rows, as large as the old 1.7x stretch)
    const seatRow = 103;
    return {
      'mama.si': pic(97, seatRow, 2, 'mamá sitting on the sofa, close'), 'mama.no': pic(97, seatRow, 2, 'abuela standing where mamá sits, close'),
      'papa.si': pic(131, seatRow, 2, 'papá sitting on the sofa, close'), 'papa.no': pic(131, seatRow, 2, 'abuelo sitting where papá sits, close'),
      'abuelo.si': pic(181, seatRow, 2, 'abuelo in his armchair, close'), 'abuelo.no': pic(181, seatRow, 2, 'abuela standing at his armchair, close'),
      'bebe.si': pic(72, 178, 2, 'the baby on the blanket, close'), 'bebe.no': pic(72, 178, 2, 'the brother on the blanket, close'),
      'familia.si': pic(120, 104, 1, 'everyone'), 'familia.no': pic(120, 104, 1, 'mamá alone on the sofa'),
      'hermano.si': pic(120, 122, 1, 'the brother standing before the sofa'), 'hermano.no': pic(120, 122, 1, 'papá standing there'),
      'hermana.si': pic(120, 122, 1, 'the sister standing before the sofa'), 'hermana.no': pic(120, 122, 1, 'mamá standing there'),
      'el.si': pic(118, 164, 1, 'the frog beside the brother'), 'el.no': pic(118, 164, 1, 'the frog beside the sister'),
      'ella.si': pic(120, 104, 1, 'the frog beside mamá'), 'ella.no': pic(120, 104, 1, 'the frog beside papá'),
      'yo.si': pic(118, 164, 1, 'the sister points at herself'), 'yo.no': pic(118, 164, 1, 'the sister points at the frog'),
      'tu.si': pic(118, 164, 1, 'the brother points at the frog'), 'tu.no': pic(118, 164, 1, 'the brother points at himself'),
    };
  }

  function CODE() {
    const C = [], c = (line, old, to, note) => C.push(note ? { line, old, to, note } : { line, old, to });
    const pn = n => ({ point: n, new: PTS[n].screen });
    c(17, 'bg(): the room', 'dropped: the set');
    c(32, 'bg(): the plant pot at 212, 94', 'dropped: the set (planta)');
    c(49, 'manta: fr(g,49,177,58,22) fr(g,50,178,56,20) fr(g,50,178,56,1); the white squares 52..104, 180..197', 'dropped: the set (manta, the same place on the screen)');
    c(52, 'marco: x = 76 + i * 24, y = 38; translate(x + 10, y + 2); rotate(.24 + .05 sin(F / 6 + i)) when !f.ok', { points: ['foto.0', 'foto.1', 'foto.2', 'foto.0.torcida', 'foto.1.torcida', 'foto.2.torcida'], new: [0, 1, 2].map(i => [PTS['foto.' + i].screen, PTS['foto.' + i + '.torcida'].screen, PTS['foto.' + i + '.torcida'].angle]) }, 'translate to points.foto.i (or foto.i.torcida, then rotate by its angle: baked crooked, no swing)');
    c(53, 'marco: fr(g,-11,-1,22,26,OUT) fr(g,-10,0,20,24,wood) fr(g,-10,0,20,1,wood) fr(g,-8,2,16,20, f ? "#BFE0F0" : "#FBF0D2")', 'the frame and the empty paper: dropped (the set). With a photo (f): fr(g, -10, 0, 20, 24, "#BFE0F0") inside the clip, the photo\'s ground');
    c(54, 'marco: g.rect(-8,2,16,20); g.clip()', { clips: ['foto.0', 'foto.1', 'foto.2', 'foto.0.torcida', 'foto.1.torcida', 'foto.2.torcida'] }, 'the clip is the quad of the set\'s opening, in picture coordinates: set it before the translate');
    c(55, 'marco: the slippers: fr(g,-8,14,16,8) and the shoes at [-6,10], [1,11]', 'relative to the frame: unchanged');
    c(58, 'marco: the frog\'s foot: fr(g,5,17,4,5) fr(g,6,18,3,4)', 'relative to the frame: unchanged');
    c(60, 'marco: the nail fr(g,0,-3,1,3,OUT)', 'dropped: the set (each frame hangs from a nail on a wire)');
    for (const [k, v] of Object.entries(OLD.SITIO)) c(75, 'SITIO.' + k + ' ' + JSON.stringify(v), { spot: 'sitio.' + k, new: SPOTS['sitio.' + k].new.concat(v.slice(2)) });
    for (const [k, v] of Object.entries(OLD.LUGAR)) c(76, 'LUGAR.' + k + ' ' + JSON.stringify(v), { spot: 'frog.' + k, new: SPOTS['frog.' + k].new.concat([v[2]]) });
    OLD.PARADOS.forEach((p, i) => c(77, 'PARADOS[' + i + '] ' + JSON.stringify(p), { spot: 'parados.' + i, new: SPOTS['parados.' + i].new }));
    OLD.APARTE.forEach((p, i) => c(77, 'APARTE[' + i + '] ' + JSON.stringify(p), { spot: 'aparte.' + i, new: SPOTS['aparte.' + i].new }));
    OLD.JUNTOS.forEach((p, i) => c(77, 'JUNTOS[' + i + '] ' + JSON.stringify(p), { spot: 'juntos.' + i, new: SPOTS['juntos.' + i].new }, 'moved (see moves, line 77)'));
    c(77, 'CAMARA ' + JSON.stringify(OLD.CAMARA), { spot: 'camara', new: SPOTS.camara.new });
    c(79, 'caja(id): [x - 11, y - alto(id), 22, alto(id)]', 'relative to the person: unchanged');
    c(82, 'box bizcocho [106,138,30,16]', { thing: 'bizcocho', box: things.bizcocho.box });
    c(82, 'box mesita [98,148,46,18]', { thing: 'mesita', box: things.mesita.box });
    c(82, 'box sofa [68,84,92,44]', { thing: 'sofa', box: things.sofa.box });
    c(82, 'box butaca [160,86,42,42]', { thing: 'butaca', box: things.butaca.box });
    c(83, 'box fotos [64,34,82,30]', { thing: 'fotos', box: things.fotos.box });
    c(83, 'box lampara [146,62,20,64]', { thing: 'lampara', box: things.lampara.box });
    c(83, 'box puerta [20,42,42,80]', { thing: 'puerta', box: things.puerta.box });
    c(83, 'box ventana [160,32,56,54]', { thing: 'ventana', box: things.ventana.box });
    c(83, 'box sala [0,122,240,94]', { thing: 'sala', box: things.sala.box });
    c(88, 'gente abuela: scale(-1,1) when dir < 0; drawImage(im,-30,0) at x, y - 50', 'relative to her: unchanged');
    c(91, 'gente: scale(-1,1) when dir < 0; drawImage(im, -PX, 0) at x, y - im.height + 1', 'relative to the person: unchanged');
    c(92, 'the Z of sleep: rects [0,0,4,1] [3,1,1,1] [2,2,1,1] [1,3,1,1] [0,4,4,1] at x + 6, y - h - 5', 'relative to abuelo: unchanged');
    c(93, 'taza at x + 13 d, y - h + 26', 'relative to abuelo: unchanged');
    c(99, 'taza: the coffee heights [0,2,4,6]', 'not a place: unchanged');
    c(101, 'rana: the dotted shadow at b.x + 2, q.y + 25', 'dropped: the engine casts his shadow (shadows.coqui)');
    c(105, 'bub2: c.scale(2,2), bub(c,k,0,0,a)', 'relative: unchanged (the bubbles are drawn at twice their size)');
    c(107, 'c.drawImage(spr("sala",bg),0,0)', 'dropped: the set, for setKey(W)');
    c(108, 'marco(c, i, W.fotos[i])', 'see line 52');
    c(109, 'the lamp at 146, 62', 'dropped: the set (lampara; luz is a set parameter)');
    c(110, 'the sofa at 68, 84; the armchair at 160, 86', 'dropped: the set (sofa, butaca)');
    c(111, 'manta(c)', 'dropped: the set');
    c(114, 'the low table at 98, 148 (sort y 165); bizcocho(c, 107, 138, n); the camera fr(c,113,139,16,10) fr(c,114,140,14,8) fr(c,118,142,5,5)', { front: 'mesita', sortY: 165, bizcocho: PTS.bizcocho.screen, camMesa: PTS.camMesa.screen }, 'the table: front (its own pixels again, depth-tested per character drawn before it); the cake at points.bizcocho; the camera\'s three rects at points.camMesa + (0, 0), (1, 1), (5, 3)');
    c(116, 'tapaojos: the hands at b.x + b.w * u, b.y + 7 s', 'relative to the frog: unchanged');
    c(120, 'borroso: drawImage(sc, 0, 0, SW, SH, 0, 0, 20, 18), smoothing on', 'smoothing.places[0]: the whole picture, unchanged');
    c(121, 'borroso: drawImage(t, 0, 0, 20, 18, 0, 0, SW, SH), smoothing on', 'smoothing.places[1]: unchanged');
    c(122, 'flash: fillRect(0, 0, SW, SH)', 'the whole picture: unchanged');
    c(126, 'talkAt: [x, y - alto - 1 - (bub ? 38 : 0)]', 'relative to the person: unchanged');
    c(131, 'hud retrato at ((DW - 136) / 2, 6)', 'display: unchanged');
    c(132, 'hud plato tarjeta(3,3,78,29) ...', 'display: unchanged');
    c(137, 'hud visor: smoothing on', 'smoothing.places[2]: unchanged');
    c(162, 'destapa stars [108,134] [132,134] [120,128]', pn('destapa.estrellas'));
    c(163, 'tres: vuelaA(120,140,50,24)', { from: PTS['tres.desde'].screen, to: PTS['hud.plato'].screen });
    c(174, 'abda: vuelaA(x.x, x.y - 30, 50, 24, 1)', pn('hud.plato'));
    c(175, 'abda: to h[0] + (bebe ? 22 : -2), bebe ? h[1] - 4 : 150', 'relative to SITIO; the row 150 is a floor row: unchanged (the floor rule)');
    c(180, 'suplato: mueve("abuela",158,200)', { floor: personW([158, 200]), new: personQ(personW([158, 200])) });
    c(183, 'final6: vuelaA(b.x, b.y - 14, q.x + 16, q.y + 8, 1, 0.8)', 'relative: unchanged');
    c(184, 'final6 stars [60,30] [180,34] [120,22] [96,44] [150,40]', 'screen effect: unchanged (over the walls\' tops and the backdrop)');
    for (const [L, pts] of [[188, [[150, 172]]], [193, [[150, 200], [182, 200]]], [198, [[94, 198], [66, 203]]], [214, [[120, 146], [72, 206]]], [224, [[98, 146], [142, 146], [172, 160], [66, 160], [140, 190], [100, 190], [106, 124]]],
      [228, [[156, 200], [84, 200], [190, 150], [97, 112]]], [230, [[162, 176]]], [231, [[192, 180]]], [235, [[192, 180]]], [236, [[152, 200], [86, 200]]], [247, [[150, 170], [182, 172]]]])
      for (const p of pts) { const mv = MOVES.flatMap(m => m.pts).find(q => q[1][0] === p[0] && q[1][1] === p[1]);
        if (mv) c(L, 'mueve / x, y ' + JSON.stringify(p), { floor: mv[3], new: mv[2] }, 'moved (see moves, line ' + L + ')');
        else c(L, 'mueve / x, y ' + JSON.stringify(p), { floor: personW(p), new: personQ(personW(p)) }, 'the floor rule: the same screen place'); }
    c(198, 'corren: a.x=40;a.y=126;b.x=34;b.y=124 (the children appear at the door)', { spots: ['puerta.hermano', 'puerta.hermana'], new: [SPOTS['puerta.hermano'].new, SPOTS['puerta.hermana'].new] }, 'in the new doorway, on its threshold');
    c(199, 'corren: the baby to mamá\'s lap: bb.x = 70 + (m.x - 70) i / 6 ..., then m.x, m.y - 15', 'from SITIO.bebe, relative to mamá: unchanged');
    c(205, 'junto: cx = p.x + (p.x < 120 ? -24 : 24); s = p.y < 150 ? .9 : 1; hopTo(cx - 16, p.y + 5 - 27, 2, s)', 'the 120 is the room\'s middle and 150 a floor row: unchanged (the floor rule); relative to the person');
    c(207, 'prueba: a star at p.x, p.y - 50', 'relative: unchanged');
    c(209, 'dispara: the star at [86 + i * 24, 50]', { points: ['foto.0', 'foto.1', 'foto.2'], new: [0, 1, 2].map(i => FR[i * 2].centre.map(Math.round)) }, 'over the middle of frame i (the old 86 + i * 24, 50 was the old frame\'s)');
    c(221, 'final7 stars at [86 + i * 24, 50]', { new: [0, 1, 2].map(i => FR[i * 2].centre.map(Math.round)) }, 'over the middle of frame i, as line 209');
    c(235, 'tapa: Math.abs(ab.x - 120) < 60; to q.x + 16, q.y + 22', 'the room\'s middle: unchanged; relative to the frog');
    c(239, 'abva: p.x + (p.x < 120 ? -22 : 22), p.y + 10', 'relative: unchanged');
    c(241, 'espejuelos: m.x + 9, m.y - 26; m.x + 28, m.y + 6; a star at ab.x, ab.y - 58', 'relative: unchanged');
    c(245, 'final8 stars [60,30] [180,34] [120,22] [96,44] [150,40]', 'screen effect: unchanged');
    c(259, 'CAM.wide [22,0,196,216]', { view: 'wide', zoom: 1, x0: views.wide.x0 });
    c(259, 'CAM.sofa [52,48,150,165.3]', { view: 'sofa', zoom: 1, x0: views.sofa.x0 });
    c(259, 'heartAt [107,6]', pn('corazon'));
    c(260, 'fresh(): cq at LUGAR.centro', 'LUGAR: line 76');
    c('juego.js:16', 'fresh(): cq x 150 y 178 s 1', 'not used here: sala\'s fresh() puts him at LUGAR.centro');
    c('cual.js:21', 'panelW(): cq x 123 y 150 s .86', 'a pair picture that shows the frog sets cq itself (remap); otherwise he is not seen (vis 0)');
    return C;
  }
}

/* ---------- the checks ---------- */
// the rules of page 13's order 31 (El frente's and El balcón's lessons), each over every moment of every recorded run of the scene's stories
const FRAME_OUT = 12;                 // juego.js spot(): the frame is box +- 5 (+ 2 when it pulses), and its rings reach 5 further out
const HANDR = [-12, 0, 36, 54];        // juego.js hand(): 12 x 15 cells of 3 px, drawn from (p.x - 12, p.y), 9 px lower on the down beat
const meets = (a, b) => a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
const within = (r, c) => r[0] >= c[0] && r[1] >= c[1] && r[0] + r[2] <= c[0] + c[2] && r[1] + r[3] <= c[1] + c[3];
const gapTo = (a, b) => Math.max(b[0] - (a[0] + a[2]), a[0] - (b[0] + b[2]), b[1] - (a[1] + a[3]), a[1] - (b[1] + b[3]));
const frogBox = q => { const w = Math.round(30 * q.s) + 2, h = Math.round(25 * q.s) + 2; return { x: Math.round(q.x + (32 - w) / 2), y: q.y + 27 - h, w, h }; };

function storyStates() {
  const os = require('os'), { execFileSync } = require('child_process');
  const dir = path.join(REPO, 'historia/cuentos'), stories = [];
  for (const f of fs.readdirSync(dir).sort()) { if (!f.endsWith('.json') || f.startsWith('cual-')) continue;
    const j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); if (j.scene === 'sala') stories.push(j); }
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'sala-sheet-'));
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
  /* the inventory: every thing, place, view, position, pair and level picture */
  for (const id of inv.thingIds) if (!sh.things[id]) P.push('thing missing: ' + id);
  if (Object.keys(sh.things).length !== inv.thingIds.length) P.push('things: ' + Object.keys(sh.things).length + ', not ' + inv.thingIds.length);
  if (sh.remap.length !== pos.positions.length) P.push('remap has ' + sh.remap.length + ' entries, positions.json ' + pos.positions.length);
  sh.remap.forEach((r, i) => { if (!r.to || (r.to.pictures && !r.to.pictures.length)) P.push('remap: no name for positions.json #' + i + ' ' + JSON.stringify(r.old)); });
  for (const k of Object.keys(inv.given.lugar)) if (!sh.lugar[k]) P.push('LUGAR missing: ' + k);
  for (const k of Object.keys(inv.given.CAM)) if (!sh.views[k]) P.push('CAM missing: ' + k);
  const pairs = JSON.parse(fs.readFileSync(path.join(REF, 'pairs.json'), 'utf8')), deacc = s => s.replace(/[áéíóú]/g, c => 'aeiou'['áéíóú'.indexOf(c)]);
  const cual = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/cual-sala.json'), 'utf8'));
  for (const it of cual.items) for (const s of ['si', 'no']) if (!sh.pictures[deacc(it.w) + '.' + s]) P.push('picture missing: ' + it.w + '.' + s);
  let nLevel = 0; for (const L of pairs.level) for (const p of L.pictures) if (p.scene === 'sala') { nLevel++; if (!sh.pictures[deacc(p.pair) + '.' + p.side]) P.push('level picture missing: ' + p.pair + '.' + p.side); }
  if (sh.level.length !== nLevel) P.push('level: ' + sh.level.length + ' pictures, pairs.json ' + nLevel);
  const lines = new Set(sh.code.map(e => String(e.line)));
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1]; if (!lines.has(L)) P.push('sala.js line ' + L + ' (' + p.what + ' ' + JSON.stringify(p.nums) + ') has no entry in code'); }
  for (const p of pos.inSceneFile) { const L = p.at.split(':')[1], es = sh.code.filter(e => String(e.line) === L), nums = p.nums.slice(0, 2).map(String);
    if (!es.some(e => nums.every(n => e.old.replace(/\s/g, '').includes(n)))) P.push('sala.js:' + L + ' ' + JSON.stringify(p.nums) + ' (' + p.what + '): no code entry names these numbers'); }
  notes.push('inventory: ' + Object.keys(sh.things).length + ' things (old ' + inv.thingIds.length + '), ' + Object.keys(sh.lugar).length + ' frog places (old ' + Object.keys(inv.given.lugar).length + '), ' + Object.keys(sh.views).length + ' views (old ' + Object.keys(inv.given.CAM).length + '), ' + sh.remap.length + ' positions (old ' + pos.positions.length + '), ' + cual.items.length + ' review pairs, ' + sh.level.length + ' level pictures (old ' + nLevel + '), ' + pos.inSceneFile.length + ' places of sala.js named in code');

  /* hops */
  let worst = 99;
  for (const h of sh.hops) { if (h.old !== h.new) P.push('hops ' + h.a + ' - ' + h.b + ': old ' + h.old + ', new ' + h.new); if (h.dNew > 0) worst = Math.min(worst, ...[3, 45, 75, 105].map(e => Math.abs(h.dNew - e))); }
  notes.push('hops: ' + sh.hops.length + ' pairs of LUGAR places, every count as the old one (round(d / 30), 1 to 4, kit.js acts.ir); the places keep their screen points, so every distance is the old one');

  /* the set's pixels: which part drew each, its depth */
  const tagMap = key => { const m = new Array(240 * 216).fill(null); for (const [k, list] of Object.entries(G.parts[key])) for (const i of list) m[i] = k; return m; };
  const TAGS = Object.fromEntries(Object.keys(G.parts).map(k => [k, tagMap(k)]));
  const keyOf = w => [0, 1, 2].map(i => (w.fotos || [])[i] && !w.fotos[i].ok ? '1' : '0').join('');
  const countIn = (tag, r, names) => { let n = 0; for (let y = Math.max(0, r[1]); y < Math.min(216, r[1] + r[3]); y++) for (let x = Math.max(0, r[0]); x < Math.min(240, r[0] + r[2]); x++) if (names.includes(tag[y * 240 + x])) n++; return n; };

  /* decor: nothing decorative over a touch box */
  const DECOR = ['planta'];
  for (const k of Object.keys(G.parts)) for (const [id, t] of Object.entries(sh.things)) if (t.set) for (const d of DECOR) { const n = countIn(TAGS[k], t.box, [d]); if (n) P.push('fotos ' + k + ': ' + n + ' px of ' + d + ' inside the box of ' + id); }
  notes.push('decor: no pixel of the plant inside any set thing\'s touch box (every baked state)');

  /* the door and the windows: the whole door (and who stands in it) in the wide view with a margin; a strip of wall over door and window */
  const x0 = sh.views.wide.x0;
  { const d = sh.things.puerta.box, who = [d];
    for (const k of ['puerta.hermano', 'puerta.hermana']) { const p = sh.spots[k].new; who.push([p[0] - 11, p[1] - 44, 22, 44]); }
    { const b = frogBox({ x: sh.lugar.puerta.q[0], y: sh.lugar.puerta.q[1], s: sh.lugar.puerta.scale }); who.push([b.x, b.y, b.w, b.h]); }
    const L = Math.min(...who.map(r => r[0])), R = Math.max(...who.map(r => r[0] + r[2])), T = Math.min(...who.map(r => r[1]));
    if (L - x0 < 8 || x0 + 196 - R < 8 || T < 8) P.push('wide view: the door or who stands in it is ' + Math.min(L - x0, x0 + 196 - R, T) + ' px from its edge (keep 8)');
    notes.push('wide view (x0 ' + x0 + '): the door, its open leaf and who stands in it from x ' + L + ' to ' + R + ' (' + (L - x0) + ' px from the left side), from row ' + T);
    for (const [k, v] of Object.entries(sh.views)) if (v.zoom === 1 && v.x0 !== x0) P.push('views: ' + k + ' is a zoom 1 window from x ' + v.x0 + ', the wide one from ' + x0);
    notes.push('views: ' + Object.keys(sh.views).map(k => k + ' zoom ' + sh.views[k].zoom + ' x0 ' + sh.views[k].x0).join(', ') + ': a change of view moves nothing');
    const tag = TAGS['000'], strip = (sx, sy) => { let n = 0; for (let y = sy - 1; y >= 0 && tag[y * 240 + sx] === 'pared'; y--) n++; return n; };
    const dTop = E.project(.03, (F.D0 + F.D1) / 2, F.DH + .14), rTop = E.project((F.W0 + F.W1) / 2, .16, F.WZ1 + .42);
    const sd = strip(Math.round(dTop.sx), Math.floor(dTop.sy) - 1), sw = strip(Math.round(rTop.sx), Math.floor(rTop.sy) - 2);
    if (sd < 6 || sw < 3) P.push('a strip of wall: over the door ' + sd + ' px, over the window\'s rod ' + sw + ' px');
    notes.push('a strip of wall: ' + sd + ' px of wall over the door\'s frame, ' + sw + ' px over the window\'s curtain rod, before the wall\'s cut top'); }

  /* the frames hang from nails on the wall; the lamp stands on its foot (structure: notes) */
  notes.push('hanging: each frame hangs on a wire from a nail in the left wall (sala-set.html frames(); crooked ones turned about that nail); the lamp stands on its round foot on the floor; the curtains hang from a rod on two brackets');

  /* the cake and the camera on the low table */
  const top = (() => { const c = F.MES_C, a = F.TURN, ax = Math.cos(a), ay = Math.sin(a), bx = -ay, by = ax, xs = [], ys = [];
    for (const s of [-F.MES_HW, F.MES_HW]) for (const t of [-F.MES_HD, F.MES_HD]) { const q = E.project(c[0] + ax * s + bx * t, c[1] + ay * s + by * t, F.MES_H); xs.push(q.sx); ys.push(q.sy); }
    return [Math.ceil(Math.min(...xs)), Math.ceil(Math.min(...ys)), Math.floor(Math.max(...xs)), Math.floor(Math.max(...ys))]; })();
  { const B = sh.points.bizcocho.screen, K = sh.points.camMesa.screen, tag = TAGS['000'], busy = ['lampara', 'fotos', 'ventana', 'planta', 'puerta'];
    const dish = [B[0] - 4, B[1] + 9, 34, 3], cam = [K[0], K[1], 16, 10];
    for (const [n, r] of [['the cake\'s dish', dish], ['the camera', cam]]) {
      if (r[0] < top[0] + 1 || r[0] + r[2] > top[2] || r[1] + r[3] - 1 > top[3] - 1 || r[1] + r[3] - 1 < top[1] + 2) P.push('table: ' + n + ' ' + JSON.stringify(r) + ' does not stand on the top ' + JSON.stringify(top));
    }
    const behind = countIn(tag, [B[0] - 4, B[1] - 16, 34, 26], busy) + countIn(tag, [K[0], K[1] - 2, 16, 12], busy);
    if (behind) P.push('table: ' + behind + ' px of the lamp, frames, window, plant or door behind the cake or the camera');
    notes.push('table: its top spans x ' + top[0] + '..' + top[2] + ', rows ' + top[1] + '..' + top[3] + '; the cake\'s dish ' + JSON.stringify(dish) + ' and the camera ' + JSON.stringify(cam) + ' stand on it, their bottoms ' + (top[3] - dish[1] - 2) + ' and ' + (top[3] - cam[1] - 9) + ' rows from its front edge; plain floor and sofa behind them'); }

  /* every moment of every run */
  const runs = storyStates();
  const at = (st, p) => p.split('.').reduce((o, k) => o == null ? o : o[/^\d+$/.test(k) ? +k : k], st);
  const sub = (x, V) => typeof x === 'string' ? x.replace(/\$(\w+)/g, (m, k) => V && V[k] != null ? V[k] : m) : x;
  const alto = (id, p) => id === 'abuela' ? 51 : id === 'bebe' ? 28 : (FAM[id].nino ? 44 : (p && p.sent ? 49 : 56));
  const shown = p => p && p.vis !== 0 && !(p.al != null && p.al <= .3);
  const people = w => Object.entries(w.gente || {}).filter(([id, p]) => shown(p));
  // a person's body: the opaque box of their sprite (idle; measured), mirrored when they face left; their face: 12 x 10 under the top of the head
  // (eyes to chin, not the hair), on the head's middle
  const spr = (id, p) => G.M.people[id + (p.sent && id !== 'abuela' && id !== 'bebe' ? '.sent' : '')];
  const body = (id, p) => { const m = spr(id, p), b = m.box, x = Math.round(p.x), y = Math.round(p.y);
    return p.dir < 0 && id !== 'bebe' ? [x - (b[0] + b[2]) + (id === 'abuela' ? 0 : 1), y + b[1], b[2], b[3]] : [x + b[0], y + b[1], b[2], b[3]]; };
  const faceOf = (id, p) => { const m = spr(id, p), b = body(id, p), hx = p.dir < 0 && id !== 'bebe' ? Math.round(p.x) - m.head + (id === 'abuela' ? 0 : 1) : Math.round(p.x) + m.head;
    return [Math.round(hx - 6), b[1] + (id === 'bebe' ? 4 : 5), 12, 10]; };
  const frogFace = q => { const b = frogBox(q); return [b.x + 2, b.y + Math.round(q.dy || 0), b.w - 4, Math.round(b.h * .6)]; };
  const BUBR = G.M.bubbles, bubRect = (k, tx, ty) => { const r = BUBR[k]; if (!r) throw new Error('no bubble ' + k); return [tx + r[0], ty + r[1], r[2], r[3]]; };
  const boardsOf = (w, x0) => { const b = []; if (w.plato != null) b.push(['the slices card', [2, 2, 80, 31]]); if (w.cafe) b.push(['the coffee card', [2, 2, 46 + 13 * (w.aciertos || 0), 38]]); if (w.visor) b.push(['the camera\'s window', [2, 2, 52, 52]]); if (w.retrato) b.push(['the photo of everyone', [29, 5, 138, 90]]);
    return b.map(([n, r]) => [n, [r[0] + x0, r[1], r[2], r[3]]]); };
  const VIEW = [x0, 0, 196, 216];
  // the old runs' W in the new places: a person at a moved place goes to its new one; the frog hopped beside a moved person (acts.junto) goes with them
  const MVall = sh.moves.flatMap(m => m.places.map(q => Object.assign({ act: m.act }, q)));
  let MV = MVall;
  const remapW = w0 => { const w = JSON.parse(JSON.stringify(w0)), moved = [];
    for (const [id, p] of Object.entries(w.gente || {})) { if (!p || p.x == null) continue; const m = MV.find(q => (q.who === 'whoever' || q.who === id) && q.old[0] === Math.round(p.x) && q.old[1] === Math.round(p.y));
      if (m) { moved.push([m.old, m.new]); p.x = m.new[0]; p.y = m.new[1]; } }
    const q = w.cq; if (q) for (const [o, n] of moved) { const jx = p => Math.round(p[0] + (p[0] < 120 ? -24 : 24) - 16), jy = p => Math.round(p[1] + 5 - 27);
      if (q.x === jx(o) && q.y === jy(o)) { q.x = jx(n); q.y = jy(n); } }
    return w; };
  let nM = 0, nB = 0, worstView = 99, worstBoard = 99; const seen = new Set();
  const facesOf = w => { const f = people(w).map(([id, p]) => [id + '\'s face', faceOf(id, p)]); if (w.cq && w.cq.vis && !(w.cq.al < .5)) f.push(['the frog\'s face', frogFace(w.cq)]); return f; };
  // sheet.talk: the first place whose bubble is inside the view, clear of the boards and of every face
  const talk = (k, top, view, boards, faces, h = 6) => { for (const [side, dy] of sh.talk.places) { const r = bubRect(k, top[0] + side * (h + 16), top[1] + dy);
      if (within(r, view) && !boards.some(b => meets(r, b[1])) && !faces.some(f => meets(r, f[1]))) return r; } return bubRect(k, top[0], top[1]); };
  const bubblesOf = (w, acts = true, view = VIEW) => {
    const out = [], boards = boardsOf(w, view[0]), faces = facesOf(w);
    for (const [id, p] of people(w)) { if (p.al != null && p.al < .5) continue;
      const ks = new Set(p.bub ? [p.bub] : []); if (acts) { ks.add('amor'); if (id === 'abuelo') ks.add('q'); }
      for (const k of ks) out.push([id + ' (' + Math.round(p.x) + ',' + Math.round(p.y) + (p.sent ? ' sitting' : '') + ') "' + k + '"', talk(k, [Math.round(p.x), Math.round(p.y) - alto(id, p) - 1], view, boards, faces)]); }
    const q = w.cq; if (q && q.vis && !(q.al < .5)) { const b = frogBox(q); for (const k of new Set((acts ? [q.bub, 'amor'] : [q.bub]).filter(Boolean))) out.push(['the frog (' + q.x + ',' + q.y + ') "' + k + '"', talk(k, [b.x + (b.w >> 1), b.y + 2], view, boards, faces, b.w >> 1)]); }
    return out; };
  const judge = (where, rect, box, boards, faces) => {
    if (!within(rect, box)) { P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is not wholly inside ' + JSON.stringify(box)); return; }
    worstView = Math.min(worstView, rect[0] - box[0], box[0] + box[2] - rect[0] - rect[2], rect[1] - box[1], box[1] + box[3] - rect[1] - rect[3]);
    for (const [bn, b] of boards) { if (meets(rect, b)) P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is over ' + bn + ' ' + JSON.stringify(b)); else worstBoard = Math.min(worstBoard, gapTo(rect, b)); }
    for (const [fn, f] of faces) if (meets(rect, f)) P.push('bubble: ' + where + ' ' + JSON.stringify(rect) + ' is on ' + fn + ' ' + JSON.stringify(f));
  };
  // standing on clear floor, sitting on a seat: no set pixel of furniture or wall nearer than a character inside its body (the low table
  // only when the character is drawn after it: before it, front draws the table again where it is nearer)
  const NEAR = .08;   // a body has some depth: a face of furniture this close behind the plane through the feet touches them, it is not in front
  const SOLID = ['sofa', 'butaca', 'lampara', 'planta', 'pared', 'puerta', 'ventana', 'fotos', 'mesita'];
  const sortY = sh.front.parts.mesita.sortY;
  const vAt = (sx, sy) => { const g = E.atZ(sx, sy, 0); return (g[0] + g[1]) / E.R2; };
  const nearer = (key, r, v, names) => { const Z = G.z[key], tag = TAGS[key]; let n = 0;
    for (let y = Math.max(0, r[1]); y < Math.min(216, r[1] + r[3]); y++) for (let x = Math.max(0, r[0]); x < Math.min(240, r[0] + r[2]); x++) { const i = y * 240 + x; if (names.includes(tag[i]) && Z[i] > (v + NEAR) / COS - (y + .5 - E.OY) * T30 / E.S) n++; }
    return n; };
  const seatOf = (gx, gy) => { for (const [n, c, hw, hd] of [['sofa', F.SOFA_C, F.SOFA_HW, F.SOFA_HD], ['butaca', F.BUT_C, F.BUT_HW, F.BUT_HD]]) {
      const dx = gx - c[0], dy = gy - c[1], s = dx * Math.cos(F.TURN) + dy * Math.sin(F.TURN), t = -dx * Math.sin(F.TURN) + dy * Math.cos(F.TURN);
      if (Math.abs(s) <= hw - .15 && t >= hd - .3 && t <= hd + .5) return n; } return null; };
  const floorSeen = new Set(); let nFloor = 0, nSit = 0;
  const floorCheck = (where, w) => {
    const key = keyOf(w);
    for (const [id, p] of people(w)) {
      if (p.z) continue;                                                       // the baby on mamá's lap
      const k = JSON.stringify([id, Math.round(p.x), Math.round(p.y), !!p.sent, key]); if (floorSeen.has(k)) continue; floorSeen.add(k);
      const g = E.atZ(Math.round(p.x), Math.round(p.y) - 1, 0);
      if (p.sent) { nSit++; if (!seatOf(g[0], g[1])) P.push('sitting: ' + where + ' ' + id + ' at ' + Math.round(p.x) + ',' + Math.round(p.y) + ' is not before a seat of the sofa or the armchair'); continue; }
      nFloor++;
      if (!(g[0] > .15 && g[1] > .15)) P.push('floor: ' + where + ' ' + id + ' at ' + Math.round(p.x) + ',' + Math.round(p.y) + ' stands outside the room (' + g.map(r2) + ')');
      const names = (p.z || p.y) < sortY ? SOLID.filter(n => n !== 'mesita') : SOLID, n = nearer(key, body(id, p), vAt(Math.round(p.x), Math.round(p.y) - 1), names);
      if (n) P.push('floor: ' + where + ' ' + id + ' at ' + Math.round(p.x) + ',' + Math.round(p.y) + ': ' + n + ' px of furniture or wall nearer than them inside their body');
    }
    const q = w.cq; if (q && q.vis) { const k = JSON.stringify(['cq', q.x, q.y, q.s, key]); if (!floorSeen.has(k)) { floorSeen.add(k); nFloor++;
      const b = frogBox(q), names = q.y + 27 < sortY ? SOLID.filter(n => n !== 'mesita') : SOLID, n = nearer(key, [b.x, b.y, b.w, b.h], vAt(b.x + b.w / 2, q.y + 25), names);
      if (n) P.push('floor: ' + where + ' the frog at ' + q.x + ',' + q.y + ': ' + n + ' px of furniture or wall nearer than him inside his box'); } }
  };
  let both = 0;
  const actsOf = st => new Set((JSON.stringify(st).match(/"act":\s*"[a-z0-9]+"/g) || []).map(a => a.split('"')[3]));
  const forRun = r => { const a = actsOf(r.story); MV = MVall.filter(q => a.has(q.act)); };
  for (const r of runs) { forRun(r); for (const L of r.lines) {
    if (JSON.stringify(L.cam) !== '[22,0,196,216]') P.push(r.story.id + ' ' + r.plan + ' ' + L.path + ': a view the sheet does not have ' + JSON.stringify(L.cam));
    const w = remapW(L.W), boards = boardsOf(w, x0), faces = facesOf(w); nM++;
    if (w.pastel != null && w.camMesa) both++;
    for (const [who, rect] of bubblesOf(w)) { const key = JSON.stringify([who, rect, boards]); if (seen.has(key)) continue; seen.add(key); nB++; judge(r.story.id + ' ' + r.plan + ' ' + L.path + ': ' + who, rect, VIEW, boards, faces); }
    floorCheck(r.story.id + ' ' + r.plan + ' ' + L.path + ':', w);
  } }
  if (both) P.push('table: at ' + both + ' moments the cake and the camera are on it at once');
  notes.push('table: the cake and the camera are never on it at once (' + nM + ' moments)');

  /* the asks: hint frames inside the view, the hand on no face, the answer cards over no one */
  const boxOf = (w, k) => { const t = sh.things[k];
    if (t && t.set) return t.box;
    if (k === 'bizcocho') return w.pastel > 0 ? t.box : null;
    if (k === 'coqui') { const b = frogBox(w.cq); return [b.x, b.y, b.w, b.h]; }
    const p = w.gente && w.gente[k]; return p && shown(p) ? body(k, p) : null; };
  // how many of a person's opaque pixels (their sprite in the pose they have, mirrored when they face left) are inside rectangle r
  const maskMeets = (id, p, r) => { const pose = id === 'bebe' ? (p.est || 'idle') : (p.pose || 'idle'), key = id + '.' + (G.M.masks[id + '.' + pose + (p.sent ? '.sent' : '')] ? pose + (p.sent ? '.sent' : '') : G.M.masks[id + '.' + pose + '0'] ? pose + '0' : 'idle' + (p.sent && id !== 'abuela' && id !== 'bebe' ? '.sent' : ''));
    const m = G.M.masks[key], x = Math.round(p.x), y = Math.round(p.y), flip = p.dir < 0 && id !== 'bebe'; let n = 0;
    for (const [dy, a, b] of m) { const row = y + dy; if (row < r[1] || row >= r[1] + r[3]) continue; const xa = flip ? x - b + (id === 'abuela' ? 0 : 1) : x + a, xb = flip ? x - a + (id === 'abuela' ? 0 : 1) : x + b;
      n += Math.max(0, Math.min(xb + 1, r[0] + r[2]) - Math.max(xa, r[0])); }
    return n; };
  const respBox = (w, k) => { const q = w.cq, b = frogBox(q), n = w.resp.length, i = w.resp.indexOf(k), m = n > 2 ? 76 : 60, cx = Math.max(x0 + m, Math.min(x0 + 196 - m, b.x + b.w / 2)), y = Math.max(4, b.y - 46);
    return n > 2 ? [Math.round(cx - 70 + i * 50), y, 40, 36] : i === 0 ? [Math.round(cx - 50), y, 40, 36] : [Math.round(cx + 10), y, 40, 36]; };
  let nF = 0, nC = 0, nH = 0, worstF = 99, worstC = 99; const askSeen = new Set(), cardHand = new Set();
  for (const r of runs) { const Ls = r.lines; forRun(r);
    Ls.forEach(L => { if (L.kind !== 'ask' && L.kind !== 'decide') return;
      const j = Ls.findIndex(M => M.path === L.path || (M.path || '').startsWith(L.path + '.')); if (j < 1) return;
      const w = remapW(Ls[j - 1].W), st = at(r.story, L.path), V = Ls[j - 1].V;
      const sb = x => sub(x, V);
      w.resp = null; let spot = null;
      if (st.ask) { spot = sb(st.ask); if (st.resp) w.resp = st.resp.map(sb); }
      else if (st.decide) { const ops = st.options.map(sb), bur = (st.burbujas || []).map(sb); spot = sb(st.pick) || ops[0]; if (st.decide === 'say') w.resp = ops; else if (bur.length) w.resp = bur; }
      const where = r.story.id + ' ' + r.plan + ' ' + L.path + ' (' + spot + ')', key = JSON.stringify([spot, w.gente, w.cq, w.resp, w.pastel]);
      if (askSeen.has(key)) return; askSeen.add(key);
      const faces = facesOf(w), bodies = people(w).map(([id, p]) => [id, body(id, p)]);
      // the answer cards
      if (w.resp) for (const k of w.resp) { const c = respBox(w, k); nC++;
        if (!within(c, VIEW)) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' is not inside the view');
        for (const [id, b] of bodies) { const p = w.gente[id], n = maskMeets(id, p, c); if (n) P.push('cards: ' + where + ' the card ' + k + ' ' + JSON.stringify(c) + ' covers ' + n + ' px of ' + id + ' ' + JSON.stringify(b)); else worstC = Math.min(worstC, gapTo(c, b)); } }
      // the frame round the thing asked for (an answer card asked for: the card), and the hand
      const rb = w.resp && w.resp.includes(spot) ? respBox(w, spot) : null, b = rb || boxOf(w, spot);
      if (!b) { P.push('ask: ' + where + ': no box for ' + spot); return; }
      nF++;
      const fr = [b[0] - FRAME_OUT, b[1] - FRAME_OUT, b[2] + 2 * FRAME_OUT, b[3] + 2 * FRAME_OUT];
      if (!rb) { if (!within(fr, VIEW)) P.push('hint frame: ' + where + ' ' + JSON.stringify(b) + ' +- ' + FRAME_OUT + ' is not wholly inside the view'); else worstF = Math.min(worstF, fr[0] - x0, x0 + 196 - fr[0] - fr[2], fr[1], 216 - fr[1] - fr[3]); }
      const hp = rb ? [rb[0] + rb[2] / 2, rb[1] + rb[3] - 6] : [Math.round(b[0] + b[2] / 2), Math.round(b[1] + b[3] / 2)], hr = [Math.round(hp[0]) + HANDR[0], Math.round(hp[1]) + HANDR[1], HANDR[2], HANDR[3]]; nH++;
      for (const [fn, f] of faces) if (meets(hr, f)) { if (rb && fn === 'the frog\'s face') { cardHand.add(spot); continue; } P.push('hand: ' + where + ' the hand ' + JSON.stringify(hr) + ' is on ' + fn + ' ' + JSON.stringify(f)); }
    }); }
  notes.push('asks: ' + nF + ' distinct asks: every hint frame (box +- ' + FRAME_OUT + ') wholly inside the view (' + worstF + ' px from its edge at the least), the hint hand on no face; ' + nC + ' answer cards inside the view, over no one\'s body (no opaque pixel of anyone\'s sprite, in their pose, under a card)');
  if (cardHand.size) notes.push('NOT the scene\'s: the hand juego.js draws at an answer card (the left one) reaches 7 px onto the frog\'s face, 46 px under it, in every scene (the card\'s place and the hand are the game\'s, respBox and hand()): at the asks for ' + [...cardHand].join(', '));
  notes.push('bubbles: ' + nB + ' bubbles at ' + nM + ' moments of ' + runs.length + ' runs (' + [...new Set(runs.map(r => r.story.id))].join(', ') + '), each its recorded one and the ones an act can show there (anyone\'s "amor" when touched, abuelo\'s "q", the frog\'s "amor"): wholly inside the view (' + worstView + ' px from its edge at the least), clear of the cards shown in the corner (' + worstBoard + ' px), on no face');
  notes.push('floor: ' + nFloor + ' distinct places where someone stands (and the frog): inside the room, nothing of the furniture or the walls nearer than them inside their body (the low table only covers who is drawn before it, and only where it is nearer); ' + nSit + ' distinct sittings, each before a seat');

  /* the review pictures */
  let nPic = 0; const pairDiff = [];
  for (const it of cual.items) {
    const ws = {};
    for (const side of ['si', 'no']) {
      const spec = it[side], w = Object.assign({ gente: {}, cq: { x: 123, y: 150, s: .86, dy: 0, al: 1, vis: spec.set && spec.set.resp ? 1 : 0, bub: null } }, JSON.parse(JSON.stringify(spec.set || {}))), nm = deacc(it.w) + '.' + side, pc = sh.pictures[nm]; ws[side] = w; nPic++;
      const crop = pc.crop, who = people(w).map(([id, p]) => [id, body(id, p)]); if (w.cq.vis) { const b = frogBox(w.cq); who.push(['the frog', [b.x, b.y, b.w, b.h]]); }
      for (const [id, b] of who) if (!within(b, crop)) P.push('pair ' + nm + ': ' + id + ' ' + JSON.stringify(b) + ' is cut by the picture ' + JSON.stringify(crop));
      for (const [who2, rect] of bubblesOf(w, false, crop)) if (!within(rect, crop)) P.push('pair ' + nm + ': ' + who2 + ' bubble is cut');
      floorCheck('pair ' + nm + ':', w);
    }
    // the one thing the pair is about: the two pictures' people and frog differ in it only (who, where, which pose)
    const a = JSON.stringify(ws.si), b = JSON.stringify(ws.no);
    if (a === b) P.push('pair ' + it.w + ': the two pictures are the same');
    const diff = []; const ids = new Set([...Object.keys(ws.si.gente || {}), ...Object.keys(ws.no.gente || {})]);
    for (const id of ids) { const x = (ws.si.gente || {})[id], y = (ws.no.gente || {})[id]; if (JSON.stringify(x) !== JSON.stringify(y)) diff.push(id + (!x ? ' only in no' : !y ? ' only in si' : ' ' + Object.keys(x).filter(k => JSON.stringify(x[k]) !== JSON.stringify(y[k])).join('/'))); }
    if (JSON.stringify(ws.si.cq) !== JSON.stringify(ws.no.cq)) diff.push('the frog ' + Object.keys(ws.si.cq).filter(k => ws.si.cq[k] !== ws.no.cq[k]).join('/'));
    pairDiff.push(deacc(it.w) + ': ' + diff.join(', '));
  }
  notes.push('pairs, what differs (the same window both sides): ' + pairDiff.join('; '));
  notes.push('pairs: ' + nPic + ' review pictures (and the ' + sh.level.length + ' level pictures, the same pictures): everyone and the frog whole in their crop, on clear floor or a seat');
  return P;
}
