// The groups of pictures of app.html: the welcome, the five tabs, every sheet and card, the book reader.
import { openApp, settle, goTab, tap, tapAt, centre, sheetOpen, untilReal, until, adv, sleepReal, dbOf } from './drive.mjs';
import { T0 } from './harness.mjs';

const MAP = [13, 20], WORDS = [21, 20], LIB = [22, 20], SPEAK = [24, 20], ME = [25, 20];
const APP = 'historia/app.html';

// a shot of an app page: the url, the seed, the steps that led to it, the orders that use it
const S = (C, pg, screen, state, o) => C.shot(pg, screen, state, { url: o.url || APP, seed: o.seed || null, steps: o.steps, orders: o.orders }, { full: !!o.full });
const open = (seed, url) => `open ${url} with the stored progress "${seed}" (coqui.palabras.v1 = seeds/${seed}.json), the clock at 19 Nov 2026 12:00 (Puerto Rico)`;
const fresh = url => `open ${url} with nothing stored (first start), the clock at 19 Nov 2026 12:00 (Puerto Rico)`;

// the screen position of a stop of the map (STOP[i] in app.html), to touch it
async function stopXY(pg, i) {
  return pg.evaluate(i => { const cv = document.getElementById('mapa'), r = cv.getBoundingClientRect(); return [r.left + STOP[i][0] * r.width / 240, r.top + STOP[i][1] * r.height / 352]; }, i);
}
async function touchStop(pg, i) { const [x, y] = await stopXY(pg, i); await tapAt(pg, x, y); await sheetOpen(pg); await adv(pg, 100); }

// ------------------------------------------------------------------------------------------------------------------
export async function bienvenida(C) {
  let pg = await C.page(null);
  await openApp(pg, C.base, '');
  const o = { orders: ME, steps: [fresh(APP)] };
  await S(C, pg, 'bienvenida', 'paso-1', { ...o });
  await tap(pg, '#sfoot .btn');
  await S(C, pg, 'bienvenida', 'paso-2', { ...o, steps: [...o.steps, 'touch "Next"'] });
  await tap(pg, '.seg button', 2);
  await S(C, pg, 'bienvenida', 'paso-2-60-min', { ...o, steps: [...o.steps, 'touch "Next"', 'touch "60 min"'] });
  await tap(pg, '#sfoot .btn');
  await S(C, pg, 'bienvenida', 'paso-3', { ...o, steps: [...o.steps, 'touch "Next"', 'touch "60 min"', 'touch "Next"'] });
  await pg.context().close();

  // opened again from Yo, "How it works": an ordinary sheet (handle, X), with the level-check paragraph
  pg = await C.page('vacio');
  await openApp(pg, C.base, '?tab=yo');
  const st = [open('vacio', APP + '?tab=yo'), 'touch "How it works"'];
  await tap(pg, '#t-yo .btn.out.full'); await sheetOpen(pg); await adv(pg, 100);
  await S(C, pg, 'bienvenida', 'como-funciona-1', { orders: ME, seed: 'vacio', url: APP + '?tab=yo', steps: st });
  await pg.evaluate(() => { const b = document.getElementById('sbody'); b.scrollTop = b.scrollHeight; b.dispatchEvent(new Event('scroll')); }); await adv(pg, 100);
  await S(C, pg, 'bienvenida', 'como-funciona-1-al-final', { orders: ME, seed: 'vacio', url: APP + '?tab=yo', steps: [...st, 'scroll the sheet to its end (the Level check paragraph)'] });
  await pg.evaluate(() => { const b = document.getElementById('sbody'); b.scrollTop = 0; b.dispatchEvent(new Event('scroll')); }); await adv(pg, 100);
  await tap(pg, '#sfoot .btn'); await adv(pg, 100);
  await S(C, pg, 'bienvenida', 'como-funciona-2', { orders: ME, seed: 'vacio', url: APP + '?tab=yo', steps: [...st, 'touch "Next"'] });
  await tap(pg, '#sfoot .btn'); await adv(pg, 100);
  await S(C, pg, 'bienvenida', 'como-funciona-3', { orders: ME, seed: 'vacio', url: APP + '?tab=yo', steps: [...st, 'touch "Next"', 'touch "Next"'] });
  await pg.context().close();
}

// ------------------------------------------------------------------------------------------------------------------
export async function mapa(C) {
  const states = [['vacio', 'nada-jugado'], ['segunda', 'una-historia-hoy'], ['uno', 'una-palabra'], ['curso', 'a-medio-curso'], ['todo', 'todo-jugado']];
  for (const [sd, name] of states) {
    const pg = await C.page(sd);
    await openApp(pg, C.base, '?tab=mapa');
    await S(C, pg, 'mapa', name, { orders: MAP, seed: sd, url: APP + '?tab=mapa', steps: [open(sd, APP + '?tab=mapa')] });
    await pg.context().close();
  }
  // "Open every place" on: every place with a stop is open to look at
  const pg = await C.page('todo');
  await openApp(pg, C.base, '?tab=yo');
  await tap(pg, '#t-yo .sw', 0);
  await goTab(pg, 'mapa');
  await S(C, pg, 'mapa', 'todo-abierto', { orders: MAP, seed: 'todo', url: APP + '?tab=yo', steps: [open('todo', APP + '?tab=yo'), 'touch the "Open every place" switch', 'touch the Mapa tab'] });
  await pg.context().close();
}

// ------------------------------------------------------------------------------------------------------------------
export async function lugar(C) {
  const mk = async (sd, url) => { const pg = await C.page(sd); await openApp(pg, C.base, url); return pg; };
  const one = async (sd, i, state, extra) => {
    const pg = await mk(sd, '?tab=mapa');
    const steps = [open(sd, APP + '?tab=mapa'), `touch the stop of place ${i + 1} on the map`];
    await touchStop(pg, i);
    await S(C, pg, 'lugar', state, { orders: MAP, seed: sd, steps });
    if (extra) await extra(pg, steps);
    await pg.context().close();
  };
  await one('vacio', 0, 'abierto-1-nada-jugado');
  await one('curso', 0, 'hecho-1', async (pg, steps) => {
    await pg.evaluate(() => { const b = document.getElementById('sbody'); b.scrollTop = b.scrollHeight; b.dispatchEvent(new Event('scroll')); });
    await adv(pg, 100);
    await S(C, pg, 'lugar', 'hecho-1-al-final', { orders: MAP, seed: 'curso', steps: [...steps, 'scroll the list of stories to its end'] });
  });
  await one('curso', 1, 'abierto-2-a-medias');
  await one('curso', 2, 'abierto-3-nada-jugado');
  await one('curso', 3, 'cerrado-4');
  await one('todo', 2, 'hecho-3');
  for (let i = 4; i < 10; i++) await one('curso', i, `cerrado-${i + 1}`);
  // "Open every place" on: a place with no stories yet says so
  const pg = await mk('todo', '?tab=yo');
  await tap(pg, '#t-yo .sw', 0);
  await goTab(pg, 'mapa');
  await touchStop(pg, 3);
  await S(C, pg, 'lugar', 'sin-construir-4', { orders: MAP, seed: 'todo', url: APP + '?tab=yo', steps: [open('todo', APP + '?tab=yo'), 'touch the "Open every place" switch', 'touch the Mapa tab', 'touch the stop of place 4 on the map'] });
  await pg.context().close();
}

// ------------------------------------------------------------------------------------------------------------------
export async function palabras(C) {
  const tabShot = async (sd, state, o = {}) => {
    const pg = await C.page(sd);
    await openApp(pg, C.base, '?tab=palabras');
    const steps = [open(sd, APP + '?tab=palabras')];
    await S(C, pg, 'palabras', state, { orders: WORDS, seed: sd, url: APP + '?tab=palabras', steps });
    if (o.full) await S(C, pg, 'palabras', state + '-pagina-entera', { orders: WORDS, seed: sd, url: APP + '?tab=palabras', steps: [...steps, 'the whole page, top to bottom'], full: true });
    if (o.more) await o.more(pg, steps);
    await pg.context().close();
  };
  await tabShot('vacio', 'nada-jugado');
  await tabShot('curso', 'a-medio-curso', {
    full: true,
    more: async (pg, steps) => {
      const url = APP + '?tab=palabras', seed = 'curso';
      await pg.evaluate("document.getElementById('extra').scrollIntoView({block:'center'})"); await adv(pg, 100);
      const s1 = [...steps, 'scroll to "Add a word or a goal"'];
      await S(C, pg, 'palabras', 'a-medio-curso-agregar-campo-vacio', { orders: WORDS, seed, url, steps: s1 });
      await pg.fill('#extra', 'talk to my 1-year-old around the house');
      const s2 = [...s1, 'type "talk to my 1-year-old around the house"'];
      await S(C, pg, 'palabras', 'a-medio-curso-agregar-campo-escrito', { orders: WORDS, seed, url, steps: s2 });
      await tap(pg, '#t-palabras .btn.go[onclick="extra()"]');
      await untilReal(pg, "document.querySelectorAll('#t-palabras p.small.mut').length>0&&document.getElementById('t-palabras').innerText.includes('Saved. Material')");
      await pg.evaluate("document.getElementById('extra').scrollIntoView({block:'center'})"); await adv(pg, 100);
      await S(C, pg, 'palabras', 'a-medio-curso-agregar-guardado', { orders: WORDS, seed, url, steps: [...s2, 'touch "Add"'] });
    },
  });
  await tabShot('todo', 'todo-jugado', { full: true });
  await tabShot('uno', 'una-palabra');
}

// ------------------------------------------------------------------------------------------------------------------
export async function palabra(C) {
  const url = APP + '?tab=palabras';
  const openWord = async (sd, pick) => {
    const pg = await C.page(sd);
    await openApp(pg, C.base, '?tab=palabras');
    const db = await dbOf(pg), words = Object.values(db.palabras);
    const pairs = new Set(await pg.evaluate("[...document.querySelectorAll('.wc:not(.np)')].map(e=>e.dataset.w)"));   // the words shown with a picture
    const w = pick(words, pairs);
    if (!w) throw new Error('no word for ' + sd);
    await tap(pg, `.wc[data-w="${w.w}"]`);
    await sheetOpen(pg); await untilReal(pg, "document.querySelectorAll('#oido .li').length>0||!document.getElementById('oido')"); await adv(pg, 100);
    return { pg, w: w.w, steps: [open(sd, url), `touch the card of the word "${w.w}"`] };
  };
  const byName = (a, b) => a.w < b.w ? -1 : 1;
  // a word with a picture, ear stage 3, no mouth record, five lines to hear
  let r = await openWord('curso', (ws, pairs) => ws.filter(x => x.ear.etapa === 3 && x.mouth.n === 0 && x.ear.due > T0 && pairs.has(x.w)).sort(byName)[0]);
  await S(C, r.pg, 'palabra', 'con-imagen-oido-3-vuelve-en-dias', { orders: WORDS, seed: 'curso', url, steps: r.steps });
  await r.pg.context().close();
  r = await openWord('curso', (ws) => ws.filter(x => x.w === 'casa')[0]);
  // the lines under "Heard in", a line playing (a second touch stops it)
  await tap(r.pg, '#oido .pb', 0);
  await untilReal(r.pg, "speaking>0"); await adv(r.pg, 100);
  await S(C, r.pg, 'palabra', 'linea-sonando', { orders: WORDS, seed: 'curso', url, steps: [...r.steps, 'touch the play button of the first "Heard in" line'] });
  await tap(r.pg, '#oido .pb', 0); await adv(r.pg, 100);
  await r.pg.evaluate(() => { const b = document.getElementById('sbody'); b.scrollTop = b.scrollHeight; b.dispatchEvent(new Event('scroll')); }); await adv(r.pg, 100);
  await S(C, r.pg, 'palabra', 'al-final', { orders: WORDS, seed: 'curso', url, steps: [...r.steps, 'scroll the sheet to its end (the word stays in the header)'] });
  await r.pg.context().close();
  // a word he has said to Danny: both meters filled
  r = await openWord('curso', (ws, pairs) => ws.filter(x => x.mouth.etapa === 3 && x.ear.etapa === 3 && pairs.has(x.w)).sort(byName)[0]);
  await S(C, r.pg, 'palabra', 'con-boca', { orders: WORDS, seed: 'curso', url, steps: r.steps });
  await r.pg.context().close();
  // a word with no picture pair: no picture on the sheet
  r = await openWord('curso', (ws, pairs) => ws.filter(x => x.ear.etapa === 3 && !pairs.has(x.w)).sort(byName)[0]);
  await S(C, r.pg, 'palabra', 'sin-imagen', { orders: WORDS, seed: 'curso', url, steps: r.steps });
  await r.pg.context().close();
  // a word that is due now
  r = await openWord('curso', (ws, pairs) => ws.filter(x => x.ear.due && x.ear.due <= T0 && x.ear.etapa >= 2 && pairs.has(x.w)).sort(byName)[0]);
  await S(C, r.pg, 'palabra', 'vuelve-hoy', { orders: WORDS, seed: 'curso', url, steps: r.steps });
  await r.pg.context().close();
  // a word his ear holds well (four dots)
  r = await openWord('todo', (ws, pairs) => ws.filter(x => x.ear.etapa === 4 && x.mouth.etapa === 3 && pairs.has(x.w)).sort(byName)[0]);
  await S(C, r.pg, 'palabra', 'bien-oido-4-boca-3', { orders: WORDS, seed: 'todo', url, steps: r.steps });
  await r.pg.context().close();
  // a word just heard (one dot), and one that has no recording to hear
  r = await openWord('curso', (ws, pairs) => ws.filter(x => x.ear.etapa === 1 && pairs.has(x.w)).sort(byName)[0]);
  await S(C, r.pg, 'palabra', 'recien-oida-oido-1', { orders: WORDS, seed: 'curso', url, steps: r.steps });
  await r.pg.context().close();
}

// ------------------------------------------------------------------------------------------------------------------
export async function biblioteca(C) {
  const url = APP + '?tab=biblioteca';
  const tabShot = async (sd, state, o = {}) => {
    const pg = await C.page(sd);
    await openApp(pg, C.base, '?tab=biblioteca');
    const steps = [open(sd, url)];
    await S(C, pg, 'biblioteca', state, { orders: LIB, seed: sd, url, steps });
    if (o.full) await S(C, pg, 'biblioteca', state + '-pagina-entera', { orders: LIB, seed: sd, url, steps: [...steps, 'the whole page, top to bottom'], full: true });
    if (o.more) await o.more(pg, steps);
    await pg.context().close();
  };
  await tabShot('vacio', 'nada-jugado');
  await tabShot('curso', 'a-medio-curso', { full: true });
  await tabShot('todo', 'todo-jugado', { full: true });
  await tabShot('casi', 'queda-una', {
    more: async (pg, steps) => {   // "1 more opens as you play the map"
      await pg.evaluate('scrollTo(0,1e7)'); await adv(pg, 100);
      await S(C, pg, 'biblioteca', 'queda-una-al-final', { orders: LIB, seed: 'casi', url, steps: [...steps, 'scroll to the end of the page'] });
    },
  });
}

// ------------------------------------------------------------------------------------------------------------------
// the book reader, of "¿Quién eres tú?" (three lines to a page, the coquí's lines carry his label) and of "Toc, toc" (a picture story)
export async function libro(C) {
  const url = APP + '?tab=biblioteca', seed = 'curso';
  let pg = await C.page(seed);
  await openApp(pg, C.base, '?tab=biblioteca');
  const base = [open(seed, url)];
  const sel = 'quien-eres-tu';
  const openBook = async (pg, id) => {
    await tap(pg, `.bk[data-c="${id}"] .btn.out`);
    await untilReal(pg, `App.libro.open&&App.libro.id===${JSON.stringify(id)}`);
    await untilReal(pg, `document.getElementById('lbimg').dataset.ok==='1'`);
  };
  const lit = (pg, k) => untilReal(pg, `App.libro.lit.length>0&&speaking>0&&App.libro.lit[0]===App.libro.ids[${k}]`);
  const rest = pg => until(pg, 'App.libro.lit.length===0&&speaking===0', 30000);
  const s0 = [...base, `touch "Read" on "¿Quién eres tú?"`];
  await openBook(pg, sel); await lit(pg, 0);
  await S(C, pg, 'libro', 'primera-pagina-linea-1-luce', { orders: LIB, seed, url, steps: s0 });
  await until(pg, 'App.libro.lit[0]===App.libro.ids[1]', 30000);
  await S(C, pg, 'libro', 'primera-pagina-linea-2-luce', { orders: LIB, seed, url, steps: [...s0, 'wait until the second line is lit'] });
  await rest(pg);
  await S(C, pg, 'libro', 'primera-pagina-en-reposo', { orders: LIB, seed, url, steps: [...s0, 'wait for the three lines to finish'] });
  // a word with a picture: the card
  const wordSel = await pg.evaluate(() => { const b = document.querySelector('#lbtxt .bw'); return b ? [...document.querySelectorAll('#lbtxt .lbl')].findIndex(l => l.contains(b)) : -1; });
  if (wordSel >= 0) {
    await tap(pg, '#lbtxt .bw', 0);
    await untilReal(pg, "document.getElementById('lbcard').classList.contains('on')"); await adv(pg, 100);
    await S(C, pg, 'libro', 'tarjeta-de-palabra', { orders: LIB, seed, url, steps: [...s0, 'wait for the three lines to finish', 'touch a word with a dotted underline'] });
    await tap(pg, '#lbcard'); await adv(pg, 100);
  }
  // a middle page: the second line lit
  await tap(pg, '#lbnext'); await untilReal(pg, 'App.libro.i===1');
  await tap(pg, '#lbnext'); await untilReal(pg, 'App.libro.i===2');
  await until(pg, 'App.libro.lit[0]===App.libro.ids[1]&&speaking>0', 30000);
  await S(C, pg, 'libro', 'pagina-media-linea-luce', { orders: LIB, seed, url, steps: [...s0, 'touch the next arrow twice (page 3 of 5)', 'wait until the second line is lit'] });
  await rest(pg);
  const s3 = [...s0, 'touch the next arrow twice (page 3 of 5)', 'wait for the lines to finish'];
  await S(C, pg, 'libro', 'pagina-media-en-reposo', { orders: LIB, seed, url, steps: s3 });
  // the text size button: 24 px
  await tap(pg, '#lbaa'); await adv(pg, 100);
  await S(C, pg, 'libro', 'texto-grande', { orders: LIB, seed, url, steps: [...s3, 'touch "Aa" (24 px text)'] });
  await tap(pg, '#lbaa'); await adv(pg, 100);
  // the last page
  await tap(pg, '#lbnext'); await untilReal(pg, 'App.libro.i===3');
  await tap(pg, '#lbnext'); await untilReal(pg, 'App.libro.i===4');
  await rest(pg);
  await S(C, pg, 'libro', 'ultima-pagina', { orders: LIB, seed, url, steps: [...s3, 'touch the next arrow twice more (page 5 of 5)', 'wait for the lines to finish'] });
  await pg.context().close();

  // a picture story's book: one line on its first page; a page with a coquí line
  pg = await C.page(seed);
  await openApp(pg, C.base, '?tab=biblioteca');
  // "Cuento con dibujos" rows only show for a finished place: La casa is finished in "curso"
  await openBook(pg, 'd-toc-toc'); await lit(pg, 0);
  const sd = [...base, 'touch "Read" on "Toc, toc"'];
  await S(C, pg, 'libro', 'cuento-con-dibujos-primera-pagina', { orders: LIB, seed, url, steps: sd });
  for (let k = 1; k <= 5; k++) { await rest(pg); await tap(pg, '#lbnext'); await untilReal(pg, `App.libro.i===${k}`); }
  await until(pg, 'App.libro.lit[0]===App.libro.ids[2]&&speaking>0', 30000);
  await S(C, pg, 'libro', 'cuento-con-dibujos-pagina-6-linea-del-coqui', { orders: LIB, seed, url, steps: [...sd, 'touch the next arrow five times (page 6 of 11)', 'wait until the third line (the coquí) is lit'] });
  await pg.context().close();
}

// ------------------------------------------------------------------------------------------------------------------
export async function hablar(C) {
  const url = APP + '?tab=hablar';
  for (const [sd, state, full] of [['vacio', 'nada-jugado', true], ['curso', 'a-medio-curso', true], ['todo', 'todo-jugado', true]]) {
    const pg = await C.page(sd);
    await openApp(pg, C.base, '?tab=hablar');
    const steps = [open(sd, url)];
    await S(C, pg, 'hablar', state, { orders: SPEAK, seed: sd, url, steps });
    if (full) await S(C, pg, 'hablar', state + '-pagina-entera', { orders: SPEAK, seed: sd, url, steps: [...steps, 'the whole page, top to bottom'], full: true });
    await pg.context().close();
  }
}

// ------------------------------------------------------------------------------------------------------------------
export async function yo(C) {
  const url = APP + '?tab=yo';
  const tabShot = async (sd, state, o = {}) => {
    const pg = await C.page(sd);
    await openApp(pg, C.base, o.q || '?tab=yo');
    const steps = [open(sd, APP + (o.q || '?tab=yo'))];
    await S(C, pg, 'yo', state, { orders: ME, seed: sd, url: APP + (o.q || '?tab=yo'), steps });
    if (o.full) await S(C, pg, 'yo', state + '-pagina-entera', { orders: ME, seed: sd, url: APP + (o.q || '?tab=yo'), steps: [...steps, 'the whole page, top to bottom'], full: true });
    if (o.more) await o.more(pg, steps);
    await pg.context().close();
  };
  await tabShot('vacio', 'nada-jugado');
  await tabShot('curso', 'a-medio-curso', {
    full: true,
    more: async (pg, steps) => {   // the settings changed: 120 minutes, every place open, speaking in stories off
      await tap(pg, '#t-yo .seg button', 3);
      await tap(pg, '#t-yo .sw', 0);
      await tap(pg, '#t-yo .sw', 1);
      await pg.evaluate('scrollTo(0,0)'); await adv(pg, 100);
      await S(C, pg, 'yo', 'ajustes-cambiados', { orders: ME, seed: 'curso', url, steps: [...steps, 'touch "120"', 'touch the "Open every place" switch', 'touch the "Speak in stories" switch'] });
      await pg.evaluate("document.getElementById('t-yo').scrollIntoView(); scrollTo(0,1e6)"); await adv(pg, 100);
      await S(C, pg, 'yo', 'ajustes-cambiados-al-final', { orders: ME, seed: 'curso', url, steps: [...steps, 'touch "120"', 'touch the "Open every place" switch', 'touch the "Speak in stories" switch', 'scroll to the end'] });
    },
  });
  await tabShot('todo', 'todo-jugado');
  await tabShot('uno', 'una-palabra');
  // speaking not available on this phone (?mic=off): the once-a-day note
  await tabShot('curso', 'nota-sin-voz', { q: '?tab=yo&mic=off', full: false });
}

// ------------------------------------------------------------------------------------------------------------------
// after a level check (stored progress "nivel", made by playing nivel.html: right up to story 11): the map further along, the words it presumes, the call open
export async function despuesDelNivel(C) {
  const seed = 'nivel';
  for (const [tab, screen, orders] of [['mapa', 'mapa', MAP], ['palabras', 'palabras', WORDS], ['hablar', 'hablar', SPEAK], ['yo', 'yo', ME]]) {
    const url = APP + '?tab=' + tab;
    const pg = await C.page(seed);
    await openApp(pg, C.base, '?tab=' + tab);
    await S(C, pg, screen, 'despues-del-nivel', { orders, seed, url, steps: [open(seed, url)] });
    if (tab === 'yo') await S(C, pg, screen, 'despues-del-nivel-pagina-entera', { orders, seed, url, steps: [open(seed, url), 'the whole page, top to bottom'], full: true });
    await pg.context().close();
  }
}

export async function despuesDelNivel1(C) {   // right on one story only: "Done: 1 story skipped."
  const seed = 'nivel1', url = APP + '?tab=yo';
  const pg = await C.page(seed);
  await openApp(pg, C.base, '?tab=yo');
  await pg.evaluate("document.querySelector('#t-yo .btn.out:not(.full)').scrollIntoView({block:'center'})"); await adv(pg, 100);
  await S(C, pg, 'yo', 'despues-del-nivel-1-historia', { orders: ME, seed, url, steps: [open(seed, url), 'scroll to the "Level check" card'] });
  await pg.context().close();
}
