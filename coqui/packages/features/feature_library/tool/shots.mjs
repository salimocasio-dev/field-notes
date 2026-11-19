// Screenshots of the shelf and the reader, held against the reference pictures of order 22 (coqui/ref/pantallas/).
//
//   node tool/shots.mjs [--out <dir>] [--no-build] [--build-dir <dir>] [--device android|iphone|both]
//                       [--mode sample|real|both] [--only name,name] [--no-side]
//
// Builds the dev entry for the web (`flutter build web -t tool/dev_main.dart --no-web-resources-cdn`), serves it on a
// free local port together with the books' files, and with Playwright captures each state at the two reference phones
// (412 x 915 at 2.625 and 390 x 844 at 3). Into <out>/<device>/<mode>/<state>.png, plus:
//   <out>/pairs.json   each picture and the reference picture it is to be held against
//   <out>/side/...     each pair as one image: the reference at the left, ours at the right
//
// Two modes. "sample": the sample course of coqui_testing alone (one book, La lluvia): what the dev entry shows by
// itself. "real": the same screens over the real files of historia/ (served from the repository, read only;
// nothing is copied into the package), which holds every story and book the reference pictures were taken with.
//
// Run it from coqui/packages/features/feature_library (it moves there itself). Needs Node 22 and the pre-installed Playwright.
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { readFileSync, writeFileSync, mkdirSync, existsSync, statSync } from 'node:fs';
import { dirname, join, extname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');

const here = dirname(fileURLToPath(import.meta.url));
const pkg = resolve(here, '..');
const repo = resolve(here, '..', '..', '..', '..', '..');
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
const deviceArg = opt('--device', 'both');
const chosen = deviceArg === 'both' ? Object.values(devices) : [devices[deviceArg]];
if (chosen.some((d) => !d)) {
  console.error('--device is android, iphone or both');
  process.exit(1);
}
const modeArg = opt('--mode', 'both');
const modes = modeArg === 'both' ? ['sample', 'real'] : [modeArg];
const refDir = join(repo, 'coqui', 'ref', 'pantallas');

// Every reference picture of order 22 and how to reach its state in the dev entry. `sampleQ` is the same state on the
// sample course (its one book, La lluvia, in place of the reference's books; the shelf states have none and use `q`); null: the sample course cannot show it.
// speed: the clips play 40 times faster than their length, so a state that waits for the lines to finish does not wait long.
const quick = 'speed=40';
const states = [
  { name: 'biblioteca-nada-jugado', ref: '046-biblioteca-nada-jugado.png', q: 'seed=vacio' },
  { name: 'biblioteca-a-medio-curso', ref: '047-biblioteca-a-medio-curso.png', q: 'seed=curso' },
  { name: 'biblioteca-a-medio-curso-pagina-entera', ref: '048-biblioteca-a-medio-curso-pagina-entera.png', q: 'seed=curso', full: true },
  { name: 'biblioteca-todo-jugado', ref: '049-biblioteca-todo-jugado.png', q: 'seed=todo' },
  { name: 'biblioteca-todo-jugado-pagina-entera', ref: '050-biblioteca-todo-jugado-pagina-entera.png', q: 'seed=todo', full: true },
  { name: 'biblioteca-queda-una', ref: '051-biblioteca-queda-una.png', q: 'seed=casi' },
  { name: 'biblioteca-queda-una-al-final', ref: '052-biblioteca-queda-una-al-final.png', q: 'seed=casi&scroll=end' },
  {
    name: 'libro-primera-pagina-linea-1-luce', ref: '053-libro-primera-pagina-linea-1-luce.png',
    q: 'screen=book&book=quien-eres-tu&hold=1', sampleQ: 'screen=book&book=la-lluvia&page=5&hold=1',
  },
  {
    name: 'libro-primera-pagina-linea-2-luce', ref: '054-libro-primera-pagina-linea-2-luce.png',
    q: `screen=book&book=quien-eres-tu&hold=2&${quick}`, sampleQ: `screen=book&book=la-lluvia&page=5&hold=2&${quick}`,
  },
  {
    name: 'libro-primera-pagina-en-reposo', ref: '055-libro-primera-pagina-en-reposo.png',
    q: `screen=book&book=quien-eres-tu&${quick}`, sampleQ: `screen=book&book=la-lluvia&page=5&${quick}`, rest: true,
  },
  {
    name: 'libro-tarjeta-de-palabra', ref: '056-libro-tarjeta-de-palabra.png',
    q: `screen=book&book=quien-eres-tu&card=1&${quick}`, sampleQ: `screen=book&book=la-lluvia&page=5&card=1&${quick}`, rest: true,
  },
  {
    name: 'libro-pagina-media-linea-luce', ref: '057-libro-pagina-media-linea-luce.png',
    q: `screen=book&book=quien-eres-tu&page=3&hold=2&${quick}`, sampleQ: `screen=book&book=la-lluvia&page=6&hold=2&${quick}`,
  },
  {
    name: 'libro-pagina-media-en-reposo', ref: '058-libro-pagina-media-en-reposo.png',
    q: `screen=book&book=quien-eres-tu&page=3&${quick}`, sampleQ: `screen=book&book=la-lluvia&page=6&${quick}`, rest: true,
  },
  {
    name: 'libro-texto-grande', ref: '059-libro-texto-grande.png',
    q: `screen=book&book=quien-eres-tu&page=3&big=1&${quick}`, sampleQ: `screen=book&book=la-lluvia&page=6&big=1&${quick}`, rest: true,
  },
  {
    name: 'libro-ultima-pagina', ref: '060-libro-ultima-pagina.png',
    q: `screen=book&book=quien-eres-tu&page=5&${quick}`, sampleQ: `screen=book&book=la-lluvia&page=9&${quick}`, rest: true,
  },
  {
    name: 'libro-cuento-con-dibujos-primera-pagina', ref: '061-libro-cuento-con-dibujos-primera-pagina.png',
    q: `screen=book&book=d-toc-toc&${quick}`, sampleQ: null, rest: true,
  },
  {
    name: 'libro-cuento-con-dibujos-pagina-6-linea-del-coqui', ref: '062-libro-cuento-con-dibujos-pagina-6-linea-del-coqui.png',
    q: `screen=book&book=d-toc-toc&page=6&hold=3&${quick}`, sampleQ: null,
  },
];

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
  '.css': 'text/css', '.map': 'application/json', '.txt': 'text/plain', '.mp3': 'audio/mpeg',
};
// The build, and the old site's files where the page asks for them: `libros/...` (the default address of a page's
// picture) and `assets/content/...` (the real course files, read through the asset bundle).
const server = createServer((req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let file;
  if (path.startsWith('/libros/')) file = join(repo, 'historia', path);
  else if (path.startsWith('/assets/content/')) file = join(repo, 'historia', path.slice('/assets/content/'.length));
  else file = join(buildDir, path === '/' ? 'index.html' : path);
  if (!existsSync(file) || !statSync(file).isFile()) {
    res.writeHead(404);
    res.end('not found');
    return;
  }
  res.writeHead(200, { 'content-type': mime[extname(file)] || 'application/octet-stream', 'cache-control': 'no-store' });
  res.end(readFileSync(file));
});
await new Promise((ok) => server.listen(0, '127.0.0.1', ok));
const base = `http://127.0.0.1:${server.address().port}/`;

const browser = await chromium.launch();
const pairs = {
  note: 'ours = the dev entry (Roboto); reference = the old app v=39 (Inter). mode sample: the sample course; real: the real files of historia/',
  reference_folder: 'coqui/ref/pantallas/<device>/',
  pairs: [],
};
try {
  for (const device of chosen) {
    for (const mode of modes) {
      mkdirSync(join(out, device.id, mode), { recursive: true });
      for (const s of states) {
        if (only.length && !only.includes(s.name)) continue;
        const q = mode === 'sample' && 'sampleQ' in s ? s.sampleQ : s.q;
        if (q === null || q === undefined) continue;
        const content = mode === 'real' ? '&content=real' : '';
        const ctx = await browser.newContext({
          viewport: { width: device.width, height: device.height },
          deviceScaleFactor: device.ratio,
          hasTouch: true,
          isMobile: true,
          locale: 'en-US',
        });
        const page = await ctx.newPage();
        const errors = [];
        page.on('pageerror', (e) => errors.push(String(e)));
        page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
        await page.goto(`${base}?${q}${content}`);
        await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 90000 });
        await page.waitForTimeout(s.rest ? 7000 : 4500);
        if (s.full) {
          const m = /shelf-height=(\d+)/.exec(await page.title());
          if (m) {
            await page.setViewportSize({ width: device.width, height: Number(m[1]) });
            await page.waitForTimeout(2500);
          }
        }
        const png = join(out, device.id, mode, `${s.name}.png`);
        await page.screenshot({ path: png });
        console.log(`${device.id} ${mode} ${s.name}${errors.length ? '  (errors: ' + [...new Set(errors)].slice(0, 3).join(' | ') + ')' : ''}`);
        pairs.pairs.push({
          device: device.id, mode, state: s.name, url: `?${q}${content}`,
          screenshot: join(device.id, mode, `${s.name}.png`),
          reference: `coqui/ref/pantallas/${device.id}/${s.ref}`,
        });
        await ctx.close();
      }
    }
  }

  if (!flag('--no-side')) {
    // each pair as one image: the reference at the left, ours at the right, at the same height
    mkdirSync(join(out, 'side'), { recursive: true });
    const ctx = await browser.newContext({ deviceScaleFactor: 1 });
    const page = await ctx.newPage();
    for (const p of pairs.pairs) {
      const a = join(repo, p.reference);
      const b = join(out, p.screenshot);
      const dst = join(out, 'side', `${p.device}__${p.mode}__${p.state}.png`);
      const html = join(out, 'side', 'pair.html');
      writeFileSync(
        html,
        `<!doctype html><meta charset="utf-8"><body style="margin:0;background:#888;display:flex;gap:12px;align-items:flex-start">` +
          `<img id="a" src="file://${a}" style="height:1600px"><img id="b" src="file://${b}" style="height:1600px"></body>`,
      );
      await page.setViewportSize({ width: 1600, height: 1600 });
      await page.goto(`file://${html}`);
      await page.waitForFunction(() => [...document.images].every((i) => i.complete && i.naturalWidth));
      await page.screenshot({ path: dst, fullPage: true });
      p.side = join('side', `${p.device}__${p.mode}__${p.state}.png`);
    }
    await ctx.close();
  }
} finally {
  await browser.close();
  server.close();
}
writeFileSync(join(out, 'pairs.json'), JSON.stringify(pairs, null, 2) + '\n');
console.log(`pairs: ${join(out, 'pairs.json')}`);
