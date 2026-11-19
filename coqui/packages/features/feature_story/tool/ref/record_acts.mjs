// What each scene did when a story called it, written down from the OLD page, so that the story runner can be checked
// against the recorded runs (coqui/ref/trazas/) with no scene of its own.
//
// The scene's acts (and its `stake`, and its `poke`) are the scenes' own code, ported later (orders 14 and 30b to 39b).
// The runner is this package's. To check the runner alone, a stand-in scene replays what the old scene did: for every
// call the story made on it, in order, how long it took, the sounds it made, the random numbers it drew, the camera
// moves it started, the story variables and the few world flags it changed. This script records exactly that, playing
// each story as `coqui/tool/ref/trazas/juega.mjs` does (the same page, the same injections, the same learner: it runs
// the files of that folder as they are), and checks that the run it watched is the committed one (the trace's
// sha256): watching changed nothing.
//
//   node coqui/packages/features/feature_story/tool/ref/record_acts.mjs [--only STORY] [--out DIR] [--jobs N]
//
// Writes DIR/<story>/<plan>.acts.json (default: coqui/packages/features/feature_story/test/fixtures/acts/). Needs Node 22
// and the pre-installed Playwright, as juega.mjs does. Nothing goes to the network.
import fs from "node:fs";
import path from "node:path";
import http from "node:http";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../../../../../..");
const HIST = path.join(ROOT, "historia");
const TRAZAS = path.join(ROOT, "coqui/tool/ref/trazas");
const REFDIR = path.join(ROOT, "coqui/ref/trazas");
const arg = (k, d) => { const i = process.argv.indexOf(k); return i >= 0 ? process.argv[i + 1] : d; };
const ONLY = arg("--only", null), JOBS = +arg("--jobs", 6);
const OUT = path.resolve(arg("--out", path.join(HERE, "../../test/fixtures/acts")));
const SEED = 1, THINK = 700, LIMIT = 4 * 3600e3, PLANS = ["right", "wrong", "alternate"];
const sha = b => crypto.createHash("sha256").update(b).digest("hex");

const INIT = fs.readFileSync(path.join(TRAZAS, "page-init.js"), "utf8").replace("__SEED__", String(SEED));
const DRIVE = fs.readFileSync(path.join(TRAZAS, "page-drive.js"), "utf8");

// Runs in the page after the story, its scene and its clips have loaded, before the drive script. It wraps what the story
// calls on the scene and what the scene calls on the game, to write down what happens inside each call. Nothing it
// wraps changes what it does.
const RECORD = `(() => {
  "use strict";
  const H = window.__H, REC = (window.__REC = { events: [], calls: [], active: 0, ctx: null, condKeys: window.__CONDKEYS || [] });
  // an event is the scene's when a scene file is on the stack that made it (async frames included): the scene's own code
  // or code of the game that the scene called. The rest is the game's own.
  const fromScene = () => (new Error().stack || "").includes("/escenas/");
  const ev = e => { e.t = H.now; e.sc = fromScene(); REC.events.push(e); return e; };
  // world flags a story's conditions or its end read, and that a scene's act may set
  const wkeys = () => ["heart", "marcas", ...REC.condKeys];
  const pick = (o, ks) => { const r = {}; for (const k of ks) if (o && k in o) { try { r[k] = JSON.parse(JSON.stringify(o[k])); } catch (e) {} } return r; };
  const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

  // Math.random: counted by page-init.js. Every draw is an event, tagged with who asked.
  const R = Math.random;
  Math.random = function random() { const v = R.call(Math); ev({ k: "rand", ctx: REC.ctx }); return v; };

  // sounds the scene makes: SFX effects and tone() called directly. (juego.js's own helpers, hopTo, make some too: inside a
  // call they are part of what the call did.)
  let inSfx = 0;
  for (const k of Object.keys(SFX)) { const f = SFX[k]; SFX[k] = function () { ev({ k: "sfx", a: [k, ...arguments], ctx: REC.ctx }); inSfx++; try { return f.apply(this, arguments); } finally { inSfx--; } }; }
  const _tone = tone;
  window.tone = function tone() { if (!inSfx) ev({ k: "tone", a: Array.from(arguments), ctx: REC.ctx }); return _tone.apply(this, arguments); };

  // the camera: a move a scene starts is part of its call
  const _camGo = camGo;
  window.camGo = function camGo(k, n) { if (fromScene()) ev({ k: "cam", a: [k, n === undefined ? null : n] }); return _camGo.apply(this, arguments); };

  // the frame: what a scene's draw does besides drawing is tagged, so it is never taken for a call's
  const flag = (obj, name) => { const f = obj[name]; if (typeof f !== "function") return; obj[name] = function () { const p = REC.ctx; REC.ctx = name; try { return f.apply(this, arguments); } finally { REC.ctx = p; } }; };
  flag(E, "draw"); flag(E, "hud");

  // a call the story makes on the scene: an act, the stake, a poke. Written with its time, the events inside it, and what it
  // changed in the story's variables (V) and in the flags above (W).
  function wrap(owner, key, name, args) {
    const f = owner[key];
    if (typeof f !== "function") return;
    owner[key] = function () {
      const top = REC.active === 0, prev = REC.ctx;
      const rec = { n: REC.calls.length, name: name(arguments), top, t0: H.now, t1: null, ev0: REC.events.length, args: args ? args(arguments) : null };
      REC.calls.push(rec);
      let v0 = null, w0 = null;
      if (top) { v0 = JSON.parse(JSON.stringify(V)); w0 = pick(W, wkeys()); }
      REC.active++; REC.ctx = "call";
      const done = () => { REC.active--; REC.ctx = prev; rec.t1 = H.now; rec.ev1 = REC.events.length;
        if (top) { const v1 = JSON.parse(JSON.stringify(V)), w1 = pick(W, wkeys()), dv = {}, dw = {};
          for (const k of new Set([...Object.keys(v0), ...Object.keys(v1)])) if (!same(v0[k], v1[k])) dv[k] = k in v1 ? v1[k] : null;
          for (const k of new Set([...Object.keys(w0), ...Object.keys(w1)])) if (!same(w0[k], w1[k])) dw[k] = k in w1 ? w1[k] : null;
          rec.v = dv; rec.w = dw; } };
      let r;
      try { r = f.apply(this, arguments); } catch (e) { done(); throw e; }
      if (r && typeof r.then === "function") { return r.then(x => { done(); return x; }, e => { done(); throw e; }); }
      done(); return r;
    };
  }
  const plain = o => { try { return JSON.parse(JSON.stringify(o, (k, v) => typeof v === "function" ? undefined : v)); } catch (e) { return null; } };
  for (const k of Object.keys(E.acts)) wrap(E.acts, k, () => "act:" + k, a => plain(a[0]));
  wrap(E, "stake", () => "stake", a => [a[0], a[1], a[2]]);
  wrap(E, "poke", () => "poke", a => [a[0]]);
  REC.start = { V: plain(V), W: pick(W, wkeys()) };
})();`;

function server() {
  const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".json": "application/json", ".css": "text/css", ".png": "image/png", ".woff2": "font/woff2", ".mp3": "audio/mpeg" };
  const s = http.createServer((req, res) => {
    const u = decodeURIComponent(new URL(req.url, "http://x").pathname), f = path.join(ROOT, u);
    if (!f.startsWith(ROOT + path.sep) || !fs.existsSync(f) || !fs.statSync(f).isFile()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { "Content-Type": types[path.extname(f)] || "application/octet-stream", "Cache-Control": "no-store" });
    fs.createReadStream(f).pipe(res);
  });
  return new Promise(r => s.listen(0, "127.0.0.1", () => r(s)));
}

// names a story's conditions read (`if`, `calc`'s `cond`): the flags of the world among them are recorded
function condKeys(story) {
  const ks = new Set();
  (function walk(x) {
    if (Array.isArray(x)) x.forEach(walk);
    else if (x && typeof x === "object") {
      for (const [k, v] of Object.entries(x)) {
        if ((k === "if" || k === "cond") && typeof v === "string") ks.add(v.replace(/^!/, "").split("=")[0]);
        walk(v);
      }
    }
  })(story);
  return [...ks];
}

function stringify(t) {   // the same layout as the traces: long lists one entry per line
  const LONG = ["clips", "sounds", "steps", "touches", "choices", "decisions"], head = {}, tail = {};
  for (const [k, v] of Object.entries(t)) (LONG.includes(k) ? tail : head)[k] = v;
  let s = JSON.stringify(head, null, 1).replace(/\n}$/, "");
  for (const k of LONG) if (k in tail) s += `,\n ${JSON.stringify(k)}: [` + (tail[k].length ? "\n" + tail[k].map(x => "  " + JSON.stringify(x)).join(",\n") + "\n ]" : "]");
  return s + "\n}\n";
}

async function playOne(browser, base, story, plan) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, timezoneId: "UTC", locale: "en-US" });
  try {
    await ctx.addInitScript(INIT);
    await ctx.route(/\/historia\/audio\/[^/]+\.mp3(\?.*)?$/, route => {
      const name = decodeURIComponent(new URL(route.request().url()).pathname.split("/").pop());
      return fs.existsSync(path.join(HIST, "audio", name)) ? route.fulfill({ status: 200, contentType: "audio/mpeg", body: "ID3" }) : route.fulfill({ status: 404, body: "" });
    });
    const page = await ctx.newPage();
    const query = `cuento=${story}&fast=1&rec=1&mic=stub:none&abiertas=todas`;
    await page.goto(`${base}/historia/index.html?${query}`);
    for (let i = 0; ; i++) {
      if (await page.evaluate("!!(window.Story&&Story.ready&&typeof voiceReady!=='undefined'&&voiceReady)")) break;
      if (i > 600) throw new Error("the page did not load the story in 30 s");
      await new Promise(r => setTimeout(r, 50));
    }
    await page.evaluate("voiceReady");
    const keys = condKeys(JSON.parse(fs.readFileSync(path.join(HIST, "cuentos", story + ".json"), "utf8")));
    await page.evaluate(`window.__CONDKEYS=${JSON.stringify(keys)}`);
    await page.evaluate(RECORD);
    await page.evaluate(DRIVE);
    const tr = await page.evaluate(cfg => window.__drive(cfg), { plan, think: THINK, limitMs: LIMIT, states: false });
    const rec = await page.evaluate(`(() => { const R = window.__REC; const end = { estado: E.estado ? E.estado(W) : null, marcas: W.marcas === undefined ? null : JSON.parse(JSON.stringify(W.marcas)), heart: W.heart || 0 }; return { start: R.start, events: R.events, calls: R.calls, end, keys: R.condKeys }; })()`);
    await ctx.close();
    return { tr, rec };
  } catch (e) { await ctx.close(); throw e; }
}

async function main() {
  const file = JSON.parse(fs.readFileSync(path.join(REFDIR, "runs.json"), "utf8"));
  const stories = [...new Set(file.runs.map(r => r.story))].filter(s => !ONLY || s === ONLY);
  const srv = await server(), base = `http://127.0.0.1:${srv.address().port}`;
  const browser = await chromium.launch();
  const jobs = [];
  for (const s of stories) for (const p of PLANS) jobs.push({ s, p });
  let next = 0, done = 0, bad = 0;
  async function worker() {
    for (;;) {
      const j = next++;
      if (j >= jobs.length) return;
      const { s, p } = jobs[j];
      let r;
      try { r = await playOne(browser, base, s, p); } catch (e) { console.log(`  ${s} ${p}: FAILED ${e}`); bad++; continue; }
      const { tr, rec } = r;
      // the run watched must be the committed one: its trace (written as juega.mjs writes it) has the committed sha256
      const committed = JSON.parse(fs.readFileSync(path.join(REFDIR, s, p + ".json"), "utf8"));
      const meta = file.runs.find(x => x.story === s && x.plan === p);
      const story = JSON.parse(fs.readFileSync(path.join(HIST, "cuentos", s + ".json"), "utf8"));
      const trace = { story: s, plan: p, seed: SEED, list: committed.list, place: committed.place, scene: story.scene, tipo: story.tipo || null, storySha256: committed.storySha256,
        page: "historia/index.html?" + `cuento=${s}&fast=1&rec=1&mic=stub:none&abiertas=todas`, think: THINK, end: tr.end, finished: tr.end === "finished", virtualMs: tr.virtualMs, voice: tr.voice, draws: tr.draws,
        decisions: tr.decisions, marks: tr.marks, lost: tr.lost, ending: tr.ending, estado: tr.estado, result: tr.result, listened: tr.listened, minutes: tr.minutes,
        choices: tr.choices, touches: tr.touches, speech: tr.speech, memory: tr.memory, clips: tr.clips, sounds: tr.sounds, steps: tr.steps, errors: tr.errors };
      const body = (({ plan, ...rest }) => rest)(trace);
      const same = sha(Buffer.from(stringify(trace))) === meta.sha256;
      if (!same) { bad++; console.log(`  ${s} ${p}: the watched run is NOT the committed trace`); }
      fs.mkdirSync(path.join(OUT, s), { recursive: true });
      fs.writeFileSync(path.join(OUT, s, p + ".acts.json"), JSON.stringify({ story: s, plan: p, traceSha256: meta.sha256, identicalToCommitted: same, ...rec }));
      console.log(`  [${++done}/${jobs.length}] ${s} ${p}: ${rec.calls.length} calls, ${rec.events.length} events${same ? "" : "  DIFFERS"}`);
    }
  }
  await Promise.all(Array.from({ length: Math.min(JOBS, jobs.length) }, worker));
  await browser.close();
  srv.close();
  console.log(`${done} of ${jobs.length} runs written to ${OUT}; ${bad} problems`);
  if (bad) process.exit(1);
}

main().catch(e => { console.error(e); process.exit(1); });
