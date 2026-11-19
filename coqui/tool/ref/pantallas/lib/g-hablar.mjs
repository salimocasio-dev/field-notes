// Hablar: the call with Danny on the page's own stub (?callstub=1), and the voice test page.
import { openApp, goTab, tap, untilReal, until, adv, freeze } from './drive.mjs';

const SPEAK = [24, 20];
const HQ = 'historia/app.html?tab=hablar&callstub=1&stub=manual';
const open = (seed, url) => `open ${url} with the stored progress "${seed}" (coqui.palabras.v1 = seeds/${seed}.json), the clock at 19 Nov 2026 12:00 (Puerto Rico)`;
const go = (pg, name) => pg.evaluate(n => CallStub.go(n), name);
const state = pg => pg.evaluate('Llamada.estado');

async function openCall(C, seed, query, motion = false) {
  const pg = await C.page(seed, { motion });
  await openApp(pg, C.base, query);
  await tap(pg, '#t-hablar .card.cc:not(.lk)');
  await untilReal(pg, 'Llamada.activo');
  await adv(pg, 100);
  return pg;
}

// ------------------------------------------------------------------------------------------------------------------
// The call, stepped by hand (?stub=manual): every state the stub can reach, in the order a call goes
export async function llamada(C) {
  const seed = 'todo', url = HQ;
  const S = (pg, state, steps, o = {}) => C.shot(pg, 'llamada', state, { url, seed, steps, orders: SPEAK }, o);
  const st0 = [open(seed, url), 'touch the green call disc of "Call Danny / La casa"'];
  const pg = await openCall(C, seed, '?tab=hablar&callstub=1&stub=manual');
  await S(pg, 'inicio', st0);
  await tap(pg, '#llam .ldisc');
  await untilReal(pg, `Llamada.estado==='connecting'&&!!CallStub.opts`); await adv(pg, 100);
  const st1 = [...st0, 'touch the call disc'];
  await S(pg, 'llamando', st1);
  await go(pg, 'connect'); await adv(pg, 100);
  await S(pg, 'conectado', [...st1, 'CallStub.go("connect")']);
  await go(pg, 'danny1'); await adv(pg, 2400);
  const st2 = [...st1, 'CallStub.go("connect")', 'CallStub.go("danny1") and 2.5 s'];
  await S(pg, 'danny-habla', st2);
  await go(pg, 'you1'); await adv(pg, 700);
  const st3 = [...st2, 'CallStub.go("you1") and 0.7 s'];
  await S(pg, 'tu-turno', st3);
  await go(pg, 'talk1'); await adv(pg, 1500);
  const st4 = [...st3, 'CallStub.go("talk1") and 1.5 s (the learner is speaking: the ring follows the microphone level)'];
  await S(pg, 'tu-turno-hablando', st4);
  await go(pg, 'quiet1'); await until(pg, `Llamada.estado==='proc'`, 5000); await adv(pg, 100);
  const st5 = [...st4, 'CallStub.go("quiet1") and wait 0.6 s of quiet'];
  await S(pg, 'un-momento', st5);
  await go(pg, 'heard1'); await adv(pg, 100);
  const st6 = [...st5, 'CallStub.go("heard1") (what the app heard: "Hola. Bien, gracias.")'];
  await S(pg, 'lo-que-oyo', st6);
  await adv(pg, 60000, 500);
  await go(pg, 'danny2'); await adv(pg, 900);
  const st7 = [...st6, 'wait 60 s', 'CallStub.go("danny2") and 0.9 s (Danny asks and shows a picture)'];
  await S(pg, 'danny-con-imagen', st7);
  await tap(pg, '#llam .lhelp'); await adv(pg, 100);
  await S(pg, 'ayuda', [...st7, 'touch "Help"']);
  await adv(pg, 5200);
  await go(pg, 'you2'); await go(pg, 'talk2'); await adv(pg, 800); await go(pg, 'quiet2'); await go(pg, 'heard2');
  await go(pg, 'you3'); await go(pg, 'talk3'); await adv(pg, 500); await go(pg, 'quiet3'); await adv(pg, 900); await go(pg, 'heard3');   // "Adiós.": the page sends "(fin)"
  await until(pg, `Llamada.estado==='done'`, 20000); await adv(pg, 100);
  await S(pg, 'fin-resumen', [...st7, 'touch "Help"', 'CallStub.go("you2"), ("talk2"), ("quiet2"), ("heard2" "Sí, quiero jugo."), ("you3"), ("talk3"), ("quiet3"), ("heard3" "Adiós.")', 'wait: the page sends "(fin)", the stub answers, the call ends']);
  await pg.context().close();
}

export async function llamadaUnaPalabra(C) {   // the X ends a live call: a summary with one word said
  const seed = 'todo', url = HQ;
  const pg = await openCall(C, seed, '?tab=hablar&callstub=1&stub=manual');
  await tap(pg, '#llam .ldisc');
  await untilReal(pg, `Llamada.estado==='connecting'&&!!CallStub.opts`);
  await go(pg, 'connect'); await go(pg, 'danny1'); await adv(pg, 1000); await go(pg, 'you1'); await adv(pg, 500);
  await pg.evaluate(() => CallStub.o.onMessage({ role: 'user', source: 'user', message: 'Hola.' })); await adv(pg, 100);   // the stub's own message callback, with one word of the place in it
  await tap(pg, '#llam .lx'); await until(pg, `Llamada.estado==='done'`, 5000); await adv(pg, 100);
  await C.shot(pg, 'llamada', 'fin-una-palabra', { url, seed, orders: SPEAK, steps: [open(seed, url), 'touch the green call disc of "Call Danny / La casa"', 'touch the call disc', 'CallStub.go("connect"), ("danny1"), ("you1")', 'the learner says "Hola." (CallStub.o.onMessage)', 'touch the X'] });
  await pg.context().close();
}

export async function llamadaErrores(C) {
  const seed = 'todo';
  const one = async (stub, state, expect, what) => {
    const q = `?tab=hablar&callstub=1&stub=${stub}`, url = 'historia/app.html' + q;
    const pg = await openCall(C, seed, q);
    await tap(pg, '#llam .ldisc');
    await until(pg, `Llamada.estado==='err'`, 5000); await adv(pg, 100);
    await C.shot(pg, 'llamada', state, { url, seed, orders: SPEAK, steps: [open(seed, url), 'touch the green call disc of "Call Danny / La casa"', 'touch the call disc', what] });
    await pg.context().close();
  };
  await one('mic', 'error-microfono', 'The microphone is off', 'the stub refuses the microphone (NotAllowedError)');
  await one('fail', 'error-no-empieza', 'The call did not start', 'the stub fails to start');
  // the voice library does not load (no stub, the network blocked): no call is placed
  const seedN = 'todo', url = 'historia/app.html?tab=hablar';
  const pg = await openCall(C, seedN, '?tab=hablar');
  await tap(pg, '#llam .ldisc');
  await untilReal(pg, `Llamada.estado==='err'`, 20000); await adv(pg, 100);
  await C.shot(pg, 'llamada', 'error-biblioteca-de-voz', { url, seed: seedN, orders: SPEAK, steps: [open(seedN, url), 'touch the green call disc of "Call Danny / La casa"', 'touch the call disc', 'the voice library (cdn.jsdelivr.net) cannot be loaded; no call is placed'] });
  await pg.context().close();
}

// the states whose look depends on motion, taken with motion on and every CSS animation pinned at 600 ms
export async function llamadaMovimiento(C) {
  const seed = 'todo', url = HQ;
  const pg = await openCall(C, seed, '?tab=hablar&callstub=1&stub=manual', true);
  const base = [open(seed, url) + ', prefers-reduced-motion off, animations pinned at 0.6 s', 'touch the green call disc of "Call Danny / La casa"', 'touch the call disc'];
  await tap(pg, '#llam .ldisc');
  await untilReal(pg, `Llamada.estado==='connecting'&&!!CallStub.opts`); await adv(pg, 100);
  await C.shot(pg, 'llamada', 'llamando-con-movimiento', { url, seed, orders: SPEAK, steps: base }, { motion: true, freeze: 450 });
  await go(pg, 'connect'); await go(pg, 'danny1'); await adv(pg, 1200);
  await C.shot(pg, 'llamada', 'danny-habla-con-ondas', { url, seed, orders: SPEAK, steps: [...base, 'CallStub.go("connect")', 'CallStub.go("danny1") and 1.2 s'] }, { motion: true, freeze: 600 });
  await go(pg, 'you1'); await go(pg, 'talk1'); await adv(pg, 700); await go(pg, 'quiet1'); await until(pg, `Llamada.estado==='proc'`, 5000); await adv(pg, 100);
  await C.shot(pg, 'llamada', 'un-momento-con-puntos', { url, seed, orders: SPEAK, steps: [...base, 'CallStub.go("connect"), ("danny1"), ("you1"), ("talk1"), ("quiet1")'] }, { motion: true, freeze: 300 });
  await pg.context().close();
}

// ------------------------------------------------------------------------------------------------------------------
// The voice test page. Twelve lines to say; the recogniser is the page's own stub (?mic=stub:...)
export async function pruebaDeVoz(C) {
  const results = ['hola abuela', 'none', 'no/nó', 'gracias', 'adios', 'la caza', 'puerta', 'ventana', 'quiero jugo por favor', 'me llamo Ana', 'como estas', 'uno dos tres'];
  const q = '?mic=stub:' + results.join('|'), url = 'historia/habla-prueba.html' + q;
  const S = (pg, state, steps, o = {}) => C.shot(pg, 'prueba-de-voz', state, { url, seed: null, steps, orders: SPEAK }, o);
  const fresh = `open ${url} with nothing stored, the clock at 19 Nov 2026 12:00 (Puerto Rico)`;
  const pg = await C.page(null);
  await pg.goto(`${C.base}/${url}`);
  await untilReal(pg, `document.getElementById('app').dataset.s==='ready'`);
  await adv(pg, 100);
  await S(pg, 'antes-linea-1', [fresh]);
  await tap(pg, '#mic');
  await until(pg, `document.getElementById('app').dataset.s==='listen'`, 2000); await adv(pg, 140);
  await S(pg, 'escuchando', [fresh, 'touch the mic disc']);
  await until(pg, `document.getElementById('app').dataset.s==='proc'`, 3000); await adv(pg, 70);
  await S(pg, 'un-momento', [fresh, 'touch the mic disc', 'wait: the speech ended']);
  await until(pg, `document.getElementById('app').dataset.s==='done'`, 3000); await adv(pg, 100);
  await S(pg, 'despues-oido-bien', [fresh, 'touch the mic disc', 'wait: the result "hola abuela" comes']);
  await tap(pg, '#next'); await adv(pg, 100);
  await tap(pg, '#mic');
  await until(pg, `document.getElementById('app').dataset.s==='done'`, 5000); await adv(pg, 100);
  await S(pg, 'despues-no-se-oyo', [fresh, 'touch the mic disc', 'touch the next arrow', 'touch the mic disc (line 2, "Sí": the stub hears nothing)']);
  for (let line = 3; line <= 12; line++) {
    await tap(pg, '#next'); await adv(pg, 100);
    await tap(pg, '#mic'); await until(pg, `document.getElementById('app').dataset.s==='done'`, 5000); await adv(pg, 100);
    if (line === 6) await S(pg, 'despues-oido-mal', [fresh, '(lines 1 to 5 as above)', 'touch the mic disc on line 6, "La casa": the stub hears "la caza"']);
  }
  await tap(pg, '#next'); await adv(pg, 100);
  await untilReal(pg, `document.getElementById('app').dataset.s==='end'`);
  const sFin = [fresh, 'say all twelve lines: touch the mic disc, then the next arrow, twelve times'];
  await S(pg, 'final', sFin);
  await pg.evaluate("{const f=document.getElementById('finscroll');f.scrollTop=f.scrollHeight;}"); await adv(pg, 100);
  await S(pg, 'final-al-final', [...sFin, 'scroll the list of lines to its end']);
  await pg.context().close();

  // the microphone cannot be used: ?mic=off
  const url2 = 'historia/habla-prueba.html?mic=off';
  const pg2 = await C.page(null);
  await pg2.goto(`${C.base}/${url2}`);
  await untilReal(pg2, `document.getElementById('app').dataset.s==='end'`); await adv(pg2, 100);
  await C.shot(pg2, 'prueba-de-voz', 'sin-microfono', { url: url2, seed: null, steps: [`open ${url2} with nothing stored`], orders: SPEAK });
  await pg2.context().close();

  // with motion on: the listening ring
  const pg3 = await C.page(null, { motion: true });
  await pg3.goto(`${C.base}/${url}`);
  await untilReal(pg3, `document.getElementById('app').dataset.s==='ready'`);
  await tap(pg3, '#mic');
  await until(pg3, `document.getElementById('app').dataset.s==='listen'`, 2000); await adv(pg3, 70);
  await C.shot(pg3, 'prueba-de-voz', 'escuchando-con-movimiento', { url, seed: null, steps: [fresh + ', prefers-reduced-motion off, animations pinned at 0.7 s', 'touch the mic disc'], orders: SPEAK }, { motion: true, freeze: 700 });
  await pg3.context().close();
}
