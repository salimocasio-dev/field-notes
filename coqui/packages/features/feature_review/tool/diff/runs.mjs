// Plays the old Repaso (cual.js) and the old level check (nivel.js) in Node on a scenario, with a scripted learner,
// and returns everything the Dart port has to reproduce. See old_harness.mjs for what is real and what is stubbed.
//
// A scenario's touches are decided HERE, by a driver that looks at the old page's state (that the sentence has
// ended, that the right picture is shown ...). What the driver did is recorded as a list of {t, k} (virtual time and
// the picture touched, ignored touches too): the Dart test replays that list at the same virtual times and has to
// get the same session.

import { newOldPage } from './old_harness.mjs';

const SNAP_REVIEW = `
(() => {
  const last = (key) => { for (let i = __log.steps.length - 1; i >= 0; i--) if (__log.steps[i][key] !== undefined) return __log.steps[i][key]; return null; };
  const ask = (CQ.cola && CQ.cola[CQ.i]) ? CQ.cola[CQ.i].it.w + (CQ.cola[CQ.i].re ? "*" : "") : null;
  return {
    scr: __estado && __estado[0],
    i: CQ.run ? CQ.i : null,
    ask: CQ.run ? ask : null,
    pan: PAN ? PAN.map(p => ({right: p.right, sign: p.sign, dim: !!(p.dim || p.pre), pre: !!p.pre})) : null,
    ring: OPT.map(d => [...d.classes].sort()),
    cap: capEl.classList.contains("on") ? capEl.textContent : "",
    bar: last("n"),
  };
})()
`;

const SNAP_LEVEL = `
(() => {
  const last = (key) => { for (let i = __log.steps.length - 1; i >= 0; i--) if (__log.steps[i][key] !== undefined) return __log.steps[i][key]; return null; };
  return {
    scr: __estado && __estado[0],
    i: NQ.run ? NQ.i : null,
    pan: PAN ? PAN.map(p => ({right: p.right, cam: p.cam})) : null,
    ring: OPT.map(d => [...d.classes].sort()),
    cap: capEl.classList.contains("on") ? capEl.textContent : "",
    bar: last("n"),
    dots: last("dots"),
  };
})()
`;

async function pump(page, drive, snapExpr, trace) {
  const { vt } = page;
  const snap = () => {
    const s = page.get(snapExpr);
    const prev = trace[trace.length - 1];
    const key = JSON.stringify(s);
    if (!prev || prev.key !== key) trace.push({ t: vt.now, key, s });
  };
  await vt.settle();
  snap();
  for (let guard = 0; guard < 200000; guard++) {
    drive();
    const t = vt.next();
    if (!t) break;
    if (page.touchTimers.has(t.id)) {
      const same = vt.timers.filter((x) => x.at === t.at).length;
      if (same > 1) throw new Error(`a touch shares its time (${t.at}) with another timer: change the script`);
    }
    vt.fire();
    await vt.settle();
    snap();
  }
}

function tracePlain(trace) {
  return trace.map((x) => ({ t: x.t, ...x.s }));
}

function installDriver(page, touches) {
  const { vt } = page;
  page.touchTimers = new Set();
  const touch = (call, k, delay) => {
    const id = vt.setTimeout(() => {
      touches.push({ t: vt.now, k });
      page.run(`${call}(${k})`, 'touch');
    }, delay);
    page.touchTimers.add(id);
  };
  return touch;
}

/**
 * sc: { seed, now, store, query, clips, script: [{pick:'r'|'w'|'none', d, early, d2, other}] }
 * Per ask of the queue (the second asks too), the script says what the learner does.
 */
export async function runReview(sc) {
  const page = await newOldPage({ seed: sc.seed, now: sc.now, store: sc.store, query: sc.query, clips: sc.clips });
  const { vt, log } = page;
  page.run(
    'cualGrupo = function(f, titulo, sub, its) { if (!its.length) return; __log.groups.push({titulo, sub, words: its.map(x => x.w)}); }; cualGrid = function() {};',
    'groups',
  );
  await page.run('cualArranca()', 'arranca');
  await vt.settle();
  const start = page.get(`({
    lista: Cual.lista, practica: !!CQ.practica, pantalla: __pantalla, estado: __estado,
    dots: __log.steps.filter(s => s.dots !== undefined).map(s => s.dots)
  })`);
  const touches = [];
  const touch = installDriver(page, touches);
  const acts = new Map();
  const trace = [];
  const drive = () => {
    const st = page.get('({listo: Cual.listo, pan: Cual.pan, i: Cual.i, run: Cual.running})');
    if (!st.run || !st.pan) return;
    const i = st.i;
    const a = acts.get(i) || {};
    acts.set(i, a);
    const sc1 = (sc.script && sc.script[i]) || {};
    const rightIdx = st.pan.findIndex((p) => p.right);
    if (!st.listo && sc1.early && !a.early) {
      a.early = true;
      touch('Cual.toca', 0, 100);
      touch('Cual.toca', 1, 260);
      touch('Cual.toca', rightIdx, 410);
    }
    if (st.listo && !a.main) {
      a.main = true;
      const pick = sc1.pick || 'r';
      if (pick !== 'none') touch('Cual.toca', pick === 'r' ? rightIdx : 1 - rightIdx, sc1.d ?? 1013);
    }
    const sign = st.pan.findIndex((p) => p.sign);
    if (sign >= 0 && !a.signed) {
      a.signed = true;
      if (sc1.other) touch('Cual.toca', 1 - sign, 307);
      touch('Cual.toca', sign, sc1.d2 ?? 811);
    }
  };
  page.get('$("#go")').onclick();
  await pump(page, drive, SNAP_REVIEW, trace);
  const result = JSON.parse(
    JSON.stringify(
      page.get(`({
        hecho: Cual.hecho, rehecho: Cual.rehecho, tt: Cual.tt, fin: Cual.fin, cola: Cual.cola,
        pantalla: __pantalla, foot: __foot, estado: __estado,
        next: {text: $("#next").textContent, cls: [...$("#next").classes]}
      })`),
    ),
  );
  page.get('$("#next").onclick()');
  return {
    start,
    trace: tracePlain(trace),
    touches,
    calls: log.calls,
    plays: log.plays,
    stops: log.stops,
    tones: log.tones,
    steps: log.steps,
    groups: log.groups,
    exits: log.exits,
    result,
    draws: log.draws,
    nextDraw: page.nextDraw(),
    end: vt.now,
  };
}

/**
 * sc: { seed, now, store, query, clips, script: {plan: 'rrwr...' | undefined, storyUpTo: N | undefined, d, early} }
 * plan[i]: 'r' right or 'w' wrong on the i-th item asked (missing: right). storyUpTo: right on items of stories <= N.
 */
export async function runLevel(sc) {
  const page = await newOldPage({ seed: sc.seed, now: sc.now, store: sc.store, query: sc.query, clips: sc.clips, nivel: true });
  const { vt, log } = page;
  await page.run('nivelArranca()', 'arranca');
  await vt.settle();
  const start = page.get(`({
    pantalla: __pantalla, estado: __estado, nv: NV.length, nn: NN, paso: PASO,
    dots: __log.steps.filter(s => s.dots !== undefined).map(s => s.dots)
  })`);
  const touches = [];
  const touch = installDriver(page, touches);
  const acts = new Map();
  const trace = [];
  const script = sc.script || {};
  const drive = () => {
    const st = page.get('({listo: Nivel.listo, pan: Nivel.pan, i: Nivel.i, run: Nivel.running, cur: window.__cur})');
    if (!st.run || !st.pan) return;
    const i = st.i;
    const a = acts.get(i) || {};
    acts.set(i, a);
    const rightIdx = st.pan.findIndex((p) => p.right);
    if (!st.listo && script.early && !a.early) {
      a.early = true;
      touch('Nivel.toca', 0, 90);
      touch('Nivel.toca', 3, 210);
    }
    if (st.listo && !a.main) {
      a.main = true;
      let want = 'r';
      if (script.plan && i < script.plan.length) want = script.plan[i];
      if (script.storyUpTo !== undefined) want = st.cur <= script.storyUpTo ? 'r' : 'w';
      const tgt = want === 'r' ? rightIdx : (rightIdx + 1) % 4;
      const d = Array.isArray(script.d) ? script.d[i % script.d.length] : (script.d ?? 1013);
      touch('Nivel.toca', tgt, d);
    }
  };
  page.get('$("#go")').onclick();
  await pump(page, drive, SNAP_LEVEL, trace);
  const result = JSON.parse(
    JSON.stringify(
      page.get(`({
        hecho: Nivel.hecho, fin: Nivel.fin, pantalla: __pantalla, foot: __foot, estado: __estado,
        next: {text: $("#next").textContent, cls: [...$("#next").classes]}
      })`),
    ),
  );
  page.get('$("#next").onclick()');
  return {
    start,
    trace: tracePlain(trace),
    touches,
    calls: log.calls,
    plays: log.plays,
    stops: log.stops,
    tones: log.tones,
    steps: log.steps,
    exits: log.exits,
    result,
    draws: log.draws,
    nextDraw: page.nextDraw(),
    end: vt.now,
  };
}
