// Screenshots of Hablar, the call and the voice test, in each state of a reference picture, for the reader (order 24).
//
//   node tool/shots.mjs [--out <dir>] [--no-build] [--only name,name] [--build-dir <dir>] [--device android|iphone|both] [--no-compose]
//
// Builds the dev entry for the web (`flutter build web -t tool/dev_main.dart --no-web-resources-cdn`), serves it on a
// free local port, and with Playwright captures, on each of the two reference phones (Android 412 x 915 at 2.625,
// iPhone 390 x 844 at 3), one PNG for each state below into <out>/<device>/<name>.png. It writes <out>/pairs.json: for
// each picture the address it was taken at and the reference picture it is to be held against (coqui/ref/pantallas/
// <device>/NNN-*.png), and, unless --no-compose, <out>/<device>/side/<name>.png: the reference on the left and this
// picture on the right, the same height, to look at.
//
// The call and the voice test are driven the way the old pictures were: the scripted call of coqui_testing (stub=manual,
// its steps at fixed ms after the tap on the call disc; the timer on the screen reads what the reference picture reads),
// the scripted recogniser (habla-prueba.html's own ?mic=stub: results). The pictures with "motion" in their name are taken
// with the animations on (the reference ones are with prefers-reduced-motion: the rings, the pulse and the dots at rest).
//
// Run it from coqui/packages/features/feature_speaking (it moves there itself). Needs Node 22 and the pre-installed Playwright.

import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { readFileSync, writeFileSync, mkdirSync, existsSync, statSync, readdirSync } from 'node:fs';
import { dirname, join, extname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');

const here = dirname(fileURLToPath(import.meta.url));
const pkg = resolve(here, '..');
const repo = resolve(pkg, '..', '..', '..', '..');
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
const which = opt('--device', 'both');
const chosen = which === 'both' ? [devices.android, devices.iphone] : [devices[which]];
if (chosen.some((d) => !d)) {
  console.error('--device is android, iphone or both');
  process.exit(1);
}

// ---- what is taken ---------------------------------------------------------------------------------------------------
// ref: the number of the reference picture (the same on both phones). q: the address (after the ?). do: what is done in the page
// before the picture, in order: { tap: 'disc'|'help'|'x'|'mic'|'next'|'card', mark: true } (mark starts the call's clock),
// { until: ms } (wait until that many ms since the mark), { wait: ms }, { reps: n, do: [...] }. full: the picture is the whole page
// (the viewport is made as tall as the reference picture).
const STEPS = (...s) => `stub=manual&steps=${s.join(',')}`;
const CALL = 'screen=call&seed=todo';
const shots = [
  // ---- the Hablar tab
  { name: 'hablar-nada-jugado', ref: '063', title: 'Hablar, nothing played: every card locked', q: 'seed=vacio' },
  { name: 'hablar-nada-jugado-pagina-entera', ref: '064', title: 'Hablar, nothing played, the whole page', q: 'seed=vacio', full: true },
  { name: 'hablar-a-medio-curso', ref: '065', title: 'Hablar, mid-course: La casa done, the next two cards locked', q: 'seed=curso' },
  { name: 'hablar-a-medio-curso-pagina-entera', ref: '066', title: 'Hablar, mid-course, the whole page', q: 'seed=curso', full: true },
  { name: 'hablar-todo-jugado', ref: '067', title: 'Hablar, everything built played: La casa open, "Coming soon" under two places', q: 'seed=todo' },
  { name: 'hablar-todo-jugado-pagina-entera', ref: '068', title: 'Hablar, everything built played, the whole page', q: 'seed=todo', full: true },
  { name: 'hablar-despues-del-nivel', ref: '079', title: 'Hablar after the level check (11 stories counted as played)', q: 'seed=nivel' },
  { name: 'hablar-sin-llamadas', ref: null, title: 'Hablar when this build cannot place a call (no reference: v=39 always could)', q: 'seed=todo&later=1' },
  // ---- the call
  // The screenshot is taken about 0.3 to 0.6 s after it is asked for, so every "until" is that much before the moment of the reference
  // picture (whose timer reads 00:00, 00:02, 00:03, 00:04, 00:05, 00:05, 01:06, 01:06, 00:01, 00:02).
  { name: 'llamada-inicio', ref: '102', title: 'The call, before the tap', q: `${CALL}&stub=manual&reduce=1` },
  { name: 'llamada-llamando', ref: '103', title: 'The call, calling', q: `${CALL}&stub=manual&reduce=1`, do: [{ tap: 'disc', mark: true }, { wait: 100 }] },
  { name: 'llamada-conectado', ref: '104', title: 'The call, connected, Danny not yet speaking', q: `${CALL}&reduce=1&${STEPS('connect@100')}`, do: [{ tap: 'disc', mark: true }, { until: 100 }] },
  { name: 'llamada-danny-habla', ref: '105', title: 'Danny speaks his first line', q: `${CALL}&reduce=1&${STEPS('connect@100', 'danny1@300')}`, do: [{ tap: 'disc', mark: true }, { until: 2200 }] },
  { name: 'llamada-tu-turno', ref: '106', title: "The learner's turn", q: `${CALL}&reduce=1&${STEPS('connect@100', 'danny1@300', 'you1@2000')}`, do: [{ tap: 'disc', mark: true }, { until: 3200 }] },
  { name: 'llamada-tu-turno-hablando', ref: '107', title: "The learner's turn, speaking: the ring follows the microphone", q: `${CALL}&reduce=1&${STEPS('connect@100', 'danny1@300', 'you1@2000', 'talk1@2200')}`, do: [{ tap: 'disc', mark: true }, { until: 4200 }] },
  { name: 'llamada-un-momento', ref: '108', title: 'One moment: he has spoken and been quiet for 0.6 s', q: `${CALL}&reduce=1&${STEPS('connect@100', 'danny1@300', 'you1@2000', 'talk1@2200', 'quiet1@3800')}`, do: [{ tap: 'disc', mark: true }, { until: 5200 }] },
  { name: 'llamada-lo-que-oyo', ref: '109', title: 'What the app heard', q: `${CALL}&reduce=1&${STEPS('connect@100', 'danny1@300', 'you1@2000', 'talk1@2200', 'quiet1@3800', 'heard1@4600')}`, do: [{ tap: 'disc', mark: true }, { until: 5200 }] },
  { name: 'llamada-danny-con-imagen', ref: '110', title: 'Danny asks for the juice and shows its picture', q: `${CALL}&reduce=1&${STEPS('connect@100', 'danny1@300', 'you1@2000', 'talk1@2200', 'quiet1@3800', 'heard1@4600', 'jump60000@4700', 'danny2@4800')}`, do: [{ tap: 'disc', mark: true }, { until: 6200 }] },
  { name: 'llamada-ayuda', ref: '111', title: 'Help touched', q: `${CALL}&reduce=1&${STEPS('connect@100', 'danny1@300', 'you1@2000', 'talk1@2200', 'quiet1@3800', 'heard1@4600', 'jump60000@4700', 'danny2@4800')}`, do: [{ tap: 'disc', mark: true }, { until: 5900 }, { tap: 'help' }, { wait: 100 }] },
  { name: 'llamada-fin-resumen', ref: '112', title: 'The summary after the learner says goodbye: 1 min, 7 words', q: `${CALL}&reduce=1&${STEPS('connect@100', 'danny1@300', 'you1@2000', 'talk1@2200', 'quiet1@3800', 'heard1@4600', 'jump60000@4700', 'danny2@4800', 'you2@5900', 'talk2@6200', 'quiet2@7000', 'heard2@7200', 'you3@7400', 'talk3@7600', 'quiet3@8400', 'heard3@8600')}`, do: [{ tap: 'disc', mark: true }, { until: 13500 }] },
  { name: 'llamada-fin-una-palabra', ref: '113', title: 'The X ends a live call: a summary with one word', q: `${CALL}&reduce=1&${STEPS('connect@100', 'danny1@300', 'you1@1000', 'say:Hola.@1500')}`, do: [{ tap: 'disc', mark: true }, { until: 1900 }, { tap: 'x' }, { wait: 400 }] },
  { name: 'llamada-error-microfono', ref: '114', title: 'The microphone is off', q: `${CALL}&reduce=1&stub=mic`, do: [{ tap: 'disc' }, { wait: 900 }] },
  { name: 'llamada-error-no-empieza', ref: '115', title: 'The call did not start', q: `${CALL}&reduce=1&stub=fail`, do: [{ tap: 'disc' }, { wait: 1000 }] },
  { name: 'llamada-error-biblioteca-de-voz', ref: '116', title: 'The voice part did not load', q: `${CALL}&reduce=1&stub=library`, do: [{ tap: 'disc' }, { wait: 900 }] },
  { name: 'llamada-llamando-con-movimiento', ref: '117', title: 'Calling, with motion (the disc pulses)', q: `${CALL}&stub=manual`, do: [{ tap: 'disc' }] },
  { name: 'llamada-danny-habla-con-ondas', ref: '118', title: 'Danny speaks, with motion (rings spread from the disc)', q: `${CALL}&${STEPS('connect@100', 'danny1@300')}`, do: [{ tap: 'disc', mark: true }, { until: 900 }] },
  { name: 'llamada-un-momento-con-puntos', ref: '119', title: 'One moment, with motion (three dots pulse)', q: `${CALL}&${STEPS('connect@100', 'danny1@300', 'you1@600', 'talk1@800', 'quiet1@1200')}`, do: [{ tap: 'disc', mark: true }, { until: 2200 }] },
  // ---- the voice test (habla-prueba.html)
  { name: 'prueba-de-voz-antes-linea-1', ref: '120', title: 'The voice test, line 1, before the mic', q: 'screen=voice&reduce=1' },
  { name: 'prueba-de-voz-escuchando', ref: '121', title: 'Listening', q: 'screen=voice&reduce=1&micwait=3000&speechwait=3000', do: [{ tap: 'mic' }, { wait: 50 }] },
  { name: 'prueba-de-voz-un-momento', ref: '122', title: 'Un momento: the speech has ended, the result is not in', q: 'screen=voice&reduce=1&micwait=3000', do: [{ tap: 'mic' }, { wait: 800 }] },
  { name: 'prueba-de-voz-despues-oido-bien', ref: '123', title: 'Heard right', q: 'screen=voice&reduce=1', do: [{ tap: 'mic' }, { wait: 600 }] },
  { name: 'prueba-de-voz-despues-no-se-oyo', ref: '124', title: 'Line 2: nothing heard', q: 'screen=voice&reduce=1', do: [{ tap: 'mic' }, { wait: 900 }, { tap: 'next' }, { wait: 300 }, { tap: 'mic' }, { wait: 800 }] },
  { name: 'prueba-de-voz-despues-oido-mal', ref: '125', title: 'Line 6: heard "la caza"', q: 'screen=voice&reduce=1', do: [{ reps: 5, do: [{ tap: 'mic' }, { wait: 900 }, { tap: 'next' }, { wait: 300 }] }, { tap: 'mic' }, { wait: 800 }] },
  { name: 'prueba-de-voz-final', ref: '126', title: 'The result after twelve lines', q: 'screen=voice&reduce=1', do: [{ reps: 12, do: [{ tap: 'mic' }, { wait: 900 }, { tap: 'next' }, { wait: 300 }] }, { wait: 300 }] },
  { name: 'prueba-de-voz-final-al-final', ref: '127', title: 'The result, scrolled to the end', q: 'screen=voice&reduce=1', do: [{ reps: 12, do: [{ tap: 'mic' }, { wait: 900 }, { tap: 'next' }, { wait: 300 }] }, { wait: 300 }, { scroll: 'end' }] },
  { name: 'prueba-de-voz-sin-microfono', ref: '128', title: 'No microphone', q: 'screen=voice&reduce=1&mic=off', do: [{ wait: 300 }] },
  { name: 'prueba-de-voz-escuchando-con-movimiento', ref: '129', title: 'Listening, with motion (a ring spreads)', q: 'screen=voice&micwait=3000&speechwait=3000', do: [{ tap: 'mic' }] },
];

const refDir = (d) => join(repo, 'coqui', 'ref', 'pantallas', d.id);
const refFile = (d, num) => {
  if (!num) return null;
  const f = readdirSync(refDir(d)).find((n) => n.startsWith(`${num}-`) && n.endsWith('.png'));
  return f ? join('coqui', 'ref', 'pantallas', d.id, f) : null;
};
const pngSize = (file) => {
  const b = readFileSync(file);
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
};

// where a tap lands, in CSS px, on a viewport of w x h (portrait; the old layouts' own numbers)
const spot = {
  disc: (w, h) => [w / 2, h - 196], // the call's disc: 32 under the zone, 116 of label, note and Help under the 96 px box
  help: (w, h) => [w / 2, h - 56],
  x: () => [32, 32],
  mic: (w, h) => [w / 2, h - 76], // the voice test's disc: 40 under it
  next: (w, h) => [w / 2, h - 76],
  card: (w) => [w - 56, 112],
};

mkdirSync(out, { recursive: true });
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
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const browser = await chromium.launch();
const pairs = { note: 'reference: the old app (v=39); picture: this build. Paths from the repository root where they start with coqui/.', repository_root: repo, devices: [] };
try {
  for (const d of chosen) {
    const dir = join(out, d.id);
    mkdirSync(dir, { recursive: true });
    const entry = { device: d.id, size: `${d.width}x${d.height} css px, deviceScaleFactor ${d.ratio}`, pictures: [] };
    for (const s of shots) {
      if (only.length && !only.includes(s.name)) continue;
      const ref = refFile(d, s.ref);
      let height = d.height;
      if (s.full && ref) height = Math.round(pngSize(join(repo, ref)).h / d.ratio);
      const ctx = await browser.newContext({
        viewport: { width: d.width, height },
        deviceScaleFactor: d.ratio,
        hasTouch: true,
        isMobile: true,
        locale: 'en-US',
        timezoneId: 'America/Puerto_Rico',
      });
      const page = await ctx.newPage();
      const errors = [];
      page.on('pageerror', (e) => errors.push(String(e)));
      page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
      const address = `?${s.q}`;
      await page.goto(base + address);
      await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
      await sleep(3500); // a first frame, and time for the fonts
      let t0 = 0;
      const run = async (acts) => {
        for (const a of acts) {
          if (a.reps) {
            for (let k = 0; k < a.reps; k++) await run(a.do);
          } else if (a.tap) {
            const [x, y] = spot[a.tap](d.width, height);
            if (a.mark) t0 = Date.now();
            await page.mouse.click(x, y);
          } else if (a.until) {
            const left = a.until - (Date.now() - t0);
            if (left > 0) await sleep(left);
          } else if (a.wait) {
            await sleep(a.wait);
          } else if (a.scroll === 'end') {
            await page.mouse.move(d.width / 2, height / 2);
            await page.mouse.wheel(0, 5000);
            await sleep(300);
          }
        }
      };
      await run(s.do || []);
      const file = join(dir, `${s.name}.png`);
      await page.screenshot({ path: file });
      console.log(`${d.id} ${s.name}${errors.length ? '  (errors: ' + errors.join(' | ') + ')' : ''}`);
      entry.pictures.push({ name: s.name, title: s.title, address, picture: `${d.id}/${s.name}.png`, reference: ref });
      await ctx.close();
    }
    pairs.devices.push(entry);
  }
  writeFileSync(join(out, 'pairs.json'), JSON.stringify(pairs, null, 2) + '\n');

  // the reference on the left and this picture on the right, the same height
  if (!flag('--no-compose')) {
    for (const entry of pairs.devices) {
      const dir = join(out, entry.device, 'side');
      mkdirSync(dir, { recursive: true });
      for (const p of entry.pictures) {
        if (!p.reference) continue;
        const a = readFileSync(join(repo, p.reference)).toString('base64');
        const b = readFileSync(join(out, p.picture)).toString('base64');
        const ra = pngSize(join(repo, p.reference));
        const rb = pngSize(join(out, p.picture));
        const hh = Math.min(2400, Math.max(ra.h, rb.h));
        const wa = Math.round((ra.w * hh) / ra.h);
        const wb = Math.round((rb.w * hh) / rb.h);
        const ctx = await browser.newContext({ viewport: { width: wa + wb + 48, height: hh + 40 }, deviceScaleFactor: 1 });
        const page = await ctx.newPage();
        await page.setContent(
          `<body style="margin:0;background:#777;font:14px sans-serif;color:#fff"><div style="display:flex;gap:16px;padding:8px 16px"><div><div>old app (v=39)</div><img style="display:block;height:${hh}px" src="data:image/png;base64,${a}"></div><div><div>this build</div><img style="display:block;height:${hh}px" src="data:image/png;base64,${b}"></div></div></body>`,
        );
        await sleep(100);
        await page.screenshot({ path: join(dir, `${p.name}.png`) });
        await ctx.close();
      }
    }
  }
} finally {
  await browser.close();
  server.close();
}
console.log(`pairs: ${join(out, 'pairs.json')}`);
