// Screenshots of the map tab for the reader (order 13).
//
//   node tool/shots.mjs [--out <dir>] [--no-build] [--only name,name] [--build-dir <dir>] [--device android|iphone]
//
// Builds the dev entry for the web (`flutter build web -t tool/dev_main.dart --no-web-resources-cdn`), serves
// it on a free local port, and with Playwright captures, at 412 x 915 CSS pixels and deviceScaleFactor 2.625
// (the Android reference size of coqui/ref/pantallas/android-412x915), one PNG for each state below: the map
// tab in the three demo states, the place sheet of an open, a done and a locked place, and the Today card in
// each of its states. It writes <out>/pairs.json: for each picture the address it was taken at and the
// reference pictures it is to be held against (all paths are from the repository root).
//
// Two kinds of reference: `coqui/ref/pp/map/hecho-N/pix.png` is the old picture of the island itself (the
// island is NEW art, so hold the map against that); `coqui/ref/pantallas/<device>/NNN-*.png` is the old app's
// screen (hold the chips, the Today card, the sheet and the tab bar against that).
//
// Everything is taken with reduceMotion on (`reduce=1`), so the map stands still, as the references do (the
// frame at time 0), and the sheet opens at once. The corner chip is left out (`chip=0`). The time zone is
// America/Puerto_Rico and the locale en-US, as the reference pictures were taken in.
//
// With `--perf` it also opens the map with motion on and reads the corner chip (the bake and the slowest frame
// in headless Chrome) into <out>/perf.json.
//
// Run it from coqui/packages/features/feature_map (it moves there itself). Needs Node 22 and the pre-installed
// Playwright.

import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { readFileSync, writeFileSync, mkdirSync, existsSync, statSync } from 'node:fs';
import { dirname, join, extname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');

const here = dirname(fileURLToPath(import.meta.url));
const pkg = resolve(here, '..');
const args = process.argv.slice(2);
const opt = (name, def) => {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] ? args[i + 1] : def;
};
const flag = (name) => args.includes(name);

const out = resolve(opt('--out', join(pkg, 'build', 'shots')));
const buildDir = resolve(opt('--build-dir', join(pkg, 'build', 'dev-web')));
const only = opt('--only', '').split(',').filter(Boolean);
const devices = {
  android: { id: 'android-412x915', width: 412, height: 915, ratio: 2.625 },
  iphone: { id: 'iphone-390x844', width: 390, height: 844, ratio: 3 },
};
const device = devices[opt('--device', 'android')];
if (!device) {
  console.error('--device is android or iphone');
  process.exit(1);
}
const repo = resolve(pkg, '..', '..', '..', '..');
const ref = `coqui/ref/pantallas/${device.id}`;
const pp = 'coqui/ref/pp/map';

// What is taken: a name, what it shows, the address (after the ?), and the references.
const shots = [
  { name: 'map-nothing-done', title: 'The map, nothing done (places 1 to 3 open, the rest locked, the frog on place 1)',
    q: 'demo=none', refs: [`${pp}/hecho-0/pix.png`, `${ref}/009-mapa-nada-jugado.png`] },
  { name: 'map-three-done', title: 'The map, places 1 to 3 done (a flag on each), place 4 open with the frog, the rest locked',
    q: 'demo=three', refs: [`${pp}/hecho-3/pix.png`, `${ref}/012-mapa-a-medio-curso.png`] },
  { name: 'map-all-done', title: 'The map, all ten places done (a flag on each; the frog sits on place 1, as in the old app)',
    q: 'demo=all', refs: [`${pp}/hecho-10/pix.png`, `${ref}/013-mapa-todo-jugado.png`] },
  { name: 'sheet-open-place', title: 'The place sheet of an open place, half played (place 2)',
    q: 'seed=curso&place=2', refs: [`${ref}/018-lugar-abierto-2-a-medias.png`] },
  { name: 'sheet-open-place-nothing-played', title: 'The place sheet of an open place, nothing played (place 1)',
    q: 'seed=vacio&place=1', refs: [`${ref}/015-lugar-abierto-1-nada-jugado.png`] },
  { name: 'sheet-done-place', title: 'The place sheet of a done place (place 1)',
    q: 'seed=curso&place=1', refs: [`${ref}/016-lugar-hecho-1.png`] },
  { name: 'sheet-locked-place', title: 'The place sheet of a locked place (place 4)',
    q: 'seed=curso&place=4', refs: [`${ref}/020-lugar-cerrado-4.png`] },
  { name: 'sheet-open-every-place', title: 'The place sheet of a place with no stories when every place is open (place 4)',
    q: 'seed=todo&todo=1&place=4', refs: [`${ref}/028-lugar-sin-construir-4.png`] },
  { name: 'today-new-story', title: 'The Today card: a new story, to play twice',
    q: 'seed=vacio', refs: [`${ref}/009-mapa-nada-jugado.png`] },
  { name: 'today-second-play', title: 'The Today card: a second play',
    q: 'seed=segunda', refs: [`${ref}/010-mapa-una-historia-hoy.png`] },
  { name: 'today-one-word', title: 'The Today card: the review, one word coming back',
    q: 'seed=uno', refs: [`${ref}/011-mapa-una-palabra.png`] },
  { name: 'today-review', title: 'The Today card: the review, ten words coming back',
    q: 'seed=curso', refs: [`${ref}/012-mapa-a-medio-curso.png`] },
  { name: 'today-listen-again', title: 'The Today card: listen again (everything built is played)',
    q: 'seed=todo', refs: [`${ref}/013-mapa-todo-jugado.png`] },
  { name: 'open-every-place', title: 'The map with "Open every place" on (every place open)',
    q: 'seed=todo&todo=1', refs: [`${ref}/014-mapa-todo-abierto.png`] },
];

mkdirSync(out, { recursive: true });

if (!flag('--no-build')) {
  console.log('building the dev entry for the web ...');
  const r = spawnSync(
    'flutter',
    ['build', 'web', '-t', 'tool/dev_main.dart', '--no-web-resources-cdn', '-o', buildDir],
    { cwd: pkg, stdio: 'inherit' },
  );
  if (r.status !== 0) {
    console.error('the web build failed');
    process.exit(1);
  }
}
if (!existsSync(join(buildDir, 'index.html'))) {
  console.error(`no build at ${buildDir}`);
  process.exit(1);
}

const mime = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.ttf': 'font/ttf', '.otf': 'font/otf',
  '.css': 'text/css', '.map': 'application/json', '.txt': 'text/plain',
};
const server = createServer((req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  const file = join(buildDir, path === '/' ? 'index.html' : path);
  if (!file.startsWith(buildDir) || !existsSync(file) || !statSync(file).isFile()) {
    res.writeHead(404);
    res.end('not found');
    return;
  }
  res.writeHead(200, { 'content-type': mime[extname(file)] || 'application/octet-stream' });
  res.end(readFileSync(file));
});
await new Promise((ok) => server.listen(0, '127.0.0.1', ok));
const base = `http://127.0.0.1:${server.address().port}/`;

const browser = await chromium.launch();
const newContext = () =>
  browser.newContext({
    viewport: { width: device.width, height: device.height },
    deviceScaleFactor: device.ratio,
    hasTouch: true,
    isMobile: true,
    locale: 'en-US',
    timezoneId: 'America/Puerto_Rico',
  });

const pairs = {
  size: `${device.width}x${device.height} css px, deviceScaleFactor ${device.ratio}`,
  note:
    'references[0] of the map pictures is the old picture of the island itself (new art: compare the map with it); ' +
    'the others are the old app screens (compare the chips, the Today card, the sheet, the tab bar with them)',
  repository_root: repo,
  pictures: [],
};
let perf = null;
try {
  for (const s of shots) {
    if (only.length && !only.includes(s.name)) continue;
    const ctx = await newContext();
    const page = await ctx.newPage();
    const errors = [];
    page.on('pageerror', (e) => errors.push(String(e)));
    page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
    await page.goto(`${base}?${s.q}&reduce=1&chip=0`);
    await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
    // A first frame, then time for the fonts, the bake and the picture to upload; the sheet slides in.
    await page.waitForTimeout(5000);
    const png = join(out, `${s.name}.png`);
    await page.screenshot({ path: png });
    console.log(`${s.name}: ${png}${errors.length ? '  (errors: ' + errors.join(' | ') + ')' : ''}`);
    pairs.pictures.push({
      name: s.name,
      title: s.title,
      address: `?${s.q}&reduce=1&chip=0`,
      picture: `${s.name}.png`,
      references: s.refs,
    });
    await ctx.close();
  }

  if (flag('--perf')) {
    // The map with motion on, as it runs, in each of the three demo states: the chip in the corner says what it
    // measured (the bake, and the slowest frame: updateFrog and draw, not the upload of the picture).
    perf = {};
    for (const demo of ['none', 'three', 'all']) {
      const ctx = await newContext();
      const page = await ctx.newPage();
      await page.goto(`${base}?demo=${demo}`);
      await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
      await page.waitForTimeout(10000);
      // Flutter draws to a canvas: turn its semantics on to read the chip as text.
      await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
      await page.waitForTimeout(1500);
      const text = await page.evaluate(() =>
        [...document.querySelectorAll('flt-semantics')].map((e) => e.textContent || e.getAttribute('aria-label') || '')
          .find((t) => /bake \d+ ms/.test(t)) || null);
      const m = text && /bake (\d+) ms · frame max ([\d.]+) ms · mean ([\d.]+) ms/.exec(text);
      perf[demo] = m ? { bake_ms: Number(m[1]), slowest_frame_ms: Number(m[2]), mean_frame_ms: Number(m[3]), chip: text } : { chip: text };
      console.log(`perf ${demo}:`, JSON.stringify(perf[demo]));
      await page.screenshot({ path: join(out, `perf-${demo}-motion-on.png`) });
      await ctx.close();
    }
  }
} finally {
  await browser.close();
  server.close();
}
writeFileSync(join(out, 'pairs.json'), JSON.stringify(pairs, null, 2) + '\n');
if (perf) writeFileSync(join(out, 'perf.json'), JSON.stringify(perf, null, 2) + '\n');
console.log(`pairs: ${join(out, 'pairs.json')}`);
