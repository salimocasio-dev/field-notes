// ref/escenas: contact sheets of the frames, for looking at them (never into the repo).
//   node coqui/tool/ref/escenas/sheets.mjs OUTDIR [scene ...]      reads coqui/ref/escenas/ (or --from DIR), writes OUTDIR/<scene>-<what>.png
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const HERE = path.dirname(fileURLToPath(import.meta.url));
const arg = (k, d) => { const i = process.argv.indexOf(k); return i >= 0 ? process.argv[i + 1] : d; };
const FROM = path.resolve(arg("--from", path.join(HERE, "../../../ref/escenas")));
const pos = process.argv.slice(2).filter((a, i, A) => !a.startsWith("--") && !(A[i - 1] || "").startsWith("--"));
const OUTD = path.resolve(pos[0]); fs.mkdirSync(OUTD, { recursive: true });
const scenes = pos.length > 1 ? pos.slice(1) : fs.readdirSync(FROM).filter(d => fs.existsSync(path.join(FROM, d, "inventory.json"))).sort();
const b64 = f => "data:image/png;base64," + fs.readFileSync(f).toString("base64");
const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 1 });
async function sheet(name, cells, w) {
  const html = `<html><body style="margin:0;background:#222;color:#eee;font:11px monospace"><div style="display:flex;flex-wrap:wrap;gap:6px;padding:6px;width:${w}px">` +
    cells.map(c => `<div style="background:#000"><img src="${b64(c.f)}" style="display:block;image-rendering:pixelated;width:${c.w}px;height:${c.h}px"><div style="width:${c.w}px;overflow:hidden;white-space:nowrap">${c.label}</div></div>`).join("") + "</div></body></html>";
  await page.setContent(html); await page.setViewportSize({ width: w + 12, height: 400 });
  await page.screenshot({ path: path.join(OUTD, name), fullPage: true });
}
for (const s of scenes) {
  const dir = path.join(FROM, s), idx = JSON.parse(fs.readFileSync(path.join(dir, "frames/index.json"), "utf8")), pr = JSON.parse(fs.readFileSync(path.join(dir, "pairs.json"), "utf8"));
  const F = (st, k) => ({ f: path.join(dir, "frames", st.files[k]), label: `${st.id} ${k} ${st.files[k] !== `${st.id}.${k}.png` ? "=" + st.files[k].split(".")[0] : ""}` });
  const per = 60;
  for (let i = 0; i < idx.states.length; i += per) {
    const part = idx.states.slice(i, i + per), n = Math.floor(i / per);
    await sheet(`${s}-full-${n}.png`, part.map(st => ({ ...F(st, "full"), w: 240, h: 216 })), 1500);
    await sheet(`${s}-nochar-${n}.png`, part.map(st => ({ ...F(st, "nochar"), w: 240, h: 216 })), 1500);
    const views = Object.keys(part[0].files).filter(k => k.startsWith("full.") );
    await sheet(`${s}-views-${n}.png`, part.flatMap(st => views.filter(v => st.files[v]).map(v => ({ ...F(st, v), w: 196, h: 216 }))), 1500);
  }
  const bgs = [...new Set(idx.states.map(st => st.files.bg))];
  await sheet(`${s}-bg.png`, bgs.map(f => ({ f: path.join(dir, "frames", f), label: f, w: 240, h: 216 })), 1500);
  const cells = [];
  for (const p of pr.pairs) for (const k of ["si", "no"]) cells.push({ f: path.join(dir, "pairs", p[k].png), label: `${p.w} ${k} (${p[k].scene})`, w: 392, h: 208 });
  if (cells.length) await sheet(`${s}-pairs.png`, cells, 1640);
  const lv = [];
  for (const q of pr.level) q.pictures.forEach((p, j) => { if (p.png) lv.push({ f: path.join(dir, "pairs", p.png), label: `${q.w} ${j}: ${p.pair}.${p.side}`, w: 192, h: 212 }); });
  if (lv.length) await sheet(`${s}-level.png`, lv, 1640);
  console.log(s, "sheets written");
}
await browser.close();
