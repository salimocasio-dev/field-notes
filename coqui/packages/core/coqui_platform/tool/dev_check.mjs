// Runs the dev screen (tool/dev_main.dart) in headless Chromium and checks what it measured.
//
//   flutter build web -t tool/dev_main.dart --no-web-resources-cdn    (in coqui/packages/core/coqui_platform)
//   node tool/dev_check.mjs [--json=<file>]
//
// A local server serves build/web at / and the worktree's historia/audio/ at /audio/. The page runs
// itself (?auto=1). It passes when every gap measured on the output bus is within 60 ms of the pause
// asked for, every line played to its end mark, every SFX call fired without an error (and sounded:
// loud frames where the speaker is), and the recognition attempt ended inside its limit (6 s + 2.5 s)
// with an error code or nothing heard. Exit code 0 or 1.
import { createServer } from "node:http";
import { readFile, stat, writeFile } from "node:fs/promises";
import { dirname, extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

const here = dirname(fileURLToPath(import.meta.url));
const web = join(here, "../build/web");
const audio = join(here, "../../../../../historia/audio");
const jsonOut = (process.argv.find((a) => a.startsWith("--json=")) || "").slice(7);
// --el=<dir>: a folder holding the ElevenLabs client's lib.iife.js (from the npm package @elevenlabs/client@1.25.0,
// the version llamada.js pins). It is served at /el/, with a module /el/esm.js that runs it and exports its
// Conversation, as the CDN's +esm build does; the page then loads that in place of the CDN (?el=el/esm.js).
const elDir = (process.argv.find((a) => a.startsWith("--el=")) || "").slice(5);
const esm = 'const t=await (await fetch(new URL("./lib.iife.js",import.meta.url))).text();(0,eval)(t);' +
  "export const Conversation=globalThis.ElevenLabsClient.Conversation;\n";

const types = { ".html": "text/html", ".js": "text/javascript", ".mjs": "text/javascript", ".json": "application/json",
  ".wasm": "application/wasm", ".mp3": "audio/mpeg", ".png": "image/png", ".otf": "font/otf", ".ttf": "font/ttf", ".css": "text/css" };

const server = createServer(async (rq, rs) => {
  try {
    const path = decodeURIComponent(new URL(rq.url, "http://x").pathname);
    if (elDir && path === "/el/esm.js") {
      rs.writeHead(200, { "content-type": "text/javascript", "cache-control": "no-store" });
      rs.end(esm);
      return;
    }
    if (elDir && path === "/el/lib.iife.js") {
      rs.writeHead(200, { "content-type": "text/javascript", "cache-control": "no-store" });
      rs.end(await readFile(join(elDir, "lib.iife.js")));
      return;
    }
    const [root, rel] = path.startsWith("/audio/") ? [audio, path.slice(7)] : [web, path === "/" ? "index.html" : path.slice(1)];
    const file = normalize(join(root, rel));
    if (!file.startsWith(root)) throw new Error("outside");
    await stat(file);
    rs.writeHead(200, { "content-type": types[extname(file)] || "application/octet-stream", "cache-control": "no-store" });
    rs.end(await readFile(file));
  } catch (e) {
    rs.writeHead(404);
    rs.end();
  }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const port = server.address().port;

const browser = await chromium.launch({
  args: ["--use-fake-device-for-media-stream", "--use-fake-ui-for-media-stream", "--autoplay-policy=no-user-gesture-required"],
});
let failed = [];
try {
  const page = await browser.newPage();
  const errors = [];
  page.on("pageerror", (e) => errors.push(String(e)));
  // What the old app leaves in localStorage: the page must read each from its space.
  const old = { "coqui.palabras.v1": '{"palabras":{},"v":1}', "coqui.juego.ult": '{"la-lluvia:3":"b"}', "coqui.juego.mem": '{"nombre":"Ana"}', "coqui.leer.tam": "2" };
  await page.addInitScript((o) => { for (const [k, v] of Object.entries(o)) localStorage.setItem(k, v); }, old);
  await page.goto(`http://127.0.0.1:${port}/?auto=1${elDir ? "&el=el/esm.js" : ""}`);
  await page.waitForFunction(() => window.__coquiDevDone === true, null, { timeout: 240000 });
  const r = JSON.parse(await page.evaluate(() => window.__coquiDev));
  if (jsonOut) await writeFile(jsonOut, JSON.stringify(r, null, 1) + "\n");

  const out = (s) => process.stdout.write(s + "\n");
  if (r.error) failed.push("the page stopped: " + r.error);
  out("AppInfo: " + JSON.stringify(r.appInfo));
  out("storage: " + JSON.stringify(r.storage));
  out("haptics: " + r.haptics);
  const want = { "progress: coqui.palabras.v1": old["coqui.palabras.v1"], "juego: ult (coqui.juego.ult)": old["coqui.juego.ult"],
    "juego: mem (coqui.juego.mem)": old["coqui.juego.mem"], "leer: tam (coqui.leer.tam)": old["coqui.leer.tam"], "dev: marca (coqui.dev.marca)": "order 18" };
  for (const [k, v] of Object.entries(want)) if ((r.storage || {})[k] !== v) failed.push(`storage ${k}: ${(r.storage || {})[k]}, not ${v}`);
  const still = await page.evaluate((ks) => ks.map((k) => localStorage.getItem(k)), Object.keys(old));
  if (still.some((v, i) => v !== Object.values(old)[i])) failed.push("an old key changed or went");
  const L = r.lines || { gaps: [], ended: [] };
  out("gap after              asked   measured   off    (context clock)");
  for (const g of L.gaps) {
    out(`${g.after.padEnd(20)} ${String(g.asked).padStart(6)} ${String(g.gap).padStart(10)} ${String(g.off).padStart(6)}    (${g.clock})`);
    if (g.off == null || Math.abs(g.off) > 60) failed.push(`gap after ${g.after}: ${g.gap} ms for ${g.asked} asked`);
  }
  if (L.gaps.length !== 9) failed.push(`${L.gaps.length} gaps, not 9`);
  out(`lines played to their end mark: ${L.ended.filter(Boolean).length} of ${L.ended.length}; worst off: ${L.worstOffMs} ms`);
  if (L.ended.length !== 10 || !L.ended.every(Boolean)) failed.push("not every line played to its end mark");
  for (const [k, v] of Object.entries(r.sfx || {})) {
    out(`SFX.${k}: ${v}`);
    if (!v.startsWith("fired, no error")) failed.push(`SFX.${k}: ${v}`);
    if (k !== "calla" && / 0 loud frames/.test(v)) failed.push(`SFX.${k} made no sound`);
  }
  if (Object.keys(r.sfx || {}).length !== 18) failed.push("not 18 SFX names");
  const S = r.speech || {};
  out("speech: " + JSON.stringify(S));
  // It cannot hear here: a clear end is an error code, or nothing heard (a miss, as juego.js counts it),
  // inside the limit, never a hang.
  if (!S.endedAfterMs || S.endedAfterMs > S.limitMs + 500 || String(S.error).startsWith("HUNG"))
    failed.push("the recognition did not end inside its limit");
  const C = r.callLibrary || {};
  out("call library: " + JSON.stringify(C));
  if (elDir && !(C.startSessionIsFunction && C.available && !C.error)) failed.push("the local copy of the client did not load");
  if (!elDir && C.pinned && !C.startSessionIsFunction) out("  (the pinned CDN copy could not be loaded from here: " + C.error + ")");
  const T = r.stubCall || {};
  out("stub call (" + T.ms + " ms):\n  " + (T.events || []).join("\n  "));
  const wantStub = ["Connected", "Mode speaking", "AgentLine ¡Hola! Soy Danny. ¿Cómo estás?", "Mode listening", "Heard Hola. Bien, gracias.",
    "Mode speaking", "AgentLine Eso. Mira. ¿Quieres jugo?", 'Tool show_picture {"picture":"jugo"}', "Mode listening", "Heard Sí, quiero jugo.",
    "Mode listening", "Heard Adiós.", "Mode speaking", "AgentLine Eso. Hasta mañana.", "Mode listening", "Ended user"];
  if (JSON.stringify(T.events) !== JSON.stringify(wantStub) || JSON.stringify(T.sent) !== '["(fin)"]' || !T.ended)
    failed.push("the stub call's events are not the old stub's");
  for (const e of errors) failed.push("page error: " + e);
} finally {
  await browser.close();
  server.close();
}
if (failed.length) {
  process.stdout.write("FAILED:\n  " + failed.join("\n  ") + "\n");
  process.exit(1);
}
process.stdout.write("all checks passed\n");
