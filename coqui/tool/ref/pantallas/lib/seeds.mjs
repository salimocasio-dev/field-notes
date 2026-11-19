// The progress states the pictures are taken in. Each is made by the old app's own code (palabras.js: PAL.cuento, PAL.responde, PAL.oido, PAL.minutos) called in
// the order a learner's days would call it, with the palabras clock (window.__PAL_NOW) set to the moment of each call, so the stored shape is the real one.
// The result of a seed is the string the app keeps under localStorage "coqui.palabras.v1".
import { T0, newPage, untilReal } from './harness.mjs';

export const CASA = ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro', 'el-jugo', 'que-calor', 'la-familia', 'la-foto', 'quien-eres-tu', 'las-flores', 'que-es-esto', 'hasta-manana'];
export const PARQUE = ['uno-dos-tres', 'donde-esta-el-gato', 'rapido-despacio', 'la-bola', 'arriba-abajo', 'otra-vez', 'pan-para-el-pato', 'los-botes', 'cual', 'la-piragua', 'senor-senora', 'el-bebe-duerme'];
export const COCINA = ['la-mesa', 'la-cuchara', 'tengo-hambre', 'arroz-con-habichuelas', 'el-pollo-y-el-huevo', 'cuidado', 'no-hay-leche', 'para-los-pajaros', 'jugo-de-china'];
const ALL = [...CASA, ...PARQUE, ...COCINA];

// one day = a list of events; d = days before today (0 = today), h/m = the time of day in Puerto Rico
const story = (d, h, m, id) => ({ k: 'story', d, h, m, id });
const review = (d, h, m, opt = {}) => ({ k: 'review', d, h, m, ...opt });
const listen = (d, h, m, id) => ({ k: 'listen', d, h, m, id });
const call = (d, h, m, said, mins) => ({ k: 'call', d, h, m, said, mins });
const read = (d, h, m, id) => ({ k: 'read', d, h, m, id });

function evCurso() {   // five days in: place 1 done (every story twice), place 2 begun, a call to Danny, no Repaso yet today
  const e = [];
  const day = (d, first, second) => { second.forEach((id, i) => e.push(story(d, 9, i * 10, id))); first.forEach((id, i) => e.push(story(d, 10, i * 10, id))); };
  day(4, ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro', 'el-jugo'], []);
  day(3, ['que-calor', 'la-familia', 'la-foto', 'quien-eres-tu'], ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro', 'el-jugo']);
  e.push(review(3, 8, 30));
  day(2, ['las-flores', 'que-es-esto', 'hasta-manana'], ['que-calor', 'la-familia', 'la-foto', 'quien-eres-tu']);
  e.push(review(2, 8, 30));
  day(1, ['uno-dos-tres', 'donde-esta-el-gato', 'rapido-despacio'], ['las-flores', 'que-es-esto', 'hasta-manana']);
  e.push(review(1, 8, 30), call(1, 18, 0, ['hola', 'bien', 'gracias', 'sí', 'jugo'], 5), read(1, 19, 0, 'la-familia'));
  day(0, ['la-bola'], ['uno-dos-tres', 'donde-esta-el-gato', 'rapido-despacio']);
  e.push(listen(0, 10, 40, 'el-jugo'));
  return e;
}
function evTodo() {   // a month in: everything built so far (places 1 to 3) played twice, a Repaso every morning, two calls, nothing due now
  const e = [];
  const nd = Math.ceil(ALL.length / 3);
  for (let k = 0; k < nd; k++) {
    const d = 30 - k, first = ALL.slice(3 * k, 3 * k + 3), prev = ALL.slice(3 * (k - 1), 3 * k);
    if (k > 0) prev.forEach((id, i) => e.push(story(d, 9, 30 + i * 10, id)));
    first.forEach((id, i) => e.push(story(d, 10, i * 10, id)));
  }
  ALL.slice(3 * (nd - 1)).forEach((id, i) => e.push(story(30 - nd, 9, 30 + i * 10, id)));
  for (let d = 29; d >= 1; d--) e.push(review(d, 8, 30, { wrongOk: true, passes: 12 }));
  e.push(review(0, 11, 30, { passes: 30 }));   // today's last, after the stories: nothing is due when the pictures are taken
  for (let d = 30 - nd - 1; d >= 0; d--) { e.push(listen(d, 10, 30, ALL[(d + 40) % ALL.length])); if (d % 3 === 0) e.push(listen(d, 18, 0, ALL[(d + 50) % ALL.length])); }
  e.push(call(17, 18, 0, ['hola', 'bien', 'gracias', 'sí', 'quiero', 'jugo', 'adiós'], 6), call(8, 18, 0, ['hola', 'abuela', 'casa', 'puerta', 'bien', 'gracias', 'adiós'], 7));
  ['la-familia', 'quien-eres-tu', 'hasta-manana', 'donde-esta-el-gato', 'rapido-despacio', 'el-bebe-duerme', 'la-cuchara', 'tengo-hambre', 'd-toc-toc'].forEach((id, i) => e.push(read(14 - i, 19, 0, id)));
  e.push(listen(9, 16, 0, 'd-toc-toc'), listen(6, 16, 0, 'd-toc-toc'), listen(5, 16, 0, 'h-frente'), listen(4, 16, 0, 'h-balcon'));
  return e;
}
export const SEED_DEFS = {
  vacio: { about: 'the welcome done, nothing played', events: () => [] },
  segunda: { about: 'La lluvia played once, this morning', events: () => [story(0, 9, 0, 'la-lluvia')] },
  uno: { about: 'one word (heard a month ago, answered slowly three times, so good now and due today), one minute listened today: the singular forms', events: () => [
    { k: 'oida', d: 30, h: 10, m: 0, w: 'abuela' }, { k: 'ans', d: 20, h: 10, m: 0, w: 'abuela' }, { k: 'ans', d: 10, h: 10, m: 0, w: 'abuela' }, { k: 'ans', d: 1, h: 10, m: 0, w: 'abuela' },
    { k: 'min', d: 0, h: 9, m: 0, mins: 1 }] },
  curso: { about: 'mid-course: five days, place 1 done, place 2 begun, some words due, a streak of 5', events: evCurso },
  casi: { about: 'everything built so far played but the last story of La cocina', events: () => evTodo().filter(x => !(x.k === 'story' && x.id === 'jugo-de-china')) },
  todo: { about: 'everything built so far played (places 1 to 3, every story twice), a month in', events: evTodo },
};

// ---- run in the page: the events, in time order, through palabras.js and the rules of cual.js -----------------------
const SIM = `async (spec) => {
  const hash = s => { let x = 0; for (const c of s) x = (x * 31 + c.charCodeAt(0)) >>> 0; return x; };
  const day0 = new Date(2026, 10, 19, 0, 0, 0).getTime(), at = e => day0 - e.d * 864e5 + (e.h * 60 + e.m) * 6e4;
  const T = {}; const get = async id => T[id] || (T[id] = await (await fetch('cuentos/' + id + '.json')).json());
  const pairs = new Set(CU.items.map(i => i.w));
  const ev = spec.events.slice().sort((a, b) => at(a) - at(b));
  for (const e of ev) {
    window.__PAL_NOW = at(e);
    if (e.k === 'story') {                       // a story played to its end (juego.js: PAL.cuento with the answers of the play, then PAL.minutos)
      const S = await get(e.id), seen = (PAL.db.cuentos[e.id] || {}).n || 0;
      const log = (S.focus_words || []).map(w => ({ word: w, asked: w, got: w, ok: !(e.d > 0 && seen === 0 && hash(e.id + w) % 11 === 0), ms: 900 + hash(w) % 900 }));
      S._lost = log.some(x => !x.ok) ? 1 : 0; PAL.cuento(S, log); PAL.minutos(CURSO.cuentos[e.id].min * .9);
    } else if (e.k === 'review') {                // Repaso sessions: up to 10 due words with a picture pair, most overdue first (cual.js: cualLista, cualItem); another session while words are due (up to e.passes)
      let t = at(e);
      for (let pass = 0; pass < (e.passes || 1); pass++) {
        const due = PAL.vence('ear').filter(w => pairs.has(w)).slice(0, 10); if (!due.length) break;
        for (const w of due) {
          window.__PAL_NOW = t; const venc = PAL.vence('ear').includes(w), miss = e.wrongOk && hash(w + e.d) % 7 === 0;
          PAL.responde(w, 'ear', !miss, 700 + hash(w + 'ms') % 2200, !venc); t += 9000;
        }
        t += 300000;
      }
    } else if (e.k === 'listen') { PAL.oido(e.id); PAL.minutos(CURSO.cuentos[e.id].min * 1); }
    else if (e.k === 'call') { e.said.forEach((w, i) => PAL.responde(w, 'mouth', true, 600 + 150 * i, false)); PAL.minutos(e.mins); }
    else if (e.k === 'read') { const d = PAL.db; d.leidos = d.leidos || {}; d.leidos[e.id] = window.__PAL_NOW; PAL.save(); }   // what marcaLeido() in app.html writes at a book's last page
    else if (e.k === 'oida') PAL.oida(e.w);
    else if (e.k === 'ans') PAL.responde(e.w, 'ear', true, 2500, false);   // right but slow: the gap does not stretch
    else if (e.k === 'min') PAL.minutos(e.mins);
  }
  window.__PAL_NOW = ${T0}; PAL.save();
  return localStorage.getItem('coqui.palabras.v1');
}`;

export async function buildSeeds(browser, dev, base) {
  const out = {};
  for (const [name, def] of Object.entries(SEED_DEFS)) {
    const pg = await newPage(browser, dev);
    await pg.goto(base + '/historia/app.html');
    await untilReal(pg, '!!(window.App&&App.ready)');
    await pg.evaluate('voiceReady');
    await pg.evaluate('App.listo()');                          // "I'm new to Spanish": the welcome is done
    out[name] = await pg.evaluate(`(${SIM})(${JSON.stringify({ events: def.events() })})`);
    if (pg.errs.length) throw new Error('seed ' + name + ': ' + pg.errs.join(' | '));
    await pg.context().close();
  }
  return out;
}
