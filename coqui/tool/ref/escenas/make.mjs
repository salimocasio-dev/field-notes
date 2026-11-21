// ref/escenas: for each of the twelve old scenes, what it holds and where, and frames of every state it reaches. See README.md in
// coqui/ref/escenas/. The old site is only read and run: nothing under historia/ changes.
//
//   node coqui/tool/ref/escenas/make.mjs                    plays every story (order 05's juega.mjs --states, into a temp folder), then writes coqui/ref/escenas/
//   node coqui/tool/ref/escenas/make.mjs --work DIR         reuse DIR/trazas and DIR/states from an earlier run (juega.mjs --out DIR/trazas --states DIR/states)
//   node coqui/tool/ref/escenas/make.mjs --only balcon      one scene (into the repo folder of that scene only)
//   node coqui/tool/ref/escenas/make.mjs --out DIR          write into DIR instead of coqui/ref/escenas
//   node coqui/tool/ref/escenas/make.mjs --without A,B --out DIR   as if the story and review files A, B were not in historia/cuentos/: their runs, their
//                                                           pairs and the level items that ask their words are left out, and so is a scene left with no
//                                                           story (for proving that what a new file adds is all that changes; never into the repo)
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import http from "node:http";
import crypto from "node:crypto";
import vm from "node:vm";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { png } from "./png.mjs";
import { readme } from "./readme.mjs";
import { functions, positions as staticPositions, writes as staticWrites, blank } from "./static.mjs";
import { SCENES, BG, CHARS, CHARKEYS, PROPKEYS, SIGNKEYS, MEANING, FRENTE_HIT, FRENTE_HIT_RECT, FRENTE_CONSTS } from "./config.mjs";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../../../..");
const HIST = path.join(ROOT, "historia");
const arg = (k, d) => { const i = process.argv.indexOf(k); return i >= 0 ? process.argv[i + 1] : d; };
const OUT = path.resolve(arg("--out", path.join(ROOT, "coqui/ref/escenas")));
const ONLY = arg("--only", null);
const WITHOUT = (arg("--without", "") || "").split(",").filter(Boolean);
if (WITHOUT.length && !process.argv.includes("--out")) throw new Error("--without writes a partial picture of the site: it needs --out DIR");
const PLANS = ["right", "wrong", "alternate"];
const TICK = 70, F_PAIR = 8;   // F for a review or level picture: a fixed frame (the frog's eyes open, the even half of every two-frame pose)
const sha = b => crypto.createHash("sha256").update(b).digest("hex");
const J = v => JSON.stringify(v);
const rel = p => path.relative(ROOT, p);
const sortObj = o => Object.fromEntries(Object.keys(o).sort().map(k => [k, o[k]]));
const ranges = ns => { const a = [...new Set(ns)].sort((x, y) => x - y), o = []; for (let i = 0; i < a.length; i++) { let j = i; while (j + 1 < a.length && a[j + 1] === a[j] + 1) j++; o.push(j > i ? `${a[i]}-${a[j]}` : `${a[i]}`); i = j; } return o.join(","); };
const slug = w => w.normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/ñ/g, "n").replace(/[^A-Za-z0-9]+/g, "_").replace(/^_|_$/g, "").toLowerCase() || "x";
const lineOf = (text, s) => { const i = text.indexOf(s); return i < 0 ? null : text.slice(0, i).split("\n").length; };
function writeJSON(f, v) { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, JSON.stringify(v, null, 1) + "\n"); }

// ---------- 1. the story runs: W after every step (order 05's player, used as it is) ----------
function runs() {
  let work = arg("--work", null);
  if (!work) {
    work = fs.mkdtempSync(path.join(os.tmpdir(), "escenas-"));
    console.log(`playing every story with coqui/tool/ref/trazas/juega.mjs --states (into ${work}) ...`);
    const r = spawnSync(process.execPath, [path.join(ROOT, "coqui/tool/ref/trazas/juega.mjs"), "--out", path.join(work, "trazas"), "--states", path.join(work, "states")], { stdio: ["ignore", "ignore", "inherit"] });
    if (r.status !== 0) throw new Error("juega.mjs failed");
  }
  return { trz: path.join(work, "trazas"), st: path.join(work, "states"), temp: !arg("--work", null) ? work : null };
}

// ---------- 2. the files: stories, review pairs ----------
const FILES = fs.readdirSync(path.join(HIST, "cuentos")).filter(f => f.endsWith(".json") && !WITHOUT.includes(f.slice(0, -5))).sort().map(f => ({ id: f.slice(0, -5), j: JSON.parse(fs.readFileSync(path.join(HIST, "cuentos", f), "utf8")) }));
const cualOf = w => FILES.find(f => f.j.tipo === "cual" && (f.j.items || []).some(x => x.w === w));
const storiesOf = id => FILES.filter(f => f.j.scene === id && f.j.tipo !== "cual").map(f => f.id);
const SRC = Object.fromEntries([...SCENES, "kit"].map(id => [id, fs.readFileSync(path.join(HIST, "escenas", id + ".js"), "utf8")]));
const SRCL = Object.fromEntries(Object.entries(SRC).map(([k, v]) => [k, v.split("\n")]));
const codeAt = loc => { const m = /^(?:escenas\/)?(\w+)\.js:(\d+)$/.exec(loc || ""); if (!m || !SRCL[m[1]]) return null; const s = SRCL[m[1]][+m[2] - 1] || ""; return s.trim().length > 220 ? s.trim().slice(0, 220) + " …" : s.trim(); };

// ---------- 3. the browser ----------
function server() {
  const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".json": "application/json", ".css": "text/css", ".png": "image/png", ".woff2": "font/woff2" };
  const s = http.createServer((req, res) => {
    const u = decodeURIComponent(new URL(req.url, "http://x").pathname), f = path.join(ROOT, u);
    if (!f.startsWith(ROOT + path.sep) || !fs.existsSync(f) || !fs.statSync(f).isFile()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { "Content-Type": types[path.extname(f)] || "application/octet-stream", "Cache-Control": "no-store" });
    fs.createReadStream(f).pipe(res);
  });
  return new Promise(r => s.listen(0, "127.0.0.1", () => r(s)));
}
const INIT = fs.readFileSync(path.join(ROOT, "coqui/tool/ref/trazas/page-init.js"), "utf8").replace("__SEED__", "1");
const PAGE = fs.readFileSync(path.join(HERE, "page-escena.js"), "utf8");
async function open(browser, base, url, ready) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, timezoneId: "UTC", locale: "en-US" });
  await ctx.addInitScript(INIT);
  await ctx.route(/\/historia\/audio\/[^/]+\.mp3(\?.*)?$/, route => {   // as ref/trazas: a clip that exists answers "ID3" (page-init.js's stand-in decodes it as silence), one that does not, 404
    const name = decodeURIComponent(new URL(route.request().url()).pathname.split("/").pop());
    return fs.existsSync(path.join(HIST, "audio", name)) ? route.fulfill({ status: 200, contentType: "audio/mpeg", body: "ID3" }) : route.fulfill({ status: 404, body: "" });
  });
  const page = await ctx.newPage(), errors = [];
  page.on("pageerror", e => errors.push(e.message));
  await page.goto(base + url);
  for (let i = 0; ; i++) { if (await page.evaluate(ready)) break; if (i > 600) throw new Error("not ready: " + url); await new Promise(r => setTimeout(r, 50)); }
  await page.evaluate(PAGE);
  const cfg = { bgFns: {}, charFns: {}, charLines: {}, keepFns: {} };
  for (const s of SCENES) { cfg.bgFns[s] = BG[s].fns; cfg.charFns[s] = CHARS[s].fns; cfg.charLines[s] = CHARS[s].lines; cfg.keepFns[s] = CHARS[s].keep; }
  await page.evaluate(c => { Object.assign(__E6.cfg, c); __E6.resetSprites(); }, cfg);
  return { page, ctx, errors };
}
const PIX = new Map();   // sha256 of RGBA -> {w, h, buf}
function keepPix(p) { if (p && p.b64 && !PIX.has(p.sha)) PIX.set(p.sha, { w: p.w, h: p.h, buf: Buffer.from(p.b64, "base64") }); return p ? p.sha : null; }

// ---------- 4. review pairs and level-check pictures, on cual.html and nivel.html as they are ----------
async function pairsAndLevel(browser, base) {
  const P = await open(browser, base, "/historia/cual.html", "typeof CU!=='undefined'&&!!CU&&!!CU.items&&CU.items.length>0");
  const items = (await P.page.evaluate("__E6.pairs()")).filter(it => cualOf(it.w));   // (--without: the pairs of a file left out are dropped)
  for (const it of items) {
    it.file = cualOf(it.w).id;
    for (const k of ["si", "no"]) { const r = await P.page.evaluate(([w, k]) => __E6.pairW(w, k), [it.w, k]); it[k].scene = r.scene; it[k].W = r.W; it[k].png = keepPix(await P.page.evaluate(([w, k, f]) => __E6.pairPic(w, k, f), [it.w, k, F_PAIR])); }
  }
  const sayText = Object.fromEntries(FILES.filter(f => f.j.tipo === "cual").flatMap(f => Object.entries(f.j.clips || {}).map(([k, v]) => [k, v.text])));
  if (P.errors.length) throw new Error("cual.html: " + P.errors.join("; "));
  await P.ctx.close();
  const N = await open(browser, base, "/historia/nivel.html", "typeof CU!=='undefined'&&!!CU&&!!CU.items&&CU.items.length>0&&typeof NV!=='undefined'");
  const nv0 = await N.page.evaluate("__E6.nivel()");
  for (let i = 0; i < nv0.length; i++) nv0[i].at = i;   // its place in the page's NV
  const nv = nv0.filter(q => q.p.every(p => cualOf(p[0])));   // (--without: an item with a picture of a file left out is dropped)
  for (const q of nv) for (let j = 0; j < q.p.length; j++) { const r = await N.page.evaluate(([i, j, f]) => __E6.nivelPic(i, j, f), [q.at, j, F_PAIR]); q.p[j] = { pair: q.p[j][0], side: q.p[j][1], x: q.p[j][2] == null ? null : q.p[j][2], crop: r.crop, scene: r.scene, png: keepPix(r.pic) }; }
  for (const q of nv) delete q.at;
  if (N.errors.length) throw new Error("nivel.html: " + N.errors.join("; "));
  await N.ctx.close();
  const nivelJson = JSON.parse(fs.readFileSync(path.join(HIST, "datos/nivel.json"), "utf8"));
  const same = J(nivelJson) === J(nv.map(q => ({ w: q.w, s: q.s, p: q.p.map(p => p.x == null ? [p.pair, p.side] : [p.pair, p.side, p.x]) })));
  return { items, nv, sayText, nivelJsonSame: same };
}

// ---------- 5. one scene ----------
async function scene(browser, base, id, PL, work) {
  const stories = storiesOf(id), text = SRC[id];
  const host = stories.find(s => !FILES.find(f => f.id === s).j.cam) || stories[0];   // a story that does not change the scene's views
  const S = await open(browser, base, `/historia/index.html?cuento=${host}&fast=1`, "!!(window.Story&&Story.ready&&typeof voiceReady!=='undefined'&&voiceReady&&E)");
  const ev = (fn, a) => S.page.evaluate(fn, a);
  const desc = await ev(id => __E6.desc(id), id);
  const CAM = desc.CAM;
  // the fresh state of each story: the scene's fresh(S), and juego.js's fresh() around it
  const fresh = {};
  for (const s of stories) { const j = FILES.find(f => f.id === s).j; fresh[s] = { scene: await ev(([id, j]) => __E6.fresh(id, j), [id, j]), page: await ev(([id, j]) => __E6.freshFull(id, j), [id, j]) }; }

  // every W: after each step of each run, and each review picture that this scene draws
  const ST = [];   // {src:{story,plan,n,path,kind,act}|{pair,side}, W, cam, F}
  const traces = {};
  for (const s of stories) for (const p of PLANS) {
    const tr = JSON.parse(fs.readFileSync(path.join(work.trz, s, p + ".json"), "utf8")); traces[s + "/" + p] = tr;
    const L = fs.readFileSync(path.join(work.st, s, p + ".states.jsonl"), "utf8").trim().split("\n").map(x => JSON.parse(x));
    for (const l of L) { let f = Math.floor(l.t / TICK); while (f % 47 < 2) f++;   // the frame counter at that time (juego.js loop every TICK from 0); never a blink (F%47<2)
      const step = l.n == null ? null : tr.steps[l.n];
      ST.push({ src: { story: s, plan: p, n: l.n, path: l.path, kind: l.kind, act: step && step.act || null }, W: l.W, cam: l.cam, F: f, t: l.t }); }
  }
  const pairsHere = PL.items.filter(it => it.si.scene === id || it.no.scene === id || FILES.find(f => f.id === it.file).j.scene === id);
  for (const it of PL.items) for (const k of ["si", "no"]) if (it[k].scene === id) ST.push({ src: { pair: it.w, side: k, file: it.file }, W: it[k].W, cam: CAM.wide, F: F_PAIR });

  // each distinct W once: its things, its picture's background, what its draw reads, its canvas calls, its hit test
  const U = new Map();
  for (const x of ST) {
    const k = J(x.W) + "|" + J(x.cam) + (id === "frente" && x.W.ave && x.W.ave.mode === "circle" ? "|" + x.F : "");
    if (!U.has(k)) U.set(k, { W: x.W, cam: x.cam, F: x.F, srcs: [] });
    U.get(k).srcs.push(x.src); x.u = U.get(k);
  }
  console.log(`  ${id}: ${ST.length} states read, ${U.size} distinct W`);
  const items = {}, clipsAll = {}, readers = { draw: new Set(), hud: new Set(), hit: new Set() }, hitSeen = {};
  for (const u of U.values()) {
    const wj = J(u.W);
    u.m = await ev(([id, w, cm, f]) => __E6.measure(id, w, cm, f), [id, wj, u.cam, u.F]);
    const fr = await ev(o => __E6.frame(o), { id, w: wj, cm: u.cam, f: u.F, variant: "full", views: [{ name: "wide", rect: CAM.wide }], record: true, pixels: false });
    u.bg = fr.bgKeys; u.reads = fr.reads; u.runs = fr.runs;
    fr.reads.forEach(k => readers.draw.add(k)); (fr.hudReads || []).forEach(k => readers.hud.add(k));
    for (const t of Object.values(u.m.things)) for (const r of [...t.siReads, ...t.boxReads, ...t.handReads]) readers.hit.add(r.split(".")[0]);
    for (const [k, mt] of Object.entries(fr.meta)) { if (!items[k]) items[k] = { ...mt, boxes: new Map(), allSites: new Set() }; mt.sites.forEach(x => items[k].allSites.add(x)); }
    for (const r of fr.runs) { const it = items[r.k], bk = J(r.box); if (!it.boxes.has(bk)) it.boxes.set(bk, new Set()); it.boxes.get(bk).add(u); }
    for (const c of fr.clips) { const ck = c.site + J(c.shapes.map(s => s.user)); (clipsAll[ck] = clipsAll[ck] || { ...c, n: 0 }).n++; }
    u.hit = await ev(([id, w, cm, f]) => __E6.hitGrid(id, w, cm, f, 3), [id, wj, u.cam, u.F]);
    for (const [k, v] of Object.entries(u.hit)) { const h = hitSeen[k] || (hitSeen[k] = { n: 0, states: 0, at: v.at }); h.n += v.n; h.states++; }
  }
  // states: the same background, the same things shown with the same boxes, the same set keys -> one state
  const thingIds = Object.keys([...U.values()][0].m.things);
  const setKeys = [...readers.draw].filter(k => !CHARKEYS[id].includes(k) && !SIGNKEYS.includes(k) && !PROPKEYS[id].includes(k)).sort();
  // a thing whose box and visibility read only character or moving-prop keys moves (abuela, a person, a duck, a ball): it does not separate states
  const thingReads = t => { const r = new Set(); for (const u of U.values()) for (const x of [...u.m.things[t].boxReads, ...u.m.things[t].siReads]) r.add(x.split(".")[0]); return [...r]; };
  const charThings = thingIds.filter(t => (id === "frente" && ["pajaro", "coqui"].includes(t)) || (() => { const r = thingReads(t); return r.length > 0 && r.every(k => CHARKEYS[id].includes(k) || PROPKEYS[id].includes(k)); })());
  const setThings = thingIds.filter(t => !charThings.includes(t));
  const boxOf = (u, t) => { const x = u.m.things[t]; return x.si === true ? x.box : null; };
  const groups = new Map();
  for (const x of ST) {
    const u = x.u, sig = J([u.bg, setThings.map(t => boxOf(u, t)), setKeys.map(k => [k, u.W[k] === undefined ? null : u.W[k]])]);
    if (!groups.has(sig)) groups.set(sig, { rep: u, repSrc: x.src, members: [], us: new Set() });
    const g = groups.get(sig); g.members.push(x); g.us.add(u); u.group = g;
  }
  const G = [...groups.values()];
  G.forEach((g, i) => { g.id = "s" + String(i).padStart(3, "0"); });
  // check: the background keys of config.mjs decide the background sprite
  const bgCheck = new Map(); let bgOk = true;
  for (const u of U.values()) { const k = J(BG[id].keys.map(b => u.W[b] === undefined ? null : u.W[b])); if (bgCheck.has(k) && bgCheck.get(k) !== J(u.bg)) bgOk = false; bgCheck.set(k, J(u.bg)); }

  // frames: every state, full and without characters, at 240 x 216 and in every view; the background alone once per background
  const viewList = Object.entries(CAM).map(([name, rect]) => ({ name, rect }));
  const storyCams = stories.filter(s => FILES.find(f => f.id === s).j.cam).flatMap(s => Object.entries(FILES.find(f => f.id === s).j.cam).map(([name, rect]) => ({ name: name + "@" + s, rect, story: s })));
  const fdir = path.join(OUT, id, "frames"); fs.rmSync(fdir, { recursive: true, force: true }); fs.mkdirSync(fdir, { recursive: true });
  const written = new Map();   // sha -> file name (the first state that made it)
  const save = (shaK, name) => { if (written.has(shaK)) return written.get(shaK); const p = PIX.get(shaK); fs.writeFileSync(path.join(fdir, name), png(p.w, p.h, p.buf)); written.set(shaK, name); return name; };
  const index = { scene: id, F: "each state is drawn at the frame counter it had in the run: floor(t/70), moved on past a blink; review pictures at F=" + F_PAIR, views: viewList.concat(storyCams).map(v => ({ name: v.name, rect: v.rect })), states: [] };
  const bgFiles = {};
  for (const g of G) {
    const u = g.rep, wj = J(u.W), vs = viewList.concat(storyCams.filter(v => g.members.some(m => m.src.story === v.story)));
    const files = {};
    for (const variant of ["full", "nochar"]) {
      const r = await ev(o => __E6.frame(o), { id, w: wj, cm: u.cam, f: u.F, variant, views: vs, record: false, pixels: true });
      files[variant] = save(keepPix(r.pic), `${g.id}.${variant}.png`);
      for (const v of vs) files[variant + "." + v.name] = save(keepPix(r.views[v.name]), `${g.id}.${variant}.${v.name}.png`);
    }
    const bk = u.bg.join("+") || "none";
    if (!bgFiles[bk]) { const r = await ev(o => __E6.frame(o), { id, w: wj, cm: u.cam, f: u.F, variant: "bg", views: [], record: false, pixels: true }); bgFiles[bk] = save(keepPix(r.pic), `bg.${slug(bk)}.png`); }
    files.bg = bgFiles[bk];
    g.files = files;
  }
  // the states, with what reaches them
  const reach = g => { const by = {}, pairs = [];
    for (const m of g.members) { if (m.src.pair) pairs.push(`${m.src.file}:${m.src.pair}.${m.src.side}`); else (by[m.src.story + "/" + m.src.plan] = by[m.src.story + "/" + m.src.plan] || []).push(m.src.n == null ? -1 : m.src.n); }
    return { steps: Object.fromEntries(Object.entries(by).map(([k, ns]) => [k, ns.includes(-1) ? ["start"].concat(ranges(ns.filter(n => n >= 0)) || []).filter(Boolean).join(",") : ranges(ns)])), pairs: [...new Set(pairs)] }; };
  const kitBird = u => u.m.extra.pajaro ? { pajaro: u.m.extra.pajaro.box } : {};
  const keyVals = u => Object.fromEntries([...new Set([...BG[id].keys, ...setKeys])].sort().map(k => [k, u.W[k] === undefined ? null : u.W[k]]));
  for (const g of G) {
    const u = g.rep;
    index.states.push({ id: g.id, files: g.files, background: u.bg, keys: keyVals(u), things: Object.fromEntries(setThings.map(t => [t, boxOf(u, t)])),
      characters: Object.assign({ coqui: u.m.extra.coqui || null }, kitBird(u), Object.fromEntries(charThings.filter(t => t !== "coqui").map(t => [t, boxOf(u, t)]))),
      drawnFrom: g.repSrc.pair ? `${g.repSrc.file}:${g.repSrc.pair}.${g.repSrc.side}` : `${g.repSrc.story}/${g.repSrc.plan}@${g.repSrc.n == null ? "start" : g.repSrc.n}`, cam: u.cam, F: u.F, distinctW: g.us.size, reachedBy: reach(g) });
  }
  writeJSON(path.join(fdir, "index.json"), index);

  // ---------- inventory ----------
  const thingsInv = {};
  for (const t of thingIds) {
    const per = new Map();
    for (const g of G) { const u = g.rep, x = u.m.things[t], k = J({ si: x.si, box: x.box }); if (!per.has(k)) per.set(k, { si: x.si, box: x.box, states: [] }); per.get(k).states.push(g.id); }
    const reads = new Set(), sir = new Set(), hr = new Set(); for (const u of U.values()) { u.m.things[t].boxReads.forEach(r => reads.add(r)); u.m.things[t].siReads.forEach(r => sir.add(r)); u.m.things[t].handReads.forEach(r => hr.add(r)); }
    const f0 = G.find(g => g.members.some(m => m.src.n == null && m.src.story));
    const o = { moves: charThings.includes(t), fresh: f0 ? { si: f0.rep.m.things[t].si, box: f0.rep.m.things[t].box, hand: f0.rep.m.things[t].hand } : null, boxReads: [...reads].sort(), siReads: [...sir].sort(), handReads: [...hr].sort() };
    if (!o.moves) o.byState = [...per.values()];
    else {   // a thing that moves: every box it had, in every snapshot (step or picture) that gave it
      const byW = new Map();
      for (const x of ST) { const m = x.u.m.things[t], k = J({ si: m.si, box: m.si === true ? m.box : null }); if (!byW.has(k)) byW.set(k, { si: m.si, box: m.si === true ? m.box : null, at: {} }); const e = byW.get(k), r = x.src.pair ? `${x.src.file}:${x.src.pair}.${x.src.side}` : `${x.src.story}/${x.src.plan}`; (e.at[r] = e.at[r] || []).push(x.src.n == null ? -1 : x.src.n); }
      o.bySnapshot = [...byW.values()].map(e => ({ si: e.si, box: e.box, at: Object.fromEntries(Object.entries(e.at).map(([k, ns]) => [k, ns.every(n => n < 0) && k.includes(":") ? "picture" : (ns.includes(-1) ? "start," : "") + ranges(ns.filter(n => n >= 0))])) }));
    }
    thingsInv[t] = o;
  }
  // what the scene was given
  const fnLine = s => s ? lineOf(text, s.split("\n")[0].slice(0, 80)) : null;
  let given;
  if (desc.kit) {
    const kitText = SRC.kit, shared = Object.keys(desc.acts).filter(k => kitText.includes(desc.acts[k].split("\n")[0].slice(0, 60)));
    given = { kit: true, call: `${id}.js:${lineOf(text, "KIT.escena(")} KIT.escena({...})`, keys: desc.keys, CAM: desc.CAM, heartAt: desc.heartAt, heartAtDefault: desc.heartAt == null ? "kit.js:135 [120,30]" : null, lugar: desc.lugar,
      cosas: desc.cosas.map(t => { const o = {}; for (const [k, v] of Object.entries(t)) o[k] = v && v.fn ? { fn: v.fn, line: fnLine(v.fn) } : v; return o; }),
      fresh: { fn: desc.fresh, line: fnLine(desc.fresh) },
      acts: { own: Object.keys(desc.acts).filter(k => !shared.includes(k)).sort(), shared: shared.sort() },
      other: desc.other, functions: Object.fromEntries(Object.entries(desc.fns).filter(([k]) => !["fresh"].includes(k)).map(([k, v]) => [k, { line: fnLine(v) }])),
      hitOrder: { rule: "kit.js:120-125: things with z (in cosas order), then the bird (aveHit), then the frog (frogBox), then the rest in cosas order; each box widened by m (default 3) on every side", order: [...desc.cosas.filter(t => t.z).map(t => t.id), "pajaro", "coqui", ...desc.cosas.filter(t => !t.z).map(t => t.id)], slack: Object.fromEntries(desc.cosas.map(t => [t.id, t.m == null ? 3 : t.m])) } };
  } else {
    const consts = {};
    for (const n of FRENTE_CONSTS) { const L = SRCL.frente.findIndex(l => new RegExp(`(^|[,\\s])(const\\s+)?${n}=`).test(l) && /^const /.test(l)); const ctx = {}; vm.createContext(ctx); vm.runInContext(SRCL.frente[L].replace(/\/\/.*$/, "").replace(/^const /, "var "), ctx); consts[n] = { line: L + 1, value: ctx[n] }; }
    const hole = SRCL.frente.findIndex(l => /HOLE=/.test(l)); { const ctx = {}; vm.createContext(ctx); vm.runInContext(SRCL.frente[hole].replace(/^const /, "var "), ctx); consts.HOLE = { line: hole + 1, value: ctx.HOLE }; }
    const sp2 = SRCL.frente.map((l, i) => /const SPOT=/.test(l) ? i + 1 : null).filter(Boolean);
    given = { kit: false, note: "El frente was written before the kit: no KIT.escena; ESCENAS.frente is built by hand (frente.js:299-302)", object: `frente.js:299 ESCENAS.frente={...}`, keys: desc.keys, CAM: desc.CAM, heartAt: desc.heartAt, handAt: desc.handAt, handAtGetters: desc.handAtSrc,
      box: { line: lineOf(text, "function box(k,W)"), fn: desc.fns.box }, hit: { line: lineOf(text, "function hit(x,y,W)"), order: FRENTE_HIT.map(h => ({ ...h, at: `frente.js:${h.line}` })), rects: FRENTE_HIT_RECT },
      consts: { ...consts, SPOT_copies: `SPOT is declared twice, frente.js:${sp2.join(" and frente.js:")} (the second inside hud(), with mkCasita, mkPalmita, escondite, dish, plato: a pasted copy)` },
      fresh: { fn: desc.fresh, line: fnLine(desc.fresh) }, acts: { own: Object.keys(desc.acts).sort(), shared: [] },
      functions: Object.fromEntries(Object.entries(desc.fns).map(([k, v]) => [k, { line: fnLine(v) }])) };
  }
  // the W keys: who writes, who reads, what values were seen
  const allW = [...U.values()].map(u => u.W), keysAll = new Set(); allW.forEach(w => Object.keys(w).forEach(k => keysAll.add(k)));
  const actSrc = desc.acts, wActs = {};
  for (const [a, s] of Object.entries(actSrc)) for (const k of staticWrites(s)) (wActs[k] = wActs[k] || []).push(a);
  const wFns = {}; for (const [fn, s] of Object.entries(desc.fns)) if (!["fresh"].includes(fn)) for (const k of staticWrites(s)) (wFns[k] = wFns[k] || []).push(fn);
  const dyn = {};   // a key changed between two snapshots: the step that ended last
  for (const s of stories) for (const p of PLANS) {
    const L = ST.filter(x => x.src.story === s && x.src.plan === p);
    for (let i = 1; i < L.length; i++) { const a = L[i - 1].W, b = L[i].W, src = L[i].src;
      for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) if (J(a[k]) !== J(b[k])) { const d = dyn[k] || (dyn[k] = {}), key = src.kind === "act" ? "act " + src.act : src.kind; d[key] = (d[key] || 0) + 1; } }
  }
  const setW = {};   // set steps in the story files and review pictures
  const walkSet = (x, where) => { if (!x || typeof x !== "object") return; if (Array.isArray(x)) { x.forEach((v, i) => walkSet(v, where + "." + i)); return; } if (x.set && typeof x.set === "object" && !Array.isArray(x.set)) for (const k of Object.keys(x.set)) (setW[k] = setW[k] || new Set()).add(where); for (const [k, v] of Object.entries(x)) if (k !== "set") walkSet(v, where + "." + k); };
  for (const s of stories) { const j = FILES.find(f => f.id === s).j; walkSet(j.beats, s + ":beats"); walkSet(j.final, s + ":final"); }
  for (const it of pairsHere) for (const k of ["si", "no"]) if (it[k].scene === id && it[k].set) for (const kk of Object.keys(it[k].set)) (setW[kk] = setW[kk] || new Set()).add(`${it.file}:${it.w}.${k}`);
  const bgReads = new Set(BG[id].keys); for (const u of U.values()) for (const b of u.bg) { /* recorded by the page when the sprite was made */ }
  const factReads = await ev(id => Object.entries(__E6.fact).filter(([k, f]) => f.bg).map(([k, f]) => ({ key: k, reads: f.reads, src: f.src, site: f.site })), id);
  factReads.forEach(f => f.reads.forEach(k => bgReads.add(k)));
  const freshKeys = new Set(Object.keys(fresh[stories[0]].page.W));
  const wkeys = {};
  for (const k of [...keysAll].sort()) {
    const vals = new Map(); for (const w of allW) { const v = J(w[k] === undefined ? null : w[k]); vals.set(v, (vals.get(v) || 0) + 1); }
    const ex = [...vals.entries()].sort((a, b) => b[1] - a[1]).slice(0, 25).map(([v, n]) => ({ v: v.length > 240 ? v.slice(0, 240) + "…" : JSON.parse(v), n }));
    wkeys[k] = { fresh: freshKeys.has(k), writtenBy: { actsInCode: (wActs[k] || []).sort(), otherCode: (wFns[k] || []).sort(), seenAfter: sortObj(dyn[k] || {}), setIn: [...(setW[k] || [])].sort() },
      readBy: { background: bgReads.has(k), spriteLayer: readers.draw.has(k), hitTest: readers.hit.has(k), hud: readers.hud.has(k) },
      role: BG[id].keys.includes(k) ? "background" : CHARKEYS[id].includes(k) ? "character" : PROPKEYS[id].includes(k) ? "moving prop" : SIGNKEYS.includes(k) ? "sign or stamp" : setKeys.includes(k) ? "set (separates states)" : "other",
      distinctValues: vals.size, values: ex };
  }
  // what the sprite layer draws: every item (the scene frames of the stack and the sprite maker), where, in which states
  const itemList = Object.entries(items).map(([k, it]) => {
    const boxes = [...it.boxes.entries()].map(([b, us]) => ({ box: JSON.parse(b), states: [...new Set([...us].map(u => u.group.id))].sort() }));
    const allStates = [...new Set(boxes.flatMap(b => b.states))].sort();
    return { key: k, class: it.bg ? "background" : it.char ? "character" : "prop or effect", maker: it.maker, method: it.m, functions: it.names, drawCall: it.drawLine, code: codeAt(it.drawLine), sites: [...it.allSites].sort((a, b) => a.localeCompare(b, "en", { numeric: true })), chain: it.chain.map(x => x.replace("@escenas/", "@")),
      clipped: it.clip ? it.clip.map(x => x && x.replace(/^escenas\//, "")) : null, states: allStates.length === G.length ? "all" : allStates, boxes: boxes.length > 30 ? boxes.slice(0, 30).concat([{ more: boxes.length - 30 }]) : boxes };
  }).sort((a, b) => (a.drawCall || "").localeCompare(b.drawCall || "", "en", { numeric: true }) || a.key.localeCompare(b.key));
  // positions written in the scene file itself (outside its background function and its sprite makers)
  const fns = functions(text), ownBody = f => { let b = text.slice(f.start, f.end); for (const g of fns) if (g !== f && g.start > f.start && g.end <= f.end) b = b.replace(text.slice(g.start, g.end), ""); return b; };
  const excl = fns.filter(f => BG[id].fns.includes(f.name) || /new Buf\(|createElement\("canvas"\)/.test(ownBody(f)));
  const inFile = staticPositions(text, excl).map(p => ({ at: `${id}.js:${p.line}`, fn: p.fn, kind: p.kind, nums: p.nums, what: p.what, comment: p.comment }));
  // hit test against the list
  const listIds = thingIds.slice(), hitIds = Object.keys(hitSeen).sort();
  const named = namedIds(id, stories, pairsHere, traces);
  const inventory = {
    scene: id, file: `historia/escenas/${id}.js`, made: "node coqui/tool/ref/escenas/make.mjs", sha256: sha(Buffer.from(text)), stories, reviewFile: FILES.find(f => f.j.tipo === "cual" && f.j.scene === id).id, hostPage: `historia/index.html?cuento=${host}&fast=1`,
    background: { functions: BG[id].fns, at: BG[id].at, keys: BG[id].keys, keysCheck: bgOk ? "no two states with the same values of these keys have a different background sprite" : "FAILED: the keys do not decide the background", sprites: factReads.map(f => ({ key: f.key, maker: f.src, readsW: f.reads, askedAt: f.site && f.site.replace(/^escenas\//, "") })) },
    given, thingIds: listIds, things: thingsInv,
    hitTest: { grid: "every 3rd pixel of 240 x 216, in every distinct W", idsAnswered: hitIds, answers: hitSeen, onlyInList: listIds.filter(t => !hitSeen[t]), notInList: hitIds.filter(t => !listIds.includes(t) && t !== "coqui" && t !== "pajaro") },
    namedInFiles: named, views: CAM, storyViews: storyCams.map(v => ({ name: v.name, rect: v.rect })),
    fresh, states: { count: G.length, distinctW: U.size, snapshots: ST.length, grouping: "same background sprite(s), the same set things shown with the same boxes, the same values of the set keys", setKeys, setThings, movingThings: charThings, propKeys: PROPKEYS[id], index: "frames/index.json" },
    wKeys: wkeys, spriteLayer: itemList, positionsInFile: inFile,
    judgments: [
      `Characters, for the frames without them: ${CHARS[id].fns.join(", ")} (functions) and the lines ${CHARS[id].lines.join(", ")}${CHARS[id].keep.length ? "; kept: " + CHARS[id].keep.join(", ") : ""} (config.mjs CHARS). ${CHARS[id].note || ""}`.trim(),
      `States are grouped without the character keys ${CHARKEYS[id].join(", ")}${PROPKEYS[id].length ? ", the moving-prop keys " + PROPKEYS[id].join(", ") : ""} and the sign and stamp keys (config.mjs); a thing whose box reads only those keys (movingThings) does not separate states either: its box in every snapshot is in things[id].bySnapshot. The frame of a state shows the characters where the first snapshot of that state had them.`,
      "The frames are the scene's draw() only: juego.js's signs (the big hand, the frame around a thing, stars, the heart, answer bubbles) are not drawn; the views add the scene's hud() as the play screen does.",
      "Each frame starts with the canvas default imageSmoothingEnabled = true (the old page keeps whatever the last frame left; order 05 found it on by default).",
    ],
  };
  writeJSON(path.join(OUT, id, "inventory.json"), inventory);
  writeJSON(path.join(OUT, id, "positions.json"), positionsOf(id, stories, pairsHere, PL, inFile, desc, U, ST, G));
  writePairs(id, pairsHere, PL);
  fs.writeFileSync(path.join(OUT, id, "draw-order.md"), drawOrder(id, itemList, clipsAll, U, G, fns));
  if (S.errors.length) console.log(`  ${id}: page errors: ${S.errors.join("; ")}`);
  await S.ctx.close();
  return { id, things: listIds.length, states: G.length, distinctW: U.size, views: Object.keys(CAM).length, pairs: pairsHere.length, level: PL.nv.filter(q => q.p.some(p => p.scene === id)).length, positions: null, frames: written.size };
}

// the thing ids the story files and review pairs name: touch targets (ask, decide, elige; what the runs offered and touched) and names
function namedIds(id, stories, pairs, traces) {
  const lit = new Map(), add = (k, where) => { if (typeof k !== "string" || !k) return; (lit.get(k) || lit.set(k, new Set()).get(k)).add(where); };
  for (const s of stories) {
    const j = FILES.find(f => f.id === s).j;
    const walk = (x, p) => { if (!x || typeof x !== "object") return; if (Array.isArray(x)) { x.forEach((v, i) => walk(v, p + "." + i)); return; }
      if (typeof x.ask === "string") add(x.ask, `${s}:${p} ask`);
      if (x.decide) { (x.options || []).forEach(o => add(o, `${s}:${p} decide${x.decide === "say" ? " (say: answer bubbles)" : ""}`)); if (x.pick) add(x.pick, `${s}:${p} pick`); (x.vale || []).forEach(o => add(o, `${s}:${p} vale`)); Object.keys(x.alias || {}).forEach(o => add(o, `${s}:${p} alias`)); Object.keys(x.gratis || {}).forEach(o => add(o, `${s}:${p} gratis`)); }
      if (x.elige) (x.options || []).forEach(o => add(o, `${s}:${p} elige (answer bubbles)`));
      if (x.set && (x.set.spot || x.set.twinkle)) add(x.set.spot || x.set.twinkle, `${s}:${p} set`);
      for (const [k, v] of Object.entries(x)) walk(v, p ? p + "." + k : k); };
    walk(j.beats, "beats"); walk(j.final, "final");
    Object.keys(j.names || {}).forEach(k => add(k, `${s}:names`));
    for (const p of PLANS) { const tr = traces[s + "/" + p]; for (const c of tr.choices) { c.live.forEach(k => add(k, `${s}/${p} choice ${c.step} live`)); } for (const t of tr.touches) add(t.what, `${s}/${p} touch (${t.why})`); }
  }
  const out = {};
  for (const [k, ws] of [...lit.entries()].sort()) { const a = [...ws]; out[k] = { $var: /^\$/.test(k), where: a.length > 12 ? a.slice(0, 12).concat([`… ${a.length - 12} more`]) : a }; }
  return out;
}

// every screen position in the scene's stories, review pairs and level items, with where it is used
function positionsOf(id, stories, pairs, PL, inFile, desc, U, ST, G) {
  const P = new Map(), num = v => typeof v === "number" ? v : typeof v === "string" && /^-?\d+(\.\d+)?$/.test(v) ? +v : null;
  const lugar = desc.kit ? desc.lugar : (() => { const ctx = {}; vm.createContext(ctx); vm.runInContext(SRCL.frente.find(l => /^const LUGAR=/.test(l)).replace(/^const /, "var "), ctx); return ctx.LUGAR; })();
  const stateAfter = (story, p) => { const x = ST.find(s => s.src.story === story && s.src.path === p); return x ? x.u : null; };
  const inside = (u, x, y) => u ? Object.entries(u.m.things).filter(([t, v]) => v.si === true && Array.isArray(v.box) && x >= v.box[0] && x < v.box[0] + v.box[2] && y >= v.box[1] && y < v.box[1] + v.box[3]).map(([t]) => t) : [];
  const meaning = owner => { const M = { ...MEANING["*"], ...(MEANING[id] || {}) }; const keys = Object.keys(M).sort((a, b) => b.length - a.length); const k = keys.find(k => owner === k || owner.startsWith(k + ".") || owner.startsWith(k + " ")); return k ? M[k] : null; };
  const add = (kind, nums, use) => { const key = kind + ":" + nums.join(","); if (!P.has(key)) P.set(key, { kind, x: nums[0], y: nums[1], w: nums[2], h: nums[3], uses: [] }); P.get(key).uses.push(use); };
  function walk(x, p, file, ctx) {
    if (!x || typeof x !== "object") return;
    if (Array.isArray(x)) {
      if (x.length === 2 && x.every(v => typeof v === "number")) return void add("point", x, { file, at: p, owner: ctx.owner, ...ctx.extra(p, x[0], x[1]) });
      if (x.length === 4 && x.every(v => typeof v === "number")) return void add(ctx.owner === "cam" || /\.cam$/.test(p) ? "cam" : "rect", x, { file, at: p, owner: ctx.owner, ...ctx.extra(p, x[0], x[1]) });
      if (x.length >= 2 && x.every(v => typeof v === "number")) return void add("numbers", x, { file, at: p, owner: ctx.owner, note: "not a place on screen (a list of counts or flags)" });
      x.forEach((v, i) => walk(v, p + "." + i, file, { ...ctx, owner: ctx.owner + "[]" })); return;
    }
    const xs = num(x.x), ys = num(x.y);
    if (xs != null && ys != null) add("point", [xs, ys], { file, at: p, owner: ctx.owner, ...ctx.extra(p, xs, ys) });
    else if (xs != null) add("x", [xs], { file, at: p, owner: ctx.owner, note: "x alone (y comes from the scene)" });
    for (const [k, v] of Object.entries(x)) {
      if (k === "x" || k === "y") continue;
      const owner = x.act && !ctx.inSet ? `act:${x.act}` + (x.quien ? ` quien=${x.quien}` : "") + (x.id ? ` id=${x.id}` : "") : ctx.owner ? ctx.owner + "." + k : k;
      walk(v, p ? p + "." + k : k, file, { ...ctx, owner: k === "set" ? "set" : owner, inSet: ctx.inSet || k === "set" });
    }
  }
  for (const s of stories) {
    const j = FILES.find(f => f.id === s).j;
    const extra = (p, x, y) => { const step = p.replace(/\.set\..*$|\.set$/, "").replace(/\.(x|y)$/, ""); const u = stateAfter(s, step) || stateAfter(s, p.split(".set")[0]); const lg = Object.entries(lugar || {}).filter(([k, v]) => v[0] === x && v[1] === y).map(([k]) => k);
      return { lugar: lg.length ? lg : undefined, insideThings: (r => r.length ? r : undefined)(inside(u, x, y)) }; };
    for (const k of ["beats", "final"]) walk(j[k], k, `cuentos/${s}.json`, { owner: "", extra });
    if (j.cam) for (const [v, r] of Object.entries(j.cam)) add("cam", r, { file: `cuentos/${s}.json`, at: `cam.${v}`, owner: "story view", note: `replaces the scene's view ${v} for this story (juego.js:413)` });
  }
  for (const it of pairs) for (const k of ["si", "no"]) {
    const spec = it[k], u = [...U.values()].find(u => u.srcs.some(s => s.pair === it.w && s.side === k));
    const extra = (p, x, y) => { const lg = Object.entries(lugar || {}).filter(([kk, v]) => v[0] === x && v[1] === y).map(([kk]) => kk); return { lugar: lg.length ? lg : undefined, insideThings: (r => r.length ? r : undefined)(inside(u, x, y)) }; };
    if (spec.scene !== id) { add("cam", spec.cam, { file: `cuentos/${it.file}.json`, at: `${it.w}.${k}.cam`, owner: "pair picture", note: `drawn by scene ${spec.scene}` }); continue; }
    add("cam", spec.cam, { file: `cuentos/${it.file}.json`, at: `${it.w}.${k}.cam`, owner: "pair picture", note: "the rectangle of the 240 x 216 picture stretched to 196 x 104 (cual.js:38)" });
    if (spec.set) walk(spec.set, `${it.w}.${k}.set`, `cuentos/${it.file}.json`, { owner: "set", inSet: true, extra });
  }
  for (const q of PL.nv) q.p.forEach((p, j) => { if (p.scene !== id) return; add("crop", p.crop, { file: "nivel.js NV", at: `${q.w}.p${j}`, owner: "level picture", note: `pair ${p.pair}.${p.side}, ${p.x == null ? "centred on the pair's camera" : "centred on x " + p.x} (nivel.js:75-76), drawn into 96 x 106` }); if (p.x != null) add("x", [p.x], { file: "nivel.js NV", at: `${q.w}.p${j}`, owner: "level crop centre", note: "the x the square crop is centred on" }); });
  const list = [...P.values()].sort((a, b) => a.kind.localeCompare(b.kind) || a.x - b.x || (a.y || 0) - (b.y || 0) || (a.w || 0) - (b.w || 0) || (a.h || 0) - (b.h || 0));
  for (const e of list) { for (const k of ["w", "h", "y"]) if (e[k] === undefined) delete e[k]; for (const u of e.uses) { const m = meaning(u.owner || ""); if (m) u.meaning = m; for (const k of Object.keys(u)) if (u[k] === undefined) delete u[k]; } }
  return { scene: id, made: "node coqui/tool/ref/escenas/make.mjs", count: list.length, kinds: "point: an x, y; x: an x alone; cam: a camera rectangle (x, y, w, h); rect: another rectangle; crop: a level-check crop; numbers: a list of numbers that is not a place", positions: list, inSceneFile: inFile };
}

function writePairs(id, pairs, PL) {
  const dir = path.join(OUT, id, "pairs"); fs.rmSync(dir, { recursive: true, force: true }); fs.mkdirSync(dir, { recursive: true });
  const put = (s, name) => { const p = PIX.get(s); fs.writeFileSync(path.join(dir, name), png(p.w, p.h, p.buf)); return name; };   // one file per picture, even when two pictures are the same
  const out = { scene: id, made: "node coqui/tool/ref/escenas/make.mjs", drawn: `cual.html and nivel.html as they are, every scene loaded (cual.js:18-20), F=${F_PAIR}; a review picture is the cam rectangle stretched to 196 x 104, a level picture the crop stretched to 96 x 106`, pairs: [], level: [] };
  for (const it of pairs) {
    const o = { file: it.file, w: it.w, say: it.say, sayText: PL.sayText[it.say] || null };
    for (const k of ["si", "no"]) o[k] = { scene: it[k].scene, cam: it[k].cam, set: it[k].set || null, esc: it[k].esc || null, png: put(it[k].png, `${slug(it.w)}.${k}.png`), samePixelsAsOther: false };
    o.si.samePixelsAsOther = o.no.samePixelsAsOther = it.si.png === it.no.png;
    out.pairs.push(o);
  }
  for (const q of PL.nv) if (q.p.some(p => p.scene === id)) out.level.push({ w: q.w, s: q.s, pictures: q.p.map((p, j) => ({ first: j === 0, pair: p.pair, side: p.side, x: p.x, crop: p.crop, scene: p.scene, png: p.scene === id ? put(p.png, `nivel.${slug(q.w)}.${j}.png`) : null })) });
  writeJSON(path.join(OUT, id, "pairs.json"), out);
}

function drawOrder(id, items, clips, U, G, fns) {
  const L = [], fnOf = n => fns.find(f => f.name === n && f.line0 <= 400);
  const d = fns.find(f => f.name === "draw");
  L.push(`# ${id}: what draw() draws, in order`, "", `Made by \`node coqui/tool/ref/escenas/make.mjs\` from the canvas calls of every distinct state (${U.size} W, ${G.length} states); each call's place is the first frame of its stack in a scene file. historia/escenas/${id}.js draw(): lines ${d.line0}-${d.line1}.`, "");
  const sorts = SRCL[id].map((l, i) => /\.sort\(\(m,n\)=>m\.y-n\.y\)/.test(l) ? i + 1 : null).filter(Boolean);
  if (sorts.length) L.push(`**Drawn in order of y:** the items pushed to a list before ${sorts.map(n => `${id}.js:${n}`).join(", ")} are sorted by their y (the feet, or a y the code gives) and drawn back to front, so what covers what changes with where things stand. Below, "always" means in every state where both are drawn; otherwise how many states.`, "");
  L.push("## Characters and props", "", "An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).", "", "| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |", "|---|---|---|---|---|");
  const seq = [...U.values()].map(u => ({ u, runs: u.runs }));
  const nonBg = items.filter(i => i.class !== "background");
  for (const it of nonBg) {
    const after = new Map(); let present = 0;
    for (const { runs } of seq) {
      const idx = runs.map((r, i) => r.k === it.key ? i : -1).filter(i => i >= 0); if (!idx.length) continue; present++;
      const myBox = runs.filter(r => r.k === it.key).reduce((a, r) => !a ? r.box : !r.box ? a : [Math.min(a[0], r.box[0]), Math.min(a[1], r.box[1]), Math.max(a[0] + a[2], r.box[0] + r.box[2]) - Math.min(a[0], r.box[0]), Math.max(a[1] + a[3], r.box[1] + r.box[3]) - Math.min(a[1], r.box[1])], null);
      const seen = new Set();
      for (let i = idx[0] + 1; i < runs.length; i++) { const r = runs[i]; if (r.k === it.key || seen.has(r.k)) continue; if (myBox && r.box && r.box[0] < myBox[0] + myBox[2] && r.box[0] + r.box[2] > myBox[0] && r.box[1] < myBox[1] + myBox[3] && r.box[1] + r.box[3] > myBox[1]) { seen.add(r.k); after.set(r.k, (after.get(r.k) || 0) + 1); } }
    }
    const both = k => seq.filter(({ runs }) => runs.some(r => r.k === it.key) && runs.some(r => r.k === k)).length;
    const cov = [...after.entries()].sort((a, b) => (items.find(y => y.key === a[0]).drawCall || "").localeCompare(items.find(y => y.key === b[0]).drawCall || "", "en", { numeric: true })).map(([k, n]) => `\`${k}\` (${n === both(k) ? "always" : n + " of " + both(k)})`);
    L.push(`| \`${it.key}\` | ${it.class} | ${it.sites.join(", ")} | ${it.maker || it.method} | ${cov.join("; ") || "nothing"} |`);
  }
  L.push("", "## Clip regions", "");
  const cl = Object.values(clips);
  if (!cl.length) L.push("None: this scene never calls clip().");
  else { L.push("| at | region (scene picture) | what is drawn inside it | seen in |", "|---|---|---|---|");
    for (const c of cl) { const inside = items.filter(i => i.clipped && i.clipped.includes(c.site.replace(/^escenas\//, ""))).map(i => `\`${i.key}\``); L.push(`| ${c.site.replace(/^escenas\//, "")} \`${codeAt(c.site).slice(0, 90)}\` | ${c.shapes.map(s => `${s.t} ${J(s.user)}${J(s.r) !== J(s.user) ? " (screen " + J(s.r) + ")" : ""}`).join(", ")} | ${inside.join("; ") || "—"} | ${c.n} W |`); } }
  L.push("", "## Background", "", ...BG[id].at.map(a => `- ${a}`), "");
  L.push("## Notes", "", ...(NOTES[id] || ["None."]).map(n => `- ${n}`), "");
  return L.join("\n");
}

// what the draw-order tables cannot say (read from the code)
const NOTES = {
  frente: ["The bubbles are drawn last (frente.js:171-174, \"so they stay bright\"): abuela's, the voice from inside (W.dentro), the frog's.", "The storm cloud(s), rain and the lightning flash (frente.js:167-170) are drawn over the characters; W.dark and W.dusk lay a colour over the whole picture (frente.js:164-165), characters included.", "abuela in the window and the frog beside her are clipped to the window opening (frente.js:147); the frog and abuela peeking from behind the half-open door are clipped to the gap (frente.js:143-144).", "The table with the cake (mesa(), frente.js:64) is drawn inside abuela's window clip, before her, only when W.win===1 and W.mesa.", "The hide-and-seek props (small palm, birdhouse: escondite(), frente.js:94) are drawn before abuela and the frog: they never cover a character."],
  balcon: ["abuela standing is drawn twice in the code: before the furniture when her feet are above y 144 (balcon.js:126), after the table and jugs when at or below (balcon.js:141).", "Standing in the doorway she is clipped to the door opening (balcon.js:124).", "Her picture bubbles and the frog's are drawn last, at twice their size (bub2, balcon.js:116, 154-155)."],
  sala: ["Everyone, the low table and the frog are sorted by y (sala.js:113-117); the photos, the lamp, the sofa, the armchair and the blanket come before (sala.js:108-111) and so never cover anyone.", "W.borroso blurs the whole picture with smoothing on (sala.js:120-121), reading back the scene canvas (sc) itself; W.flash whitens it (sala.js:122)."],
  patio: ["The sky (cielo) is a separate background sprite, then the sun or moon, then fondo (the yard) over it (patio.js:129-132): the sun sets behind the wall.", "The light of the hour and W.osc lay a colour over everything (patio.js:147-148); the fireflies are drawn after that, so they glow (patio.js:149)."],
  camino: ["Birds in the trees and the cat up a tree are drawn before everyone (camino.js:99-100), so people and the frog cover them.", "The leash is drawn after the sorted list (camino.js:109): over the dog, the frog and whoever holds it."],
  campo: ["W.oscuro darkens everything, then draws the frog again on top (campo.js:110): his eyes are shut, all is dark but him."],
  lago: ["anima() (lago.js:81) runs at the start of every draw and moves ducks, fish and birds: some positions are animated by draw() itself, not by an act.", "The reeds (JUNCOS) are in the sorted list (lago.js:116): they cover what stands behind them."],
  banco: ["W.seva moves the cart, the piragua man and the dogs inside draw() (banco.js:196): their boxes there are not those of the state.", "At night a patch of the background (46 x 38 at 84,6) is copied to 196,6 (banco.js:194) before the night colour is laid over everything."],
  mesa: ["W.afuera swaps the whole background for mkPuesto (mesa.js:156) and drops the table (mesa.js:171); set only by cual-mesa (order 05: no story reaches it).", "Things in the air, the pouring jug and what is held up (mesa.js:182-184) are drawn after the sorted list: over everyone."],
  estufa: ["People seen through the window are clipped to it (estufa.js:134) and drawn before the counters."],
  nevera: ["The yard in the window (patio(), nevera.js:105) is clipped to the window: the cart, the birds on the wall and people outside.", "The fridge is drawn by nevera() (nevera.js:115) every frame, after the background: open, half shut or shut (W.nev.abierta)."],
  comer: ["One background (fondo, comer.js:31) for every state; the table (mkMesa, comer.js:58) is not part of it: it is an item of the sorted list at y TZ 173 (comer.js:552).",
    "Each person is two items of the sorted list (comer.js:551): the body without the holding arms (cuerpo) and the arms, hands and what they hold (objetos). Their depths come from capa() (comer.js:546-547): somebody seated or at a corner (est) has his body at his feet and his hands over the table (TZ+.9); somebody standing behind the table (detrasMesa) is drawn behind everyone, body and hands, at 40+y/100; anyone else by his feet.",
    "Things on the table (W.cosas inside the table top, enMesa) are drawn at TZ+y/1000, just after the table; a thing elsewhere at its y+1; a thing with z at z (comer.js:553). The frog is over the table (TZ+(y+27)/1000) unless W.cq.sobre===0 (comer.js:558).",
    "Things in the air (W.vuelos) and pouring streams (chorro) are drawn after the sorted list: over everyone (comer.js:560). The thought clouds, a person's and then the frog's, are drawn last (comer.js:567-568).",
    "With ?txt=no every speaker gets an empty speech bubble (hab, comer.js:561-566); the recorded runs do not use txt=no, so no frame here has one."],
};

async function main() {
  const work = runs();
  const srv = await server(), base = `http://127.0.0.1:${srv.address().port}`;
  const browser = await chromium.launch();
  console.log("review pairs and level pictures ...");
  const PL = await pairsAndLevel(browser, base);
  console.log(`  ${PL.items.length} pairs, ${PL.nv.length} level items; datos/nivel.json ${PL.nivelJsonSame ? "is" : "is NOT"} the same as nivel.js NV`);
  const done = [];
  for (const id of (ONLY ? [ONLY] : SCENES).filter(id => storiesOf(id).length)) { console.log(`scene ${id} ...`); done.push(await scene(browser, base, id, PL, work)); }
  await browser.close(); srv.close();
  if (work.temp) fs.rmSync(work.temp, { recursive: true, force: true });
  if (!ONLY) {
    const sum = done.map(d => { const p = JSON.parse(fs.readFileSync(path.join(OUT, d.id, "positions.json"), "utf8")); return { ...d, positions: p.count }; });
    writeJSON(path.join(OUT, "summary.json"), { made: "node coqui/tool/ref/escenas/make.mjs", nivelJsonSameAsNV: PL.nivelJsonSame, scenes: sum });
    fs.writeFileSync(path.join(OUT, "README.md"), readme(sum, PL, done.reduce((n, d) => n + storiesOf(d.id).length, 0)));
  }
  console.log("done:", done.map(d => `${d.id} ${d.things} things, ${d.states} states, ${d.views} views, ${d.pairs} pairs, ${d.frames} frames`).join("; "));
}
main().catch(e => { console.error(e); process.exit(1); });
