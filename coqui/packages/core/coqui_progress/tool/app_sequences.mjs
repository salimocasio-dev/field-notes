// Runs the pieces of historia/app.html that read or write the word store, against the real
// historia/palabras.js, and prints what the store is after every call. make_fixture.mjs uses it;
// it is not run by hand (it needs TZ set in its environment: make_fixture.mjs starts it once per zone).
//
//   TZ=UTC node tool/app_sequences.mjs            prints JSON: {zone, pieces, sequences}
//
// How: each piece of app.html is cut out of the file by a pattern (the tool stops if a pattern no
// longer matches), run with vm.runInContext in the same context as palabras.js, with the page's
// globals stubbed (document, location, tick, yo ...). Nothing in app.html or palabras.js is changed.
//   - marcaLeido(), extra(), listo(), notaHabla() and the `onclick` handlers that write `ajustes`
//     are run as they are written.
//   - what the page only reads (`hecho`, `veces`, `rd=db().leidos||{}` and `!!rd[c]`,
//     `ex=db().extra||[]`, `db().nivel`, `d.minutos||0`, `AJ()`) is run as the expression the page uses.
// The clock is window.__PAL_NOW, set before every call, and Date (no arguments) and Date.now() give the
// same time, so the page's own `new Date()` in notaHabla() is the scripted time too.
import vm from 'node:vm';
import fs from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '../../../../..');
const APP = fs.readFileSync(resolve(repo, 'historia/app.html'), 'utf8');
const PALABRAS = fs.readFileSync(resolve(repo, 'historia/palabras.js'), 'utf8');
const zone = process.env.TZ === 'America/New_York' ? 'America_New_York' : process.env.TZ === 'UTC' ? 'UTC' : null;
if (!zone) throw new Error('set TZ=UTC or TZ=America/New_York');

// ---- cutting the pieces out of app.html -----------------------------------------------------------
const pieces = {};
function cut(name, re) {
  const m = APP.match(re);
  if (!m) throw new Error(`app.html: no longer has the piece "${name}" (${re})`);
  pieces[name] = m[0];
  return m[0];
}
const P = {
  pnow: cut('pnow', /const pnow=\(\)=>window\.__PAL_NOW\|\|Date\.now\(\);/),
  db: cut('db, AJ, hecho, veces', /const db=\(\)=>PAL\.db,AJ=\(\)=>db\(\)\.ajustes,hecho=id=>[^;\n]*;/),
  marcaLeido: cut('marcaLeido', /function marcaLeido\(\)\{[^\n]*?PAL\.save\(\);\}\}/),
  rd: cut('rd (biblioteca)', /rd=db\(\)\.leidos\|\|\{\}/),
  leido: cut('leido (biblioteca)', /leido=!!rd\[c\]/),
  ex: cut('ex (palabras)', /ex=db\(\)\.extra\|\|\[\]/),
  extra: cut('extra', /function extra\(\)\{[^\n]*?palabras\(\);\}/),
  nivel: cut('nivel (yo)', /db\(\)\.nivel\?"Done: "\+db\(\)\.nivel\.historias/),
  minutos: cut('minutos (yo)', /Math\.round\(d\.minutos\|\|0\)/),
  notapag: cut('NOTAPAG', /let NOTAPAG="";/),
  notaHabla: cut('notaHabla', /function notaHabla\(\)\{[\s\S]*?right now\.<\/div>`;\}/),
  listo: cut('listo', /function listo\(\)\{[^\n]*?\}/),
  hMin: cut('handler min (yo)', /AJ\(\)\.min=\$\{m\};PAL\.save\(\);tick\(\);yo\(\)/),
  hTodo: cut('handler todo (yo)', /AJ\(\)\.todo=AJ\(\)\.todo\?0:1;PAL\.save\(\);tick\(\);yo\(\)/),
  hHabla: cut('handler habla (yo)', /AJ\(\)\.habla=AJ\(\)\.habla===0\?1:0;PAL\.save\(\);tick\(\);yo\(\)/),
  hBienvenidaNivel: cut('handler bienvenida (welcome)', /AJ\(\)\.bienvenida=1;PAL\.save\(\);location\.href='nivel\.html'/),
  hMinBienvenida: cut('handler min (welcome)', /AJ\(\)\.min=\$\{m\};PAL\.save\(\);bienvenida\(1\)/),
};

// ---- a run: palabras.js and the pieces in one context ----------------------------------------------
const copy = (x) => JSON.parse(JSON.stringify(x));
const localMs = (s) => {
  const [d, t] = s.split(' ');
  const [y, mo, da] = d.split('-').map(Number);
  const [h, mi] = t.split(':').map(Number);
  return new Date(y, mo - 1, da, h, mi).getTime();
};

class Run {
  constructor(id, title, stored = null) {
    this.id = id;
    this.title = title;
    this.stored = stored;
    this.mem = stored === null ? {} : { 'coqui.palabras.v1': stored };
    this.input = { value: '' };
    const mem = this.mem;
    const ctx = (this.ctx = vm.createContext({
      window: { __PAL_NOW: 0 },
      localStorage: { getItem: (k) => (k in mem ? mem[k] : null), setItem: (k, v) => { mem[k] = String(v); } },
      document: { getElementById: () => this.input },
      location: { href: '' },
      palabras() {}, cierra() {}, hud() {}, tick() {}, yo() {}, bienvenida() {}, habDisp: () => false,
    }));
    // new Date() with no argument, and Date.now(), are the scripted time
    vm.runInContext(
      'globalThis.__RealDate=Date;Date=class extends __RealDate{constructor(...a){a.length?super(...a):super(window.__PAL_NOW)}static now(){return window.__PAL_NOW}};',
      ctx,
    );
    vm.runInContext(PALABRAS, ctx);
    for (const p of [P.pnow, P.db, P.marcaLeido, P.extra, P.notapag, P.notaHabla, P.listo]) vm.runInContext(p, ctx);
    this.PAL = vm.runInContext('PAL', ctx);
    this.steps = [];
    this.now = 0;
    this.initial = { store: JSON.stringify(copy(this.PAL.db)), saved: stored };
  }
  at(local) { this.now = localMs(local); return this; }
  // one call. fn runs it and returns what the old code returned (undefined for nothing)
  step(call, member, dart, fn) {
    this.ctx.window.__PAL_NOW = this.now;
    const s = { i: this.steps.length, now: this.now, call, member, dart };
    try {
      const r = fn();
      if (r !== undefined) s.returns = copy(r);
    } catch (e) {
      s.throws = String(e.message);
    }
    s.store = JSON.stringify(copy(this.PAL.db));
    const kv = this.mem['coqui.palabras.v1'];
    s.saved = kv === undefined ? null : kv === s.store ? 'same' : (() => { try { const j = JSON.parse(kv); return typeof j === 'object' && j !== null && !Array.isArray(j) ? j : { text: kv }; } catch { return { text: kv }; } })();
    this.steps.push(s);
    return this;
  }
  run(code) { return vm.runInContext(code, this.ctx); }
  // ---- what app.html does, one call each ----
  pal(call, args, member, dart) { return this.step(call, member, dart, () => this.PAL[call](...args)); }
  marcaLeido(id) { return this.step('marcaLeido', 'markRead', { id }, () => { this.ctx.LEE = { id }; return this.run('marcaLeido()'); }); }
  hasRead(id) { return this.step('leido', 'hasRead', { id }, () => this.run(`(c=>{const ${P.rd};return !!rd[c];})(${JSON.stringify(id)})`)); }
  extra(text) { return this.step('extra', 'add', { wordOrGoal: text }, () => { this.input.value = text; return this.run('extra()'); }); }
  added() { return this.step('ex', 'added', {}, () => this.run(`(()=>{const ${P.ex};return ex;})()`)); }
  played(id) { return this.step('hecho', 'played', { id }, () => this.run(`hecho(${JSON.stringify(id)})`)); }
  setting(key) { return this.step('AJ()', 'setting', { key }, () => this.run(`AJ()[${JSON.stringify(key)}]`)); }
  level() { return this.step('db().nivel', 'levelResult', {}, () => this.run(`${P.nivel.split('?')[0]}||null`)); }
  minutes() { return this.step('d.minutos', 'minutes', {}, () => this.run(`(()=>{const d=db();return ${P.minutos.slice('Math.round('.length, -1)};})()`)); }
  // a handler of the page that writes AJ(); `key` is what it sets, `value` read back afterwards
  handler(call, code, key) {
    let after;
    this.step(call, 'setSetting', null, () => { this.run(code); after = this.run(`AJ()[${JSON.stringify(key)}]`); });
    const s = this.steps.at(-1);
    s.dart = { key, value: after };
    delete s.returns; // what the page function returns is HTML, not the store's
    return this;
  }
  min(m) { return this.handler(`AJ().min=${m}`, P.hMin.replace('${m}', m), 'min'); }
  minWelcome(m) { return this.handler(`AJ().min=${m} (welcome)`, P.hMinBienvenida.replace('${m}', m), 'min'); }
  todo() { return this.handler('AJ().todo=AJ().todo?0:1', P.hTodo, 'todo'); }
  habla() { return this.handler('AJ().habla=AJ().habla===0?1:0', P.hHabla, 'habla'); }
  bienvenidaNivel() { return this.handler("AJ().bienvenida=1 (nivel)", P.hBienvenidaNivel, 'bienvenida'); }
  listo() { return this.handler('listo()', 'listo()', 'bienvenida'); }
  // notaHabla(): writes only the first time a day; member null when it wrote nothing
  notaHabla() {
    const before = this.run('JSON.stringify(PAL.db)');
    this.step('notaHabla()', 'setSetting', null, () => this.run('notaHabla()'));
    const s = this.steps.at(-1);
    delete s.returns; // the note's HTML
    if (JSON.stringify(copy(this.PAL.db)) === before) { s.member = null; s.dart = {}; }
    else s.dart = { key: 'notaHabla', value: this.run('AJ().notaHabla') };
    return this;
  }
  out() {
    return {
      id: this.id, title: this.title, tz: process.env.TZ, source: 'historia/app.html + historia/palabras.js', dartReplayable: true,
      setup: { stored: this.stored, storage: 'memory', clock: 'hook' }, initial: this.initial, steps: this.steps,
    };
  }
}

// ---- the sequences ------------------------------------------------------------------------------------
const runs = [];

// a01: finishing a book: leidos[id] = the palabras clock, saved only the first time
runs.push(
  new Run('a01-leidos', 'marcaLeido(): the time of the first reading is kept; a second reading changes nothing and saves nothing')
    .at('2026-03-02 17:00').hasRead('la-lluvia')
    .marcaLeido('la-lluvia').hasRead('la-lluvia').hasRead('el-jugo')
    .at('2026-03-02 17:05').marcaLeido('la-lluvia')
    .at('2026-03-03 09:30').marcaLeido('el-jugo').hasRead('el-jugo')
    .pal('minutos', [1.5], 'addMinutes', { m: 1.5 })
    .at('2026-03-03 09:40').marcaLeido('que-calor').marcaLeido('el-jugo'),
);

// a02: the "Add a word or a goal" box: trimmed, empty ones dropped, nothing else (no duplicate check, no cap)
const sp = ['\t', '\n', '\v', '\f', '\r', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', '　', '﻿'];
const notSp = ['\u0085', '᠎', '​', '⁠', '­'];
const r2 = new Run('a02-extra', 'extra(): trim as JavaScript trims, nothing for an empty value, no duplicate check, no limit, in order of adding')
  .at('2026-03-02 17:00').added()
  .extra('  talk to my 1-year-old around the house  ').added()
  .extra('').extra('   ').extra('\n\t \r\n').added()
  .extra('la playa').extra('la playa').extra(' La playa').added()
  .extra('x'.repeat(600)).extra('¿cómo estás?  ').extra("it's \"quoted\" $x \\ end");
for (const c of [...sp, ...notSp]) r2.extra(`${c}${c}w${c}`);
r2.extra(sp.join('') + 'all kinds' + sp.join('')).extra(sp.join('')).added();
runs.push(r2);

// a03: the switches of the Yo page, the welcome sheet and the speaking note
runs.push(
  new Run('a03-ajustes', 'the handlers of the page that write ajustes, each followed by PAL.save(); notaHabla() once a day')
    .at('2026-03-02 17:00').setting('min').setting('todo').setting('habla').setting('bienvenida').setting('notaHabla').setting('nada')
    .min(15).setting('min').min(120).min(30).minWelcome(60).setting('min')
    .todo().setting('todo').todo().setting('todo')
    .habla().setting('habla').habla().setting('habla').habla()
    .bienvenidaNivel().setting('bienvenida')
    .notaHabla().setting('notaHabla').notaHabla()
    .at('2026-03-03 08:00').notaHabla().setting('notaHabla')
    .listo().setting('bienvenida'),
);

// a04: what the pages read, after the scheduler has written
runs.push(
  new Run('a04-lecturas', 'hecho, db().nivel, d.minutos, AJ() and db().extra read after PAL calls and a level check')
    .at('2026-03-02 17:00').played('la-lluvia').level().minutes().added()
    .pal('oida', ['casa'], 'heard', { w: 'casa' }).played('la-lluvia')
    .pal('minutos', [0.1], 'addMinutes', { m: 0.1 }).pal('minutos', [0.2], 'addMinutes', { m: 0.2 }).minutes()
    .at('2026-03-02 17:10')
    .pal('cuento', [{ id: 'la-lluvia', focus_words: ['casa', 'puerta'], _lost: 0 }, [{ word: 'casa', asked: 'casa', got: 'casa', ok: true, ms: 800 }]], 'storyFinished',
      { result: { id: 'la-lluvia', focusWords: ['casa', 'puerta'], backAgain: [], lost: 0, log: [{ word: 'casa', asked: 'casa', got: 'casa', ok: true, ms: 800 }] } })
    .played('la-lluvia').played('el-jugo')
    .at('2026-03-02 17:20')
    .pal('presume', [['agua', 'jugo'], ['el-jugo', 'que-calor'], [{ w: 'agua', s: 1, ok: true }]], 'presume', { words: ['agua', 'jugo'], stories: ['el-jugo', 'que-calor'], log: [{ w: 'agua', s: 1, ok: true }] })
    .played('el-jugo').played('que-calor').played('cual-frente').level().minutes()
    .pal('racha', [], 'streak', {}).pal('oido', ['la-lluvia'], 'listened', { id: 'la-lluvia' }).minutes()
    .pal('reset', [], 'reset', {}).played('la-lluvia').level().minutes().added().setting('min'),
);

// a05: a store with the keys of the pages already in it (as the old app wrote them), and odd values
const old = '{"palabras":{},"dias":{"2026-03-01":2},"cuentos":{"la-lluvia":{"n":2,"primera":1772400000000,"ultima":1772450000000,"perdido":0},"zero":{"n":0,"primera":5},"sinn":{"primera":6}},"ajustes":{"min":15,"habla":0,"notaHabla":"2026-03-01"},"minutos":12.5,"v":1,"extra":["la playa"],"leidos":{"la-lluvia":1700000000000,"cero":0},"nivel":{"t":1772400000000,"log":[],"historias":3}}';
runs.push(
  new Run('a05-guardado-viejo', 'a stored store with leidos, extra, nivel and ajustes already in it, and values that are falsy', old)
    .at('2026-03-02 17:00').played('la-lluvia').played('zero').played('sinn').played('nada')
    .hasRead('la-lluvia').hasRead('cero').hasRead('nada').added().level().minutes()
    .setting('min').setting('habla').setting('todo').setting('notaHabla')
    .marcaLeido('la-lluvia').marcaLeido('cero').hasRead('cero').extra(' otra ').added()
    .habla().notaHabla().todo().min(60),
);
runs.push(
  new Run('a06-nulos', 'leidos, extra, nivel and minutos stored as null', '{"palabras":{},"dias":{},"cuentos":{},"ajustes":{"min":30},"minutos":null,"v":1,"leidos":null,"extra":null,"nivel":null}')
    .at('2026-03-02 17:00').hasRead('x').added().level().minutes().played('x')
    .marcaLeido('x').hasRead('x').extra('uno').added(),
);
runs.push(
  new Run('a07-extra-falsy', 'leidos and extra stored as 0 and "" (falsy: replaced by an empty object and an empty list)', '{"leidos":0,"extra":"","ajustes":null,"cuentos":null}')
    .at('2026-03-02 17:00').hasRead('x').added().setting('min')
    .marcaLeido('x').extra('uno').added().setting('habla'),
);

// a08: an evening of use, the calls of the scheduler and the pages in the order the app makes them
runs.push(
  new Run('a08-una-tarde', 'a first evening: a story, the minutes, a book, a word typed in, the settings, then the next morning')
    .at('2026-03-02 17:00').setting('min').bienvenidaNivel()
    .at('2026-03-02 17:02')
    .pal('cuento', [{ id: 'la-lluvia', focus_words: ['casa', 'puerta', 'ventana'], _lost: 1 }, [{ word: 'casa', asked: 'casa', got: 'casa', ok: true, ms: 400 }, { word: 'puerta', asked: 'puerta', got: 'ventana', ok: false, ms: 900 }]], 'storyFinished',
      { result: { id: 'la-lluvia', focusWords: ['casa', 'puerta', 'ventana'], backAgain: [], lost: 1, log: [{ word: 'casa', asked: 'casa', got: 'casa', ok: true, ms: 400 }, { word: 'puerta', asked: 'puerta', got: 'ventana', ok: false, ms: 900 }] } })
    .pal('minutos', [3.25], 'addMinutes', { m: 3.25 }).played('la-lluvia').minutes()
    .at('2026-03-02 17:30').marcaLeido('la-lluvia').extra('talk to my 1-year-old').habla().notaHabla()
    .at('2026-03-03 09:00').pal('vence', ['ear'], 'due', { skill: 'ear', at: null })
    .pal('responde', ['puerta', 'ear', true, 700, false], 'answer', { w: 'puerta', skill: 'ear', ok: true, ms: 700, intro: false })
    .pal('minutos', [0.5], 'addMinutes', { m: 0.5 }).pal('racha', [], 'streak', {}).minutes().added().hasRead('la-lluvia').todo().min(120).notaHabla(),
);

console.log(JSON.stringify({ zone, pieces, sequences: runs.map((r) => r.out()) }));
