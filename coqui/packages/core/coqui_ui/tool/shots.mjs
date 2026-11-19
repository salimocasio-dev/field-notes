// Screenshots of the gallery for the reader (order 20).
//
//   node tool/shots.mjs [--out <dir>] [--no-build] [--only name,name] [--build-dir <dir>]
//
// Builds the gallery for the web (`flutter build web -t tool/dev_main.dart
// --no-web-resources-cdn`), serves it on a free local port, and with Playwright
// captures each section at 412 x 915 CSS pixels, deviceScaleFactor 2.625 (the
// Android reference size of coqui/ref/pantallas/android-412x915), one PNG per
// section, into <out> (default: ./shots next to the build). It also writes
// <out>/pairs.json: for each section its PNG and the reference picture(s) it is to
// be held against.
//
// Run it from coqui/packages/core/coqui_ui (it moves there itself). Needs Node 22 and
// the pre-installed Playwright.

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

const out = resolve(opt('--out', join(pkg, 'build', 'gallery-shots')));
const buildDir = resolve(opt('--build-dir', join(pkg, 'build', 'gallery-web')));
const only = opt('--only', '').split(',').filter(Boolean);
mkdirSync(out, { recursive: true });

if (!flag('--no-build')) {
  console.log('building the gallery for the web ...');
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

// The sections and their references come from the gallery's own list, read from the source,
// so the pairing file cannot drift from what is drawn.
const src = readFileSync(join(pkg, 'tool', 'gallery', 'screens.dart'), 'utf8');
const sections = [];
const re = /GallerySection\(\s*'([^']+)',\s*'([^']*)',\s*(?:const\s*)?\[([^\]]*)\]/g;
for (let m; (m = re.exec(src)); ) {
  const refs = [...m[3].matchAll(/'([^']+)'/g)].map((x) => x[1]);
  sections.push({ name: m[1], title: m[2], refs });
}
if (!sections.length) {
  console.error('no sections found in tool/gallery/screens.dart');
  process.exit(1);
}

const mime = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.ttf': 'font/ttf', '.otf': 'font/otf',
  '.css': 'text/css', '.map': 'application/json', '.txt': 'text/plain',
};
const server = createServer((req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let file = join(buildDir, path === '/' ? 'index.html' : path);
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
const pairs = { size: '412x915 css px, deviceScaleFactor 2.625', reference_folder: 'coqui/ref/pantallas/android-412x915/', sections: [] };
try {
  for (const s of sections) {
    if (only.length && !only.includes(s.name)) continue;
    const ctx = await browser.newContext({
      viewport: { width: 412, height: 915 },
      deviceScaleFactor: 2.625,
      hasTouch: true,
      isMobile: true,
      locale: 'en-US',
    });
    const page = await ctx.newPage();
    const errors = [];
    page.on('pageerror', (e) => errors.push(String(e)));
    page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
    await page.goto(`${base}?section=${s.name}`);
    await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
    // A first frame, then time for fonts and the pictures to upload.
    await page.waitForTimeout(3500);
    const png = join(out, `${s.name}.png`);
    await page.screenshot({ path: png });
    console.log(`${s.name}: ${png}${errors.length ? '  (errors: ' + errors.join(' | ') + ')' : ''}`);
    pairs.sections.push({ name: s.name, title: s.title, gallery: `${s.name}.png`, reference: s.refs });
    await ctx.close();
  }
} finally {
  await browser.close();
  server.close();
}
writeFileSync(join(out, 'pairs.json'), JSON.stringify(pairs, null, 2) + '\n');
console.log(`pairs: ${join(out, 'pairs.json')}`);
