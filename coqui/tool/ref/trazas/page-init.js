// Injected into historia/index.html before any page script runs (Playwright addInitScript). See README.md.
// The token SEED (between double underscores) below is replaced by the runner with the seed (1).
(() => {
  "use strict";
  const H = (window.__H = { draws: 0, drawsAtGo: null, now: 0, errors: [], canvases: [], sounds: [] });

  // 1. Math.random: Mulberry32 (the standard one, by Tommy Ettinger / bryc), seeded once at page start.
  function mulberry32(a) {
    return function () {
      let t = (a += 0x6d2b79f5);
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  const R = mulberry32(__SEED__);
  Math.random = function random() { H.draws++; return R(); };

  // 2. Time: a virtual clock. Nothing waits for real time; the runner moves the clock from one timer to the next.
  const real = { MessageChannel: window.MessageChannel };
  const timers = new Map();
  let seq = 0, nextId = 1;
  function add(fn, delay, args, rep) {
    if (typeof fn !== "function") { const code = String(fn); fn = () => (0, eval)(code); }
    let d = (Number(delay) || 0) | 0;   // WebIDL "long", as the browser converts it: fractions cut
    if (d < 0) d = 0;
    if (rep && d === 0) throw new Error("setInterval with 0 ms (not supported by the virtual clock)");
    const id = nextId++;
    timers.set(id, { id, at: H.now + d, seq: ++seq, fn, args, rep: rep ? d : 0 });
    return id;
  }
  window.setTimeout = function setTimeout(fn, d, ...a) { return add(fn, d, a, false); };
  window.setInterval = function setInterval(fn, d, ...a) { return add(fn, d, a, true); };
  window.clearTimeout = function clearTimeout(id) { timers.delete(id); };
  window.clearInterval = function clearInterval(id) { timers.delete(id); };
  window.requestAnimationFrame = function () { throw new Error("requestAnimationFrame is not supported by the virtual clock"); };
  H.next = () => { let b = null; for (const t of timers.values()) if (!b || t.at < b.at || (t.at === b.at && t.seq < b.seq)) b = t; return b; };
  H.fire = t => { H.now = t.at; if (t.rep) { t.at += t.rep; t.seq = ++seq; } else timers.delete(t.id); try { t.fn.apply(window, t.args); } catch (e) { H.errors.push("timer: " + (e && e.stack || e)); } };
  H.timerCount = () => timers.size;
  // a real macrotask, so every microtask queued so far runs before the next timer
  const mc = new real.MessageChannel(), waiters = [];
  mc.port1.onmessage = () => { const w = waiters.shift(); if (w) w(); };
  H.drain = () => new Promise(r => { waiters.push(r); mc.port2.postMessage(0); });
  performance.now = function now() { return H.now; };
  const BASE = Date.UTC(2026, 2, 2, 15, 0, 0);   // what Date.now and palabras.js's clock read at virtual time 0
  Date.now = function now() { return BASE + H.now; };
  Object.defineProperty(window, "__PAL_NOW", { get() { return BASE + H.now; }, configurable: true });

  // 3. Audio: a stand-in AudioContext. A clip "plays" in no time: its end is reported by a timer at +0 ms.
  class P { constructor() { this.value = 0; } setValueAtTime() { return this; } exponentialRampToValueAtTime() { return this; } linearRampToValueAtTime() { return this; } }
  class N { connect(n) { return n; } disconnect() {} }
  class Buf { constructor(ch, len, sr) { this.numberOfChannels = ch; this.length = len; this.sampleRate = sr; this.duration = len / sr; this._d = Array.from({ length: ch }, () => new Float32Array(len)); } getChannelData(i) { return this._d[i]; } }
  class Src extends N {
    constructor() { super(); this.buffer = null; this.loop = false; this.onended = null; this._s = 0; }
    start() { if (this.loop) return; setTimeout(() => { if (this._s) return; this._s = 1; if (this.onended) this.onended({}); }, 0); }
    stop() { this._s = 1; }
  }
  class AC {
    constructor() { this.sampleRate = 44100; this.destination = new N(); this.state = "running"; }
    get currentTime() { return H.now / 1000; }
    createGain() { const n = new N(); n.gain = new P(); return n; }
    createOscillator() { const n = new N(); n.frequency = new P(); n.type = "sine"; n.start = () => {}; n.stop = () => {}; return n; }
    createBiquadFilter() { const n = new N(); n.frequency = new P(); n.type = "lowpass"; return n; }
    createBufferSource() { return new Src(); }
    createBuffer(ch, len, sr) { return new Buf(ch, len, sr); }
    decodeAudioData(ab, ok, no) {
      const u = new Uint8Array(ab), good = u.length === 3 && u[0] === 73 && u[1] === 68 && u[2] === 51;   // the runner serves "ID3" for a clip that exists
      return Promise.resolve().then(() => { if (!good) { const e = new Error("decode"); if (no) no(e); throw e; } const b = new Buf(1, 4410, 44100); if (ok) ok(b); return b; });
    }
    resume() { this.state = "running"; return Promise.resolve(); }
    suspend() { this.state = "suspended"; return Promise.resolve(); }
  }
  window.AudioContext = AC; window.webkitAudioContext = AC;
  H.noiseBuffer = () => {   // juego.js's noise() buffer, filled here (xorshift32, seed 1) so Math.random is not drawn ~88,000 times
    const b = new Buf(1, 44100 * 2, 44100), d = b.getChannelData(0); let x = 1;
    for (let i = 0; i < d.length; i++) { x ^= x << 13; x ^= x >>> 17; x ^= x << 5; d[i] = ((x >>> 0) / 4294967296) * 2 - 1; }
    return b;
  };

  // 4. Things that would answer later in real time: the microphone permission query never answers (HAB.perm stays null).
  try { if (navigator.permissions) navigator.permissions.query = () => new Promise(() => {}); } catch (e) {}
  try { navigator.vibrate = () => true; } catch (e) {}

  // 5. Every canvas made, with the stack that made it (for the sprite dump).
  Error.stackTraceLimit = 80;
  const CV = (H.cv = new WeakMap());
  const ce = Document.prototype.createElement;
  Document.prototype.createElement = function createElement(tag) {
    const el = ce.apply(this, arguments);
    if (String(tag).toLowerCase() === "canvas") {
      const st = new Error().stack;
      CV.set(el, st);
      if (!/\bat spr \(/.test(st) && /\/escenas\//.test(st)) H.canvases.push({ el, st, t: H.now, atLoad: H.drawsAtGo === null });   // made by a scene outside the sprite cache
    }
    return el;
  };

  // 6. What each kit scene passes to KIT.escena (its list of things), caught as the scene's script is added.
  H.escena = {};
  const wrapped = new WeakSet(), ap = Node.prototype.appendChild;
  Node.prototype.appendChild = function appendChild(n) {
    if (n && n.tagName === "SCRIPT" && /\/escenas\//.test(n.src || "")) {
      let K = null;
      try { K = (0, eval)("typeof KIT!=='undefined'?KIT:null"); } catch (e) {}
      if (K && !wrapped.has(K)) { wrapped.add(K); const o = K.escena; K.escena = function escena(d) { H.escena[d.id] = d; return o.apply(this, arguments); }; }
    }
    return ap.apply(this, arguments);
  };

  window.addEventListener("error", e => H.errors.push("error: " + (e.message || e.error)));
  window.addEventListener("unhandledrejection", e => H.errors.push("unhandledrejection: " + (e.reason && (e.reason.stack || e.reason))));
})();
