// ref/trazas: every story, picture story and routine played by machine on the OLD page (historia/index.html), three plans each.
// Also gathers the scene sprites for ref/sprites/escenas (see ../escenas_sprites/). See README.md in this folder.
//
//   node coqui/tool/ref/trazas/juega.mjs                       all 51 files x 3 plans; writes coqui/ref/trazas/ and coqui/ref/sprites/escenas/
//   node coqui/tool/ref/trazas/juega.mjs --only la-lluvia      one story, three plans, into a scratch folder (--out DIR, default: a temp folder); nothing in the repo changes
//   node coqui/tool/ref/trazas/juega.mjs --out DIR             everything, into DIR instead of the repo
//   options: --jobs N (pages at once, default 6)
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import http from "node:http";
import crypto from "node:crypto";
import vm from "node:vm";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { mergeSprites, writeSprites } from "../escenas_sprites/sprites.mjs";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const HERE = path.dirname(fileURLToPath(import.meta.url));
const arg0 = (k, d) => { const i = process.argv.indexOf(k); return i >= 0 ? process.argv[i + 1] : d; };
const ROOT = path.resolve(arg0("--root", path.resolve(HERE, "../../../..")));   // --root: another site folder holding historia/ (for testing the tool only)
const HIST = path.join(ROOT, "historia");
const SEED = 1, THINK = 700, LIMIT = 4 * 3600e3;
const PLANS = ["right", "wrong", "alternate"];
const arg = (k, d) => { const i = process.argv.indexOf(k); return i >= 0 ? process.argv[i + 1] : d; };
const ONLY = arg("--only", null), JOBS = +arg("--jobs", 6);
const SCRATCH = ONLY || arg("--out", null) !== null;   // --only or --out: write somewhere else, never into the repo
const OUT = SCRATCH ? path.resolve(arg("--out", null) || fs.mkdtempSync(path.join(os.tmpdir(), "trazas-"))) : path.join(ROOT, "coqui/ref/trazas");
const SPR_OUT = SCRATCH ? path.join(OUT, "_sprites") : path.join(ROOT, "coqui/ref/sprites/escenas");
const sha = b => crypto.createHash("sha256").update(b).digest("hex");

// The 51 files the story page plays: CURSO's cuentos, dibujos and haz, from curso.js as it is.
function course() {
  const ctx = {};
  vm.createContext(ctx);
  vm.runInContext(fs.readFileSync(path.join(HIST, "curso.js"), "utf8"), ctx);
  const C = vm.runInContext("CURSO", ctx), ids = [];
  for (const l of C.lugares) for (const k of ["cuentos", "dibujos", "haz"]) for (const id of l[k] || []) ids.push({ id, list: k, place: l.id });
  return { ids, cual: C.cual.slice() };
}

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

const INIT = fs.readFileSync(path.join(HERE, "page-init.js"), "utf8").replace("__SEED__", String(SEED));
const DRIVE = fs.readFileSync(path.join(HERE, "page-drive.js"), "utf8");

async function playOne(browser, base, story, plan) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, timezoneId: "UTC", locale: "en-US" });
  const consoleErrors = [];
  try {
    await ctx.addInitScript(INIT);
    // a clip that exists answers "ID3" (the stand-in AudioContext decodes it as a short silent buffer); one that does not, 404
    await ctx.route(/\/historia\/audio\/[^/]+\.mp3(\?.*)?$/, route => {
      const name = decodeURIComponent(new URL(route.request().url()).pathname.split("/").pop());
      return fs.existsSync(path.join(HIST, "audio", name)) ? route.fulfill({ status: 200, contentType: "audio/mpeg", body: "ID3" }) : route.fulfill({ status: 404, body: "" });
    });
    const page = await ctx.newPage();
    page.on("pageerror", e => consoleErrors.push("pageerror: " + e.message));
    page.on("console", m => { if (m.type() === "error") consoleErrors.push("console: " + m.text()); });
    const query = `cuento=${story}&fast=1&rec=1&mic=stub:none&abiertas=todas`;
    await page.goto(`${base}/historia/index.html?${query}`);
    // wait (real time) for the story, its scene and the clip list; Playwright's waitForFunction would use the page's own timers, which are virtual here
    for (let i = 0; ; i++) {
      if (await page.evaluate("!!(window.Story&&Story.ready&&typeof voiceReady!=='undefined'&&voiceReady)")) break;
      if (i > 600) throw new Error("the page did not load the story in 30 s");
      await new Promise(r => setTimeout(r, 50));
    }
    await page.evaluate("voiceReady");
    await page.evaluate(DRIVE);
    const tr = await page.evaluate(cfg => window.__drive(cfg), { plan, think: THINK, limitMs: LIMIT });
    const spr = await page.evaluate("window.__sprites()");
    return { tr, spr, page, ctx, query, consoleErrors };
  } catch (e) {
    await ctx.close();
    throw e;
  }
}

async function main() {
  const { ids, cual } = course();
  const folder = fs.readdirSync(path.join(HIST, "cuentos")).filter(f => f.endsWith(".json")).map(f => f.slice(0, -5)).sort();
  const listed = new Set(ids.map(x => x.id)), cualSet = new Set(cual);
  const missing = ids.filter(x => !folder.includes(x.id)).map(x => x.id), unlisted = folder.filter(f => !listed.has(f) && !cualSet.has(f));
  let todo = ONLY ? ids.filter(x => x.id === ONLY) : ids;
  if (ONLY && !todo.length && folder.includes(ONLY)) todo = [{ id: ONLY, list: "none", place: null }];   // a file in no list (for testing the tool)
  if (!todo.length) throw new Error("no such story in curso.js: " + ONLY);
  console.log(`curso.js: ${ids.length} files to play (${ids.filter(x => x.list === "cuentos").length} stories, ${ids.filter(x => x.list === "dibujos").length} picture stories, ${ids.filter(x => x.list === "haz").length} routines); ${cual.length} review sets not played; folder: ${folder.length} files; missing: ${missing.length}; in the folder but in no list: ${unlisted.length}`);
  const srv = await server(), base = `http://127.0.0.1:${srv.address().port}`;
  const browser = await chromium.launch();
  if (!ONLY) { fs.rmSync(OUT, { recursive: true, force: true }); fs.rmSync(SPR_OUT, { recursive: true, force: true }); }   // a full run replaces everything
  fs.mkdirSync(OUT, { recursive: true });
  const jobs = [];
  for (const s of todo) for (const p of PLANS) jobs.push({ s, p });
  const results = new Array(jobs.length), SPR = new Array(jobs.length), PIX = new Map();   // SPR: each run's sprite cache (metadata); PIX: sha256 -> RGBA bytes
  let next = 0, done = 0;
  async function worker() {
    for (;;) {
      const j = next++;
      if (j >= jobs.length) return;
      const { s, p } = jobs[j], file = JSON.parse(fs.readFileSync(path.join(HIST, "cuentos", s.id + ".json"), "utf8"));
      let r;
      try { r = await playOne(browser, base, s.id, p); }
      catch (e) { results[j] = { story: s.id, plan: p, failed: String(e && e.stack || e) }; console.log(`  ${s.id} ${p}: FAILED ${e}`); continue; }
      const { tr, spr, page, ctx, query, consoleErrors } = r;
      // the scene's own sprites: the metadata of every run is kept and merged in job order at the end (so the order runs finish in does not matter);
      // the pixels of each distinct picture are fetched once
      const scene = file.scene, own = `escenas/${scene}.js`;
      for (const x of spr.cache) if (x.callerFile === own && x.sha256 && !PIX.has(x.sha256)) PIX.set(x.sha256, Buffer.from(await page.evaluate(k => window.__pixels(k), x.key), "base64"));
      for (let i = 0; i < spr.outside.length; i++) { const x = spr.outside[i]; if (x.file === own && !PIX.has(x.sha256)) PIX.set(x.sha256, Buffer.from(await page.evaluate(n => window.__pixels(null, n), i), "base64")); }
      SPR[j] = { scene, run: `${s.id}/${p}`, cache: spr.cache, outside: spr.outside.filter(x => x.file === own) };
      await ctx.close();
      const trace = {
        story: s.id, plan: p, seed: SEED, list: s.list, place: s.place, scene, tipo: file.tipo || null,
        storySha256: sha(fs.readFileSync(path.join(HIST, "cuentos", s.id + ".json"))),
        page: "historia/index.html?" + query, think: THINK,
        end: tr.end, finished: tr.end === "finished", virtualMs: tr.virtualMs, voice: tr.voice, draws: tr.draws,
        decisions: tr.decisions, marks: tr.marks, lost: tr.lost, ending: tr.ending, estado: tr.estado,
        result: tr.result, listened: tr.listened, minutes: tr.minutes,
        choices: tr.choices, touches: tr.touches, speech: tr.speech, memory: tr.memory,
        clips: tr.clips, sounds: tr.sounds, steps: tr.steps,
        errors: tr.errors.concat(consoleErrors),
      };
      results[j] = trace;
      console.log(`  [${++done}/${jobs.length}] ${s.id} ${p}: ${tr.end}, ${tr.decisions.length} decisions, lost ${tr.lost}, ${tr.clips.length} clips, ${tr.steps.length} steps, ${tr.draws.total} draws${trace.errors.length ? ", ERRORS " + trace.errors.length : ""}`);
    }
  }
  await Promise.all(Array.from({ length: Math.min(JOBS, jobs.length) }, worker));
  await browser.close();
  srv.close();

  // the traces, and runs.json
  const runs = [];
  const body = t => { const { plan, ...rest } = t; return JSON.stringify(rest); };
  for (let j = 0; j < jobs.length; j++) {
    const t = results[j], { s, p } = jobs[j], rel = `${s.id}/${p}.json`;
    fs.mkdirSync(path.join(OUT, s.id), { recursive: true });
    if (t.failed) { runs.push({ story: s.id, plan: p, file: null, failed: t.failed }); continue; }
    const buf = Buffer.from(stringify(t));
    fs.writeFileSync(path.join(OUT, rel), buf);
    runs.push({ story: s.id, plan: p, list: s.list, scene: t.scene, file: rel, sha256: sha(buf), bytes: buf.length, end: t.end, finished: t.finished, decisions: t.decisions.length, choices: t.choices.length, lost: t.lost, draws: t.draws.total, errors: t.errors.length });
  }
  for (const s of todo) {
    const by = {};
    for (let j = 0; j < jobs.length; j++) if (jobs[j].s === s && !results[j].failed) by[jobs[j].p] = results[j];
    const flags = [];
    if (by.right && by.alternate && body(by.right) === body(by.alternate)) flags.push("right-equals-alternate");
    if (by.right && by.wrong && body(by.right) === body(by.wrong)) flags.push("right-equals-wrong");
    for (const r of runs) if (r.story === s.id && flags.length) r.identical = flags;
  }
  const index = {
    made: ONLY ? `node coqui/tool/ref/trazas/juega.mjs --only ${ONLY}` : "node coqui/tool/ref/trazas/juega.mjs",
    seed: SEED, plans: PLANS, think: THINK, page: "historia/index.html", juegoSha256: sha(fs.readFileSync(path.join(HIST, "juego.js"))),
    count: { played: todo.length, runs: runs.length, finished: runs.filter(r => r.finished).length, notFinished: runs.filter(r => !r.finished).map(r => `${r.story}/${r.plan}: ${r.end || r.failed}`) },
    course: { files: ids.length, stories: ids.filter(x => x.list === "cuentos").length, pictureStories: ids.filter(x => x.list === "dibujos").length, routines: ids.filter(x => x.list === "haz").length, reviewSetsNotPlayed: cual, folderFiles: folder.length, missingFromFolder: missing, inFolderInNoList: unlisted },
    runs,
  };
  fs.writeFileSync(path.join(OUT, "runs.json"), JSON.stringify(index, null, 1) + "\n");
  writeSprites(mergeSprites(SPR), PIX, SPR_OUT, HIST);
  console.log(`${runs.filter(r => r.finished).length}/${runs.length} runs finished; written to ${OUT}`);
}

function stringify(t) {   // the long lists one entry per line, the rest pretty
  const LONG = ["clips", "sounds", "steps", "touches", "choices", "decisions"], head = {}, tail = {};
  for (const [k, v] of Object.entries(t)) (LONG.includes(k) ? tail : head)[k] = v;
  let s = JSON.stringify(head, null, 1).replace(/\n}$/, "");
  for (const k of LONG) if (k in tail) s += `,\n ${JSON.stringify(k)}: [` + (tail[k].length ? "\n" + tail[k].map(x => "  " + JSON.stringify(x)).join(",\n") + "\n ]" : "]");
  return s + "\n}\n";
}

main().catch(e => { console.error(e); process.exit(1); });
