// The call stub's data, from the old page's own stub (historia/llamada.js, installStub), run in node.
//
//   node tool/llamada_stub.mjs          (in coqui/packages/core/coqui_platform)
//
// It runs llamada.js as the page would with ?callstub=1 (and the ?stub= options), on a fake clock, and
// writes three files. A second run is byte-identical (the clock is fake; nothing random is written).
//
//   assets/call_stub.json                 the stub's lines and errors, for the package's own stub
//                                         (lib/src/call/call_stub.dart): its Spanish lines are the old
//                                         stub's test text, kept here as data, never in code
//   test/fixtures/llamada_stub_trace.json what the old stub does, call by call, in each scenario of
//                                         llamada_check.py (the times in ms, the callbacks it calls)
//   test/fixtures/llamada_stub_js.dart    installStub's own source, for the Chrome tests: there it is the
//                                         fake JS client the interop is checked against
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const src = readFileSync(join(here, "../../../../../historia/llamada.js"), "utf8");

// ---------- a fake clock
function clock() {
  let now = 0, seq = 0;
  const q = [];
  return {
    get now() { return now; },
    setTimeout(f, ms) { const id = ++seq; q.push({ id, at: now + Math.max(0, +ms || 0), f }); return id; },
    clearTimeout(id) { const i = q.findIndex((x) => x.id === id); if (i >= 0) q.splice(i, 1); },
    // runs the timers in time order (ties in the order they were set), letting promises settle after each
    async run(until) {
      for (;;) {
        await settle();
        if (!q.length) return;
        q.sort((a, b) => a.at - b.at || a.id - b.id);
        if (q[0].at > until) { now = until; return; }
        const t = q.shift();
        now = t.at;
        t.f();
      }
    },
  };
}
const settle = async () => { for (let i = 0; i < 5; i++) await Promise.resolve(); };

// ---------- llamada.js, loaded as the page loads it, with ?callstub=1&stub=<opts>
function load(opts, clk) {
  const window = {};
  const location = { search: "?callstub=1" + (opts.length ? "&stub=" + opts.join(",") : "") };
  const performance = { now: () => clk.now };
  const noop = () => {};
  const document = { createElement: () => ({}), head: { appendChild: noop }, getElementById: () => null, body: { style: {} } };
  const f = new Function("window", "location", "performance", "document", "setTimeout", "clearTimeout", "setInterval", "clearInterval",
    "addEventListener", "removeEventListener", "matchMedia",
    src + "\n;return window;");
  return f(window, location, performance, document, (g, ms) => clk.setTimeout(g, ms), (id) => clk.clearTimeout(id),
    () => 0, noop, noop, noop, () => ({ matches: false }));
}

// The options the page passes (llamada.js, inicia), with every callback written down.
function options(log, clk, onEvent) {
  const at = () => Math.round(clk.now);
  const push = (e) => { log.push([at(), ...e]); onEvent && onEvent(e); };
  return {
    agentId: "agent_3301m795q3xtfpx8c99zc0s870vm",
    connectionType: "websocket",
    dynamicVariables: { place: "La casa", job: "job", words_open: "a, b", words_heard: "", minutes: "5", opening: "opening" },
    clientTools: { show_picture: (p) => { push(["tool", p]); return "shown"; } },
    onConnect: (d) => push(["connect", d]),
    onDisconnect: (d) => push(["disconnect", d && d.reason]),
    onError: (e) => push(["error", String((e && e.message) || e || "")]),
    onMessage: (m) => push(["message", m.role, m.source, m.message]),
    onModeChange: (m) => push(["mode", m && m.mode]),
  };
}

// ---------- the scenarios of llamada_check.py, at the level of the session (what the page's call screen does is
// not here: only what it sends and when it ends the call, as llamada.js does it)
//   fin:  the learner's goodbye ("Adiós." / "Hasta mañana.") sends "(fin)" at once (enviaFin)
//   endOnGoodbye: the call ends when the goodbye line is over (the first "listening" after it), 400 ms later
//   endAt: the page ends the call at this time (the 15 s cap after "(fin)", or a test's own end)
const scenarios = {
  "natural call": { opts: [], fin: true, endOnGoodbye: true },
  "the learner's 'Hasta mañana.'": { opts: ["hasta"], fin: true, endOnGoodbye: true },
  "Danny's own goodbye": { opts: ["dannybye"], fin: false, endOnGoodbye: true },
  "goodbye loop": { opts: ["loop"], fin: true, endOnGoodbye: true },
  "Danny's own goodbye followed by the loop": { opts: ["dannybye", "loop"], fin: false, endOnGoodbye: true },
  "no answer to (fin)": { opts: ["nofin"], fin: true, endAfterFin: 15000 },
  "refused microphone": { opts: ["mic"] },
  "failed start": { opts: ["fail"] },
};

const goodbye = (t) => /\badi[oó]s\b|\bhasta ma[nñ]ana\b/i.test(t);
const traces = {};
for (const [name, sc] of Object.entries(scenarios)) {
  const clk = clock(), log = [];
  const w = load(sc.opts, clk);
  let conv = null, fin = null, ended = false;
  const end = (why) => { if (ended) return; ended = true; log.push([Math.round(clk.now), "endSession", why]); if (conv) conv.endSession(); };
  const o = options(log, clk, (e) => {
    if (e[0] === "message" && e[1] === "user" && sc.fin && !fin && goodbye(e[3])) {
      fin = { at: clk.now, seen: false };
      log.push([Math.round(clk.now), "sendUserMessage", "(fin)"]);
      conv.sendUserMessage("(fin)");
      if (sc.endAfterFin) clk.setTimeout(() => end("cap"), sc.endAfterFin);
    }
    if (e[0] === "message" && e[1] === "agent" && !sc.fin && !fin && goodbye(e[3])) fin = { at: clk.now, seen: true };
    if (fin && e[0] === "mode" && e[1] === "speaking") fin.seen = true;
    if (fin && sc.endOnGoodbye && e[0] === "mode" && e[1] === "listening" && fin.seen) clk.setTimeout(() => end("fin"), 400);
  });
  w.ELConv.startSession(o).then((c) => { conv = c; log.push([Math.round(clk.now), "resolved"]); },
    (e) => log.push([Math.round(clk.now), "rejected", e.name, e.message]));
  await clk.run(60000);
  traces[name] = { opts: sc.opts, log, sent: w.CallStub.sent, ended: w.CallStub.ended, modes: w.CallStub.log };
}

// ---------- the lines, step by step (?stub=manual): every step's callbacks
async function steps(opts, drive) {
  const clk = clock(), log = [];
  const w = load(["manual", ...opts], clk);
  let conv = null;
  w.ELConv.startSession(options(log, clk)).then((c) => { conv = c; });
  await drive(w.CallStub, () => conv, clk);
  return { log, names: w.CallStub.names };
}
const lastText = (log) => log.filter((e) => e[1] === "message").map((e) => e[4]);
const manual = await steps([], async (S, c, clk) => {
  for (const n of ["connect", "danny1", "you1", "talk1", "quiet1", "heard1", "danny2", "you2", "talk2", "quiet2", "heard2", "you3", "talk3", "quiet3", "heard3", "danny3"]) {
    S.go(n);
    await clk.run(clk.now + 600);
  }
  c().sendUserMessage("(fin)");
  await clk.run(clk.now + 5000);
});
const hasta = await steps(["hasta"], async (S, c, clk) => { S.go("connect"); await clk.run(10); S.go("heard3"); await clk.run(100); });
const loop = await steps(["loop"], async (S, c, clk) => { S.go("connect"); await clk.run(10); S.go("heard3"); await clk.run(clk.now + 6400); });
const err = async (o) => {
  const clk = clock(), w = load([o], clk);
  let got = null;
  w.ELConv.startSession(options([], clk)).catch((e) => { got = { name: e.name, message: e.message }; });
  await clk.run(5000);
  return got;
};
const t = lastText(manual.log);
const loopLines = lastText(loop.log).slice(1);
const tool = manual.log.find((e) => e[1] === "tool");
const connect = manual.log.find((e) => e[1] === "connect");
const stub = {
  note: "Made by tool/llamada_stub.mjs from historia/llamada.js (installStub). Test text of the old page's stub. Do not edit by hand.",
  steps: manual.names,
  lines: {
    danny1: t[0], heard1: t[1], danny2: t[2], heard2: t[3], heard3: t[4], danny3: t[5], finReply: t[6],
    heard3Hasta: lastText(hasta.log)[0], loopEven: loopLines[0], loopOdd: loopLines[1],
  },
  picture: tool[2],
  connect: connect[2],
  micError: await err("mic"),
  failError: await err("fail"),
};
if (Object.values(stub.lines).some((v) => typeof v !== "string") || t.length !== 7) throw new Error("the stub's lines were not all found: " + JSON.stringify(stub.lines));

const js = src.slice(src.indexOf("  function installStub(){"), src.indexOf("  if(STUB)installStub();"));
if (!js.includes("window.ELConv={startSession")) throw new Error("installStub was not found");

writeFileSync(join(here, "../assets/call_stub.json"), JSON.stringify(stub, null, 1) + "\n");
writeFileSync(join(here, "../test/fixtures/llamada_stub_trace.json"),
  JSON.stringify({ note: "Made by tool/llamada_stub.mjs from historia/llamada.js. Do not edit by hand.", traces }, null, 1) + "\n");
writeFileSync(join(here, "../test/fixtures/llamada_stub_js.dart"),
  "// Made by tool/llamada_stub.mjs from historia/llamada.js (installStub, as it is). Do not edit by hand.\n" +
  "// The old page's fake ElevenLabs client: the Chrome tests run the interop against it.\n\n" +
  "const llamadaInstallStub = r'''\n" + js.replace(/'''/g, "") + "''';\n");
process.stdout.write(`${Object.keys(traces).length} scenarios; ${manual.names.length} steps; lines: ${Object.keys(stub.lines).length}\n`);
