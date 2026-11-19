// The lesson pages that are not stories: Repaso (cual.html) and the level check (nivel.html).
import { tap, untilReal, until, adv } from './drive.mjs';

const REV = [23, 20];
const CUAL = 'historia/cual.html', NIVEL = 'historia/nivel.html';
const open = (seed, url) => `open ${url} with the stored progress "${seed}" (coqui.palabras.v1 = seeds/${seed}.json), the clock at 19 Nov 2026 12:00 (Puerto Rico)`;

async function ready(pg, base, url, objName) {
  await pg.goto(`${base}/${url}`);
  await untilReal(pg, `typeof ${objName}!=='undefined'&&!!document.querySelector('#fin h1')`);
  await untilReal(pg, 'voiceReady!==null');
  await pg.evaluate('voiceReady');
}
const rightIx = pg => pg.evaluate('Cual.pan.findIndex(p=>p.right)');

// ------------------------------------------------------------------------------------------------------------------
// Repaso. Session 1 (stored progress "curso": ten words due): the start screen; the first sentence while it plays (both pictures dimmed); his turn; a right touch;
// a wrong touch, and the right picture shown; no touch at all; then the rest touched right; the end screen. Session 2 ("todo": nothing due): the practice session.
export async function repaso(C) {
  const q = 'historia/cual.html';
  const S = (pg, state, steps, seed) => C.shot(pg, 'repaso', state, { url: q, seed, steps, orders: REV });
  {
    const seed = 'curso', pg = await C.page(seed);
    await ready(pg, C.base, q, 'Cual');
    const st = [open(seed, q)];
    await S(pg, 'inicio', st, seed);
    await tap(pg, '#go');
    const s1 = [...st, 'touch the green start disc'];
    // the first item: the sentence plays, both pictures dimmed
    await until(pg, 'Cual.pan&&Cual.speaking>0&&!Cual.listo', 20000); await adv(pg, 70);
    await S(pg, 'frase-suena-imagenes-oscuras', s1.concat(['wait: the sentence is playing']), seed);
    await until(pg, 'Cual.listo', 20000); await adv(pg, 70);
    await S(pg, 'tu-turno', s1.concat(['wait until the sentence ends (both pictures at full brightness)']), seed);
    let r = await rightIx(pg);
    await pg.evaluate(`Cual.toca(${r})`);
    await until(pg, 'Cual.pan&&Cual.pan.some(p=>p.dim)&&document.querySelector(".opt.chk")', 5000); await adv(pg, 140);
    await S(pg, 'toque-bien', s1.concat(['wait until the sentence ends', 'touch the right picture']), seed);
    // the second item: a wrong touch
    await until(pg, 'Cual.i===1&&Cual.pan&&Cual.listo', 30000); await adv(pg, 70);
    r = await rightIx(pg);
    await pg.evaluate(`Cual.toca(${1 - r})`);
    await adv(pg, 140);
    const s2 = [...s1, '(first word answered right)', 'wait until the second sentence ends', 'touch the wrong picture'];
    await S(pg, 'toque-mal', s2, seed);
    await until(pg, 'Cual.pan&&Cual.pan.some(p=>p.sign)', 5000); await adv(pg, 140);
    await S(pg, 'toque-mal-se-muestra-la-buena', [...s2, 'wait half a second: the right picture gets the green ring and the sign'], seed);
    await pg.evaluate(`Cual.toca(${r})`);
    // the third item: no touch for 12 seconds
    await until(pg, 'Cual.i===2&&Cual.pan&&Cual.listo', 30000); await adv(pg, 70);
    await until(pg, 'Cual.pan&&Cual.pan.some(p=>p.sign)', 40000); await adv(pg, 140);
    await S(pg, 'sin-toque-se-muestra-la-buena', [...s2, '(touch the right picture)', 'wait until the third sentence ends', 'do not touch for 12 seconds (the sentence plays again at 6 s)'], seed);
    r = await rightIx(pg); await pg.evaluate(`Cual.toca(${r})`);
    // the rest: right every time (the two missed words come back once, three items later)
    let last = 2;
    for (let n = 0; n < 4000; n++) {
      const s = await pg.evaluate('({fin:!!Cual.fin,pan:!!Cual.pan,i:Cual.i,listo:Cual.listo})');
      if (s.fin) break;
      if (s.pan && s.listo && s.i !== last) { last = s.i; await pg.evaluate(`Cual.toca(Cual.pan.findIndex(p=>p.right))`); }
      await adv(pg, 70);
    }
    await until(pg, '!!Cual.fin', 60000); await adv(pg, 300);
    await S(pg, 'fin-a-subir-y-a-repasar', [...s2, '(second and third word missed)', 'touch the right picture on every other ask, the two missed words come back once'], seed);
    await pg.context().close();
  }
  {   // one word due: "1 word · about 1 min"
    const seed = 'uno', pg = await C.page(seed);
    await ready(pg, C.base, q, 'Cual');
    await S(pg, 'inicio-una-palabra', [open(seed, q)], seed);
    await pg.context().close();
  }
  {
    const seed = 'todo', pg = await C.page(seed);
    await ready(pg, C.base, q, 'Cual');
    const st = [open(seed, q)];
    await S(pg, 'inicio-practica', st, seed);
    await tap(pg, '#go');
    // two missed (the third and the sixth ask), the rest right
    let last = -1, plan = { 2: 'w', 5: 'w' };
    for (let n = 0; n < 4000; n++) {
      const s = await pg.evaluate('({fin:!!Cual.fin,pan:!!Cual.pan,i:Cual.i,listo:Cual.listo})');
      if (s.fin) break;
      if (s.pan && s.listo && s.i !== last) {
        last = s.i;
        const rr = await rightIx(pg);
        if (plan[s.i] === 'w') { await pg.evaluate(`Cual.toca(${1 - rr})`); await until(pg, 'Cual.pan&&Cual.pan.some(p=>p.sign)', 5000); await pg.evaluate(`Cual.toca(${rr})`); }
        else await pg.evaluate(`Cual.toca(${rr})`);
      }
      await adv(pg, 70);
    }
    await until(pg, '!!Cual.fin', 60000); await adv(pg, 300);
    await S(pg, 'fin-practica', [...st, 'touch the green start disc', 'touch the right picture on every ask but the third and the sixth (touch the wrong one, then the right one)'], seed);
    await pg.context().close();
  }
}

// ------------------------------------------------------------------------------------------------------------------
async function driveNivel(pg, N, hooks = {}) {   // N: right on every item of the first N stories and wrong after; N = 0: wrong every time
  let last = -1;
  for (let n = 0; n < 6000; n++) {
    const s = await pg.evaluate('({fin:!!Nivel.fin,pan:!!Nivel.pan,i:Nivel.i,listo:Nivel.listo,cur:window.__cur})');
    if (s.fin) return;
    if (s.pan && s.listo && s.i !== last) {
      last = s.i; await adv(pg, 70);
      if (hooks[s.i]) await hooks[s.i](pg);
      const r = await pg.evaluate('Nivel.pan.findIndex(p=>p.right)');
      const want = N > 0 && s.cur <= N;
      await pg.evaluate(`Nivel.toca(${want ? r : (r + 1) % 4})`);
    }
    await adv(pg, 70);
  }
  throw new Error('the level check did not end');
}

export async function nivel(C) {
  const q = NIVEL;
  const S = (pg, state, steps, seed) => C.shot(pg, 'nivel', state, { url: q, seed, steps, orders: REV }, {});
  const seed = 'vacio';
  let pg = await C.page(seed);
  await ready(pg, C.base, q, 'Nivel');
  const st = [open(seed, q)];
  await S(pg, 'explicacion', st, seed);
  await tap(pg, '#go');
  const s1 = [...st, 'touch the green start disc'];
  await until(pg, 'Nivel.pan&&!Nivel.listo&&speaking>0', 20000); await adv(pg, 70);
  await S(pg, 'pregunta-suena', [...s1, 'wait: the first sentence is playing'], seed);
  await until(pg, 'Nivel.listo', 20000); await adv(pg, 70);
  const r = await pg.evaluate('Nivel.pan.findIndex(p=>p.right)');
  await pg.evaluate(`Nivel.toca(${(r + 1) % 4})`); await adv(pg, 70);
  await S(pg, 'pregunta-tocada', [...s1, 'wait until the sentence ends', 'touch one of the four pictures (a white ring, no right or wrong)'], seed);
  // the rest: right on every item of the first 11 stories, wrong after that
  await driveNivel(pg, 11);
  await adv(pg, 300);
  await S(pg, 'resultado-11-historias', [...s1, 'touch the right picture on every item up to story 11 and a wrong one after it'], seed);
  await pg.context().close();

  pg = await C.page(seed);
  await ready(pg, C.base, q, 'Nivel');
  await tap(pg, '#go');
  await driveNivel(pg, 1);
  await adv(pg, 300);
  await S(pg, 'resultado-1-historia', [...st, 'touch the green start disc', 'touch the right picture on the items of story 1 and a wrong one after it'], seed);
  await pg.context().close();

  pg = await C.page(seed);
  await ready(pg, C.base, q, 'Nivel');
  await tap(pg, '#go');
  await driveNivel(pg, 0);
  await adv(pg, 300);
  await S(pg, 'resultado-desde-el-principio', [...st, 'touch the green start disc', 'touch a wrong picture every time (it stops after three misses)'], seed);
  await pg.context().close();
}

// the stored progress after a level check (right up to story 11), made by playing the level check itself
export async function nivelSeed(C, N = 11) {
  const pg = await C.page('vacio');
  await ready(pg, C.base, NIVEL, 'Nivel');
  await tap(pg, '#go');
  await driveNivel(pg, N);
  await adv(pg, 300);
  const json = await pg.evaluate("localStorage.getItem('coqui.palabras.v1')");
  await pg.context().close();
  return json;
}
