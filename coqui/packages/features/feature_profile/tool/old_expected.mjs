// What the old page (historia/app.html, v=39) does in `yo`, `bienvenida`, `listo` and `notaHabla`, run in node
// against the real historia/palabras.js and historia/curso.js, written as data for the widget tests
// (test/support/old_expected.dart). There is no old check script for this tab: this is it.
//
//   node tool/old_expected.mjs          (in this package) writes test/support/old_expected.dart
//   node tool/old_expected.mjs --check  says whether that file is the one the old page gives
//
// How (the pattern of coqui_progress/tool/app_sequences.mjs): each piece of app.html is cut out of the file by a
// pattern (the tool stops if a pattern no longer matches) and run with vm.runInContext in the same context as
// palabras.js and curso.js, with the page's globals stubbed (document, location, tick, sheet, cierra, hud,
// habDisp). Nothing in app.html is changed. `yo()` and `bienvenida(k)` write HTML; the facts the tests compare
// are read out of that HTML (the text in order, the pill and the switches that are on, the dot that is lit, the
// buttons), and the `onclick` of each control is run as the old page runs it, to see what it writes.
process.env.TZ = 'America/Puerto_Rico'; // the zone of the reference pictures (the streak counts local days)
import vm from 'node:vm';
import fs from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '../../../../..');
const APP = fs.readFileSync(resolve(repo, 'historia/app.html'), 'utf8');
const PALABRAS = fs.readFileSync(resolve(repo, 'historia/palabras.js'), 'utf8');
const CURSO = fs.readFileSync(resolve(repo, 'historia/curso.js'), 'utf8');
const SEEDS = resolve(repo, 'coqui/ref/pantallas/seeds');
const target = resolve(here, '../test/support/old_expected.dart');

// ---- cutting the pieces out of app.html -------------------------------------------------------------------
function cut(name, re) {
  const m = APP.match(re);
  if (!m) throw new Error(`app.html: no longer has the piece "${name}" (${re})`);
  return m[0];
}
const P = [
  cut('db, AJ, hecho, veces', /const db=\(\)=>PAL\.db,AJ=\(\)=>db\(\)\.ajustes,hecho=id=>[^;\n]*;/),
  cut('aqui', /const aqui=\(\)=>[^\n]*;/),
  cut('NIVELTXT', /const NIVELTXT="[^"]*";/),
  cut('NOTAPAG', /let NOTAPAG="";/),
  cut('notaHabla', /function notaHabla\(\)\{[\s\S]*?right now\.<\/div>`;\}/),
  cut('yo', /function yo\(\)\{[\s\S]*?How it works<\/button>`;\}/),
  cut('bienvenida', /function bienvenida\(k\)\{[\s\S]*?foot:p\[k\]\[1\]\}\);\}/),
  cut('listo', /function listo\(\)\{[^\n]*?\}/),
];

// ---- a page: palabras.js, curso.js and the pieces in one context ------------------------------------------
class Page {
  // `mem`: the browser's storage, shared by the pages of one run (a reload keeps it); `now`: the scripted time.
  constructor(mem, now, { mic = true } = {}) {
    this.mem = mem;
    this.log = { html: {}, sheet: null, ticks: 0, href: null, calls: [] };
    const log = this.log;
    const el = (id) => ({
      set innerHTML(v) { log.html[id] = v; },
      get innerHTML() { return log.html[id] || ''; },
    });
    const location = {};
    Object.defineProperty(location, 'href', { set(v) { log.href = v; }, get() { return log.href; } });
    const ctx = (this.ctx = vm.createContext({
      window: { __PAL_NOW: now },
      localStorage: { getItem: (k) => (k in mem ? mem[k] : null), setItem: (k, v) => { mem[k] = String(v); } },
      document: { getElementById: el },
      location,
      tick() { log.ticks++; },
      hud() { log.calls.push('hud'); },
      cierra() { log.calls.push('cierra'); },
      habDisp: () => mic,
      sheet(html, o) { log.sheet = { html, modal: !!o.modal, foot: o.foot }; log.calls.push('sheet'); },
    }));
    // new Date() with no argument, and Date.now(), are the scripted time
    vm.runInContext(
      'globalThis.__RealDate=Date;Date=class extends __RealDate{constructor(...a){a.length?super(...a):super(window.__PAL_NOW)}static now(){return window.__PAL_NOW}};',
      ctx,
    );
    vm.runInContext(PALABRAS, ctx);
    vm.runInContext(CURSO, ctx);
    for (const p of P) vm.runInContext(p, ctx);
  }
  run(code) { return vm.runInContext(code, this.ctx); }
  get ajustes() { return JSON.parse(JSON.stringify(this.run('AJ()'))); }
  get db() { return JSON.parse(JSON.stringify(this.run('db()'))); }
  yo() { this.run('yo()'); return this.log.html['t-yo']; }
  welcome(k) { this.run(`bienvenida(${k})`); return { ...this.log.sheet }; }
}

// ---- facts out of the HTML ---------------------------------------------------------------------------------
const decode = (t) => t.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&#39;/g, "'");
// the text nodes in order; `.lab` is upper case by its CSS (text-transform)
const texts = (html) =>
  html
    .replace(/<div class="lab">([^<]*)<\/div>/g, (m, t) => `<div class="lab">${t.toUpperCase()}</div>`)
    .split(/<[^>]*>/)
    .map((t) => decode(t).trim())
    .filter(Boolean);
const buttons = (html) =>
  [...html.matchAll(/<button([^>]*)>([\s\S]*?)<\/button>/g)].map((m) => ({
    cls: (m[1].match(/class="([^"]*)"/) || [, ''])[1],
    onclick: (m[1].match(/onclick="([^"]*)"/) || [, ''])[1],
    text: texts(m[2]).join(' '),
  }));
const factsYo = (html) => {
  const bs = buttons(html);
  const pills = bs.filter((b) => /^\d+$/.test(b.text) && !b.cls.includes('btn'));
  return {
    texts: texts(html),
    pills: pills.map((b) => ({ text: b.text, on: b.cls.split(' ').includes('on') })),
    switches: bs.filter((b) => b.cls.split(' ').includes('sw')).map((b) => b.cls.split(' ').includes('on')),
    note: html.includes("Speaking in stories isn't available"),
  };
};
const factsSheet = (s) => {
  const bs = buttons(s.html + s.foot);
  const dots = [...s.foot.matchAll(/<i style="[^"]*background:([^";]*)"/g)].map((m) => m[1] === 'var(--info)');
  return {
    modal: s.modal,
    texts: texts(s.html),
    footer: bs.filter((b) => !/^\d+ min$/.test(b.text)).map((b) => b.text),
    pills: bs.filter((b) => /^\d+ min$/.test(b.text)).map((b) => ({ text: b.text, on: b.cls.split(' ').includes('on') })),
    dot: dots.indexOf(true),
  };
};

// ---- the scenarios -----------------------------------------------------------------------------------------
const NOW = 1795104000000; // 19 Nov 2026, 12:00 in Puerto Rico: the moment of the reference pictures
const seedNames = ['vacio', 'segunda', 'uno', 'curso', 'casi', 'todo', 'nivel', 'nivel1'];
const seedText = (n) => JSON.stringify(JSON.parse(fs.readFileSync(`${SEEDS}/${n}.json`, 'utf8')));
const withDb = (seed, patch) => {
  const j = JSON.parse(seedText(seed));
  for (const [k, v] of Object.entries(patch)) {
    if (k === 'ajustes') j.ajustes = { ...j.ajustes, ...v };
    else j[k] = v;
  }
  return JSON.stringify(j);
};

const out = { about: 'Made by tool/old_expected.mjs from historia/app.html, palabras.js and curso.js. Do not edit.', now: NOW };

// yo(): the whole page, for each seed, with and without the recogniser
out.yo = {};
for (const n of seedNames) {
  out.yo[n] = {
    mic: factsYo(new Page({ 'coqui.palabras.v1': seedText(n) }, NOW, { mic: true }).yo()),
    nomic: factsYo(new Page({ 'coqui.palabras.v1': seedText(n) }, NOW, { mic: false }).yo()),
  };
}

// yo(): what each number does with other values (the settings, minutes, the level check)
out.yoVariants = [];
const variant = (label, seed, patch) => {
  const stored = withDb(seed, patch);
  out.yoVariants.push({ label, seed, patch, stored, facts: factsYo(new Page({ 'coqui.palabras.v1': stored }, NOW).yo()) });
};
for (const m of [0, 0.4, 0.5, 1, 1.49, 1.5, 2, 2.5, 59.5, 108.9]) variant(`minutos ${m}`, 'vacio', { minutos: m });
for (const m of [15, 30, 60, 120, 45, 0]) variant(`min ${m}`, 'vacio', { ajustes: { min: m } });
for (const t of [0, 1, 2, true, false, null]) variant(`todo ${JSON.stringify(t)}`, 'vacio', { ajustes: { todo: t } });
for (const h of [0, 1, null, 2, false]) variant(`habla ${JSON.stringify(h)}`, 'vacio', { ajustes: { habla: h } });
variant('habla absent', 'vacio', {});
for (const k of [0, 1, 2, 11]) variant(`nivel historias ${k}`, 'vacio', { nivel: { t: NOW, historias: k, log: [] } });
variant('nivel without historias', 'vacio', { nivel: { t: NOW, log: [] } });

// the controls of yo(): each onclick run as the old page runs it
out.yoHandlers = [];
const handlerCases = [
  ['curso', {}],
  ['vacio', { ajustes: { todo: 1 } }],
  ['vacio', { ajustes: { habla: 0 } }],
  ['vacio', { ajustes: { habla: null } }],
  ['vacio', { ajustes: { min: 45 } }],
];
for (const [seed, patch] of handlerCases) {
  const stored = withDb(seed, patch);
  const probe = new Page({ 'coqui.palabras.v1': stored }, NOW);
  const html = probe.yo();
  buttons(html).forEach((b, i) => {
    if (!b.onclick) return;
    const page = new Page({ 'coqui.palabras.v1': stored }, NOW);
    page.yo();
    const before = page.ajustes;
    page.log.ticks = 0;
    page.log.calls = [];
    page.run(b.onclick);
    out.yoHandlers.push({
      seed, patch, stored, button: b.text || b.cls, cls: b.cls, onclick: b.onclick, index: i,
      before, after: page.ajustes, ticks: page.log.ticks, href: page.log.href,
      welcome: page.log.calls.includes('sheet') ? factsSheet(page.log.sheet) : null,
      redraw: page.log.html['t-yo'] !== html || b.onclick.endsWith('yo()'),
    });
  });
}

// bienvenida(k): each step, first start and "How it works", with other minutes
out.welcome = [];
for (const [seen, min] of [[0, 30], [1, 30], [0, 60], [1, 120], [1, 45]]) {
  for (const k of [0, 1, 2]) {
    const stored = withDb('vacio', { ajustes: { bienvenida: seen, min } });
    const page = new Page({ 'coqui.palabras.v1': stored }, NOW);
    out.welcome.push({ seen, min, k, stored, ...factsSheet(page.welcome(k)) });
  }
}

// the controls of the welcome: each onclick run as the old page runs it
out.welcomeHandlers = [];
for (const seen of [0, 1]) {
  for (const k of [0, 1, 2]) {
    const stored = withDb('vacio', { ajustes: { bienvenida: seen } });
    const probe = new Page({ 'coqui.palabras.v1': stored }, NOW);
    const s = probe.welcome(k);
    for (const b of buttons(s.html + s.foot)) {
      if (!b.onclick) continue;
      const page = new Page({ 'coqui.palabras.v1': stored }, NOW);
      page.welcome(k);
      const before = page.ajustes;
      page.log.ticks = 0;
      page.log.calls = [];
      page.log.href = null;
      page.log.sheet = null;
      page.run(b.onclick);
      out.welcomeHandlers.push({
        seen, k, button: b.text, onclick: b.onclick, before, after: page.ajustes, ticks: page.log.ticks,
        href: page.log.href, calls: page.log.calls, welcome: page.log.sheet ? factsSheet(page.log.sheet) : null,
      });
    }
  }
}
// listo() itself (the page also calls it from App.listo)
{
  const page = new Page({ 'coqui.palabras.v1': withDb('vacio', { ajustes: { bienvenida: 0 } }) }, NOW);
  page.run('listo()');
  out.listo = { after: page.ajustes, calls: page.log.calls };
}

// notaHabla(): once a day, and again on the same page. Each run is one browser's storage; a step is a draw of yo() on
// a page that is already open, or on a new one (a reload), at a day, with the recogniser there or not.
out.note = [];
{
  const DAY = 864e5;
  const run = (name, steps) => {
    const mem = { 'coqui.palabras.v1': seedText('vacio') };
    let page = null;
    const done = [];
    for (const st of steps) {
      if (st.reload || !page) page = new Page(mem, NOW + st.day * DAY, { mic: st.mic });
      page.ctx.window.__PAL_NOW = NOW + st.day * DAY;
      const note = factsYo(page.yo()).note;
      done.push({ ...st, note, notaHabla: page.ajustes.notaHabla ?? null });
    }
    out.note.push({ name, steps: done });
  };
  run('one page: the first draw writes the day, a second draw shows it again, the next day writes the next', [
    { day: 0, mic: false, reload: true },
    { day: 0, mic: false },
    { day: 1, mic: false },
    { day: 1, mic: false },
  ]);
  run('a reload the same day does not show it again; the next day it comes back', [
    { day: 0, mic: false, reload: true },
    { day: 0, mic: false, reload: true },
    { day: 0, mic: false },
    { day: 1, mic: false, reload: true },
    { day: 1, mic: false },
    { day: 2, mic: true, reload: true },
  ]);
  run('with the recogniser there it never shows and never writes', [
    { day: 0, mic: true, reload: true },
    { day: 1, mic: true, reload: true },
  ]);
}

const text = [
  '// Made by tool/old_expected.mjs from historia/app.html (yo, bienvenida, listo, notaHabla), run in node. Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  '/// What the old page does, as JSON (see tool/old_expected.mjs for its shape).',
  'const String oldExpectedJson =',
  '    ' + JSON.stringify(JSON.stringify(out)).replace(/\$/g, '\\$').replace(/'/g, "\\'").replace(/^"|"$/g, "'").replace(/\\"/g, '"') + ';',
  '',
].join('\n');
// the Dart literal must read back as the same data (a Dart and a JavaScript single-quoted string agree on these escapes)
{
  const lit = text.match(/oldExpectedJson =\n {4}('[\s\S]*');\n/)[1];
  if (JSON.stringify(JSON.parse(eval(lit))) !== JSON.stringify(out)) throw new Error('the Dart literal does not read back as the data');
}
if (process.argv.includes('--check')) {
  const same = fs.existsSync(target) && fs.readFileSync(target, 'utf8') === text;
  console.log(same ? 'test/support/old_expected.dart is what the old page gives.' : 'test/support/old_expected.dart is NOT what the old page gives: run `node tool/old_expected.mjs`.');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(target, text);
console.log(`wrote test/support/old_expected.dart: ${Object.keys(out.yo).length} seeds, ${out.yoVariants.length} variants, ${out.yoHandlers.length} yo controls, ${out.welcome.length} welcome sheets, ${out.welcomeHandlers.length} welcome controls, ${out.note.length} note runs`);
