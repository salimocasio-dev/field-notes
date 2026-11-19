// The expected values for the sound tests: juego.js's own sound code, run in node on a recording stub
// of AudioContext. Every call the code makes on the context and its nodes is written down, in order.
//
//   node tool/juego_sonido.mjs          (in coqui/packages/core/coqui_platform)
//
// It reads historia/juego.js, takes the part headed "sound: effects, and the recorded voice" (up to the
// next heading) as it is, and runs it once per scenario in a fresh scope, so each scenario starts
// with no context, no master gain, no noise buffer and no rain. It writes test/fixtures/juego_sonido.json.
// A second run is byte-identical (nothing it writes depends on Math.random or the clock).
//
// The log's form, one array per call:
//   ["new", <name>, ...args]          a node or buffer made by the context (osc1, gain1, biquad1, source1, buffer1)
//   [<name>, <prop>, <value>]         a property set: type, buffer, loop
//   [<name>.<param>, "=", v]          an AudioParam's value set
//   [<name>.<param>, <method>, v, t]  setValueAtTime / exponentialRampToValueAtTime
//   [<name>, "connect", <name>]       destination is "destination"
//   [<name>, "start" | "stop", ...args]   exactly the arguments given
//   ["timer", ms]                     a setTimeout the code starts (the clip time limit)
//   ["resolved", value]               what playClip's promise gave
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const juego = join(here, "../../../../../historia/juego.js");
const out = join(here, "../test/fixtures/juego_sonido.json");

const src = readFileSync(juego, "utf8");
const a = src.indexOf("/* ---------- sound: effects, and the recorded voice ---------- */");
const b = src.indexOf("/* ---------- the words on screen");
if (a < 0 || b < 0 || b < a) throw new Error("the sound section of juego.js was not found");
const section = src.slice(a, b);

const NOW = 3.25; // the stub context's currentTime, in s
const RATE = 44100; // its sampleRate

function makeContext(log) {
  const count = {};
  const name = (k) => k + (count[k] = (count[k] || 0) + 1);
  const param = (owner, p, v) => {
    let value = v;
    return {
      get value() { return value; },
      set value(x) { value = x; log.push([owner + "." + p, "=", x]); },
      setValueAtTime(x, t) { log.push([owner + "." + p, "setValueAtTime", x, t]); },
      exponentialRampToValueAtTime(x, t) { log.push([owner + "." + p, "exponentialRampToValueAtTime", x, t]); },
    };
  };
  const node = (kind, extra) => {
    const n = name(kind);
    log.push(["new", n]);
    const o = {
      _name: n,
      connect(to) { log.push([n, "connect", to._name]); return to; },
      start(...args) { log.push([n, "start", ...args]); },
      stop(...args) { log.push([n, "stop", ...args]); },
    };
    for (const p of extra.params || []) o[p[0]] = param(n, p[0], p[1]);
    for (const p of extra.props || []) {
      let v;
      Object.defineProperty(o, p, {
        get() { return v; },
        set(x) { v = x; log.push([n, p, x && x._name ? x._name : x]); },
      });
    }
    return o;
  };
  return class StubAudioContext {
    constructor() { this.currentTime = NOW; this.sampleRate = RATE; this.destination = { _name: "destination" }; log.push(["new", "context"]); }
    createOscillator() { return node("osc", { params: [["frequency", 440]], props: ["type"] }); }
    createGain() { return node("gain", { params: [["gain", 1]] }); }
    createBiquadFilter() { return node("biquad", { params: [["frequency", 350]], props: ["type"] }); }
    createBufferSource() {
      const s = node("source", { props: ["buffer", "loop"] });
      s.onended = null;
      return s;
    }
    createBuffer(ch, len, rate) {
      const n = name("buffer");
      log.push(["new", n, ch, len, rate]);
      const d = new Float32Array(len);
      return { _name: n, duration: len / rate, sampleRate: rate, getChannelData() { return d; } };
    }
  };
}

// One fresh copy of the sound section. The names it uses from the rest of juego.js are stubbed here.
function fresh(log) {
  const timers = [];
  const window = { AudioContext: makeContext(log) };
  const setTimeout = (f, ms) => { log.push(["timer", ms]); timers.push(f); return timers.length; };
  const clearTimeout = () => {};
  const body = `
    let muted=false;const HAB={guard:false};const S={};const FAST=1;let runId=0;
    const sleep=()=>Promise.resolve();const partes=()=>({quien:""});const letras=()=>{};const letrasFin=()=>{};
    ${section}
    return {SFX,tone,playClip,hush,CLIPS,
      setVoice(v){VOICE=v;},setMuted(m){muted=m;},setGuard(g){HAB.guard=g;},
      toggleMuted(){muted=!muted;if(master)master.gain.value=muted?0:1;},   // juego.js line 417, the sound button
      live(){return [...live];}};`;
  const api = new Function("window", "setTimeout", "clearTimeout", "fetch", body)(window, setTimeout, clearTimeout, null);
  api.timers = timers;
  return api;
}

const scenarios = {};
const run = async (key, f) => {
  const log = [];
  const api = fresh(log);
  await f(api, log);
  scenarios[key] = log;
};
const settle = () => new Promise((r) => setImmediate(r));

// Every SFX name, as the scenes call it (no arguments).
const names = Object.keys(fresh([]).SFX);
for (const n of names) await run("SFX." + n, (api) => { api.SFX[n](); });
await run("SFX.trueno(0.6)", (api) => { api.SFX.trueno(0.6); });
await run("SFX.trueno then SFX.lluvia (one noise buffer)", (api) => { api.SFX.trueno(); api.SFX.lluvia(); });
await run("SFX.lluvia twice, SFX.calla twice", (api) => { api.SFX.lluvia(); api.SFX.lluvia(); api.SFX.calla(); api.SFX.calla(); });

// tone's own fallbacks: no type, no vol, a zero end frequency.
await run("tone(440,0,.1)", (api) => { api.tone(440, 0, 0.1); });
await run("tone(440,.25,.3,'sine',0,0)", (api) => { api.tone(440, 0.25, 0.3, "sine", 0, 0); });

// muted: tones are not made at all; the noise and the rain go through the master gain at 0.
await run("muted: SFX.right, SFX.trueno, SFX.lluvia", (api) => { api.setMuted(true); api.SFX.right(); api.SFX.trueno(); api.SFX.lluvia(); });
await run("SFX.lluvia, then the sound button twice", (api) => { api.SFX.lluvia(); api.toggleMuted(); api.toggleMuted(); });

// A clip from its start mark to its end mark (the marks of ab_bien_y_tu in marcas.json: 198, 4462).
const clip = (api, id, t0, t1) => { api.CLIPS[id] = { buf: { _name: "decoded_" + id }, t0, t1 }; api.setVoice(true); };
await run("playClip ab_bien_y_tu, to its end", async (api, log) => {
  clip(api, "ab_bien_y_tu", 198 / 1000, 4462 / 1000);
  const p = api.playClip("ab_bien_y_tu");
  api.live()[0].onended();
  log.push(["resolved", await p]);
});
await run("playClip of a clip shorter than 50 ms", async (api, log) => {
  clip(api, "x", 1 / 1000, 21 / 1000);
  const p = api.playClip("x");
  api.live()[0].onended();
  log.push(["resolved", await p]);
});
await run("playClip, then hush", async (api, log) => {
  clip(api, "ab_bien_y_tu", 198 / 1000, 4462 / 1000);
  const p = api.playClip("ab_bien_y_tu");
  api.hush();
  log.push(["resolved", await p]);
});
await run("playClip after a speaking turn (the time limit fires)", async (api, log) => {
  clip(api, "ab_bien_y_tu", 198 / 1000, 4462 / 1000);
  api.setGuard(true);
  const p = api.playClip("ab_bien_y_tu");
  api.timers[0]();
  log.push(["resolved", await p]);
});
await run("playClip of an unknown clip", async (api, log) => {
  api.setVoice(true);
  log.push(["resolved", await api.playClip("nada")]);
});
await run("playClip while muted, then the sound button", async (api, log) => {
  clip(api, "ab_bien_y_tu", 198 / 1000, 4462 / 1000);
  api.setMuted(true);
  const p = api.playClip("ab_bien_y_tu");
  api.toggleMuted();
  api.live()[0].onended();
  log.push(["resolved", await p]);
});
await settle();

const doc = {
  note: "Made by tool/juego_sonido.mjs from historia/juego.js. Do not edit by hand.",
  currentTime: NOW,
  sampleRate: RATE,
  sfx: names,
  scenarios,
};
const text = JSON.stringify(doc, null, 1) + "\n";
writeFileSync(out, text);
process.stdout.write(`${Object.keys(scenarios).length} scenarios, ${names.length} SFX names: ${names.join(" ")}\n`);
