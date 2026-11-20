// Order 27: pictures of the Palabras tab in the whole app (real pictures, real course), for a before / after read.
//
//   node tool/app_shots.mjs <app build dir> --out=<dir> [--only=01,09] [--width=390 --height=844 --ratio=2]
//                          [--text=1.3]
//
// <app build dir> is a build made by coqui/tool/build_sitio.sh. It is served at /field-notes/app/ and the
// repository's own historia/ at /field-notes/historia/, as coqui/tool/check_app.mjs does. Each state is a fresh
// phone (reduced motion on, the clock fixed at 19 Nov 2026 12:00 in Puerto Rico, as coqui/ref/pantallas) with a
// seed of coqui/ref/pantallas/seeds/ in localStorage, opened at #/tab/words. A whole-page picture is put together
// from stretches of a tall view, scrolled by the mouse wheel (the stretches are checked to meet exactly).
// `--text=1.3` sets the browser's text size (the page's font size), for the text-size check.
// Needs the globally installed Playwright, and python3 with Pillow and numpy for the whole-page pictures.
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire('/opt/node-tools/')('playwright');

const args = process.argv.slice(2);
const flag = (name, dflt) => {
  const a = args.find((x) => x.startsWith(`--${name}=`));
  return a ? a.slice(name.length + 3) : dflt;
};
const dir = args.find((x) => !x.startsWith('--'));
const OUT = flag('out', '');
if (!dir || !fs.existsSync(path.join(dir, 'index.html')) || !OUT) {
  console.error('usage: node tool/app_shots.mjs <app build dir> --out=<dir> [--only=01,02]');
  process.exit(2);
}
fs.mkdirSync(OUT, { recursive: true });
const BUILD = path.resolve(dir);
const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, '..', '..', '..', '..', '..');
const SEEDS = path.join(REPO, 'coqui/ref/pantallas/seeds');
const ONLY = flag('only', '').split(',').filter(Boolean);
const W = +flag('width', '390');
const H = +flag('height', '844');
const RATIO = +flag('ratio', '2');
const TEXT = +flag('text', '1');
const NOW = Date.parse('2026-11-19T16:00:00Z');

// what to take: file name, seed, steps
const STATES = [
  ['01-nada-jugado', 'vacio', []],
  ['02-una-palabra', 'uno', []],
  ['03-a-medio-curso', 'curso', []],
  ['04-a-medio-curso-pagina-entera', 'curso', [{ do: 'whole' }]],
  ['05-todo-jugado', 'todo', []],
  ['06-todo-jugado-pagina-entera', 'todo', [{ do: 'whole' }]],
  ['07-agregar-campo-escrito', 'curso', [{ do: 'end' }, { do: 'type', text: 'talk to my 1-year-old around the house' }]],
  ['08-agregar-guardado', 'curso', [{ do: 'end' }, { do: 'type', text: 'talk to my 1-year-old around the house' }, { do: 'add' }]],
  ['09-palabra-con-imagen', 'curso', [{ do: 'card', word: 'abuelo' }]],
  ['10-palabra-sin-imagen', 'curso', [{ do: 'card', word: 'eres' }]],
  ['11-palabra-vuelve-hoy', 'curso', [{ do: 'card', word: 'abre' }]],
  ['12-palabra-bien-sabida', 'todo', [{ do: 'card', word: 'adiós' }]],
  ['13-palabra-recien-oida', 'curso', [{ do: 'card', word: 'pájaro' }]],
  ['14-palabra-linea-sonando', 'curso', [{ do: 'card', word: 'casa' }, { do: 'playFirst' }]],
  ['15-palabra-al-final', 'curso', [{ do: 'card', word: 'casa' }, { do: 'sheetEnd' }]],
  ['16-palabra-ventana', 'curso', [{ do: 'card', word: 'ventana' }]],
];

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json', '.png': 'image/png', '.wasm': 'application/wasm', '.otf': 'font/otf', '.ttf': 'font/ttf',
  '.mp3': 'audio/mpeg', '.frag': 'text/plain', '.svg': 'image/svg+xml', '.css': 'text/css',
};
const server = http.createServer((req, res) => {
  const p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let root = null, rel = null;
  if (p.startsWith('/field-notes/app/')) { root = BUILD; rel = p.slice('/field-notes/app/'.length); }
  else if (p.startsWith('/field-notes/')) { root = REPO; rel = p.slice('/field-notes/'.length); }
  if (root !== null) {
    if (rel === '' || rel.endsWith('/')) rel += 'index.html';
    const file = path.resolve(root, rel);
    if (file.startsWith(root + path.sep) && fs.existsSync(file) && fs.statSync(file).isFile()) {
      res.writeHead(200, { 'content-type': TYPES[path.extname(file)] || 'application/octet-stream' });
      res.end(fs.readFileSync(file));
      return;
    }
  }
  res.writeHead(404);
  res.end('not found');
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const ORIGIN = `http://127.0.0.1:${server.address().port}`;
const APP = `${ORIGIN}/field-notes/app/`;

const browser = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });

async function nodes(page) {
  return page.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => {
    const r = e.getBoundingClientRect();
    const label = (e.getAttribute('aria-label') || '').trim();
    let own = '';
    for (const c of e.childNodes) if (c.nodeType === 3 || (c.nodeType === 1 && !c.tagName.startsWith('FLT-SEMANTICS'))) own += c.textContent;
    return { text: (label || own).trim(), role: e.getAttribute('role') || '', x: r.x + r.width / 2, y: r.y + r.height / 2, w: r.width, h: r.height, top: r.y };
  }).filter((n) => n.text && n.w > 0 && n.h > 0));
}
async function waitFor(page, test, what, timeout = 30000) {
  const t0 = Date.now();
  for (;;) {
    const ns = await nodes(page);
    const hit = test(ns);
    if (hit) return hit;
    if (Date.now() - t0 > timeout) throw new Error(`${what} never came; on screen: ${JSON.stringify(ns.map((n) => n.text)).slice(0, 800)}`);
    await page.waitForTimeout(250);
  }
}
const lineOf = (n, re) => re.test(n.text) || n.text.split('\n').some((l) => re.test(l.trim()));
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

async function wheelTo(page, find, what) {
  // scroll the tab until a node is in the middle part of the view
  for (let i = 0; i < 80; i++) {
    const n = (await nodes(page)).find(find);
    if (n && n.y > 120 && n.y < H - 160) return n;
    await page.mouse.move(W / 2, H / 2);
    await page.mouse.wheel(0, n && n.y <= 120 ? -300 : 300);
    await page.waitForTimeout(150);
  }
  throw new Error(`could not scroll to ${what}`);
}

async function take(name, seed, steps) {
  const tall = steps.some((s) => s.do === 'whole');
  const vh = tall ? 3000 : H;
  const context = await browser.newContext({
    viewport: { width: W, height: vh }, deviceScaleFactor: RATIO, isMobile: true, hasTouch: false,
    reducedMotion: 'reduce', locale: 'en-US', timezoneId: 'America/Puerto_Rico',
  });
  await context.route((u) => !u.href.startsWith(ORIGIN) && !u.href.startsWith('data:') && !u.href.startsWith('blob:'), (r) => r.abort());
  const s = fs.readFileSync(path.join(SEEDS, `${seed}.json`), 'utf8').replace(/\n/g, '');
  await context.addInitScript(([s, text]) => {
    localStorage.setItem('coqui.palabras.v1', s);
    if (text !== 1) document.addEventListener('DOMContentLoaded', () => { document.documentElement.style.fontSize = `${16 * text}px`; });
  }, [s, TEXT]);
  const page = await context.newPage();
  await page.clock.setFixedTime(NOW);
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  await page.goto(`${APP}#/tab/words`, { waitUntil: 'load' });
  await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
  await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 60000 });
  await page.evaluate(() => {
    const p = document.querySelector('flt-semantics-placeholder');
    const r = p.getBoundingClientRect();
    p.dispatchEvent(new MouseEvent('click', { clientX: r.left + r.width / 2, clientY: r.top + r.height / 2, bubbles: true }));
  });
  await waitFor(page, (ns) => ns.some((n) => lineOf(n, /^Repaso$/)), 'the Repaso card', 60000);
  await page.waitForTimeout(2500); // pictures
  const file = path.join(OUT, `${name}.png`);
  for (const st of steps) {
    if (st.do === 'card') {
      const re = new RegExp(`^${esc(st.word)}([:,]|$)`);
      const n = await wheelTo(page, (n) => n.role === 'button' && re.test(n.text), `the card of ${st.word}`);
      await page.mouse.click(n.x, n.y);
      await waitFor(page, (ns) => ns.some((n) => /^Close$/i.test(n.text)), 'the word sheet');
      await page.waitForTimeout(1500);
    } else if (st.do === 'playFirst') {
      const n = await waitFor(page, (ns) => ns.find((n) => /^Play: /.test(n.text)), 'a play button');
      await page.mouse.click(n.x, n.y);
      await page.waitForTimeout(500);
    } else if (st.do === 'sheetEnd') {
      for (let i = 0; i < 10; i++) { await page.mouse.move(W / 2, H * 0.7); await page.mouse.wheel(0, 400); await page.waitForTimeout(120); }
      await page.waitForTimeout(800);
    } else if (st.do === 'end') {
      for (let i = 0; i < 80; i++) { await page.mouse.move(W / 2, H / 2); await page.mouse.wheel(0, 1500); await page.waitForTimeout(40); }
      await page.waitForTimeout(800);
    } else if (st.do === 'type') {
      // the field is not in the accessibility tree until it is focused: it stands 16 px above Add, 48 px high
      const add = await waitFor(page, (ns) => ns.find((n) => /^Add$/.test(n.text)), 'Add');
      const n = { x: W / 2, y: add.top - 16 - 24 };
      await page.mouse.click(n.x, n.y);
      await page.waitForTimeout(400);
      await page.keyboard.type(st.text, { delay: 10 });
      await page.waitForTimeout(500);
    } else if (st.do === 'add') {
      const n = await waitFor(page, (ns) => ns.find((n) => /^Add$/.test(n.text)), 'Add');
      await page.mouse.click(n.x, n.y);
      await page.waitForTimeout(1200);
    }
  }
  if (tall) {
    // stretches of STEP css px from the top of the view, until the wheel moves the page no further
    const STEP = 2000;
    const parts = [];
    let last = null;
    for (let k = 0; k < 60; k++) {
      const p = path.join(OUT, `.${name}-${k}.png`);
      await page.waitForTimeout(1200);
      await page.screenshot({ path: p });
      const buf = fs.readFileSync(p);
      if (last && buf.equals(last)) { fs.rmSync(p); break; }
      parts.push(p);
      last = buf;
      // one wheel event moves the page at most 500 px
      await page.mouse.move(W / 2, 400);
      for (let i = 0; i < STEP / 500; i++) {
        await page.mouse.wheel(0, 500);
        await page.waitForTimeout(60);
      }
    }
    const py = spawnSync('python3', ['-I', path.join(HERE, 'stitch_shots.py'), file, String(STEP * RATIO), ...parts], { encoding: 'utf8' });
    if (py.status !== 0) throw new Error(`stitch: ${py.stderr}`);
    if (py.stdout.trim()) console.log(`  ${py.stdout.trim()}`);
    for (const p of parts) fs.rmSync(p);
  } else {
    await page.waitForTimeout(600);
    await page.screenshot({ path: file });
  }
  await context.close();
  if (errors.length) console.log(`  page errors: ${errors.join(' | ').slice(0, 400)}`);
  console.log(`${name}: ok`);
}

let failed = 0;
for (const [name, seed, steps] of STATES) {
  if (ONLY.length && !ONLY.some((o) => name.startsWith(o))) continue;
  try {
    await take(name, seed, steps);
  } catch (e) {
    failed++;
    console.log(`${name}: FAILED ${e.message}`);
  }
}
await browser.close();
server.close();
process.exit(failed ? 1 : 0);
