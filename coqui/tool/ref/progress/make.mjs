// ref/progress: historia/palabras.js run as it is, in node, on the scripted sequences of sequences.mjs,
// once under TZ=UTC and once under TZ=America/New_York. See README.md in this folder.
//
//   node coqui/tool/ref/progress/make.mjs            writes coqui/ref/progress/ (both time zones, and index.json)
//   node coqui/tool/ref/progress/make.mjs --tz <TZ>  (internal: one time zone; started by the line above with TZ set)
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { SEQUENCES } from "./sequences.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../../../..");
const PAL_PATH = path.join(ROOT, "historia/palabras.js");
const OUT = path.join(ROOT, "coqui/ref/progress");
const ZONES = ["UTC", "America/New_York"];
const KEY = "coqui.palabras.v1";
const slug = tz => tz.replace(/\//g, "_");

// The old function, and the ProgressStore member page 12 maps it to (null: none).
const MEMBERS = {
  rec: null, oida: "heard", responde: "answer", cuento: "storyFinished", presume: "presume", oido: "listened",
  minutos: "addMinutes", vence: "due", racha: "streak", save: null, norm: "normalize", abiertaHabla: "openForSpeaking",
  db: "raw", STAGES: null, reset: "reset",
};
const NOTES = {
  rec: "no ProgressStore member makes a record without hearing it; a Dart replay cannot apply this call",
  save: "no member: the Dart store saves after every change; the store is unchanged by this call",
  norm: "normalize() is a top-level function of coqui_contracts, not a ProgressStore member",
  STAGES: "a constant of palabras.js, read only",
  db: "the getter PAL.db; ProgressStore.raw",
};
// Positional JS arguments -> the Dart call's arguments, by name (null: the call has no Dart form).
function dartArgs(fn, a) {
  switch (fn) {
    case "oida": case "rec": case "abiertaHabla": return { w: a[0] };
    case "responde": return { w: a[0], skill: a[1], ok: !!a[2], ms: a[3] === undefined ? null : a[3], intro: !!a[4] };
    case "cuento": {
      const S = a[0] || {};
      return { result: { id: S.id, focusWords: S.focus_words || [], backAgain: S.back_again || [], lost: S._lost || 0, log: a[1] || [] } };
    }
    case "presume": return { words: a[0] || [], stories: a[1] || [], log: a[2] || [] };
    case "oido": return { id: a[0] };
    case "minutos": return { m: a[0] };
    case "vence": return { skill: a[0], at: a[1] || null }; // palabras.js: t||now(), so 0 and absent both mean now
    case "norm": return a[0] === null || a[0] === undefined || typeof a[0] === "string" ? { s: a[0] === undefined ? null : a[0] } : null;
    default: return {};
  }
}

function localLabel(ms) {
  const d = new Date(ms), p = n => String(n).padStart(2, "0"), off = -d.getTimezoneOffset();
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}${off >= 0 ? "+" : "-"}${p(Math.floor(Math.abs(off) / 60))}:${p(Math.abs(off) % 60)}`;
}
// "YYYY-MM-DD HH:MM" in local time (this process's TZ) -> epoch ms
function T(s) {
  const m = /^(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d)$/.exec(s);
  if (!m) throw new Error("bad time " + s);
  return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], 0, 0).getTime();
}
const clone = v => (v === undefined ? undefined : JSON.parse(JSON.stringify(v)));

function runSequence(seq, src) {
  const setup = seq.setup || {};
  const storage = setup.storage || "memory", win = setup.window || "hook";
  let stored = setup.stored === undefined ? null : setup.stored;
  const ctx = { __CLOCK: 0 };
  if (storage !== "absent") {
    ctx.localStorage = {
      getItem(k) { if (storage === "throws") throw new Error("storage blocked"); return k === KEY ? stored : null; },
      setItem(k, v) { if (storage === "throws") throw new Error("storage blocked"); if (k === KEY) stored = String(v); },
    };
  }
  if (win !== "none") ctx.window = { __PAL_NOW: 0 };
  vm.createContext(ctx);
  // The clock. "hook": palabras.js's own window.__PAL_NOW; Date.now is made to throw, so a read of the real clock cannot go unnoticed.
  // "zero" and "none": __PAL_NOW is 0 or there is no window, palabras.js reads Date.now, which is given the same scripted time.
  vm.runInContext(win === "hook" ? "Date.now=()=>{throw new Error('palabras.js read the real clock')}" : "Date.now=()=>globalThis.__CLOCK", ctx);
  vm.runInContext(src, ctx, { filename: PAL_PATH });
  const PAL = vm.runInContext("PAL", ctx);
  const savedNow = () => stored;
  const initial = { store: clone(PAL.db), saved: savedNow() };
  const steps = [];
  const call = (now, fn, ...args) => {
    if (!Number.isFinite(now) || now <= 0) throw new Error(`${seq.id}: bad clock ${now}`);
    ctx.__CLOCK = now;
    if (win !== "none") ctx.window.__PAL_NOW = win === "zero" ? 0 : now;
    const argsCopy = clone(args.map(a => (a === undefined ? null : a)));
    const undefArgs = args.map((a, i) => (a === undefined ? i : -1)).filter(i => i >= 0);
    let ret, threw = null;
    try {
      if (fn === "db") ret = PAL.db;
      else if (fn === "STAGES") ret = PAL.STAGES;
      else ret = PAL[fn](...args);
    } catch (e) { threw = String(e && e.message || e); }
    const st = {
      i: steps.length, now, local: localLabel(now), call: fn, args: argsCopy,
      member: MEMBERS[fn], dart: MEMBERS[fn] === null && fn !== "save" && fn !== "STAGES" ? null : dartArgs(fn, args),
    };
    if (undefArgs.length) st.undefinedArgs = undefArgs; // positions passed as undefined (written as null in args)
    if (NOTES[fn]) st.note = NOTES[fn];
    if (threw !== null) st.throws = threw; // the old code threw (the message is V8's); the store is as it was left
    else if (ret !== undefined) st.returns = clone(ret);
    st.store = clone(PAL.db);
    const sv = savedNow();
    let parsed;
    try { parsed = sv === null ? null : JSON.parse(sv); } catch (e) { parsed = undefined; }
    if (parsed !== undefined && sv !== null && JSON.stringify(parsed) === JSON.stringify(st.store)) st.saved = "same";
    else st.saved = parsed === undefined ? { text: sv } : parsed;
    steps.push(st);
    return ret;
  };
  seq.run(T, call);
  return { initial, steps };
}

function stringify(doc) {
  // one step per line, everything else pretty: small files, readable diffs
  const { steps, ...head } = doc;
  const h = JSON.stringify(head, null, 1).replace(/\n}$/, "");
  return h + ',\n "steps": [\n' + steps.map(s => "  " + JSON.stringify(s)).join(",\n") + "\n ]\n}\n";
}

function child(tz) {
  if (process.env.TZ !== tz) throw new Error("TZ must be set in the environment");
  const src = fs.readFileSync(PAL_PATH, "utf8");
  const dir = path.join(OUT, slug(tz));
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
  for (const seq of SEQUENCES) {
    const { initial, steps } = runSequence(seq, src);
    const doc = {
      id: seq.id, tz, title: seq.title,
      source: "historia/palabras.js", sourceSha256: crypto.createHash("sha256").update(src).digest("hex"),
      setup: { stored: seq.setup && seq.setup.stored !== undefined ? seq.setup.stored : null, storage: (seq.setup && seq.setup.storage) || "memory", clock: (seq.setup && seq.setup.window) || "hook" },
      dartReplayable: !steps.some(s => s.call === "rec"),
      initial, steps,
    };
    fs.writeFileSync(path.join(dir, seq.id + ".json"), stringify(doc));
  }
}

function parent() {
  for (const tz of ZONES) {
    const r = spawnSync(process.execPath, [fileURLToPath(import.meta.url), "--tz", tz], { env: { ...process.env, TZ: tz }, stdio: "inherit" });
    if (r.status !== 0) process.exit(r.status || 1);
  }
  const files = [];
  for (const tz of ZONES) for (const f of fs.readdirSync(path.join(OUT, slug(tz))).sort()) {
    const rel = slug(tz) + "/" + f, buf = fs.readFileSync(path.join(OUT, rel)), doc = JSON.parse(buf);
    const calls = {};
    doc.steps.forEach(s => { calls[s.call] = (calls[s.call] || 0) + 1; });
    files.push({ file: rel, id: doc.id, tz, steps: doc.steps.length, dartReplayable: doc.dartReplayable, calls, sha256: crypto.createHash("sha256").update(buf).digest("hex") });
  }
  const used = new Set(files.flatMap(f => Object.keys(f.calls)));
  const index = { made: "node coqui/tool/ref/progress/make.mjs", zones: ZONES, sequences: SEQUENCES.length, exported: Object.keys(MEMBERS), notCalled: Object.keys(MEMBERS).filter(k => !used.has(k)), files };
  fs.writeFileSync(path.join(OUT, "index.json"), JSON.stringify(index, null, 1) + "\n");
  console.log(`ref/progress: ${files.length} files (${SEQUENCES.length} sequences x ${ZONES.length} zones); not called: ${index.notCalled.join(", ") || "none"}`);
}

if (process.argv[2] === "--tz") child(process.argv[3]);
else parent();
