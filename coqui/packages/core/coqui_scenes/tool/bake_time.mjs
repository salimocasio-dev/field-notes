#!/usr/bin/env node
// The bake time of each of a converted scene's states (El frente's, or --scene balcon, sala, patio, camino, campo, lago, banco, mostrador, estantes, frutas or esquina) in a release web
// build of the dev entry, in headless Chrome: each state's first bake, then each again on the same engine ("again").
//
//   flutter build web --release --no-web-resources-cdn -t tool/dev_main.dart     (in this package)
//   node tool/bake_time.mjs [--scene balcon|sala|patio|camino|campo|lago|banco|mostrador|estantes|frutas|esquina] [--shots DIR]
//
// It serves build/web on 127.0.0.1 (a free port), opens ?page=bake, waits for `window.coquiBakes` and prints each
// state's ms, then the least, the median and the most (and, for a set with glints on its water, what drawing them costs a frame). --shots DIR: also screenshots of ?page=pairs and of the scene.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const ROOT = path.resolve('build/web');
if (!fs.existsSync(path.join(ROOT, 'index.html'))) { console.error('build the dev entry first (see the top of this file)'); process.exit(2); }
const i = process.argv.indexOf('--shots'), SHOTS = i < 0 ? null : process.argv[i + 1];
const j = process.argv.indexOf('--scene'), SCENE = j < 0 ? null : process.argv[j + 1];
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf' };
const srv = http.createServer((req, res) => {
  let f = path.join(ROOT, decodeURIComponent(new URL(req.url, 'http://x').pathname));
  if (fs.existsSync(f) && fs.statSync(f).isDirectory()) f = path.join(f, 'index.html');
  if (!f.startsWith(ROOT) || !fs.existsSync(f)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream' });
  fs.createReadStream(f).pipe(res);
});
await new Promise(r => srv.listen(0, '127.0.0.1', r));
const base = `http://127.0.0.1:${srv.address().port}/`;
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 900, height: 1000 } });
await page.goto(base + '?page=bake' + (SCENE ? '&scene=' + SCENE : ''));
await page.waitForFunction(() => window.coquiBakes, null, { timeout: 120000 });
const ms = JSON.parse(await page.evaluate(() => window.coquiBakes));
for (const [k, v] of Object.entries(ms)) console.log(`${k}: ${v.toFixed(k.startsWith('glints') ? 3 : 1)} ms`);
for (const [what, keep] of [['first bakes', k => !k.endsWith(' again') && !k.startsWith('glints')], ['later bakes', k => k.endsWith(' again')]]) {
  const v = Object.entries(ms).filter(([k]) => keep(k)).map(([, x]) => x).sort((a, b) => a - b);
  if (!v.length) continue;
  const med = v.length % 2 ? v[(v.length - 1) / 2] : (v[v.length / 2 - 1] + v[v.length / 2]) / 2;
  console.log(`${what}, ${v.length} states: min ${v[0].toFixed(1)} ms, median ${med.toFixed(1)} ms, max ${v[v.length - 1].toFixed(1)} ms`);
}
if (SHOTS) {
  fs.mkdirSync(SHOTS, { recursive: true });
  for (const [name, q] of [['pairs', '?page=pairs'], ['scene', '?view=wide&w=' + encodeURIComponent(JSON.stringify({ door: 1, ab: { en: 'puerta', pose: 'wave', bub: 'hola', al: 1 } }))]]) {
    await page.goto(base + q);
    await page.waitForTimeout(6000);
    await page.screenshot({ path: path.join(SHOTS, name + '.png'), fullPage: true });
  }
}
await browser.close();
srv.close();
