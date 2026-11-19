// Run in historia/index.html after the story, its scene and its clips have loaded (global code: it sees juego.js's
// top-level names). It wraps a few of juego.js's functions to watch them, then plays the story by rule. See README.md.
(() => {
  "use strict";
  const H = window.__H;

  // ---------- watching ----------
  const PATHS = new WeakMap();
  (function walk(x, p) {
    if (!x || typeof x !== "object" || PATHS.has(x)) return;
    PATHS.set(x, p);
    if (Array.isArray(x)) x.forEach((v, i) => walk(v, p + "." + i));
    else for (const k of Object.keys(x)) walk(x[k], p ? p + "." + k : k);
  })(S, "");
  const T = { steps: [], clips: [], sounds: [], choices: [], touches: [], speech: [], result: null, listened: null, minutes: null };
  const kindOf = st => typeof st === "string" ? "line" : !st || typeof st !== "object" ? "bad" : st.say ? "say" : st.wait != null ? "wait" : st.cam ? "cam" : st.dots != null ? "dots" : st.set ? "set" :
    st.if ? "if" : st.act ? "act" : st.ask ? "ask" : st.decide ? "decide" : st.elige ? "elige" : st.draw ? "draw" : st.reparte ? "reparte" : st.calc ? "calc" : st.recuerda ? "recuerda" : st.cost ? "cost" : "unknown";
  const CH = [];   // the ask / decide / elige steps running now, innermost last
  let nextPath = null;
  const _pasos = pasos;
  window.pasos = async function pasos(list) {   // the same loop as juego.js's pasos, which also tells paso where each step sits in the story file
    if (list != null && !Array.isArray(list)) return _pasos(list);
    const L = list || [], base = PATHS.has(L) ? PATHS.get(L) : null;
    for (let i = 0; i < L.length; i++) { nextPath = base === null ? null : base + "." + i; await paso(L[i]); }
  };
  const _paso = paso;
  window.paso = function paso(st) {
    const path = (st && typeof st === "object" && PATHS.has(st) ? PATHS.get(st) : null) || nextPath;
    nextPath = null;
    const k = kindOf(st), r = { n: T.steps.length, t: H.now, path, kind: k };
    if (k === "line") r.id = sub(st);
    else if (k === "say") r.id = sub(st.say);
    else if (k === "act") r.act = st.act;
    T.steps.push(r);
    if (k !== "ask" && k !== "decide" && k !== "elige") return _paso(st);
    const c = { kind: k, st, path, esperas: 0 };
    CH.push(c);   // before the call: ask, decide and elige reach espera() synchronously
    const pop = () => { const i = CH.indexOf(c); if (i >= 0) CH.splice(i, 1); };
    let p;
    try { p = _paso(st); } catch (e) { pop(); throw e; }
    Promise.resolve(p).then(pop, pop);
    return p;
  };
  let esperas = 0;
  const _espera = espera;
  window.espera = function espera(liveSet, lead, line, o) {
    const top = CH.length ? CH[CH.length - 1] : null, p = _espera.apply(this, arguments), me = pending;
    if (me && !me.__i) {
      let role = "scene";
      if (top) role = top.kind === "decide" && me.kind !== "decide" ? "retry" : top.esperas++ === 0 ? "first" : "again";
      me.__i = { n: esperas++, role, choice: top, line: line || null };
    }
    return p;
  };
  let inSay = 0;
  const clip = (id, via) => {
    const L = LINES[id] || null, e = { t: H.now, id, via };
    if (L && L.who) e.who = L.who;
    const q = L ? partes(id).quien : null;
    if (q) e.talker = q;
    if (!(VOICE && CLIPS[id])) e.voice = false;
    T.clips.push(e);
  };
  const _say = say;
  window.say = function say(id, gap) { clip(id, "say"); inSay++; try { return _say(id, gap); } finally { inSay--; } };
  const _playClip = playClip;
  window.playClip = function playClip(id) { if (!inSay) clip(id, "clip"); return _playClip(id); };
  let inSfx = 0;
  for (const k of Object.keys(SFX)) { const f = SFX[k]; SFX[k] = function () { T.sounds.push(arguments.length ? [k, ...arguments] : k); inSfx++; try { return f.apply(this, arguments); } finally { inSfx--; } }; }
  const _tone = tone;
  window.tone = function tone() { if (!inSfx) T.sounds.push(["tone", ...arguments]); return _tone.apply(this, arguments); };
  const _cuento = PAL.cuento, _oido = PAL.oido, _minutos = PAL.minutos, _responde = PAL.responde;
  PAL.cuento = function (St, log) {
    T.result = { id: St.id, focusWords: St.focus_words || [], backAgain: St.back_again || [], lost: St._lost || 0, log: JSON.parse(JSON.stringify(log || [])) };
    return _cuento.apply(this, arguments);
  };
  PAL.oido = function (id) { T.listened = id; return _oido.apply(this, arguments); };
  PAL.minutos = function (m) { T.minutes = m; return _minutos.apply(this, arguments); };
  PAL.responde = function (w, sk, ok, ms, intro) { T.speech.push({ t: H.now, w, sk, ok, ms, intro }); return _responde.apply(this, arguments); };
  // juego.js's noise() fills its buffer with ~88,000 Math.random draws the first time thunder or rain sounds. It is filled here instead.
  NOISE = H.noiseBuffer();
  // A touch on a named thing: tap() exactly as juego.js has it, except that what was touched is given instead of found by the hit test.
  const src = tap.toString(), from = "what=(W.resp||[]).find(k=>inb(respBox(k)))||E.hit(x,y,W)";
  if (src.indexOf(from) < 0) throw new Error("juego.js tap() is not as expected; the forced touch cannot be made");
  (0, eval)(src.replace(from, "what=(window.__FORCE!==undefined?window.__FORCE:((W.resp||[]).find(k=>inb(respBox(k)))||E.hit(x,y,W)))"));
  const touch = (k, why, pn) => {
    const rb = respBox(k), h = !rb && E.handAt && E.handAt[k];   // the point Story.tapOn(k) would touch
    let x, y;
    if (h) { x = h[0]; y = h[1] + 3; } else { const b = bx(k); x = b[0] + b[2] / 2; y = b[1] + b[3] / 2; }
    T.touches.push({ t: H.now, what: k, why, espera: pn && pn.__i ? pn.__i.n : null, x, y });
    window.__FORCE = k;
    try { tap(x, y); } finally { window.__FORCE = undefined; }
  };

  // ---------- the rule: what is wrong ----------
  const FRENTE = [   // El frente has no list of things: its hit() order, each with the condition hit() tests
    ["abuela", W => !!W.ab], ["palma_pequena", W => !!W.escondite], ["casa_pequena", W => !!W.escondite], ["palma_grande", W => !!W.escondite], ["casa_grande", W => !!W.escondite],
    ["pajaro", W => !!(W.ave && W.ave.mode !== "none")], ["bizcocho", W => W.plato != null], ["nube", W => !!(W.storm && W.nube)],
    ["puerta", () => true], ["ventana", () => true], ["casa", () => true], ["sol", W => !W.storm], ["palma", () => true]];
  function sceneList() {
    if (S.scene === "frente") return FRENTE.filter(e => e[1](W)).map(e => e[0]);
    const d = H.escena[S.scene];
    if (!d) throw new Error("no thing list for scene " + S.scene);
    return d.cosas.filter(t => (!t.si || t.si(W)) && (typeof t.box === "function" ? t.box(W) : t.box)).map(t => t.id);
  }
  const counts = (pn, w) => { if (pn.loose && (w === "puerta" || w === "ventana")) w = "casa"; if (pn.alias && pn.alias[w]) w = pn.alias[w]; return pn.live.includes(w); };   // as tap() maps a touch
  function wrongPoke(pn) {   // an ask: the first thing in the scene's list that is not the asked one and that the touch would not count as it
    return sceneList().find(k => k !== "coqui" && !counts(pn, k) && !(W.resp || []).includes(k)) || null;
  }
  function wrongOption(pn, st) {   // a decide: the first live thing that is not the right one, not also right ("vale") and not free ("gratis")
    const vale = (st.vale || []).map(sub), gratis = Object.keys(st.gratis || {});
    return pn.live.find(k => k !== pn.pick && !vale.includes(k) && !gratis.includes(k) && !(pn.alias && (pn.alias[k] === pn.pick || vale.includes(pn.alias[k])))) || null;
  }
  let letters = 0;
  const turnLetter = new WeakMap();   // HAB.log entry -> its letter (not written on the entry: HAB.log is recorded as it is)
  const letterFor = plan => { const k = letters++; return plan === "right" ? "r" : plan === "wrong" ? "w" : k % 2 === 0 ? "r" : "w"; };

  // ---------- the learner ----------
  function learner(plan) {
    if (HAB.est === "ready" && HAB.cur) {   // a speaking turn waits for the mic
      const reg = HAB.log[HAB.log.length - 1], pn = pending && !pending.done ? pending : null;
      const key = HAB.cur;
      return { key, act() {
        if (!turnLetter.has(reg)) turnLetter.set(reg, pn && pn.__i ? (pn.__i.letter || (pn.__i.letter = letterFor(plan))) : letterFor(plan));
        const letter = turnLetter.get(reg);
        let ans = "none";
        if (letter === "r" || reg.tipo === "elige") {
          let id = reg.id;
          if (reg.tipo === "elige") { const ids = reg.id.split("|"); id = ids[letter === "r" ? 0 : Math.min(1, ids.length - 1)]; }
          const Tm = habMarca(id);
          ans = Tm ? Tm.map(x => x.formas[0]).join(" ") : "none";
        }
        T.speech.push({ t: H.now, turn: reg.id, tipo: reg.tipo, letter, says: ans });
        STUB[HAB.si] = ans;
        MICB.click();
      } };
    }
    const pn = pending;
    if (!pn || pn.done || !pn.asked || !("tEnd" in pn) || pn.busy || speaking || habOcupado()) return null;
    const I = pn.__i || (pn.__i = { n: esperas++, role: "scene", choice: null });
    if (I.role === "first" && !I.letter) {
      I.letter = letterFor(plan);
      T.choices.push(I.rec = { espera: I.n, t: H.now, kind: I.choice.kind, step: I.choice.path, letter: I.letter, live: pn.live.slice(), pick: pn.pick || null, touched: [] });
    }
    let k, why;
    if (I.role !== "first") { k = I.role === "retry" && pn.pick && pn.live.includes(pn.pick) ? pn.pick : pn.live[0]; why = I.role; }
    else if (I.choice.kind === "ask") {
      if (I.letter === "w" && !I.poked) {   // I.poked is set when the touch is made, so the plan stays the same until then
        const c = wrongPoke(pn);
        if (c) { k = c; why = "wrong-poke"; } else { I.rec.noWrong = true; k = pn.live[0]; why = "right"; }
      } else { k = pn.live[0]; why = "right"; }
    } else if (I.choice.kind === "decide") {
      if (I.letter === "w") { const c = wrongOption(pn, I.choice.st); if (c) { k = c; why = "wrong"; } else { I.rec.noWrong = true; k = pn.pick; why = "right"; } }
      else { k = pn.pick || pn.live[0]; why = "right"; }
    } else { k = I.letter === "w" && pn.live.length > 1 ? pn.live[1] : pn.live[0]; why = I.letter === "w" ? "second" : "first"; }
    const key = pn.__key || (pn.__key = {});
    return { key: key[k + "|" + why] || (key[k + "|" + why] = {}), act() { if (I.rec) I.rec.touched.push(k); if (why === "wrong-poke") I.poked = k; touch(k, why, pn); } };
  }

  window.__drive = async function drive(cfg) {
    const THINK = cfg.think, LIMIT = cfg.limitMs;
    H.drawsAtGo = H.draws;
    document.querySelector("#go").click();
    let started = false, plan = null, end = null, iters = 0;
    for (;;) {
      await H.drain();
      if (H.errors.length) { end = "page error"; break; }
      if (running) started = true; else if (started) { end = "finished"; break; }
      const want = learner(cfg.plan);
      if (want) { if (!plan || plan.key !== want.key) plan = { key: want.key, at: H.now + THINK, act: want.act }; else plan.act = want.act; } else plan = null;
      const t = H.next();
      if (plan && (!t || t.at > plan.at)) { H.now = plan.at; const a = plan.act; plan = null; a(); continue; }
      if (!t) { end = "stuck: nothing scheduled and nothing to touch"; break; }
      if (t.at > LIMIT) { end = "stuck: still running at the time limit"; break; }
      H.fire(t);
      if (++iters > 5e6) { end = "stuck: too many timers"; break; }
    }
    const ending = { lost: W.lost, stakeSteps: S.stake && S.stake.steps != null ? S.stake.steps : null, heart: W.heart || 0, final: T.steps.filter(s => s.path && /^final\b/.test(s.path)).map(s => s.path), screen: (document.querySelector("#app") || { dataset: {} }).dataset.s || null };
    return {
      end, virtualMs: H.now, draws: { atLoad: H.drawsAtGo, total: H.draws }, voice: VOICE,
      decisions: JSON.parse(JSON.stringify(LOG)), marks: W.marcas === undefined ? null : JSON.parse(JSON.stringify(W.marcas)), lost: W.lost,
      estado: E.estado ? E.estado(W) : null, ending, result: T.result, listened: T.listened, minutes: T.minutes,
      choices: T.choices, touches: T.touches, steps: T.steps, clips: T.clips, sounds: T.sounds,
      speech: { turns: JSON.parse(JSON.stringify(HAB.log)), events: T.speech },
      memory: JSON.parse(JSON.stringify(MEM)), errors: H.errors.slice(),
    };
  };

  // ---------- sprites: every entry of engine.js's cache SP, with the file that asked for it ----------
  const frames = st => st.split("\n").slice(1).map(l => { const m = /^\s*at (?:(.*?) \()?(.*?):(\d+):(\d+)\)?$/.exec(l); return m ? { fn: m[1] || "", file: m[2].replace(/^.*\/historia\//, "").replace(/\?.*$/, ""), line: +m[3], col: +m[4] } : null; }).filter(Boolean);
  window.__sprites = async function sprites() {
    const out = [];
    const one = async (cv, extra) => {
      const w = cv.width, h = cv.height, d = cv.getContext("2d").getImageData(0, 0, w, h).data;
      const sha = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", d))).map(b => b.toString(16).padStart(2, "0")).join("");
      return Object.assign({ w, h, sha256: sha }, extra);
    };
    for (const key of Object.keys(SP)) {
      const cv = SP[key], st = H.cv.get(cv);
      if (!(cv instanceof HTMLCanvasElement)) { out.push({ key, type: String(cv && cv.constructor && cv.constructor.name) }); continue; }
      const f = st ? frames(st) : [], i = f.findIndex(x => x.fn === "spr" && x.file === "engine.js");
      const caller = i >= 0 && f[i + 1] ? f[i + 1] : null, maker = i > 0 ? f[i - 1] : null;
      out.push(await one(cv, { key, caller: caller ? `${caller.file}:${caller.line}:${caller.col}${caller.fn ? " " + caller.fn : ""}` : null, callerFile: caller ? caller.file : null,
        maker: maker ? `${maker.file}:${maker.line}:${maker.col}${maker.fn ? " " + maker.fn : ""}` : null }));
    }
    const other = [];
    for (const c of H.canvases) {
      const f = frames(c.st).filter(x => /^escenas\//.test(x.file)), top = f[0];
      other.push(await one(c.el, { made: top ? `${top.file}:${top.line}:${top.col}${top.fn ? " " + top.fn : ""}` : null, file: top ? top.file : null, atLoad: c.atLoad, t: c.t }));
    }
    return { cache: out, outside: other };
  };
  window.__pixels = (key, idx) => {
    const cv = key != null ? SP[key] : H.canvases[idx].el, d = cv.getContext("2d").getImageData(0, 0, cv.width, cv.height).data;
    let s = ""; for (let i = 0; i < d.length; i += 8192) s += String.fromCharCode.apply(null, d.subarray(i, i + 8192));
    return btoa(s);
  };
})();
