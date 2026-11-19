// Where habla-prueba.html puts each part of the voice test, at the sizes of the old checks, from the old page itself: the expected
// values of test/voice_layout_test.dart.
//
//   node tool/prueba_layout.mjs            writes test/fixtures/prueba_layout.json
//   node tool/prueba_layout.mjs --check    compares it with what the old page gives now (exit 1 if they differ)
//
// It serves the worktree at /field-notes/, opens historia/habla-prueba.html with the page's own recogniser stub (?mic=stub:...), reads the
// rect of each part (getBoundingClientRect, CSS px) before the mic, and again once the first line has been heard. Nothing leaves the
// machine: every request that is not to the local server is refused. Needs Node 22 and the pre-installed Playwright.

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../../../..');
const outFile = path.resolve(here, '../test/fixtures/prueba_layout.json');
const check = process.argv.includes('--check');

const SIZES = [
  { w: 412, h: 915, r: 2.625 },
  { w: 390, h: 844, r: 3 },
  { w: 360, h: 640, r: 3 },
  { w: 844, h: 390, r: 3 },
];
const PARTS = ['#bar', '#ins', '#n', '#line', '#heard', '#st', '#mic', '#next'];
const STUB = 'hola abuela|none|no/nó';

const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json' };
const server = http.createServer((rq, rs) => {
  const u = decodeURIComponent(rq.url.split('?')[0]);
  if (!u.startsWith('/field-notes/')) { rs.writeHead(404); rs.end(); return; }
  const f = path.join(repo, u.slice('/field-notes/'.length));
  fs.readFile(f, (e, b) => {
    if (e) { rs.writeHead(404); rs.end(); return; }
    rs.writeHead(200, { 'content-type': MIME[path.extname(f)] || 'application/octet-stream', 'cache-control': 'no-store' });
    rs.end(b);
  });
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const port = server.address().port;
const browser = await chromium.launch({ args: ['--mute-audio'] });
const real = (ms) => new Promise((r) => setTimeout(r, ms));
const round = (n) => Math.round(n * 100) / 100;
const read = (pg) =>
  pg.evaluate((parts) => Object.fromEntries(parts.map((k) => {
    const e = document.querySelector(k), b = e.getBoundingClientRect(), cs = getComputedStyle(e);
    return [k, [b.top, b.bottom, b.left, b.right, cs.display === 'none' || b.width === 0 ? 0 : 1]];
  })), PARTS);

const sizes = {};
try {
  for (const s of SIZES) {
    const ctx = await browser.newContext({ viewport: { width: s.w, height: s.h }, deviceScaleFactor: s.r, isMobile: true, hasTouch: true, locale: 'en-US', reducedMotion: 'reduce' });
    await ctx.route((url) => !/^http:\/\/127\.0\.0\.1[:/]/.test(url.href), (r) => r.abort());
    const pg = await ctx.newPage();
    await pg.goto(`http://127.0.0.1:${port}/field-notes/historia/habla-prueba.html?mic=stub:${STUB}`);
    await pg.waitForFunction("document.getElementById('app').dataset.s==='ready'", null, { timeout: 10000 });
    await real(200);
    const ready = await read(pg);
    await pg.click('#mic');
    await pg.waitForFunction("document.getElementById('app').dataset.s==='done'", null, { timeout: 10000 });
    await real(200);
    const done = await read(pg);
    const fix = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, v.map(round)]));
    sizes[`${s.w}x${s.h}@${s.r}`] = { width: s.w, height: s.h, ratio: s.r, ready: fix(ready), done: fix(done) };
    await ctx.close();
  }
} finally {
  await browser.close();
  server.close();
}
const text = JSON.stringify({ about: 'getBoundingClientRect of each part of habla-prueba.html, [top, bottom, left, right, shown] in CSS px, made by tool/prueba_layout.mjs from the page itself. Do not edit.', sizes }, null, 1) + '\n';
if (check) {
  const same = fs.existsSync(outFile) && fs.readFileSync(outFile, 'utf8') === text;
  console.log(same ? 'prueba_layout.json is current' : 'prueba_layout.json is NOT current');
  process.exit(same ? 0 : 1);
}
fs.mkdirSync(path.dirname(outFile), { recursive: true });
fs.writeFileSync(outFile, text);
console.log(`wrote ${outFile}: ${Object.keys(sizes).length} sizes`);
