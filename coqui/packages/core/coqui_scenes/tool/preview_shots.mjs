#!/usr/bin/env node
// The pictures of docs/proyecto/pixel/<scene>-preview.html (the old sprite layer on the new set, through the sheet: what
// the Dart scene must draw), rendered in headless Chrome, for the comparison test (test/preview_test.dart,
// test/balcon_preview_test.dart).
//
//   node tool/preview_shots.mjs [--scene frente|balcon|sala|patio|camino|campo|lago|banco|mesa|estufa|nevera|comer] --states DIR --out DIR [--fixture]
//
// --scene: the converted scene (frente when not given). La sala's cases carry the acts their story names (`acts`): its
//   preview moves a person only at a moved place of an act the story uses (PREVIEW.acts, the sheet's `moves`). El patio's
//   carry them too, and the story is given to its preview (PREVIEW.story: the moves of the acts it names, the story
//   positions the sheet moved for it); its pairs are cual-patio's and cual-camino's parque.no (a picture of the yard). El camino's
//   are drawn as El patio's (PREVIEW.story, the moves of its acts and the story positions the sheet moved); its pairs are
//   cual-camino's but parque.no (El patio's). El campo's, El lago's, El banco's, La estufa's, La nevera's and A comer's are
//   drawn as El camino's; their pairs are all cual-campo's, cual-lago's, cual-banco's, cual-estufa's, cual-nevera's and
//   cual-comer's (A comer's pictures fold the question marks away too: ¿qué quieres?.si is que_quieres.si). --states: the folder
//   `node coqui/tool/ref/trazas/juega.mjs --only <story> --states DIR` wrote (W after every step of every run of the
//   scene's stories: El frente's five, El balcón's four, La sala's six). --out: where every picture and cases.json go. --fixture: also
//   write the package's fixture (El frente: test/support/fixtures/preview_fixture.dart; El balcón:
//   test/support/fixtures/balcon_preview_fixture.dart): the cases the test keeps and their pictures (PNG, base64; a
//   picture two cases share is kept once), read by the test on the vm and in Chrome.
// Run it in coqui/packages/core/coqui_scenes. It serves the repository over 127.0.0.1 (a free port); nothing goes to the
// network. Needs Node 22 and the pre-installed Playwright (`require('playwright')`).
//
// The cases, by a fixed rule:
//   pair.<word>.<side>: the 24 pictures of cual-frente (PV.pair), and level.<word>.<index>: the level pictures of the
//     sheet (PV.pair of the picture each names).
//   blur.<k> (La sala only): five moments of quien-eres-tu's right run with W.borroso set (the blur keeps its smoothing),
//     all kept.
//   story.<story>.<plan>.<n>: every moment at rest of every run: the state after a step whose view is one of the sheet's
//     views exactly (not mid-slide), with no character half faded (the frog seen at al 1, abuela at al 1), skipping a
//     state equal to the one kept just before it in that run. Drawn at the frame counter it had, floor(t / 70), wind
//     time 0. The fixture keeps the "right" plan's moments whose place in their story is a multiple of 3, and the first
//     moment of each view.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const arg = (k, d) => { const i = process.argv.indexOf(k); return i < 0 ? d : process.argv[i + 1]; };
const STATES = arg('--states', null), OUT = arg('--out', null), FIXTURE = process.argv.includes('--fixture'), SCENE = arg('--scene', 'frente');
const SCENES = {
  frente: { stories: ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro', 'd-toc-toc', 'h-frente'], fixture: 'preview_fixture.dart', cases: 'previewCases', pictures: 'previewPictures' },
  balcon: { stories: ['el-jugo', 'que-calor', 'd-agua-pajaro', 'h-balcon'], fixture: 'balcon_preview_fixture.dart', cases: 'balconPreviewCases', pictures: 'balconPreviewPictures' },
  sala: { stories: ['la-familia', 'la-foto', 'quien-eres-tu', 'd-bizcocho-bebe', 'd-foto-familia', 'h-sala'], fixture: 'sala_preview_fixture.dart', cases: 'salaPreviewCases', pictures: 'salaPreviewPictures' },
  patio: { stories: ['las-flores', 'que-es-esto', 'hasta-manana', 'd-la-bola', 'd-buenas-noches', 'h-patio'], fixture: 'patio_preview_fixture.dart', cases: 'patioPreviewCases', pictures: 'patioPreviewPictures' },
  camino: { stories: ['uno-dos-tres', 'donde-esta-el-gato', 'rapido-despacio', 'd-corre', 'h-camino'], fixture: 'camino_preview_fixture.dart', cases: 'caminoPreviewCases', pictures: 'caminoPreviewPictures' },
  campo: { stories: ['la-bola', 'arriba-abajo', 'otra-vez', 'd-bola-canelo', 'h-campo'], fixture: 'campo_preview_fixture.dart', cases: 'campoPreviewCases', pictures: 'campoPreviewPictures' },
  lago: { stories: ['pan-para-el-pato', 'los-botes', 'cual', 'd-pato-pequeno', 'h-lago'], fixture: 'lago_preview_fixture.dart', cases: 'lagoPreviewCases', pictures: 'lagoPreviewPictures' },
  banco: { stories: ['la-piragua', 'senor-senora', 'el-bebe-duerme', 'd-piragua-luis', 'd-vamos-a-casa', 'h-banco'], fixture: 'banco_preview_fixture.dart', cases: 'bancoPreviewCases', pictures: 'bancoPreviewPictures' },
  mesa: { stories: ['la-mesa', 'la-cuchara', 'tengo-hambre', 'h-mesa'], fixture: 'mesa_preview_fixture.dart', cases: 'mesaPreviewCases', pictures: 'mesaPreviewPictures' },
  estufa: { stories: ['arroz-con-habichuelas', 'el-pollo-y-el-huevo', 'cuidado', 'h-estufa'], fixture: 'estufa_preview_fixture.dart', cases: 'estufaPreviewCases', pictures: 'estufaPreviewPictures' },
  nevera: { stories: ['no-hay-leche', 'para-los-pajaros', 'jugo-de-china', 'h-nevera'], fixture: 'nevera_preview_fixture.dart', cases: 'neveraPreviewCases', pictures: 'neveraPreviewPictures' },
  comer: { stories: ['que-quieres', 'buen-provecho', 'cafe-con-azucar'], fixture: 'comer_preview_fixture.dart', cases: 'comerPreviewCases', pictures: 'comerPreviewPictures' },
};
if (!STATES || !OUT || !SCENES[SCENE]) { console.error('usage: node tool/preview_shots.mjs [--scene frente|balcon|sala|patio|camino|campo|lago|banco|mesa|estufa|nevera|comer] --states DIR --out DIR [--fixture]'); process.exit(2); }
const PKG = process.cwd(), ROOT = path.resolve(PKG, '../../../..');
if (!fs.existsSync(path.join(ROOT, `docs/proyecto/pixel/${SCENE}-preview.html`))) { console.error('run this in coqui/packages/core/coqui_scenes'); process.exit(2); }

const STORIES = SCENES[SCENE].stories, PLANS = ['right', 'wrong', 'alternate'];
const SHEET = JSON.parse(fs.readFileSync(path.join(ROOT, `docs/proyecto/pixel/${SCENE}-sheet.json`), 'utf8'));
const CUAL = JSON.parse(fs.readFileSync(path.join(ROOT, `historia/cuentos/cual-${SCENE}.json`), 'utf8'));
// El patio draws one picture of another file's pair: cual-camino's parque.no (the yard, not the park)
const OTHER = SCENE === 'patio' ? [{ file: 'cual-camino', items: JSON.parse(fs.readFileSync(path.join(ROOT, 'historia/cuentos/cual-camino.json'), 'utf8')).items.filter(i => i.w === 'parque'), sides: ['no'] }] : [];
// a word with its accents folded: La sala's sheet and preview name a pair's pictures so (mamá.si is mama.si); El patio's
// also fold ñ and write a space as _ (hasta mañana.si is hasta_manana.si)
const PATIO_LIKE = SCENE === 'patio' || SCENE === 'camino' || SCENE === 'campo' || SCENE === 'lago' || SCENE === 'banco' || SCENE === 'mesa' || SCENE === 'estufa' || SCENE === 'nevera' || SCENE === 'comer';
const fold = w => PATIO_LIKE ? (SCENE === 'comer' ? w.replace(/[¿?]/g, '') : w).replace(/[áéíóúñ]/g, c => 'aeioun'['áéíóúñ'.indexOf(c)]).replace(/ /g, '_') : w.replace(/[áéíóú]/g, c => 'aeiou'['áéíóú'.indexOf(c)]);
const same = (a, b) => a.length === b.length && a.every((x, i) => x === b[i]);
const viewOf = cam => Object.keys(SHEET.views).find(k => same(SHEET.views[k].old, cam)) || null;
// the acts a story file names (sala-sheet-make.js actsOf): La sala's preview moves a person only at a moved place of an act
// the story uses (PREVIEW.acts, sheet: moves)
const actsOf = st => [...new Set((JSON.stringify(JSON.parse(fs.readFileSync(path.join(ROOT, `historia/cuentos/${st}.json`), 'utf8'))).match(/"act":\s*"[a-z0-9]+"/g) || []).map(a => a.split('"')[3]))];

function cases() {
  const out = [];
  // a level picture names its pair picture as the sheet does (La sala's: folded)
  const items = [...CUAL.items, ...OTHER.flatMap(o => o.items)];
  const fileOf = w => (OTHER.find(o => o.items.some(i => i.w === w || fold(i.w) === w)) || { file: `cual-${SCENE}` }).file;
  const spec = (w, side) => { const it = items.find(i => i.w === w) || items.find(i => fold(i.w) === w); return { set: it[side].set || null, cam: it[side].cam }; };
  // a side the sheet does not draw (El camino's parque.no is El patio's picture) is not this scene's
  const own = (w, side) => SCENE !== 'camino' || SHEET.pictures[fold(w) + '.' + side];
  for (const it of CUAL.items) for (const side of ['si', 'no']) if (own(it.w, side)) out.push(Object.assign({ id: `pair.${it.w}.${side}`, kind: 'pair', word: it.w, side }, spec(it.w, side)));
  for (const o of OTHER) for (const it of o.items) for (const side of o.sides) out.push(Object.assign({ id: `pair.${it.w}.${side}`, kind: 'pair', word: it.w, side, cual: o.file }, spec(it.w, side)));
  for (const L of SHEET.level) { const [w, s] = L.picture.split('.'); out.push(Object.assign({ id: `level.${L.w}.${L.index}`, kind: 'pair', word: w, side: s, cual: fileOf(w) }, spec(w, s))); }
  const seenView = new Set();
  for (const st of STORIES) for (const plan of PLANS) {
    const lines = fs.readFileSync(path.join(STATES, st, plan + '.states.jsonl'), 'utf8').trim().split('\n').map(l => JSON.parse(l));
    let prev = null, n = 0;
    for (const s of lines) {
      const view = viewOf(s.cam);
      if (!view) continue;
      const W = s.W, q = W.cq;
      if (q.vis && q.al !== 1) continue;
      if (W.ab && W.ab.al != null && W.ab.al !== 1) continue;
      const key = JSON.stringify([s.cam, W]);
      if (key === prev) continue;
      prev = key;
      const c = { id: `story.${st}.${plan}.${String(n).padStart(3, '0')}`, kind: 'story', story: st, plan, n, step: s.path, view, F: Math.floor(s.t / 70), W };
      if (SCENE === 'sala' || PATIO_LIKE) c.acts = actsOf(st);
      c.keep = plan === 'right' && (n % 3 === 0 || !seenView.has(view));
      if (plan === 'right') seenView.add(view);
      out.push(c);
      n++;
    }
  }
  // La sala's blur (W.borroso: sala.js:120 and :121 keep their smoothing, the sheet's smoothing.places): no moment at rest
  // has it (it is on for 1.1 s inside acts.tropieza), so five moments of quien-eres-tu's right run are drawn with it set
  if (SCENE === 'sala') {
    const lines = fs.readFileSync(path.join(STATES, 'quien-eres-tu', 'right.states.jsonl'), 'utf8').trim().split('\n').map(l => JSON.parse(l));
    [5, 12, 20, 30, 40].forEach((i, k) => { const s = lines[Math.min(i, lines.length - 1)];
      out.push({ id: `blur.${k}`, kind: 'story', story: 'quien-eres-tu', plan: 'right', n: i, step: s.path, view: 'wide', F: Math.floor(s.t / 70), W: Object.assign({}, s.W, { borroso: 1 }), acts: actsOf('quien-eres-tu'), keep: true }); });
  }
  return out;
}

function server() {
  const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.png': 'image/png' };
  const s = http.createServer((req, res) => {
    const u = decodeURIComponent(new URL(req.url, 'http://x').pathname), f = path.join(ROOT, u);
    if (!f.startsWith(ROOT + path.sep) || !fs.existsSync(f) || !fs.statSync(f).isFile()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-store' });
    fs.createReadStream(f).pipe(res);
  });
  return new Promise(r => s.listen(0, '127.0.0.1', () => r(s)));
}

(async () => {
  const all = cases();
  const srv = await server(), base = `http://127.0.0.1:${srv.address().port}`;
  const browser = await chromium.launch();
  const page = await (await browser.newContext({ viewport: { width: 800, height: 900 }, deviceScaleFactor: 1 })).newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  await page.goto(base + `/docs/proyecto/pixel/${SCENE}-preview.html`);
  await page.evaluate(() => window.PREVIEW.done);
  fs.mkdirSync(OUT, { recursive: true });
  const pngs = {};
  for (const c of all) {
    const url = c.kind === 'pair'
      ? await page.evaluate(([w, s, f]) => window.PREVIEW.pair(w, s, f || undefined), [SCENE === 'sala' || PATIO_LIKE ? fold(c.word) : c.word, c.side, c.cual || null])
      : PATIO_LIKE
      ? await page.evaluate(async ([w, F, st]) => { window.PREVIEW.story = await (await fetch('../../../historia/cuentos/' + st + '.json')).json(); return window.PREVIEW.render(window.PREVIEW.baseW(w), { F, t: 0 }); }, [c.W, c.F, c.story])
      : await page.evaluate(([w, v, F, acts]) => { if (acts) window.PREVIEW.acts = acts; return window.PREVIEW.render(window.PREVIEW.baseW(w), { view: v, F, t: 0 }); }, [c.W, c.view, c.F, c.acts || null]);
    const png = Buffer.from(url.split(',')[1], 'base64');
    c.file = c.id + '.png';
    fs.writeFileSync(path.join(OUT, c.file), png);
    if (c.kind === 'pair' || c.keep) { c.png = png.toString('base64'); }
  }
  await browser.close();
  srv.close();
  if (errs.length) { console.error(errs.join('\n')); process.exit(1); }
  const strip = c => { const o = Object.assign({}, c); delete o.keep; delete o.png; return o; };
  fs.writeFileSync(path.join(OUT, 'cases.json'), JSON.stringify(all.map(strip), null, 1) + '\n');
  if (FIXTURE) {
    const kept = all.filter(c => c.kind === 'pair' || c.keep), pics = [], at = {};
    for (const c of kept) { if (!(c.png in at)) { at[c.png] = pics.length; pics.push(c.png); } c.picture = at[c.png]; }
    const piece = s => { const o = []; for (let i = 0; i < s.length; i += 4000) o.push("    '" + s.slice(i, i + 4000) + "',"); return o.join('\n'); };
    const dart = [
      `// Made by tool/preview_shots.mjs ${SCENE === 'frente' ? '' : `--scene ${SCENE} `}--fixture from docs/proyecto/pixel/${SCENE}-preview.html in headless Chrome. Do not edit.`,
      '// ignore_for_file: lines_longer_than_80_chars',
      '',
      `/// The cases the comparison keeps (JSON: id, kind, and what to draw), each with \`picture\`: its index in [${SCENES[SCENE].pictures}].`,
      `const String ${SCENES[SCENE].cases} = r'''` + JSON.stringify(kept.map(c => Object.assign(strip(c), { picture: c.picture }))) + "''';",
      '',
      '/// What the preview drew for them: PNG files, base64 in pieces.',
      `const List<List<String>> ${SCENES[SCENE].pictures} = [`,
      ...pics.map(p => '  [\n' + piece(p) + '\n  ],'),
      '];',
      '',
    ].join('\n');
    fs.writeFileSync(path.join(PKG, 'test/support/fixtures/' + SCENES[SCENE].fixture), dart);
  }
  console.log(`${all.length} pictures in ${OUT}` + (FIXTURE ? `; ${all.filter(c => c.kind === 'pair' || c.keep).length} kept in test/support/fixtures/${SCENES[SCENE].fixture}` : ''));
})().catch(e => { console.error(e); process.exit(1); });
