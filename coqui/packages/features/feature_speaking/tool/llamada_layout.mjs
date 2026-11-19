// Where llamada.js puts each element of the call screen, at the sizes the old check looked at, from the old page itself:
// the expected values of test/call_layout_test.dart.
//
//   node tool/llamada_layout.mjs            writes test/fixtures/llamada_layout.json
//   node tool/llamada_layout.mjs --check    compares it with what the old page gives now (exit 1 if they differ)
//
// It serves the worktree at /field-notes/, opens historia/app.html with the page's own call stub (?callstub=1&stub=manual) in the
// progress state "todo", opens La casa's call, taps the call disc and steps the stub to Danny's first line (so Help shows), and
// reads the rect of each element (getBoundingClientRect, CSS px). Nothing leaves the machine: every request that is not to the
// local server is refused. Needs Node 22 and the pre-installed Playwright.

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../../../..');
const outFile = path.resolve(here, '../test/fixtures/llamada_layout.json');
const check = process.argv.includes('--check');

const SIZES = [
  { w: 412, h: 915, r: 2.625 },
  { w: 390, h: 844, r: 3 },
  { w: 360, h: 640, r: 3 },
  { w: 844, h: 390, r: 3 },
];
const PARTS = ['.lx', '.lt', 'canvas', '.ld', '.lh', '.lmic', '.ldisc', '.ll', '.lo', '.lhelp'];

const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.png': 'image/png', '.css': 'text/css' };
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
const seed = fs.readFileSync(path.join(repo, 'coqui/ref/pantallas/seeds/todo.json'), 'utf8');
const browser = await chromium.launch({ args: ['--mute-audio'] });
const real = (ms) => new Promise((r) => setTimeout(r, ms));
const round = (n) => Math.round(n * 100) / 100;

const sizes = {};
try {
  for (const s of SIZES) {
    const ctx = await browser.newContext({ viewport: { width: s.w, height: s.h }, deviceScaleFactor: s.r, isMobile: true, hasTouch: true, locale: 'en-US', serviceWorkers: 'block' });
    await ctx.addInitScript(`localStorage.setItem('coqui.palabras.v1',${JSON.stringify(seed)})`);
    await ctx.route((url) => !/^http:\/\/127\.0\.0\.1[:/]/.test(url.href), (r) => r.abort());
    const pg = await ctx.newPage();
    await pg.goto(`http://127.0.0.1:${port}/field-notes/historia/app.html?tab=hablar&callstub=1&stub=manual`);
    await pg.waitForFunction('window.App&&App.ready', null, { timeout: 30000 });
    await real(300);
    await pg.click('#t-hablar .card.cc >> nth=0');
    await pg.waitForFunction('Llamada.activo', null, { timeout: 5000 });
    await real(200);
    const idle = await pg.evaluate((parts) => Object.fromEntries(parts.map((k) => { const b = document.querySelector('#llam ' + k).getBoundingClientRect(); return [k, [b.top, b.bottom, b.left, b.right]]; })), PARTS);
    await pg.click('#llam .ldisc');
    await pg.waitForFunction("Llamada.estado==='connecting'&&!!CallStub.opts", null, { timeout: 5000 });
    await pg.evaluate("CallStub.go('connect');CallStub.go('danny1')");
    await real(500);
    const live = await pg.evaluate((parts) => Object.fromEntries(parts.map((k) => { const b = document.querySelector('#llam ' + k).getBoundingClientRect(); return [k, [b.top, b.bottom, b.left, b.right]]; })), PARTS);
    sizes[`${s.w}x${s.h}@${s.r}`] = {
      width: s.w, height: s.h, ratio: s.r,
      idle: Object.fromEntries(Object.entries(idle).map(([k, v]) => [k, v.map(round)])),
      live: Object.fromEntries(Object.entries(live).map(([k, v]) => [k, v.map(round)])),
    };
    await ctx.close();
  }
} finally {
  await browser.close();
  server.close();
}
const text = JSON.stringify({ about: 'getBoundingClientRect of each part of #llam, [top, bottom, left, right] in CSS px, made by tool/llamada_layout.mjs from historia/llamada.js on the page itself. Do not edit.', sizes }, null, 1) + '\n';
if (check) {
  const same = fs.existsSync(outFile) && fs.readFileSync(outFile, 'utf8') === text;
  console.log(same ? 'llamada_layout.json is current' : 'llamada_layout.json is NOT current');
  process.exit(same ? 0 : 1);
}
fs.mkdirSync(path.dirname(outFile), { recursive: true });
fs.writeFileSync(outFile, text);
console.log(`wrote ${outFile}: ${Object.keys(sizes).length} sizes`);
