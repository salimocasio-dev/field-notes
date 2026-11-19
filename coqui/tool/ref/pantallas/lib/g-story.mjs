// The story page (index.html): story 1, La lluvia, and the states other stories bring (answer bubbles, a speaking turn).
import fs from 'node:fs';
import path from 'node:path';
import { REPO } from './harness.mjs';
import { tap, untilReal, until, adv, freeze } from './drive.mjs';

const PLAY = [15, 20];
const open = (seed, url) => `open ${url} with the stored progress "${seed}" (coqui.palabras.v1 = seeds/${seed}.json), the clock at 19 Nov 2026 12:00 (Puerto Rico)`;

async function ready(pg, base, url) {
  await pg.goto(`${base}/${url}`);
  await untilReal(pg, `Story.ready&&voiceReady!==null`);
  await pg.evaluate('voiceReady');
  await untilReal(pg, `!!document.querySelector('#cv')`);
}
// what the page is waiting for (a touch), from outside
const PEND = `(()=>{const p=Story.pending;return p?{kind:p.kind,live:p.live,pick:p.pick,asked:p.asked,lock:p.lock,turn:!!p.turnoOn}:null})()`;

// plays the story as a learner who touches the right thing every time, until stop(pg) is true; wrong: {n: which decision, option} touches the wrong option on the nth decision
async function autoplay(pg, stop, { maxMs = 400000, step = 70, wrongOn = null } = {}) {
  let t = 0, seen = 0, lastKey = '';
  for (;;) {
    if (await pg.evaluate(stop)) return t;
    const p = await pg.evaluate(PEND);
    if (p && p.asked && !p.turn) {
      const key = p.kind + p.live.join(',') + p.asked;
      let target = p.pick || p.live[0];
      if (wrongOn && p.kind === 'decide' && !wrongOn.done) { target = p.live.find(x => x !== p.pick) || target; wrongOn.done = true; }
      await pg.evaluate(k => Story.tapOn(k), target);
    }
    if (t >= maxMs) throw new Error('autoplay: no stop after ' + maxMs + ' ms: ' + stop);
    await pg.clock.runFor(step); t += step;
  }
}

export async function cuento(C) {
  const seed = 'vacio', story = 'la-lluvia';
  const q = `historia/index.html?cuento=${story}&a=ventana`;    // a=ventana: the first draw is fixed (the page's own switch)
  const S = (pg, state, steps, o = {}, url = q) => C.shot(pg, 'cuento', state, { url, seed, steps, orders: PLAY }, o);
  const st0 = [open(seed, q)];
  let pg = await C.page(seed);
  await ready(pg, C.base, q);
  await S(pg, 'inicio', st0);
  await tap(pg, '#go');
  const st1 = [...st0, 'touch the green start disc'];
  // a line with its caption (the narrator's lines show under the picture while they are spoken)
  await until(pg, `!!Story.cap`, 30000); await adv(pg, 70);
  await S(pg, 'subtitulo-del-narrador', [...st1, 'wait until the first line is being spoken']);
  // the big touch sign
  await until(pg, `!!Story.W.spot`, 60000); await adv(pg, 140);
  await S(pg, 'senal-de-tocar', [...st1, 'wait until the sign shows (everything else dims, a frame pulses, a hand taps)']);
  // a speech bubble: the first line of the coquí or of a person (La lluvia: "Abuela dice: ...")
  await autoplay(pg, `!!Story.bub`, { maxMs: 120000 }); await adv(pg, 70);
  await S(pg, 'globo-de-dialogo', [...st1, 'touch the right thing every time (the casa, the puerta, the ventana)', 'wait until a speech bubble shows']);
  // a wrong touch: the next decision, the wrong one
  const wrong = { done: false };
  await autoplay(pg, `Story.W.lost>=1&&!!Story.cap&&F-Story.W.flash>=3`, { maxMs: 200000, wrongOn: wrong }); await adv(pg, 70);
  const st2 = [...st1, 'touch the right thing every time', 'at the first decision ("Toca la ventana ya") touch the other thing (the puerta)'];
  await S(pg, 'toque-equivocado', [...st2, 'wait until the line that says what it was is spoken (the cloud, the thing at stake, has lost a step)']);
  await until(pg, `!!Story.W.spot`, 60000); await adv(pg, 140);
  await S(pg, 'senal-despues-del-error', [...st2, 'wait until the sign shows the right one']);
  // to the end
  await autoplay(pg, `document.getElementById('app').dataset.s==='end'`, { maxMs: 400000, step: 140 }); await adv(pg, 280);
  await S(pg, 'fin-con-un-error', [...st2, 'touch the right thing to the end']);
  // again, with no error
  await tap(pg, '#again');
  await autoplay(pg, `document.getElementById('app').dataset.s==='end'`, { maxMs: 400000, step: 140 }); await adv(pg, 280);
  await S(pg, 'fin-sin-errores', [...st2, 'touch the right thing to the end', 'touch "Play again"', 'touch the right thing every time to the end']);
  await pg.context().close();

  // ?txt=no: no caption, no bubble
  const qn = `historia/index.html?cuento=${story}&a=ventana&txt=no`;
  pg = await C.page(seed);
  await ready(pg, C.base, qn);
  await tap(pg, '#go');
  await until(pg, `Story.running&&Story.speaking>0`, 30000); await adv(pg, 70);
  await S(pg, 'sin-texto', [open(seed, qn), 'touch the green start disc', 'wait until the first line is being spoken (compare "subtitulo-del-narrador")'], {}, qn);
  await autoplay(pg, `!!Story.W.spot`, { maxMs: 60000 }); await adv(pg, 140);
  await S(pg, 'sin-texto-senal-de-tocar', [open(seed, qn), 'touch the green start disc', 'wait until the sign shows'], {}, qn);
  await pg.context().close();

  // told straight through (Listen on the shelf): nothing to touch
  const qo = `historia/index.html?cuento=${story}&oir=1`;
  pg = await C.page(seed);
  await ready(pg, C.base, qo);
  await tap(pg, '#go');
  await adv(pg, 12000, 140); await until(pg, `!!Story.cap`, 30000, 70);
  await S(pg, 'escuchar-en-marcha', [open(seed, qo), 'touch the green start disc', 'wait about 12 seconds'], {}, qo);
  await until(pg, `document.getElementById('app').dataset.s==='end'`, 400000, 140); await adv(pg, 280);
  await S(pg, 'escuchar-fin', [open(seed, qo), 'touch the green start disc', 'wait for the story to end by itself'], {}, qo);
  await pg.context().close();
}

// ------------------------------------------------------------------------------------------------------------------
// the answer bubbles: El bizcocho asks "¿Abres la puerta?" and the answers are two bubbles (the frog nodding, the frog shaking his head)
export async function burbujas(C) {
  const seed = 'vacio';
  for (const [story, state, why] of [['el-bizcocho', 'burbujas-si-no', 'the Say move: two answer bubbles, sí and no'], ['que-es-esto', 'burbujas-con-dibujos', 'answer bubbles with pictures in them']]) {
    const q = `historia/index.html?cuento=${story}`;
    const pg = await C.page(seed);
    await ready(pg, C.base, q);
    await tap(pg, '#go');
    await autoplay(pg, `!!(Story.W.resp&&Story.W.resp.length)&&!!Story.pending&&Story.pending.asked`, { maxMs: 300000 }); await adv(pg, 140);
    await C.shot(pg, 'cuento', state, { url: q, seed, steps: [open(seed, q), 'touch the green start disc', 'touch the right thing every time', 'wait until the answer bubbles show (' + why + ')'], orders: PLAY });
    await pg.context().close();
  }
}

// ------------------------------------------------------------------------------------------------------------------
// a speaking turn: the mic and its states. v=39 has no story marked for speaking turns yet (the real ones are marked later), so the page is given a copy of El bizcocho
// with four of its clips marked (as tools/habla_motor_check.py does), served in memory under the name zhabla; ?mic=stub: is the page's own recogniser stub, ?abiertas=todas opens every word.
export async function micro(C) {
  const seed = 'vacio';
  const T = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/el-bizcocho.json'), 'utf8'));
  T.id = 'zhabla'; T.title = 'El bizcocho'; T.next = null;
  const mk = (w, f) => [{ palabra: w, formas: [f] }];
  T.clips.cq_si.tu_turno = mk('sí', 'si'); T.clips.cq_no.tu_turno = mk('no', 'no'); T.clips.cq_si_gracias.tu_turno = mk('sí', 'si'); T.clips.cq_no_gracias.tu_turno = mk('no', 'no');
  const q = 'historia/index.html?cuento=zhabla&mic=stub:si|si|si|si&abiertas=todas';
  const routes = async (pg, ctx) => { await ctx.route('**/historia/cuentos/zhabla.json', r => r.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(T) })); };
  const note = 'the page is served a copy of El bizcocho in which the clips cq_si, cq_no, cq_si_gracias, cq_no_gracias carry "tu_turno" (see the README)';
  const steps = [open(seed, q) + '; ' + note, 'touch the green start disc', 'touch the right thing every time'];
  const mic = (pg, s) => pg.evaluate(s => Story.hab.mic === s, s);
  const S = (pg, state, st, o = {}) => C.shot(pg, 'cuento', state, { url: q, seed, steps: st, orders: PLAY }, o);
  for (const motion of [false, true]) {
    const pg = await C.page(seed, { routes, motion });
    await ready(pg, C.base, q);
    await tap(pg, '#go');
    const tag = motion ? '-con-movimiento' : '';
    const mo = motion ? { motion: true } : {};
    const st = motion ? steps.map((x, i) => i === 0 ? x + ', prefers-reduced-motion off, animations pinned at 0.6 s' : x) : steps;
    if (!motion) {
      await autoplay(pg, `Story.hab.mic==='dead'&&Story.hab.est==='dead'`, { maxMs: 200000 }); await adv(pg, 140);
      await S(pg, 'micro-gris-habla-la-app', [...st, 'wait until the first speaking turn starts: the mic is grey while the line plays, the coquí\'s bubble holds a mic'], mo);
    }
    await autoplay(pg, `Story.hab.est==='ready'`, { maxMs: 200000 }); await adv(pg, 140);
    if (!motion) await S(pg, 'micro-listo', [...st, 'wait until the mic is ready (green disc, white mic; the bubble holds a mic)'], mo);
    await tap(pg, '#mic');
    await until(pg, `Story.hab.est==='listening'`, 2000, 70); await adv(pg, 70);
    if (motion) await freeze(pg, 600);
    await S(pg, 'micro-escuchando' + tag, [...st, 'wait until the mic is ready', 'touch the mic'], mo);
    await until(pg, `Story.hab.est==='processing'`, 3000, 70);   // the dots show for 0.12 s of the stub's own time: no step after it
    if (motion) await freeze(pg, 300);
    await S(pg, 'micro-un-momento' + tag, [...st, 'wait until the mic is ready', 'touch the mic', 'wait: he has spoken, the app is thinking (three dots)'], mo);
    if (!motion) {
      await until(pg, `Story.hab.est==='ok'`, 3000, 70); await adv(pg, 70);
      await S(pg, 'micro-oido', [...st, 'wait until the mic is ready', 'touch the mic', 'wait: the stub hears "si"'], mo);
    }
    await pg.context().close();
  }
}
