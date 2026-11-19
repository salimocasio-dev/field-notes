#!/usr/bin/env node
// Order 03, proof of the site build: opens a build made by tool/build_sitio.sh in headless Chrome,
// served the way GitHub Pages serves it (under /field-notes/app/), at phone size.
//
//   node coqui/tool/check_sitio.mjs <build dir> [--shot=<png file>] [--build=<n>]
//
// Serves <build dir> on a free port of 127.0.0.1 at /field-notes/app/ (Playwright is installed
// globally on this machine; it is not a dependency of the repo). Checks, and exits 1 if any fails:
//   - the page shows "Coquí" and "build <n>" (--build, default dev), read from Flutter's
//     accessibility tree, and the page paints (the screenshot is not blank)
//   - no console error or warning, no uncaught page error, no failed request
//   - no request leaves 127.0.0.1 (CanvasKit and the fonts come from the build itself)
//   - the manifest, every icon it names, and the favicon answer 200 and decode as pictures of the
//     size the manifest says
//   - no service worker is registered, and none was requested
//   - no file or folder name in the build starts with "_" or "." (GitHub Pages would drop it)
//   - index.html (the file) has <html lang="en" translate="no">, the notranslate meta, the old app's viewport
//     and theme-color; in the running page translate="no" and the notranslate meta are still there.
//     NOTE: the running page's `lang` and viewport are NOT the file's: Flutter's engine rewrites them at
//     start (lang = the app's locale; viewport = "width=device-width, initial-scale=1.0, maximum-scale=5.0"
//     plus viewport-fit). They are printed as INFO lines, not checked.
//   - console: an error fails; a warning fails except Chrome's own "GL Driver Message" notes, which the
//     headless software GPU prints
//   - both CanvasKit variants a dart2js + CanvasKit build loads work: the Chromium one
//     (canvaskit/chromium/, what Chrome loads) and the full one (canvaskit/, what Safari and Firefox
//     load). Only Chromium is installed here, so the second pass hides Intl.v8BreakIterator, which is
//     what makes the loader choose the full variant. Each pass must show the words, answer 200 to
//     every request, send none outside 127.0.0.1, print no error, and request the variant it should.
// The screenshot is phone size (390 x 844), deviceScaleFactor 1.
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { createRequire } from 'node:module';

const { chromium } = createRequire(import.meta.url)('playwright');

const args = process.argv.slice(2);
const flag = (name, dflt) => { const a = args.find((x) => x.startsWith(`--${name}=`)); return a ? a.slice(name.length + 3) : dflt; };
const dir = args.find((x) => !x.startsWith('--'));
if (!dir || !fs.existsSync(path.join(dir, 'index.html'))) {
  console.error('usage: node coqui/tool/check_sitio.mjs <build dir> [--shot=<png file>] [--build=<n>]');
  process.exit(2);
}
const ROOT = path.resolve(dir);
const BUILD = flag('build', 'dev');
const SHOT = flag('shot', '');
const PREFIX = '/field-notes/app/';

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json',
  '.png': 'image/png', '.wasm': 'application/wasm', '.otf': 'font/otf', '.ttf': 'font/ttf', '.frag': 'text/plain',
};

// ---- the server: only /field-notes/app/..., everything else is a 404 --------------------------------
const served = []; // { url, status }
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  let status = 404;
  let body = 'not found';
  let type = 'text/plain';
  if (url.pathname.startsWith(PREFIX)) {
    let rel = decodeURIComponent(url.pathname.slice(PREFIX.length));
    if (rel === '' || rel.endsWith('/')) rel += 'index.html';
    const file = path.resolve(ROOT, rel);
    if (file.startsWith(ROOT + path.sep) && fs.existsSync(file) && fs.statSync(file).isFile()) {
      status = 200;
      body = fs.readFileSync(file);
      type = TYPES[path.extname(file)] || 'application/octet-stream';
    }
  }
  served.push({ url: url.pathname, status });
  res.writeHead(status, { 'content-type': type, 'cache-control': 'no-store' });
  res.end(body);
});
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const ORIGIN = `http://127.0.0.1:${server.address().port}`;

// ---- results ------------------------------------------------------------------------------------------
let failed = 0;
const check = (ok, what, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${what}${detail ? `  (${detail})` : ''}`);
  if (!ok) failed++;
};

// ---- the names in the build -------------------------------------------------------------------------
const names = [];
const walk = (d) => {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    names.push(path.relative(ROOT, path.join(d, e.name)));
    if (e.isDirectory()) walk(path.join(d, e.name));
  }
};
walk(ROOT);
const dropped = names.filter((n) => n.split(path.sep).some((part) => part.startsWith('_') || part.startsWith('.')));
check(dropped.length === 0, 'no file or folder name starts with "_" or "."', dropped.join(', '));
check(!names.includes('flutter_service_worker.js'), 'no flutter_service_worker.js in the build');

// ---- the page ---------------------------------------------------------------------------------------------
const browser = await chromium.launch();
const phone = { viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, isMobile: true, hasTouch: true };
const gpuNote = /GL Driver Message/; // Chrome's software GPU in headless mode, not the app
// What a page did: its console problems, uncaught errors, requests and failed requests.
const watch = (pg) => {
  const w = { consoleProblems: [], pageErrors: [], requests: [], failedRequests: [] };
  pg.on('console', (m) => {
    if (m.type() === 'error' || (m.type() === 'warning' && !gpuNote.test(m.text()))) w.consoleProblems.push(`${m.type()}: ${m.text()}`);
  });
  pg.on('pageerror', (e) => w.pageErrors.push(String(e)));
  pg.on('request', (r) => w.requests.push(r.url()));
  pg.on('requestfailed', (r) => w.failedRequests.push(`${r.url()} ${r.failure()?.errorText}`));
  return w;
};
// The words of the page, from Flutter's accessibility tree (see below).
const wordsOf = async (pg) => {
  await pg.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await pg.waitForTimeout(1000);
  return pg.evaluate(() => [...document.querySelectorAll('flt-semantics')]
    .map((e) => (e.getAttribute('aria-label') || e.textContent || '').trim()).filter(Boolean));
};
// The same checks of what a page did, for either pass.
const checkTraffic = (label, w, servedFrom) => {
  const seen = served.slice(servedFrom);
  const outside = w.requests.filter((u) => !u.startsWith(ORIGIN) && !u.startsWith('data:') && !u.startsWith('blob:'));
  check(outside.length === 0, `${label}: no request leaves 127.0.0.1 (${w.requests.length} requests)`, outside.join(', '));
  const notFound = seen.filter((s) => s.status !== 200);
  check(notFound.length === 0, `${label}: every request to the server answered 200 (${seen.length})`, notFound.map((s) => `${s.status} ${s.url}`).join(', '));
  check(w.failedRequests.length === 0, `${label}: no failed request`, w.failedRequests.join(', '));
  check(w.consoleProblems.length === 0 && w.pageErrors.length === 0, `${label}: no console error or warning, no page error`,
    [...w.consoleProblems, ...w.pageErrors].join(' | '));
};

const context = await browser.newContext(phone);
const page = await context.newPage();
const watched = watch(page);

await page.goto(`${ORIGIN}${PREFIX}`, { waitUntil: 'load' });
await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
await page.waitForTimeout(3000); // the first frame

// The app draws on a canvas. Its words are read from Flutter's accessibility tree, which the
// page builds when the (invisible) "Enable accessibility" button is activated.
const words = await wordsOf(page);
check(words.includes('Coquí'), 'the page shows "Coquí"', `tree: ${JSON.stringify(words)}`);
check(words.includes(`build ${BUILD}`), `the page shows "build ${BUILD}"`);

const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
check(/<html lang="en" translate="no">/.test(html) && /<meta name="google" content="notranslate">/.test(html),
  'index.html: <html lang="en" translate="no"> and the notranslate meta');
check(html.includes('<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover,user-scalable=no">'),
  'index.html: the old app\'s viewport, as it is');
check(html.includes('<meta name="theme-color" content="#5C94FC">') && html.includes('<base href="/field-notes/app/">')
  && html.includes('<meta name="apple-mobile-web-app-capable" content="yes">') && html.includes('<link rel="apple-touch-icon" href="icons/Icon-192.png">'),
  'index.html: theme-color, base href, apple web-app meta and touch icon');
const head = await page.evaluate(() => ({
  lang: document.documentElement.getAttribute('lang'),
  translate: document.documentElement.getAttribute('translate'),
  notranslate: document.querySelector('meta[name="google"]')?.content,
  viewport: document.querySelector('meta[name="viewport"]')?.content,
  manifest: document.querySelector('link[rel="manifest"]')?.href,
  title: document.title,
}));
check(head.translate === 'no' && head.notranslate === 'notranslate' && head.title === 'Coquí',
  'running page: translate="no", the notranslate meta, title Coquí');
console.log(`INFO  running page, after Flutter's engine rewrote them: lang="${head.lang}", viewport="${head.viewport}"`);

// manifest and icons: fetched by the page, as a browser would
const manifestUrl = head.manifest;
const manifest = await (await page.request.get(manifestUrl)).json();
check(manifest.name === 'Coquí' && manifest.short_name === 'Coquí' && manifest.display === 'standalone'
  && manifest.orientation === 'portrait' && manifest.start_url === PREFIX && manifest.scope === PREFIX,
  'manifest: name, short_name, display, orientation, start_url, scope');
check(manifest.theme_color === '#5C94FC' && manifest.background_color === '#F6F5F1', 'manifest: theme and background colours',
  `${manifest.theme_color} ${manifest.background_color}`);
const icons = [...manifest.icons.map((i) => ({ src: new URL(i.src, manifestUrl).href, size: i.sizes, purpose: i.purpose || 'any' })),
  { src: new URL('favicon.png', manifestUrl).href, size: '32x32', purpose: 'favicon' },
  { src: new URL('icons/Icon-192.png', manifestUrl).href, size: '192x192', purpose: 'apple-touch-icon' }];
check(manifest.icons.some((i) => i.sizes === '192x192' && !i.purpose) && manifest.icons.some((i) => i.sizes === '512x512' && !i.purpose)
  && manifest.icons.some((i) => i.sizes === '192x192' && i.purpose === 'maskable') && manifest.icons.some((i) => i.sizes === '512x512' && i.purpose === 'maskable'),
  'manifest names 192 and 512, and a maskable 192 and 512');
for (const icon of icons) {
  const r = await page.request.get(icon.src);
  const { w, h } = await page.evaluate(async (u) => {
    const bmp = await createImageBitmap(await (await fetch(u)).blob());
    return { w: bmp.width, h: bmp.height };
  }, icon.src);
  check(r.status() === 200 && `${w}x${h}` === icon.size, `${icon.purpose} icon ${path.basename(icon.src)} answers 200 and is ${icon.size}`, `${r.status()} ${w}x${h}`);
}

// no service worker
const regs = await page.evaluate(async () => (await navigator.serviceWorker.getRegistrations()).length);
check(regs === 0, 'no service worker is registered', `${regs} registrations`);
check(!served.some((s) => /service_worker/.test(s.url)), 'no service worker file was requested');

// requests (the whole first pass; the server's list started empty)
checkTraffic('chromium variant', watched, 0);
check(served.some((x) => x.url === `${PREFIX}canvaskit/chromium/canvaskit.wasm`) && !served.some((x) => x.url === `${PREFIX}canvaskit/canvaskit.wasm`),
  'chromium variant: canvaskit/chromium/canvaskit.wasm was loaded, and not the full variant');

// the screenshot: phone size, and not blank
const png = await page.screenshot({ path: SHOT || undefined });
const colours = await page.evaluate(async (b64) => {
  const img = new Image();
  img.src = `data:image/png;base64,${b64}`;
  await img.decode();
  const c = new OffscreenCanvas(img.width, img.height);
  const g = c.getContext('2d');
  g.drawImage(img, 0, 0);
  const d = g.getImageData(0, 0, img.width, img.height).data;
  const seen = new Set();
  for (let i = 0; i < d.length; i += 4) seen.add((d[i] << 16) | (d[i + 1] << 8) | d[i + 2]);
  return { w: img.width, h: img.height, colours: seen.size };
}, png.toString('base64'));
check(colours.w === 390 && colours.h === 844 && colours.colours > 2, 'the screenshot is 390 x 844 and not blank', `${colours.w}x${colours.h}, ${colours.colours} colours${SHOT ? `, saved to ${SHOT}` : ''}`);

// ---- second pass: the full CanvasKit variant (Safari, Firefox) -----------------------------------------
const mark = served.length;
const context2 = await browser.newContext(phone);
await context2.addInitScript(() => { delete Intl.v8BreakIterator; });
const page2 = await context2.newPage();
const watched2 = watch(page2);
await page2.goto(`${ORIGIN}${PREFIX}`, { waitUntil: 'load' });
await page2.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
await page2.waitForTimeout(3000);
const words2 = await wordsOf(page2);
check(words2.includes('Coquí') && words2.includes(`build ${BUILD}`), 'full variant: the page shows "Coquí" and "build ' + BUILD + '"', `tree: ${JSON.stringify(words2)}`);
checkTraffic('full variant', watched2, mark);
const seen2 = served.slice(mark).map((x) => x.url);
check(seen2.includes(`${PREFIX}canvaskit/canvaskit.wasm`) && seen2.includes(`${PREFIX}canvaskit/canvaskit.js`) && !seen2.some((u) => u.includes('/canvaskit/chromium/')),
  'full variant: canvaskit/canvaskit.js and .wasm were loaded, and nothing from canvaskit/chromium/');
check(seen2.every((u) => !/skwasm|wimp|webparagraph/.test(u)), 'neither pass asked for a skwasm, wimp or webparagraph file');

await browser.close();
server.close();
console.log(failed === 0 ? '\nall checks passed' : `\n${failed} check(s) FAILED`);
process.exit(failed === 0 ? 0 : 1);
