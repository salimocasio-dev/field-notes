// ref/escenas: checks the folders make.mjs wrote, by other roads where it can.
//   node coqui/tool/ref/escenas/check.mjs            (--from DIR to check another output folder)
// 1. thing ids: the inventory's against the list the running page's scene was given (or El frente's hit order), against what its hit()
//    answers, and against the ids the scene's story files and review pairs name.
// 2. states: every step of every recorded run of the scene's stories (coqui/ref/trazas) and every review picture is in exactly one state,
//    and every state's frames exist with the right size.
// 3. positions: the story, review and level files walked again; every place on screen found there is in positions.json.
// 4. size of the folder.
import fs from "node:fs";
import path from "node:path";
import http from "node:http";
import vm from "node:vm";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { SCENES, FRENTE_HIT } from "./config.mjs";
const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const HERE = path.dirname(fileURLToPath(import.meta.url)), ROOT = path.resolve(HERE, "../../../.."), HIST = path.join(ROOT, "historia");
const arg = (k, d) => { const i = process.argv.indexOf(k); return i >= 0 ? process.argv[i + 1] : d; };
const FROM = path.resolve(arg("--from", path.join(ROOT, "coqui/ref/escenas")));
const PLANS = ["right", "wrong", "alternate"];
const FILES = fs.readdirSync(path.join(HIST, "cuentos")).filter(f => f.endsWith(".json")).sort().map(f => ({ id: f.slice(0, -5), j: JSON.parse(fs.readFileSync(path.join(HIST, "cuentos", f), "utf8")) }));
let bad = 0; const fail = m => { bad++; console.log("  FAIL " + m); };
const pngSize = f => { const b = fs.readFileSync(f); return [b.readUInt32BE(16), b.readUInt32BE(20)]; };
const parseRanges = s => s.split(",").filter(Boolean).flatMap(r => r === "start" ? ["start"] : r.includes("-") ? (([a, b]) => Array.from({ length: b - a + 1 }, (_, i) => a + i))(r.split("-").map(Number)) : [+r]);

// the page, for the scene's own list of things
const srv = http.createServer((req, res) => { const u = decodeURIComponent(new URL(req.url, "http://x").pathname), f = path.join(ROOT, u);
  if (!f.startsWith(ROOT + path.sep) || !fs.existsSync(f) || !fs.statSync(f).isFile()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { "Content-Type": f.endsWith(".js") ? "text/javascript" : f.endsWith(".html") ? "text/html" : "application/json" }); fs.createReadStream(f).pipe(res); });
await new Promise(r => srv.listen(0, "127.0.0.1", r));
const browser = await chromium.launch();
const INIT = fs.readFileSync(path.join(ROOT, "coqui/tool/ref/trazas/page-init.js"), "utf8").replace("__SEED__", "1");
async function sceneList(id, story) {
  const ctx = await browser.newContext(); await ctx.addInitScript(INIT);
  await ctx.route(/\/historia\/audio\/[^/]+\.mp3(\?.*)?$/, route => { const n = decodeURIComponent(new URL(route.request().url()).pathname.split("/").pop()); return fs.existsSync(path.join(HIST, "audio", n)) ? route.fulfill({ status: 200, body: "ID3" }) : route.fulfill({ status: 404, body: "" }); });
  const p = await ctx.newPage(); await p.goto(`http://127.0.0.1:${srv.address().port}/historia/index.html?cuento=${story}&fast=1`);
  for (let i = 0; i < 600; i++) { if (await p.evaluate("!!(window.Story&&Story.ready&&typeof voiceReady!=='undefined'&&voiceReady&&E)")) break; await new Promise(r => setTimeout(r, 50)); }
  const r = await p.evaluate(id => { const d = __H.escena[id]; if (!d) return null; const out = new Set(); const w = W; for (let y = 0; y < 216; y += 2) for (let x = 0; x < 240; x += 2) { const k = ESCENAS[id].hit(x, y, w); if (k) out.add(k); } return { ids: d.cosas.map(t => t.id), freshHit: [...out] }; }, id);
  await ctx.close(); return r;
}

const table = [];
for (const id of SCENES) {
  console.log(`${id}:`);
  const dir = path.join(FROM, id), inv = JSON.parse(fs.readFileSync(path.join(dir, "inventory.json"), "utf8")), idx = JSON.parse(fs.readFileSync(path.join(dir, "frames/index.json"), "utf8"));
  const pos = JSON.parse(fs.readFileSync(path.join(dir, "positions.json"), "utf8")), pairs = JSON.parse(fs.readFileSync(path.join(dir, "pairs.json"), "utf8"));
  const stories = FILES.filter(f => f.j.scene === id && f.j.tipo !== "cual").map(f => f.id);
  // 1. ids
  const page = id === "frente" ? { ids: FRENTE_HIT.map(h => h.id), freshHit: null } : await sceneList(id, stories.find(s => !FILES.find(f => f.id === s).j.cam));
  const invIds = inv.thingIds, extra = ["coqui", "pajaro"];
  const same = JSON.stringify(invIds) === JSON.stringify(page.ids);
  if (!same) fail(`thing ids differ from the page's: inventory ${invIds} / page ${page.ids}`);
  const hitNot = inv.hitTest.idsAnswered.filter(k => !invIds.includes(k) && !extra.includes(k));
  if (hitNot.length) fail(`hit() answered ids not in the list: ${hitNot}`);
  if (page.freshHit) { const fh = page.freshHit.filter(k => !invIds.includes(k) && !extra.includes(k)); if (fh.length) fail(`hit() in the fresh state answered ids not in the list: ${fh}`); }
  const neverHit = invIds.filter(k => !inv.hitTest.idsAnswered.includes(k));
  // named in files: walked again here
  const named = new Map(), resp = new Set(), templ = new Set(), alias = new Set(), add = (k, w) => { if (typeof k !== "string" || !k) return; if (k.includes("$")) { templ.add(k); return; } (named.get(k) || named.set(k, new Set()).get(k)).add(w); };   // a name with $ is filled at run time: the runs give what it became
  for (const s of stories) { const j = FILES.find(f => f.id === s).j;
    const walk = (x, p) => { if (!x || typeof x !== "object") return; if (Array.isArray(x)) return x.forEach((v, i) => walk(v, p + "." + i));
      if (typeof x.ask === "string") add(x.ask, `${s}:${p} ask`);
      if (x.decide && x.decide !== "say") { const av = Object.values(x.alias || {}).filter(o => !invIds.includes(o));   // an option that is a value of the step's alias is a name for the things that are its keys (juego.js:185): those must be in the scene
        Object.keys(x.alias || {}).forEach(o => add(o, `${s}:${p} alias`)); (x.options || []).forEach(o => av.includes(o) ? alias.add(o) : add(o, `${s}:${p} decide`)); if (x.pick && !av.includes(x.pick)) add(x.pick, `${s}:${p} pick`); (x.vale || []).forEach(o => add(o, `${s}:${p} vale`)); }
      for (const [k, v] of Object.entries(x)) walk(v, p + "." + k); };
    walk(j.beats, "beats"); walk(j.final, "final"); Object.keys(j.names || {}).forEach(k => add(k, `${s}:names`));
    const at = p => p.split(".").reduce((o, k) => o == null ? o : o[k], j);
    for (const p of PLANS) { const tr = JSON.parse(fs.readFileSync(path.join(ROOT, "coqui/ref/trazas", s, p + ".json"), "utf8"));
      for (const c of tr.choices) { const st = at(c.step) || {}; const bubbles = st.decide === "say" || !!st.elige || !!st.resp || !!(st.burbujas && st.burbujas.length);   // answer bubbles, not things
        const av = Object.values(st.alias || {}).filter(o => !invIds.includes(o));
        if (bubbles) c.live.forEach(k => (resp.add(k))); else { c.live.forEach(k => av.includes(k) ? alias.add(k) : add(k, `${s}/${p} ${c.kind} ${c.step} (as played)`)); } }
      for (const t of tr.touches) if (!resp.has(t.what) && !alias.has(t.what)) add(t.what, `${s}/${p} touch (${t.why})`); }   // a touch is recorded by the name the alias gave it
  }
  const namedNotInScene = [...named.keys()].filter(k => !invIds.includes(k) && !extra.includes(k) && !resp.has(k)).sort();
  const sceneNotNamed = invIds.filter(k => !named.has(k));
  for (const k of namedNotInScene) fail(`a story names ${k} (${[...named.get(k)].slice(0, 3).join("; ")}), the scene has no such thing`);
  // 2. states
  const reached = new Map();
  for (const st of idx.states) {
    for (const [run, r] of Object.entries(st.reachedBy.steps)) for (const n of parseRanges(r)) { const k = run + "@" + n; if (reached.has(k)) fail(`${k} in two states`); reached.set(k, st.id); }
    for (const p of st.reachedBy.pairs) reached.set("pair:" + p, st.id);
    for (const [k, f] of Object.entries(st.files)) { const fp = path.join(dir, "frames", f); if (!fs.existsSync(fp)) { fail(`${st.id} ${k}: ${f} missing`); continue; } const [w, h] = pngSize(fp); const want = k.includes(".") ? [196, 216] : [240, 216]; if (w !== want[0] || h !== want[1]) fail(`${f} is ${w}x${h}`); }
  }
  let steps = 0;
  for (const s of stories) for (const p of PLANS) { const tr = JSON.parse(fs.readFileSync(path.join(ROOT, "coqui/ref/trazas", s, p + ".json"), "utf8"));
    for (const n of ["start", ...tr.steps.map(x => x.n)]) { steps++; if (!reached.has(`${s}/${p}@${n}`)) fail(`${s}/${p} step ${n} has no state`); } }
  let pics = 0;
  for (const f of FILES.filter(f => f.j.tipo === "cual")) for (const it of f.j.items) for (const k of ["si", "no"]) if ((it[k].esc || f.j.scene) === id) { pics++; if (!reached.has(`pair:${f.id}:${it.w}.${k}`)) fail(`${f.id} ${it.w}.${k} has no state`); }
  for (const p of pairs.pairs) for (const k of ["si", "no"]) { const [w, h] = pngSize(path.join(dir, "pairs", p[k].png)); if (w !== 196 || h !== 104) fail(`pair ${p.w}.${k} is ${w}x${h}`); }
  for (const q of pairs.level) for (const p of q.pictures) if (p.png) { const [w, h] = pngSize(path.join(dir, "pairs", p.png)); if (w !== 96 || h !== 106) fail(`level ${q.w} is ${w}x${h}`); }
  // 3. positions, found again
  const P = new Set(pos.positions.map(e => e.kind + ":" + [e.x, e.y, e.w, e.h].filter(v => v !== undefined).join(",")));
  let found = 0, looked = 0;
  const look = (kind, nums, where) => { looked++; const alt = kind === "cam" ? ["cam", "rect"] : [kind]; if (alt.some(k => P.has(k + ":" + nums.join(",")))) found++; else fail(`${where}: ${kind} ${nums} not in positions.json`); };
  const num = v => typeof v === "number" ? v : typeof v === "string" && /^-?\d+(\.\d+)?$/.test(v) ? +v : null;
  const walk = (x, where) => { if (!x || typeof x !== "object") return;
    if (Array.isArray(x)) { if (x.length === 2 && x.every(v => typeof v === "number")) return look("point", x, where); if (x.length === 4 && x.every(v => typeof v === "number")) return look("cam", x, where); return x.forEach((v, i) => walk(v, where + "." + i)); }
    const a = num(x.x), b = num(x.y); if (a != null && b != null) look("point", [a, b], where); else if (a != null) look("x", [a], where);
    for (const [k, v] of Object.entries(x)) if (k !== "x" && k !== "y") walk(v, where + "." + k); };
  for (const s of stories) { const j = FILES.find(f => f.id === s).j; walk(j.beats, s + ":beats"); walk(j.final, s + ":final"); if (j.cam) Object.entries(j.cam).forEach(([k, r]) => look("cam", r, s + ":cam." + k)); }
  for (const f of FILES.filter(f => f.j.tipo === "cual")) for (const it of f.j.items) for (const k of ["si", "no"]) {
    const sc = it[k].esc || f.j.scene; if (sc !== id && f.j.scene !== id) continue;
    look("cam", it[k].cam, `${f.id}:${it.w}.${k}.cam`); if (sc === id && it[k].set) walk(it[k].set, `${f.id}:${it.w}.${k}.set`); }
  const ctx = {}; vm.createContext(ctx); vm.runInContext(fs.readFileSync(path.join(HIST, "nivel.js"), "utf8").match(/const NV=\[[\s\S]*?\}\];/)[0].replace("const NV", "var NV"), ctx);
  const byW = {}; for (const f of FILES.filter(f => f.j.tipo === "cual")) for (const it of f.j.items) byW[it.w] = { it, scene: f.j.scene };
  for (const q of ctx.NV) q.p.forEach((p, j) => { const e = byW[p[0]], spec = e.it[p[1]], sc = spec.esc || e.scene; if (sc !== id) return; const cm = spec.cam, h = cm[3], w = h * 96 / 106, cx = p[2] != null ? p[2] : cm[0] + cm[2] / 2;
    look("crop", [Math.max(0, Math.min(240 - w, cx - w / 2)), cm[1], w, h].map(v => Math.round(v * 100) / 100), `nivel.js NV ${q.w}.p${j}`); if (p[2] != null) look("x", [p[2]], `nivel.js NV ${q.w}.p${j} x`); });
  console.log(`  ids: ${invIds.length} = the page's list ${same ? "(same, same order)" : "(DIFFERENT)"}; hit() answered ${inv.hitTest.idsAnswered.length} ids, none outside the list${hitNot.length ? " — NO" : ""}; never answered: ${neverHit.join(", ") || "none"}`);
  console.log(`  named by stories (as written, or as played) and not in the scene: ${namedNotInScene.join(", ") || "none"}; in the scene and named by no story: ${sceneNotNamed.join(", ") || "none"}`);
  console.log(`  left aside: answer-bubble ids ${[...resp].filter(k => !invIds.includes(k)).sort().join(", ") || "none"}; names filled at run time ${[...templ].sort().join(", ") || "none"}${alias.size ? "; names given by a step's alias (its keys are checked) " + [...alias].sort().join(", ") : ""}`);
  console.log(`  states: ${idx.states.length}; ${steps} recorded steps (start included) and ${pics} review pictures, each in one state with its frames; positions: ${found}/${looked} uses found`);
  table.push({ id, things: invIds.length, states: idx.states.length, positions: pos.count, pairs: pairs.pairs.length, level: pairs.level.length, views: Object.keys(inv.views).length });
}
await browser.close(); srv.close();
let bytes = 0, blocks = 0; const walkD = d => { for (const f of fs.readdirSync(d)) { const p = path.join(d, f), s = fs.statSync(p); if (s.isDirectory()) walkD(p); else { bytes += s.size; blocks += Math.ceil(s.size / 4096) * 4096; } } }; walkD(FROM);
console.log(`size of ${path.relative(ROOT, FROM)}: ${(bytes / 1e6).toFixed(1)} MB in files (${(blocks / 1e6).toFixed(1)} MB on a 4 KB-block disk)`);
console.log(table.map(t => `${t.id}: ${t.things} things, ${t.states} states, ${t.positions} positions, ${t.pairs} pairs, ${t.level} level items, ${t.views} views`).join("\n"));
console.log(bad ? `${bad} FAILED` : "all checks passed");
process.exit(bad ? 1 : 0);
