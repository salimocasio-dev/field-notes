// Screenshots of the dev entry for the reader (order 23): each screen of Repaso and the level check in each
// reference state, on both reference phones, and a side-by-side image of each against the old picture.
//
//   node tool/shots.mjs [--out <dir>] [--no-build] [--only state,state] [--device android|iphone] [--build-dir <dir>]
//                       [--no-sbs]
//
// Builds the dev entry for the web (`flutter build web -t tool/dev_main.dart --no-web-resources-cdn`), serves it on a
// free local port and, with Playwright, opens it once for each picture of coqui/ref/pantallas/index.json that lists
// order 23 (screens "repaso" and "nivel"), at the address that plays the lesson to that state
// (`?screen=review|level&state=<state>&seed=<seed>`, see tool/dev_main.dart). The phones are 412 x 915 at 2.625 and
// 390 x 844 at 3 (the reference folders android-412x915 and iphone-390x844).
//
// Writes into <out> (default: build/shots next to the build):
//   <device>/<nn>-<screen>-<state>.png     the Flutter screen
//   <device>/sbs/<nn>-<screen>-<state>.png the old picture on the left, the Flutter one on the right
//   pairs.json                             each screenshot with the reference picture it is held against
//
// Run it from coqui/packages/features/feature_review (it moves there itself). Needs Node 22 and the pre-installed
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
const coqui = resolve(pkg, '..', '..', '..');
const refDir = join(coqui, 'ref', 'pantallas');
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
const picked = opt('--device', 'both');
const chosen = picked === 'both' ? Object.values(devices) : [devices[picked]];
if (chosen.some((d) => !d)) {
  console.error('--device is android, iphone or both');
  process.exit(1);
}

if (!flag('--no-build')) {
  console.log('building the dev entry for the web ...');
  const r = spawnSync('flutter', ['build', 'web', '-t', 'tool/dev_main.dart', '--no-web-resources-cdn', '-o', buildDir], {
    cwd: pkg,
    stdio: 'inherit',
  });
  if (r.status !== 0) {
    console.error('the web build failed');
    process.exit(1);
  }
}
if (!existsSync(join(buildDir, 'index.html'))) {
  console.error(`no build at ${buildDir}`);
  process.exit(1);
}

// the pictures of order 23, from the reference index
const index = JSON.parse(readFileSync(join(refDir, 'index.json'), 'utf8'));
const screens = { repaso: 'review', nivel: 'level' };
const pictures = index.pictures
  .filter((p) => (p.orders || []).includes(23) && screens[p.screen] && p.device === 'android-412x915')
  .map((p) => ({
    nn: p.file.split('/')[1].slice(0, 3),
    name: p.file.split('/')[1].replace(/\.png$/, ''),
    screen: p.screen,
    state: p.state,
    seed: p.seed,
    lesson: screens[p.screen],
  }))
  .filter((p) => !only.length || only.includes(p.state) || only.includes(p.name));

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
const pairs = { size: {}, reference_folder: 'coqui/ref/pantallas/', pairs: [] };
try {
  for (const d of chosen) {
    mkdirSync(join(out, d.id, 'sbs'), { recursive: true });
    pairs.size[d.id] = `${d.width}x${d.height} css px, deviceScaleFactor ${d.ratio}`;
    for (const p of pictures) {
      const ctx = await browser.newContext({
        viewport: { width: d.width, height: d.height },
        deviceScaleFactor: d.ratio,
        hasTouch: true,
        isMobile: true,
        locale: 'en-US',
      });
      const page = await ctx.newPage();
      const errors = [];
      page.on('pageerror', (e) => errors.push(String(e)));
      page.on('console', (m) => {
        if (m.type() === 'error') errors.push(m.text());
      });
      const url = `${base}?screen=${p.lesson}&state=${p.state}&seed=${p.seed}`;
      await page.goto(url);
      await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
      // the lesson is played on a virtual clock to the state; the page says when it stands there
      await page.waitForFunction('window.__devReady === true', null, { timeout: 120000 });
      await page.waitForTimeout(1500); // the last frames, the 200 ms bar, the 120 ms caption
      const png = join(out, d.id, `${p.name}.png`);
      await page.screenshot({ path: png });
      const ref = join(refDir, d.id, `${p.name}.png`);
      let sbs = null;
      if (!flag('--no-sbs')) {
        sbs = join(out, d.id, 'sbs', `${p.name}.png`);
        const flat = await browser.newContext({ viewport: { width: 100, height: 100 }, deviceScaleFactor: 1 });
        const view = await flat.newPage();
        const a = readFileSync(ref).toString('base64');
        const b = readFileSync(png).toString('base64');
        const w = Math.round(d.width * d.ratio);
        const h = Math.round(d.height * d.ratio);
        await view.setViewportSize({ width: w * 2 + 40, height: h });
        await view.setContent(
          `<body style="margin:0;background:#888;display:flex;gap:40px"><img src="data:image/png;base64,${a}" width="${w}" height="${h}"><img src="data:image/png;base64,${b}" width="${w}" height="${h}"></body>`,
        );
        await view.screenshot({ path: sbs });
        await flat.close();
      }
      console.log(`${d.id} ${p.name}${errors.length ? '  (errors: ' + errors.join(' | ') + ')' : ''}`);
      pairs.pairs.push({
        device: d.id,
        screen: p.screen,
        state: p.state,
        seed: p.seed,
        url: `?screen=${p.lesson}&state=${p.state}&seed=${p.seed}`,
        screenshot: png,
        reference: ref,
        side_by_side: sbs,
        errors,
      });
      await ctx.close();
    }
  }
} finally {
  await browser.close();
  server.close();
}
mkdirSync(out, { recursive: true });
writeFileSync(join(out, 'pairs.json'), JSON.stringify(pairs, null, 2) + '\n');
console.log(`pairs: ${join(out, 'pairs.json')}`);
