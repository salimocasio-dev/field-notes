#!/usr/bin/env node
// Order 03's proof of the site build, brought up to date for the app of order 26: opens a build made by
// tool/build_sitio.sh in headless Chrome, served the way GitHub Pages serves it (the build under /field-notes/app/, the
// repository's own historia/ at /field-notes/historia/), at phone size.
//
//   node coqui/tool/check_sitio.mjs <build dir> [--shot=<png file>] [--build=<n>]
//
// --build is the build number the app was built with (COQUI_BUILD, the workflow reads it from coqui/BUILD); without
// it, the number in coqui/BUILD. Pass --build=dev for a build made without COQUI_BUILD.
//
// Serves <build dir> on a free port of 127.0.0.1 at /field-notes/app/, and every other /field-notes/... path from the
// repository this script is in (so the content the app reads is the real historia/). Playwright is installed globally
// on this machine; it is not a dependency of the repo. Checks, and exits 1 if any fails:
//   - the app starts: with the welcome done (the seed of coqui/ref/pantallas/seeds/vacio.json in localStorage, as
//     check_app.mjs does) it opens on the map: the address is #/tab/map, the tab bar's five names are there, and the
//     map's place chip ("1 . La casa") is, all read from Flutter's accessibility tree; the screenshot is not blank
//   - it reads its content from /field-notes/historia/ (datos/curso.json, audio/ready.json, audio/marcas.json,
//     datos/prueba-voz.json: each asked for there and answered 200), and nothing from inside /field-notes/app/ but the
//     preview content bundled in the app (assets/assets/previa/: its overlay curso.json is asked for and answered 200)
//   - it shows the build number: the Yo tab (the only place the app shows it) says "build <n>"
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
//     what makes the loader choose the full variant. Each pass must open the map and show the build number,
//     answer 200 to every request, send none outside 127.0.0.1, print no error, and request the variant it should.
// The screenshot is phone size (390 x 844), deviceScaleFactor 1.
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');

const args = process.argv.slice(2);
const flag = (name, dflt) => { const a = args.find((x) => x.startsWith(`--${name}=`)); return a ? a.slice(name.length + 3) : dflt; };
const dir = args.find((x) => !x.startsWith('--'));
if (!dir || !fs.existsSync(path.join(dir, 'index.html'))) {
  console.error('usage: node coqui/tool/check_sitio.mjs <build dir> [--shot=<png file>] [--build=<n>]');
  process.exit(2);
}
const ROOT = path.resolve(dir);
const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const BUILD = flag('build', fs.readFileSync(path.join(REPO, 'coqui/BUILD'), 'utf8').trim());
const SHOT = flag('shot', '');
const PREFIX = '/field-notes/app/';
const HISTORIA = '/field-notes/historia/';
// the progress with the welcome done and nothing played (check_app.mjs puts seeds in the same way)
const SEED = fs.readFileSync(path.join(REPO, 'coqui/ref/pantallas/seeds/vacio.json'), 'utf8').replace(/\n/g, '');

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json',
  '.png': 'image/png', '.wasm': 'application/wasm', '.otf': 'font/otf', '.ttf': 'font/ttf', '.frag': 'text/plain',
  '.mp3': 'audio/mpeg', '.svg': 'image/svg+xml', '.css': 'text/css',
};

// ---- the server: /field-notes/app/ is the build, the rest of /field-notes/ the repository, everything else a 404 ---------
const served = []; // { url, status }
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  let status = 404;
  let body = 'not found';
  let type = 'text/plain';
  const p = decodeURIComponent(url.pathname);
  let root = null;
  let rel = null;
  if (p.startsWith(PREFIX)) { root = ROOT; rel = p.slice(PREFIX.length); }
  else if (p.startsWith('/field-notes/')) { root = REPO; rel = p.slice('/field-notes/'.length); }
  if (root !== null) {
    if (rel === '' || rel.endsWith('/')) rel += 'index.html';
    const file = path.resolve(root, rel);
    if (file.startsWith(root + path.sep) && fs.existsSync(file) && fs.statSync(file).isFile()) {
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
// The app draws on a canvas. What is on screen is read from Flutter's accessibility tree, which the page builds when the
// (invisible) "Enable accessibility" button is activated: on a phone it fills the view, and a click at its exact middle
// turns the tree on (as TalkBack's tap does; check_app.mjs does the same).
const enableSemantics = async (pg) => {
  await pg.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 60000 });
  await pg.evaluate(() => {
    const p = document.querySelector('flt-semantics-placeholder');
    const r = p.getBoundingClientRect();
    p.dispatchEvent(new MouseEvent('click', { clientX: r.left + r.width / 2, clientY: r.top + r.height / 2, bubbles: true }));
  });
  await pg.waitForFunction(() => document.querySelectorAll('flt-semantics').length > 0, null, { timeout: 30000 });
};
const nodesOf = (pg) => pg.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => {
  const r = e.getBoundingClientRect();
  const label = (e.getAttribute('aria-label') || '').trim();
  let own = '';
  for (const c of e.childNodes) if (c.nodeType === 3 || (c.nodeType === 1 && c.tagName !== 'FLT-SEMANTICS' && c.tagName !== 'FLT-SEMANTICS-CONTAINER')) own += c.textContent;
  return { text: (label || own).trim(), x: r.x + r.width / 2, y: r.y + r.height / 2, w: r.width, h: r.height };
}).filter((n) => n.text && n.w > 0 && n.h > 0));
// a node's label can hold several lines (a card's title and its line under it): each line is matched alone too
const says = (n, re) => re.test(n.text) || n.text.split('\n').some((l) => re.test(l.trim()));
const wordsOf = async (pg) => (await nodesOf(pg)).map((n) => n.text);
// Waits for the page to say something that matches [re]; the words on screen when it never does.
const waitSays = async (pg, re, what, timeout = 30000) => {
  const t0 = Date.now();
  for (;;) {
    const ns = await nodesOf(pg);
    if (ns.some((n) => says(n, re))) return ns;
    if (Date.now() - t0 > timeout) throw new Error(`${what} never came; on screen: ${JSON.stringify(ns.map((n) => n.text)).slice(0, 600)}`);
    await pg.waitForTimeout(250);
  }
};
// One pass over the app, for either variant: opens it with the welcome done, finds the map, opens Yo, reads the build.
// Returns what it saw, for the checks.
const openApp = async (pg, label) => {
  await pg.goto(`${ORIGIN}${PREFIX}`, { waitUntil: 'load' });
  await pg.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
  await enableSemantics(pg);
  const seen = { label };
  try {
    const onMap = await waitSays(pg, /^1 · La casa$/, 'the map\'s place chip', 60000);
    seen.tabBar = ['Biblioteca', 'Palabras', 'Mapa', 'Hablar', 'Yo'].filter((t) => !onMap.some((n) => n.text === t));
    seen.mapAddress = new URL(pg.url()).hash;
    seen.mapWords = onMap.map((n) => n.text);
  } catch (e) {
    seen.mapError = String(e.message || e);
  }
  return seen;
};
// Yo is the one place the app shows the build number: its tab, then the line "build <n>".
const readBuild = async (pg, seen) => {
  try {
    const ns = await nodesOf(pg);
    const yo = ns.filter((n) => n.text === 'Yo').pop(); // the tab bar's
    if (!yo) throw new Error('no Yo in the tab bar');
    await pg.mouse.click(yo.x, yo.y);
    await pg.waitForFunction(() => location.hash === '#/tab/me', null, { timeout: 15000 });
    const onYo = await waitSays(pg, /^build \S+$/, 'Yo\'s build line', 30000);
    seen.build = onYo.map((n) => n.text).filter((t) => /^build \S+$/.test(t));
  } catch (e) {
    seen.buildError = String(e.message || e);
  }
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

// An empty browser, with the progress of a learner who has done the welcome and played nothing (the first screen is then the map).
const newContext = async (extra) => {
  const c = await browser.newContext(phone);
  await c.addInitScript((seed) => {
    if (!localStorage.getItem('coqui.palabras.v1')) localStorage.setItem('coqui.palabras.v1', seed);
  }, SEED);
  if (extra) await c.addInitScript(extra);
  return c;
};
// What the checks of one pass say about [seen] (the app's start and its build line).
const checkApp = (label, seen) => {
  check(!seen.mapError, `${label}: the app starts on the map (the place chip "1 · La casa")`, seen.mapError || '');
  check(seen.mapAddress === '#/tab/map', `${label}: the address is #/tab/map`, seen.mapAddress);
  check(seen.tabBar && seen.tabBar.length === 0, `${label}: the tab bar names Biblioteca, Palabras, Mapa, Hablar and Yo`,
    `missing: ${JSON.stringify(seen.tabBar)}; on screen: ${JSON.stringify(seen.mapWords).slice(0, 400)}`);
  check(!seen.buildError && JSON.stringify(seen.build) === JSON.stringify([`build ${BUILD}`]),
    `${label}: Yo shows "build ${BUILD}"`, seen.buildError || JSON.stringify(seen.build));
};

const context = await newContext();
const page = await context.newPage();
const watched = watch(page);

const first = await openApp(page, 'chromium variant');
// the screenshot is of the map, before the tab is changed
await page.waitForTimeout(600);
const png = await page.screenshot({ path: SHOT || undefined });
await readBuild(page, first);
checkApp('chromium variant', first);
// the content comes from /field-notes/historia/ (the base the app takes from its own address: ../historia/)
const answered = (u) => served.some((x) => x.url === u && x.status === 200);
const content = ['datos/curso.json', 'audio/ready.json', 'audio/marcas.json', 'datos/prueba-voz.json'];
check(content.every((f) => answered(`${HISTORIA}${f}`)), 'the content is read from /field-notes/historia/ (' + content.join(', ') + ')',
  content.filter((f) => !answered(`${HISTORIA}${f}`)).map((f) => `not answered: ${f}`).join(', '));
// the one exception: the preview content bundled in the app (lib/src/previa.dart), its overlay and its story files, under
// assets/assets/previa/ of the build
const PREVIA = `${PREFIX}assets/assets/previa/`;
check(!served.some((x) => x.url.startsWith(PREFIX) && !x.url.startsWith(PREVIA) && /\.json$/.test(x.url) && /curso|ready|marcas|prueba-voz|cuentos|libros/.test(x.url)),
  'none of the content is asked for inside /field-notes/app/, but the bundled preview');
check(answered(`${PREVIA}curso.json`), 'the preview overlay is read from the build (assets/assets/previa/curso.json, 200)');

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

// the screenshot (of the map, taken above): phone size, and not blank
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
const context2 = await newContext(() => { delete Intl.v8BreakIterator; });
const page2 = await context2.newPage();
const watched2 = watch(page2);
const second = await openApp(page2, 'full variant');
await readBuild(page2, second);
checkApp('full variant', second);
checkTraffic('full variant', watched2, mark);
const seen2 = served.slice(mark).map((x) => x.url);
check(seen2.includes(`${PREFIX}canvaskit/canvaskit.wasm`) && seen2.includes(`${PREFIX}canvaskit/canvaskit.js`) && !seen2.some((u) => u.includes('/canvaskit/chromium/')),
  'full variant: canvaskit/canvaskit.js and .wasm were loaded, and nothing from canvaskit/chromium/');
check(seen2.every((u) => !/skwasm|wimp|webparagraph/.test(u)), 'neither pass asked for a skwasm, wimp or webparagraph file');

await browser.close();
server.close();
console.log(failed === 0 ? '\nall checks passed' : `\n${failed} check(s) FAILED`);
process.exit(failed === 0 ? 0 : 1);
