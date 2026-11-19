// Screenshots of the Yo tab and the welcome in each reference state, for the reader (order 25).
//
//   node tool/shots.mjs [--out <dir>] [--no-build] [--only name,name] [--build-dir <dir>] [--device android|iphone|both]
//
// Builds the dev entry for the web (`flutter build web -t tool/dev_main.dart --no-web-resources-cdn`), serves it on a
// free local port, and with Playwright captures each state on the two reference phones of coqui/ref/pantallas
// (android-412x915: 412 x 915 CSS px at 2.625; iphone-390x844: 390 x 844 at 3), one PNG each, into <out>
// (default: ./build/shots next to the build). It writes <out>/pairs.json: for each shot its PNG, its address and the
// reference picture it is held against, and <out>/side-by-side/<device>/<name>.png: the reference, the shot and
// the difference, side by side, to look at.
//
// Run it from coqui/packages/features/feature_profile (it moves there itself). Needs Node 22 and the pre-installed
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
const refRoot = resolve(pkg, '../../../ref/pantallas');
const args = process.argv.slice(2);
const opt = (name, def) => {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] ? args[i + 1] : def;
};
const flag = (name) => args.includes(name);

const out = resolve(opt('--out', join(pkg, 'build', 'shots')));
const buildDir = resolve(opt('--build-dir', join(pkg, 'build', 'web')));
const only = opt('--only', '').split(',').filter(Boolean);
const devices = {
  android: { id: 'android-412x915', width: 412, height: 915, ratio: 2.625 },
  iphone: { id: 'iphone-390x844', width: 390, height: 844, ratio: 3 },
};
const which = opt('--device', 'both');
const chosen = which === 'both' ? Object.values(devices) : [devices[which]];
if (chosen.some((d) => !d)) {
  console.error('--device is android, iphone or both');
  process.exit(1);
}
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

// ---- the states: a name, the address, what the reference calls it, and what is done before the shot ----
// `ref`: the file name of the reference picture (the same on both phones); null for a state v=39 has no picture of
// (the three new things). `whole`: the viewport is made as tall as the reference picture, as the old pictures of the
// whole page were taken. `scroll`: 'end' wheels the page to its end, a number wheels that many CSS px, 'sheet' wheels
// the open sheet to its end.
const states = [
  { name: 'bienvenida-paso-1', ref: '001-bienvenida-paso-1.png', query: 'screen=welcome&step=0' },
  { name: 'bienvenida-paso-2', ref: '002-bienvenida-paso-2.png', query: 'screen=welcome&step=1' },
  { name: 'bienvenida-paso-2-60-min', ref: '003-bienvenida-paso-2-60-min.png', query: 'screen=welcome&step=1&do=min:60' },
  { name: 'bienvenida-paso-3', ref: '004-bienvenida-paso-3.png', query: 'screen=welcome&step=2&do=min:60' },
  { name: 'bienvenida-como-funciona-1', ref: '005-bienvenida-como-funciona-1.png', query: 'seed=vacio&how=0' },
  { name: 'bienvenida-como-funciona-1-al-final', ref: '006-bienvenida-como-funciona-1-al-final.png', query: 'seed=vacio&how=0', scroll: 'sheet' },
  { name: 'bienvenida-como-funciona-2', ref: '007-bienvenida-como-funciona-2.png', query: 'seed=vacio&how=1' },
  { name: 'bienvenida-como-funciona-3', ref: '008-bienvenida-como-funciona-3.png', query: 'seed=vacio&how=2' },
  { name: 'yo-nada-jugado', ref: '069-yo-nada-jugado.png', query: 'seed=vacio' },
  { name: 'yo-a-medio-curso', ref: '070-yo-a-medio-curso.png', query: 'seed=curso' },
  { name: 'yo-a-medio-curso-pagina-entera', ref: '071-yo-a-medio-curso-pagina-entera.png', query: 'seed=curso', whole: true },
  { name: 'yo-ajustes-cambiados', ref: '072-yo-ajustes-cambiados.png', query: 'seed=curso&do=min:120,todo,habla' },
  { name: 'yo-ajustes-cambiados-al-final', ref: '073-yo-ajustes-cambiados-al-final.png', query: 'seed=curso&do=min:120,todo,habla', scroll: 'end' },
  { name: 'yo-todo-jugado', ref: '074-yo-todo-jugado.png', query: 'seed=todo' },
  { name: 'yo-una-palabra', ref: '075-yo-una-palabra.png', query: 'seed=uno' },
  { name: 'yo-nota-sin-voz', ref: '076-yo-nota-sin-voz.png', query: 'seed=curso&mic=off' },
  { name: 'yo-despues-del-nivel', ref: '080-yo-despues-del-nivel.png', query: 'seed=nivel' },
  { name: 'yo-despues-del-nivel-pagina-entera', ref: '081-yo-despues-del-nivel-pagina-entera.png', query: 'seed=nivel', whole: true },
  { name: 'yo-despues-del-nivel-1-historia', ref: '082-yo-despues-del-nivel-1-historia.png', query: 'seed=nivel1', scroll: 'level-check' },
  // new in order 25: no picture of v=39
  { name: 'nuevo-yo-pie-al-final', ref: null, query: 'seed=curso&build=39', scroll: 'end' },
  { name: 'nuevo-sobre', ref: null, query: 'seed=curso&build=39&about=1' },
  { name: 'nuevo-sobre-al-final', ref: null, query: 'seed=curso&build=39&about=1', scroll: 'sheet' },
  { name: 'nuevo-pista-iphone', ref: null, query: 'seed=curso&ios=1&build=39' },
];

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

// A reference PNG's size, from its header.
const pngSize = (file) => {
  const b = readFileSync(file);
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
};

const browser = await chromium.launch();
const pairs = {
  about: 'Each shot of the Yo tab and the welcome, and the reference picture of v=39 it is held against.',
  devices: chosen.map((d) => ({ id: d.id, css_px: [d.width, d.height], device_scale_factor: d.ratio })),
  shots: [],
};
try {
  for (const dev of chosen) {
    mkdirSync(join(out, dev.id), { recursive: true });
    for (const s of states) {
      if (only.length && !only.includes(s.name)) continue;
      const refFile = s.ref ? join(refRoot, dev.id, s.ref) : null;
      let height = dev.height;
      if (s.whole && refFile) height = Math.round(pngSize(refFile).h / dev.ratio);
      const ctx = await browser.newContext({
        viewport: { width: dev.width, height },
        deviceScaleFactor: dev.ratio,
        hasTouch: true,
        isMobile: true,
        locale: 'en-US',
      });
      const page = await ctx.newPage();
      const errors = [];
      page.on('pageerror', (e) => errors.push(String(e)));
      page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
      await page.goto(`${base}?${s.query}`);
      await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
      await page.waitForTimeout(3500); // a first frame, then time for the fonts and the sheet's slide
      if (s.scroll === 'end' || s.scroll === 'level-check') {
        await page.mouse.move(dev.width / 2, 200);
        await page.mouse.wheel(0, 5000);
        await page.waitForTimeout(800);
      } else if (s.scroll === 'sheet') {
        await page.mouse.move(dev.width / 2, height - 300);
        await page.mouse.wheel(0, 5000);
        await page.waitForTimeout(800);
      }
      const png = join(out, dev.id, `${s.name}.png`);
      await page.screenshot({ path: png });
      console.log(`${dev.id}/${s.name}${errors.length ? '  (errors: ' + errors.join(' | ') + ')' : ''}`);
      pairs.shots.push({
        name: s.name,
        device: dev.id,
        shot: `${dev.id}/${s.name}.png`,
        address: `?${s.query}`,
        scroll: s.scroll ?? null,
        reference: s.ref ? `coqui/ref/pantallas/${dev.id}/${s.ref}` : null,
      });
      await ctx.close();
    }
  }
  writeFileSync(join(out, 'pairs.json'), JSON.stringify(pairs, null, 2) + '\n');

  // ---- the side-by-side pictures: the reference, the shot, and where they differ ----
  const sbs = join(out, 'side-by-side');
  for (const p of pairs.shots) {
    if (!p.reference) continue;
    const dev = chosen.find((d) => d.id === p.device);
    mkdirSync(join(sbs, p.device), { recursive: true });
    const ref = readFileSync(join(refRoot, p.device, p.reference.split('/').pop())).toString('base64');
    const mine = readFileSync(join(out, p.shot)).toString('base64');
    const ctx = await browser.newContext({ viewport: { width: 900, height: 900 }, deviceScaleFactor: 1 });
    const page = await ctx.newPage();
    await page.setContent('<canvas id="c"></canvas>');
    const size = await page.evaluate(async ([a, b]) => {
      const load = (s) => new Promise((ok) => { const i = new Image(); i.onload = () => ok(i); i.src = 'data:image/png;base64,' + s; });
      const [ia, ib] = await Promise.all([load(a), load(b)]);
      const w = Math.max(ia.width, ib.width), h = Math.max(ia.height, ib.height), gap = 24;
      const c = document.getElementById('c');
      c.width = w * 3 + gap * 2; c.height = h;
      const g = c.getContext('2d');
      g.fillStyle = '#888'; g.fillRect(0, 0, c.width, c.height);
      g.drawImage(ia, 0, 0); g.drawImage(ib, w + gap, 0);
      // the difference: what is different is bright, what is the same is dark
      const da = (() => { const t = document.createElement('canvas'); t.width = w; t.height = h; const x = t.getContext('2d'); x.drawImage(ia, 0, 0); return x.getImageData(0, 0, w, h); })();
      const db = (() => { const t = document.createElement('canvas'); t.width = w; t.height = h; const x = t.getContext('2d'); x.drawImage(ib, 0, 0); return x.getImageData(0, 0, w, h); })();
      const d = g.createImageData(w, h);
      for (let i = 0; i < d.data.length; i += 4) {
        const m = Math.max(Math.abs(da.data[i] - db.data[i]), Math.abs(da.data[i + 1] - db.data[i + 1]), Math.abs(da.data[i + 2] - db.data[i + 2]));
        const v = Math.min(255, m * 3);
        d.data[i] = v; d.data[i + 1] = v; d.data[i + 2] = v; d.data[i + 3] = 255;
      }
      g.putImageData(d, (w + gap) * 2, 0);
      return { w: c.width, h: c.height };
    }, [ref, mine]);
    const data = await page.evaluate(() => document.getElementById('c').toDataURL('image/png').split(',')[1]);
    writeFileSync(join(sbs, p.device, `${p.name}.png`), Buffer.from(data, 'base64'));
    p.side_by_side = `side-by-side/${p.device}/${p.name}.png`;
    p.side_by_side_size = size;
    await ctx.close();
  }
  writeFileSync(join(out, 'pairs.json'), JSON.stringify(pairs, null, 2) + '\n');
} finally {
  await browser.close();
  server.close();
}
console.log(`pairs: ${join(out, 'pairs.json')}`);
