// Screenshots of the dev entry for the reader (order 21): every picture of coqui/ref/pantallas/ that order 21 uses
// (index.json: `orders` has 21), taken on both reference phones, each paired with its reference.
//
//   node tool/shots.mjs [--out <dir>] [--no-build] [--only 030,038,...] [--device android|iphone] [--no-sbs]
//
// Run it from coqui/packages/features/feature_words (it moves there itself). It builds the dev entry for the web
// (`flutter build web -t tool/dev_main.dart --no-web-resources-cdn`), serves it on a free local port and drives it
// with Playwright: for each picture, a phone of the reference's size (412 x 915 at 2.625; 390 x 844 at 3) opens
// `?state=<the picture's seed>`, then does the steps the picture's entry in index.json lists (touch the card of a
// word, scroll to the foot, type, touch Add, ...), through the page's accessibility tree (the dev entry's widgets
// carry the old aria-labels). Into <out>/<device>/ it writes:
//   <nn>-<screen>-<state>.png        the dev entry's picture (device pixels, as the reference)
//   <nn>-...-sbs.png                 the reference at the left, the dev entry's at the right
// and <out>/pairs.json: for each picture the three files, and for a whole-page picture the two page heights.
// A whole-page reference (the viewport as tall as the page: 8000 css px and more) cannot be drawn by one canvas;
// the dev entry is scrolled through it and each stretch is put beside the same stretch of the reference
// (<nn>-...-sbs-<k>.png), the last one with the tab bar.
//
// Needs Node 22 and the pre-installed Playwright. Default <out>: build/shots.

import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { readFileSync, writeFileSync, mkdirSync, existsSync, statSync } from 'node:fs';
import { dirname, join, extname, resolve, basename } from 'node:path';
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
const wanted = opt('--device', 'both') === 'both' ? ['android', 'iphone'] : [opt('--device', 'both')];
for (const d of wanted) if (!devices[d]) { console.error('--device is android, iphone or both'); process.exit(1); }

if (!flag('--no-build')) {
  console.log('building the dev entry for the web ...');
  const r = spawnSync('flutter', ['build', 'web', '-t', 'tool/dev_main.dart', '--no-web-resources-cdn', '-o', buildDir], { cwd: pkg, stdio: 'inherit' });
  if (r.status !== 0) { console.error('the web build failed'); process.exit(1); }
}
if (!existsSync(join(buildDir, 'index.html'))) { console.error(`no build at ${buildDir}`); process.exit(1); }

// ---------- what to take: the pictures of order 21, and their steps ----------
const index = JSON.parse(readFileSync(join(refDir, 'index.json'), 'utf8'));
const pictures = index.pictures.filter((p) => p.orders.includes(21));

// A step of index.json, as something this script can do.
function plan(pic) {
  const steps = [];
  for (const s of pic.steps.slice(1)) {
    let m;
    if (s === 'the whole page, top to bottom') steps.push({ do: 'whole' });
    else if (s.startsWith('scroll to "Add a word or a goal"')) steps.push({ do: 'pageEnd' });
    else if ((m = s.match(/^type "(.*)"$/))) steps.push({ do: 'type', text: m[1] });
    else if (s === 'touch "Add"') steps.push({ do: 'add' });
    else if ((m = s.match(/^touch the card of the word "(.*)"$/))) steps.push({ do: 'card', word: m[1] });
    else if (s.startsWith('touch the play button of the first "Heard in" line')) steps.push({ do: 'playFirst' });
    else if (s.startsWith('scroll the sheet to its end')) steps.push({ do: 'sheetEnd' });
    else throw new Error(`a step this script does not know: ${s}`);
  }
  return steps;
}

// ---------- the server ----------
const mime = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.ttf': 'font/ttf', '.otf': 'font/otf',
  '.css': 'text/css', '.map': 'application/json', '.txt': 'text/plain',
};
const server = createServer((req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  const file = join(buildDir, path === '/' ? 'index.html' : path);
  if (!file.startsWith(buildDir) || !existsSync(file) || !statSync(file).isFile()) { res.writeHead(404); res.end('not found'); return; }
  res.writeHead(200, { 'content-type': mime[extname(file)] || 'application/octet-stream' });
  res.end(readFileSync(file));
});
await new Promise((ok) => server.listen(0, '127.0.0.1', ok));
const base = `http://127.0.0.1:${server.address().port}/`;

// ---------- driving the page ----------
const wait = (page, ms) => page.waitForTimeout(ms);

// The semantic node of a label ("casa: ear 3 of 4, mouth 0 of 4" is found by "casa: ear"), or null.
async function node(page, label, { prefix = true } = {}) {
  const sel = prefix ? `flt-semantics[aria-label^="${label}"]` : `flt-semantics[aria-label="${label}"]`;
  const box = await page.locator(sel).first().boundingBox().catch(() => null);
  return box;
}

// How far the page has scrolled and how long it is: the scroll container of the semantics tree.
const scrollInfo = (page) => page.evaluate(() => {
  const e = [...document.querySelectorAll('flt-semantics')].find((x) => x.scrollHeight > x.clientHeight + 2 && getComputedStyle(x).overflowY === 'scroll');
  return e ? { top: e.scrollTop, height: e.scrollHeight, view: e.clientHeight } : null;
});

async function wheel(page, dev, dy, x = dev.width / 2, y = dev.height / 2) {
  await page.mouse.move(x, y);
  // one wheel step at a time: Flutter turns each into one scroll of that many css px
  let left = dy;
  while (Math.abs(left) > 0) {
    const step = Math.sign(left) * Math.min(Math.abs(left), 1500);
    await page.mouse.wheel(0, step);
    left -= step;
    await wait(page, 60);
  }
  await wait(page, 350);
}

// Brings a card into the middle of the screen (Playwright's own scroll-into-view of the old script), then touches it.
async function touchCard(page, dev, word) {
  const label = `${word}: ear`;
  for (let i = 0; i < 80; i++) {
    const box = await node(page, label);
    const mid = box ? box.y + box.height / 2 : null;
    if (box && box.y > 60 && box.y + box.height < dev.height - 100) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      return;
    }
    if (box && mid !== null && Math.abs(mid - dev.height / 2) > 8) await wheel(page, dev, mid - dev.height / 2);
    else await wheel(page, dev, 600);
  }
  throw new Error(`no card for "${word}"`);
}

// The sheet's body: from its header's foot to the sheet's foot (the tab bar and the Mapa disc stay clear below).
const sheetBody = (dev) => {
  const bottom = dev.height - 72 - 14;
  const top = bottom - dev.height * 0.7;
  return { top: top + 56, bottom };
};

async function run(page, dev, steps) {
  for (const s of steps) {
    if (s.do === 'whole') continue; // the caller handles it
    if (s.do === 'pageEnd') await wheel(page, dev, 40000);
    else if (s.do === 'card') { await touchCard(page, dev, s.word); await wait(page, 900); }
    else if (s.do === 'sheetEnd') {
      const b = sheetBody(dev);
      await wheel(page, dev, 40000, dev.width / 2, (b.top + b.bottom) / 2);
    } else if (s.do === 'playFirst') {
      // the first line's button, brought to the middle of the sheet's body (as Playwright's click did)
      const b = sheetBody(dev);
      let box = await node(page, 'Play: ');
      if (!box) throw new Error('no Heard in line');
      await wheel(page, dev, box.y + box.height / 2 - (b.top + b.bottom) / 2, dev.width / 2, (b.top + b.bottom) / 2);
      box = await node(page, 'Play: ');
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      await wait(page, 500);
    } else if (s.do === 'type') {
      const box = await page.locator('input[aria-label="A word or a goal"]').first().boundingBox().catch(() => null)
        ?? await node(page, 'A word or a goal');
      if (!box) throw new Error('no field');
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      await wait(page, 400);
      await page.keyboard.type(s.text, { delay: 15 });
      await wait(page, 500);
    } else if (s.do === 'add') {
      const box = await node(page, 'Add', { prefix: false });
      if (!box) throw new Error('no Add button');
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      await wait(page, 900);
    }
  }
}

// ---------- the side by side ----------
// A page of the browser puts pictures side by side; nothing but Playwright is needed.
let sbsPage;
async function sideBySide(refFile, mineFile, outFile, { refCrop, mineCrop, label } = {}) {
  const ref = readFileSync(refFile).toString('base64');
  const mine = readFileSync(mineFile).toString('base64');
  const r = await sbsPage.evaluate(async ({ ref, mine, refCrop, mineCrop, label }) => {
    const load = (b64) => new Promise((ok, no) => { const i = new Image(); i.onload = () => ok(i); i.onerror = no; i.src = 'data:image/png;base64,' + b64; });
    const [a, b] = await Promise.all([load(ref), load(mine)]);
    const ca = refCrop ?? { y: 0, h: a.height };
    const cb = mineCrop ?? { y: 0, h: b.height };
    const h = Math.max(ca.h, cb.h), cap = 36, gap = 24;
    const c = document.createElement('canvas');
    c.width = a.width + gap + b.width;
    c.height = h + cap;
    const g = c.getContext('2d');
    g.fillStyle = '#555';
    g.fillRect(0, 0, c.width, c.height);
    g.fillStyle = '#fff';
    g.font = '24px sans-serif';
    g.fillText('reference (v=39)' + (label ? '  ' + label : ''), 8, 26);
    g.fillText('dev entry', a.width + gap + 8, 26);
    g.drawImage(a, 0, ca.y, a.width, ca.h, 0, cap, a.width, ca.h);
    g.drawImage(b, 0, cb.y, b.width, cb.h, a.width + gap, cap, b.width, cb.h);
    return c.toDataURL('image/png').split(',')[1];
  }, { ref, mine, refCrop, mineCrop, label });
  writeFileSync(outFile, Buffer.from(r, 'base64'));
}
const pngSize = (file) => {
  const b = readFileSync(file);
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
};

// ---------- the run ----------
const browser = await chromium.launch();
sbsPage = await (await browser.newContext({ viewport: { width: 400, height: 300 } })).newPage();
await sbsPage.goto('about:blank');
const pairs = {
  about: 'Each entry: the dev entry\'s picture (`mine`), its reference, and the side by side. Sizes are device pixels.',
  pictures: [],
};
mkdirSync(out, { recursive: true });
try {
  for (const dk of wanted) {
    const dev = devices[dk];
    mkdirSync(join(out, dev.id), { recursive: true });
    for (const pic of pictures.filter((p) => p.device === dev.id)) {
      const name = basename(pic.file, '.png');
      if (only.length && !only.some((o) => name.startsWith(o))) continue;
      const steps = plan(pic);
      const whole = steps.some((s) => s.do === 'whole');
      const refFile = join(refDir, pic.file);
      const refSize = pngSize(refFile);
      const ctx = await browser.newContext({
        viewport: { width: dev.width, height: dev.height },
        deviceScaleFactor: dev.ratio,
        hasTouch: true,
        isMobile: true,
        locale: 'en-US',
      });
      const page = await ctx.newPage();
      const errors = [];
      page.on('pageerror', (e) => errors.push(String(e)));
      page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
      await page.goto(`${base}?state=${pic.seed}`);
      await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
      await wait(page, 3500);
      await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
      await wait(page, 1200);
      const entry = { device: dev.id, name, screen: pic.screen, state: pic.state, seed: pic.seed, reference: join(refDir, pic.file), orders: pic.orders };
      if (!whole) {
        await run(page, dev, steps);
        const file = join(out, dev.id, `${name}.png`);
        await page.screenshot({ path: file });
        const sbs = join(out, dev.id, `${name}-sbs.png`);
        if (!flag('--no-sbs')) await sideBySide(refFile, file, sbs);
        Object.assign(entry, { mine: file, sideBySide: flag('--no-sbs') ? null : sbs, size: pngSize(file), referenceSize: refSize });
      } else {
        // the whole page: the reference is one picture as tall as the page; the dev entry is scrolled through
        const refCss = refSize.h / dev.ratio;
        const info0 = await scrollInfo(page);
        const stretch = dev.height - 100; // css px of the page each shot is used for (the tab bar's zone is left out)
        const tiles = [];
        let top = 0;
        for (let k = 0; ; k++) {
          const want = k * stretch;
          const now = (await scrollInfo(page))?.top ?? 0;
          if (want !== now) await wheel(page, dev, want - now);
          const at = (await scrollInfo(page))?.top ?? 0;
          const file = join(out, dev.id, `${name}-${String(k).padStart(2, '0')}.png`);
          await page.screenshot({ path: file });
          const info = await scrollInfo(page);
          const last = !info || at + info.view >= info.height - 1;
          const sbs = join(out, dev.id, `${name}-sbs-${String(k).padStart(2, '0')}.png`);
          // the stretch [at, at + stretch) of both; the last one is the page's foot, with the tab bar
          const refY = Math.round(at * dev.ratio);
          const hh = Math.round((last ? dev.height : stretch) * dev.ratio);
          if (!flag('--no-sbs')) {
            const refTop = last ? Math.max(0, refSize.h - hh) : refY;
            await sideBySide(refFile, file, sbs, {
              refCrop: { y: refTop, h: Math.min(hh, refSize.h - refTop) },
              mineCrop: { y: 0, h: hh },
              label: `y ${Math.round(refTop / dev.ratio)} css px`,
            });
          }
          tiles.push({ scrollTop: at, mine: file, sideBySide: sbs });
          top = at;
          if (last || k > 60) break;
        }
        const end = await scrollInfo(page);
        Object.assign(entry, {
          pageHeightCssMine: end ? end.height : null,
          pageHeightCssReference: refCss,
          tiles,
          referenceSize: refSize,
          note: 'page heights are css px; mine is the scroll extent of the dev entry (the content and its foot padding)',
        });
        void info0; void top;
      }
      if (errors.length) entry.errors = errors;
      pairs.pictures.push(entry);
      console.log(`${dev.id}/${name}${errors.length ? '  (errors: ' + errors.join(' | ') + ')' : ''}`);
      await ctx.close();
    }
  }
} finally {
  await browser.close();
  server.close();
}
writeFileSync(join(out, 'pairs.json'), JSON.stringify(pairs, null, 2) + '\n');
console.log(`pairs: ${join(out, 'pairs.json')}`);
