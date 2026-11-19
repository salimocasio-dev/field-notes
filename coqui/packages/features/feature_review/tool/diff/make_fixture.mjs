// Makes the expected values of the differential tests, from the OLD code.
//
//   cd coqui/packages/features/feature_review && node tool/diff/make_fixture.mjs
//
// Writes test/fixtures/:
//   course.json            the course data the sessions run on, copied from historia/ (the review pairs of every
//                          cual-*.json in CURSO.cual's order, their clip lines, the level-check items NV, the places,
//                          the fixed lines, and each story's focus_words)
//   review_sessions.json   each scenario with what cual.js did: the words asked, the sides, every PAL call, every
//                          clip played, the picture states over time, the end screen
//   level_sessions.json    the same for nivel.js
//
// The files are the same byte for byte on every run (a seeded generator, virtual time, nothing from the clock).
// Where the old code cannot be run outside the page, the Dart test says so ("by reading"): see the tests.

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';
import { HISTORIA, mulberry32, newOldPage, wordRec } from './old_harness.mjs';
import { runReview, runLevel } from './runs.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const out = path.resolve(here, '..', '..', 'test', 'fixtures');
fs.mkdirSync(out, { recursive: true });
const read = (p) => fs.readFileSync(path.join(HISTORIA, p), 'utf8');

// ---------------------------------------------------------------- the course
const cursoCtx = vm.createContext({});
vm.runInContext(read('curso.js') + ';this.CURSO=CURSO', cursoCtx);
const CURSO = JSON.parse(JSON.stringify(cursoCtx.CURSO));
// NV is read from the old page itself (nivel.js, loaded in the harness)
const probe = await newOldPage({ seed: 1, now: 0, store: null, nivel: true });
const NV = JSON.parse(JSON.stringify(probe.get('NV')));
if (JSON.stringify(NV) !== JSON.stringify(JSON.parse(read('datos/nivel.json')))) throw new Error('datos/nivel.json is not NV');

const files = [];
const clips = {};
const pairs = [];
for (const f of CURSO.cual) {
  const j = JSON.parse(read(`cuentos/${f}.json`));
  files.push({ file: f, scene: j.scene });
  Object.assign(clips, j.clips);
  for (const it of j.items) pairs.push({ scene: j.scene, item: it });
}
const stories = {};
for (const l of CURSO.lugares)
  for (const id of l.cuentos || []) {
    try {
      stories[id] = { focus_words: JSON.parse(read(`cuentos/${id}.json`)).focus_words || [] };
    } catch (e) {
      // a story with no file: the old page skips it (nivel.js: try/catch around the fetch)
    }
  }
const course = {
  from: 'historia/curso.js, historia/cuentos/cual-*.json, historia/nivel.js (NV), historia/datos/fijos.json, historia/cuentos/<story>.json (focus_words)',
  places: CURSO.lugares,
  pairs,
  clips,
  levelItems: NV,
  fixed: JSON.parse(read('datos/fijos.json')).clips,
  stories,
};
fs.writeFileSync(path.join(out, 'course.json'), JSON.stringify(course) + '\n');

// ---------------------------------------------------------------- stores
const NOW = 1795104000000; // 19 Nov 2026 16:00 UTC, the old pictures' own fixed clock
const DAY = 864e5;
const allWords = [];
for (const p of pairs) if (!allWords.includes(p.item.w)) allWords.push(p.item.w);

const baseStore = () => ({ palabras: {}, dias: {}, cuentos: {}, ajustes: { min: 30, todo: 0, bienvenida: 0, habla: 1 }, minutos: 0, v: 1 });
/** n words due, the first the most overdue, written in a shuffled order so the order has to come from the due times. */
function dueStore(n, { from = 0, spread = 1 } = {}) {
  const ws = allWords.slice(from, from + n);
  const recs = ws.map((w, i) => wordRec(w, { due: NOW - (n - i) * spread * 3600e3 }));
  const shuffled = [...recs.filter((_, i) => i % 2 === 0), ...recs.filter((_, i) => i % 2 === 1)];
  const s = baseStore();
  for (const r of shuffled) s.palabras[r.w] = r;
  return s;
}
/** n words heard, none due (practice). */
function heardStore(n, { extraDue = 0 } = {}) {
  const s = baseStore();
  for (const w of allWords.slice(0, n)) s.palabras[w] = wordRec(w, { due: NOW + 3 * DAY });
  return s;
}
/** words with a record but nothing in the course (a word with no pair is never asked) plus pair words. */
function mixedStore() {
  const s = dueStore(6);
  s.palabras['palabra-sin-par'] = wordRec('palabra-sin-par', { due: NOW - 5 * 3600e3 });
  s.palabras['otra-sin-par'] = wordRec('otra-sin-par', { due: NOW + 2 * DAY });
  s.palabras[allWords[40]] = wordRec(allWords[40], { due: NOW + DAY });
  return s;
}
/** a word parked for a week and a word due: the parked one is not due. */
function parkedStore() {
  const s = dueStore(4);
  const w = allWords[50];
  s.palabras[w] = wordRec(w, { due: NOW - 3 * 3600e3, aparcada: NOW + 7 * DAY });
  const v = allWords[51];
  s.palabras[v] = wordRec(v, { etapa: 0, due: NOW - 3 * 3600e3 });
  return s;
}

// ---------------------------------------------------------------- review scenarios
const R = (name, seed, store, script = [], more = {}) => ({ name, seed, now: NOW, store, script, ...more });
const scr = (s) => [...s].map((c) => ({ r: { pick: 'r' }, w: { pick: 'w' }, n: { pick: 'none' } })[c] || {});
const reviewScenarios = [];
reviewScenarios.push(R('3 due, all right', 1, dueStore(3), scr('rrr')));
reviewScenarios.push(R('3 due, all right (another seed)', 2, dueStore(3), scr('rrr')));
reviewScenarios.push(R('10 due, all right', 1, dueStore(10), []));
reviewScenarios.push(R('14 due: the 10 most overdue are asked', 7, dueStore(14), scr('rrrrrrrrrr')));
reviewScenarios.push(R('14 due, a miss in the middle (comes back three items later)', 3, dueStore(14), scr('rrwrrrrrrrr')));
reviewScenarios.push(R('7 due: a miss first, and a miss sixth of seven (the end)', 5, dueStore(7), scr('wrrrrrwrw')));
reviewScenarios.push(R('every answer wrong, the second asks too', 11, dueStore(10), scr('w'.repeat(20))));
reviewScenarios.push(R('every answer wrong (another seed)', 12, dueStore(10), scr('w'.repeat(20))));
reviewScenarios.push(
  R('no touch: replays at 6 s, shows the right one at 12 s (a miss), then the second ask', 4, dueStore(3), [
    { pick: 'none', d2: 1500 },
    {},
    {},
    { pick: 'none', d2: 900 },
  ]),
);
reviewScenarios.push(
  R('touch at 3 s (no replay), touch at 7 s (while it plays again), touch at 13 s (after both)', 6, dueStore(3), [
    { pick: 'w', d: 3011 },
    { pick: 'r', d: 7013 },
    { pick: 'w', d: 13017 },
    { pick: 'r', d: 5993 },
  ]),
);
reviewScenarios.push(
  R('touches before the sentence ends are ignored; the other picture touched while the right one shows', 8, dueStore(4), [
    { early: true },
    { early: true, pick: 'w', other: true },
    { pick: 'w', other: true, d2: 2111 },
    { early: true },
    { early: true },
  ]),
);
reviewScenarios.push(R('a slow right answer (over 2 s) and a fast one', 9, dueStore(3), [{ d: 2503 }, { d: 301 }, { d: 1999 }]));
reviewScenarios.push(R('words with no pair, parked and unheard are not asked', 10, mixedStore(), scr('rrrrrr')));
reviewScenarios.push(R('a parked word and a word at stage 0 are not asked', 13, parkedStore(), scr('rrrr')));
reviewScenarios.push(R('practice: 12 heard, none due (not scored)', 1, heardStore(12), scr('rrwrrrwrrr')));
reviewScenarios.push(R('practice: 12 heard (another seed)', 2, heardStore(12), scr('rwrrwrrrrr')));
reviewScenarios.push(R('practice: 40 heard', 3, heardStore(40), scr('rwwrrrrrrr')));
reviewScenarios.push(R('practice: 70 heard (the shuffle merges runs)', 4, heardStore(70), scr('rrrrrwrrrr')));
reviewScenarios.push(R('practice: 100 heard', 5, heardStore(100), scr('rrrrrrrrrr')));
reviewScenarios.push(R('practice: all 128 heard, every answer wrong', 6, heardStore(128), scr('w'.repeat(20))));
reviewScenarios.push(R('practice: nothing heard at all (every pair, shuffled)', 7, baseStore(), scr('rrrrrrwrrr')));
reviewScenarios.push(R('practice: nothing heard (another seed)', 8, baseStore(), scr('rrrrrrrrrr')));
reviewScenarios.push(R('3 due, no clip ready (the sentence runs by its length in words)', 1, dueStore(3), scr('rwr'), { clips: 'silent' }));
reviewScenarios.push(R('practice, no clip ready', 2, heardStore(12), scr('rrrrr'), { clips: 'silent', query: { n: '5' } }));
reviewScenarios.push(R('switch n=4: asks 4 of 12 due', 4, dueStore(12), scr('rrrr'), { query: { n: '4' } }));
reviewScenarios.push(R('switch solo=casa,puerta', 1, dueStore(12), scr('rr'), { query: { solo: 'casa,puerta' } }));
reviewScenarios.push(R('switch todo=1&n=200: every pair is a word to ask (practice)', 2, baseStore(), scr('r'.repeat(30)), { query: { todo: '1', n: '200' } }));
reviewScenarios.push(R('switch todo=1 with some words heard: still every pair', 3, heardStore(20), scr('rr'), { query: { todo: '1', n: '12' } }));
reviewScenarios.push(R('one word due: a miss comes back at the end of a one-word session', 14, dueStore(1), scr('wr')));
reviewScenarios.push(R('a re-ask answered wrong: no third ask', 15, dueStore(2), scr('wwrw')));
// random learners: a seeded script of right, wrong and no-touch with random times
function randomScript(seed, n) {
  const r = mulberry32(seed);
  const out = [];
  for (let i = 0; i < n; i++) {
    const x = r();
    const e = { d: 200 + Math.floor(r() * 7000) * 2 + 1, d2: 301 + Math.floor(r() * 1500) * 2 };
    if (x < 0.55) e.pick = 'r';
    else if (x < 0.85) e.pick = 'w';
    else e.pick = 'none';
    if (r() < 0.2) e.early = true;
    if (r() < 0.2) e.other = true;
    out.push(e);
  }
  return out;
}
for (const seed of [101, 102, 103, 104, 105, 106]) reviewScenarios.push(R(`random learner ${seed}, 10 due`, seed, dueStore(10), randomScript(seed, 22)));
for (const seed of [201, 202, 203]) reviewScenarios.push(R(`random learner ${seed}, practice from 30 heard`, seed, heardStore(30), randomScript(seed, 22)));
for (const seed of [301, 302]) reviewScenarios.push(R(`random learner ${seed}, 5 due, no clip ready`, seed, dueStore(5), randomScript(seed, 12), { clips: 'silent' }));

const reviews = [];
for (const sc of reviewScenarios) {
  const res = await runReview(sc);
  reviews.push({ scenario: sc, expected: res });
  process.stderr.write(`review: ${sc.name}: ${res.result.cola.length} asks, ${res.calls.filter((c) => c.op === 'responde').length} answers, ${res.draws} draws\n`);
}
fs.writeFileSync(path.join(out, 'review_sessions.json'), JSON.stringify({ node: process.version, sessions: reviews }) + '\n');

// ---------------------------------------------------------------- level check scenarios
const L = (name, seed, script, more = {}) => ({ name, seed, now: NOW, store: baseStore(), script, ...more });
const levelScenarios = [];
levelScenarios.push(L('all right: 16 items', 1, { plan: '' }));
levelScenarios.push(L('all right (another seed)', 2, { plan: '' }));
levelScenarios.push(L('all wrong: it stops after three misses in a row', 3, { plan: 'w'.repeat(20) }));
levelScenarios.push(L('all wrong (another seed)', 4, { plan: 'w'.repeat(20) }));
levelScenarios.push(L('right, wrong, right, wrong ...: it has gone up and down enough', 5, { plan: 'rw'.repeat(10) }));
levelScenarios.push(L('wrong, right, wrong, right ...', 6, { plan: 'wr'.repeat(10) }));
for (const k of [1, 2, 4, 6, 11, 20, 32]) levelScenarios.push(L(`right on the items of stories up to ${k}, wrong after`, 10 + k, { storyUpTo: k }));
levelScenarios.push(L('every item, all right (todo=1)', 7, { plan: '' }, { query: { todo: '1' } }));
levelScenarios.push(L('every item, right up to story 11 (todo=1)', 8, { storyUpTo: 11 }, { query: { todo: '1' } }));
levelScenarios.push(L('touches before the sentence ends are ignored', 9, { plan: 'rrwrrrwr', early: true }));
levelScenarios.push(L('a touch after 10 s: the sentence has played again (9 s)', 12, { plan: 'rrrwrrr', d: [10011, 1013, 19007] }));
levelScenarios.push(L('all right, no clip ready', 13, { plan: '' }, { clips: 'silent' }));
levelScenarios.push(L('wrong at first, then right (nothing skipped)', 14, { plan: 'wwrrrrrrrrrrrrrr' }));
levelScenarios.push(L('right at the very top: the last two items right ends it', 15, { storyUpTo: 99 }));
function randomPlan(seed, n) {
  const r = mulberry32(seed);
  let s = '';
  for (let i = 0; i < n; i++) s += r() < 0.65 ? 'r' : 'w';
  return s;
}
for (const seed of [401, 402, 403, 404, 405, 406, 407, 408]) levelScenarios.push(L(`random learner ${seed}`, seed, { plan: randomPlan(seed, 20), d: [701, 1303, 2807] }));

const levels = [];
for (const sc of levelScenarios) {
  const res = await runLevel(sc);
  levels.push({ scenario: sc, expected: res });
  const fin = res.result.fin;
  process.stderr.write(`level: ${sc.name}: ${res.result.hecho.length} items, S0=${fin ? fin.S0 : '-'}, ${res.draws} draws\n`);
}
fs.writeFileSync(path.join(out, 'level_sessions.json'), JSON.stringify({ node: process.version, sessions: levels }) + '\n');
