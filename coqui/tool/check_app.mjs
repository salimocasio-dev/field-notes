#!/usr/bin/env node
// Order 26, the browser check of the app: a build made by tool/build_sitio.sh, served as the live site serves it (the
// build at /field-notes/app/, the repository's own historia/ at /field-notes/historia/), opened in headless Chrome at
// the two phone sizes of coqui/ref/pantallas/ (412 x 915 at 2.625, an Android Chrome; 390 x 844 at 3, an iPhone Safari).
//
//   node coqui/tool/check_app.mjs <build dir> --out=<dir> [--only=android|iphone] [--perf-runs=N]
//
// Serves, on a free port of 127.0.0.1, /field-notes/app/... from <build dir> and every other /field-notes/... from the
// repository this script is in (so the content is the real historia/). Playwright is installed globally on this
// machine; it is not a dependency of the repo. A request to any other host is not let out: it is aborted and listed.
//
// For each phone, with an empty store and with the mid-course seed (coqui/ref/pantallas/seeds/curso.json put into
// localStorage under coqui.palabras.v1 before the app starts), it checks, and exits 1 if any fails:
//   - the app starts with no console error and no page error;
//   - each tab opens (its name is the selected tab, and words only that tab shows are there);
//   - empty store: the welcome shows, and is finished; story 1 opens from the map's Today card and reaches its first
//     spoken line (the caption is in the page and the picture is drawn), and its clips are asked for from
//     /field-notes/historia/audio/; the browser's back from it returns to the map, and so does its X;
//   - the book reader, Repaso's start, the level check's start, Hablar and Yo render;
//   - mid-course seed: Repaso (the games of page 15) starts, and one item is played by touches until it writes an Ear
//     answer; when a "Touch the word you heard" item is shown (the first, or the next of the first six items), the
//     clips of its three words said alone (w_*.mp3, and the clip each of its three words has in historia/datos/repaso.json)
//     have been asked for from /field-notes/historia/audio/, and each of its tiles has a speaker;
//   - reloading on a lesson's address (#/nivel) opens that lesson again;
//   - every request stays on the local server, except the ElevenLabs library's (cdn.jsdelivr.net/npm/@elevenlabs/...),
//     which is allowed only once Hablar shows an open call card (the seed: La casa is done); every request that
//     leaves is listed.
// It saves a screenshot of each screen into <out>/<phone>-<state>-<screen>.png, and <out>/report.json.
// Then, on the Android size with ?perf=1 (--perf-runs times, default 3): the time from navigation to the map's first
// frame, the map's bake and frame times as its corner chip shows them, and El frente's first bake from the story's chip.
import fs from 'node:fs';
import http from 'node:http';
import os from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');

const args = process.argv.slice(2);
const flag = (name, dflt) => { const a = args.find((x) => x.startsWith(`--${name}=`)); return a ? a.slice(name.length + 3) : dflt; };
const dir = args.find((x) => !x.startsWith('--'));
const OUT = flag('out', '');
if (!dir || !fs.existsSync(path.join(dir, 'index.html')) || !OUT) {
  console.error('usage: node coqui/tool/check_app.mjs <build dir> --out=<dir> [--only=android|iphone] [--perf-runs=N]');
  process.exit(2);
}
fs.mkdirSync(OUT, { recursive: true });
const BUILD = path.resolve(dir);
const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const ONLY = flag('only', '');
const PERF_RUNS = +flag('perf-runs', '3');
const SEED = fs.readFileSync(path.join(REPO, 'coqui/ref/pantallas/seeds/curso.json'), 'utf8').replace(/\n/g, '');
const REPASO = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/datos/repaso.json'), 'utf8'));
const FIRST_LINE = JSON.parse(fs.readFileSync(path.join(REPO, 'historia/cuentos/la-lluvia.json'), 'utf8')).clips.esta_casa.text;

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json', '.png': 'image/png', '.wasm': 'application/wasm', '.otf': 'font/otf', '.ttf': 'font/ttf',
  '.mp3': 'audio/mpeg', '.frag': 'text/plain', '.svg': 'image/svg+xml', '.css': 'text/css',
};

// ---- the server: /field-notes/app/ is the build, the rest of /field-notes/ the repository -------------------------
const served = []; // { url, status }
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  let status = 404;
  let body = 'not found';
  let type = 'text/plain';
  const p = decodeURIComponent(url.pathname);
  let root = null, rel = null;
  if (p.startsWith('/field-notes/app/')) { root = BUILD; rel = p.slice('/field-notes/app/'.length); }
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
  served.push({ url: url.pathname + url.search, status });
  // GitHub Pages answers with max-age=600; the old pages' cache rules are what the app asks for
  res.writeHead(status, { 'content-type': type, 'cache-control': 'max-age=600' });
  res.end(body);
});
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const ORIGIN = `http://127.0.0.1:${server.address().port}`;
const APP = `${ORIGIN}/field-notes/app/`;

// ---- results ------------------------------------------------------------------------------------------------------
let failed = 0;
const results = [];
const check = (ok, what, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${what}${detail ? `  (${detail})` : ''}`);
  results.push({ ok, what, detail });
  if (!ok) failed++;
};
const left = []; // every request that was meant to leave the site: { phone, state, url, when }
const EL = /^https:\/\/cdn\.jsdelivr\.net\/npm\/@elevenlabs\//;

const PHONES = {
  android: {
    viewport: { width: 412, height: 915 }, deviceScaleFactor: 2.625, isMobile: true, hasTouch: true,
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
  },
  iphone: {
    viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
  },
};

const browser = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });

// A page, watched: console problems, page errors, the requests that leave (aborted and listed).
async function openPage(phone, state, { seed = false } = {}) {
  const context = await browser.newContext(PHONES[phone]);
  if (seed) {
    await context.addInitScript((s) => {
      if (!localStorage.getItem('coqui.palabras.v1')) localStorage.setItem('coqui.palabras.v1', s);
    }, SEED);
  }
  const w = { console: [], errors: [], outside: [], hablarOpenCard: false };
  await context.route((u) => !u.href.startsWith(ORIGIN) && !u.href.startsWith('data:') && !u.href.startsWith('blob:'), (route) => {
    const url = route.request().url();
    w.outside.push(url);
    left.push({ phone, state, url, hablarOpenCard: w.hablarOpenCard });
    return route.abort();
  });
  const page = await context.newPage();
  page.on('console', (m) => {
    if (m.type() === 'error' || (m.type() === 'warning' && !/GL Driver Message/.test(m.text()))) w.console.push(`${m.type()}: ${m.text()}`);
  });
  page.on('pageerror', (e) => w.errors.push(String(e)));
  return { context, page, w };
}

// Flutter draws on a canvas; what is on screen is read from its accessibility tree, turned on once per page load.
// On a phone the placeholder fills the view, and a click at its exact middle turns the tree on (as TalkBack's tap does).
async function enableSemantics(page) {
  await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 60000 });
  await page.evaluate(() => {
    const p = document.querySelector('flt-semantics-placeholder');
    const r = p.getBoundingClientRect();
    p.dispatchEvent(new MouseEvent('click', { clientX: r.left + r.width / 2, clientY: r.top + r.height / 2, bubbles: true }));
  });
  await page.waitForFunction(() => document.querySelectorAll('flt-semantics').length > 0, null, { timeout: 30000 });
}
async function nodes(page) {
  return page.evaluate(() => {
    return [...document.querySelectorAll('flt-semantics')].map((e) => {
      const r = e.getBoundingClientRect();
      const label = (e.getAttribute('aria-label') || '').trim();
      let own = '';
      for (const c of e.childNodes) if (c.nodeType === 3 || (c.nodeType === 1 && c.tagName !== 'FLT-SEMANTICS' && c.tagName !== 'FLT-SEMANTICS-CONTAINER')) own += c.textContent;
      return { text: (label || own).trim(), role: e.getAttribute('role') || '', selected: e.getAttribute('aria-selected') || e.getAttribute('aria-current') || '', x: r.x + r.width / 2, y: r.y + r.height / 2, w: r.width, h: r.height };
    }).filter((n) => n.text && n.w > 0 && n.h > 0);
  });
}
const words = async (page) => (await nodes(page)).map((n) => n.text);
async function waitFor(page, test, what, timeout = 30000) {
  const t0 = Date.now();
  for (;;) {
    const ns = await nodes(page);
    if (test(ns)) return ns;
    if (Date.now() - t0 > timeout) throw new Error(`${what} never came; on screen: ${JSON.stringify(ns.map((n) => n.text)).slice(0, 600)}`);
    await page.waitForTimeout(250);
  }
}
// a node's label can hold several lines (a card's title and its line under it): each line is matched alone too
const says = (n, re) => re.test(n.text) || n.text.split('\n').some((l) => re.test(l.trim()));
const has = (re) => (ns) => ns.some((n) => says(n, re));
async function tapText(page, re, { last = false } = {}) {
  const ns = (await nodes(page)).filter((n) => says(n, re));
  if (!ns.length) throw new Error(`nothing on screen says ${re}`);
  const n = last ? ns[ns.length - 1] : ns[0];
  await page.mouse.click(n.x, n.y);
  await page.waitForTimeout(400);
}
async function startApp(page, hash = '', query = '') {
  await page.goto(`${APP}${query}${hash ? '#' + hash : ''}`, { waitUntil: 'load' });
  await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
  await enableSemantics(page);
}
async function shot(page, name) {
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
}
// The tab bar's five names are always there on a tab; the selected one is read from the URL.
const tabOf = (page) => new URL(page.url()).hash.replace(/^#/, '');
async function openTab(page, label, id) {
  await tapText(page, new RegExp(`^${label}$`), { last: true });
  await page.waitForFunction((h) => location.hash === h, `#/tab/${id}`, { timeout: 15000 });
  await page.waitForTimeout(800);
}
// Whether the picture area is drawn (not one flat colour): from a screenshot of a region.
async function drawn(page, clip) {
  const png = await page.screenshot({ clip });
  return png.length > 3000; // a flat region compresses to a few hundred bytes
}

async function run(phone, state) {
  const seed = state === 'seed';
  const { context, page, w } = await openPage(phone, state, { seed });
  const tag = `${phone}-${state}`;
  const step = async (what, f) => {
    try { await f(); check(true, `${tag}: ${what}`); } catch (e) { check(false, `${tag}: ${what}`, String(e.message || e).slice(0, 900)); }
  };
  await step('the app starts on the map', async () => {
    await startApp(page);
    await waitFor(page, has(/^Mapa$/), 'the tab bar', 60000);
    await waitFor(page, has(seed ? /^2 · El parque$/ : /^1 · La casa$/), 'the map\'s place chip', 30000);
    if (tabOf(page) !== '/tab/map') throw new Error(`the address is ${page.url()}`);
  });
  if (!seed) {
    await step('the welcome shows, and is finished', async () => {
      await waitFor(page, has(/^Next$/), 'the welcome');
      await shot(page, `${tag}-01-welcome`);
      await tapText(page, /^Next$/);
      await tapText(page, /^Next$/);
      await waitFor(page, has(/^I'm new to Spanish$/), 'the welcome\'s last step');
      await shot(page, `${tag}-02-welcome-3`);
      await tapText(page, /^I'm new to Spanish$/);
      await page.waitForTimeout(1200);
      if ((await words(page)).includes("I'm new to Spanish")) throw new Error('the welcome is still there');
    });
  }
  await shot(page, `${tag}-03-map`);
  for (const [label, id, sure] of [
    ['Biblioteca', 'library', /^Biblioteca$|^feature_library$/],
    ['Palabras', 'words', /^Palabras$|^feature_words$/],
    // The seed has an unlocked hero call; its locked-place message is absent.
    ['Hablar', 'speak', seed ? /^By place$/ : /^Opens when you finish /],
    ['Yo', 'me', /day streak/],
    ['Mapa', 'map', seed ? /^2 · El parque$/ : /^1 · La casa$/],
  ]) {
    await step(`the ${label} tab opens`, async () => {
      if (id === 'speak' && seed) w.hablarOpenCard = true; // La casa is done in the seed: its card is open
      await openTab(page, label, id);
      await waitFor(page, has(sure), `${label}'s own words`, 15000);
      await shot(page, `${tag}-04-tab-${id}`);
    });
  }
  if (!seed) {
    await step('story 1 opens from the map\'s Today card and reaches its first spoken line', async () => {
      const before = served.length;
      await tapText(page, /^La lluvia$/);
      await page.waitForFunction(() => location.hash === '#/cuento/la-lluvia', null, { timeout: 15000 });
      await waitFor(page, has(/^Start$/), 'the start disc', 30000);
      const ns = await nodes(page);
      if (ns.some((n) => /^Mapa$/.test(n.text))) throw new Error('the tab bar is there on the story');
      await shot(page, `${tag}-05-story-start`);
      await tapText(page, /^Start$/);
      await waitFor(page, has(new RegExp(FIRST_LINE.replace(/[.?]/g, '\\$&'))), 'the first line\'s caption', 30000);
      await shot(page, `${tag}-06-story-first-line`);
      const vp = PHONES[phone].viewport;
      if (!(await drawn(page, { x: 0, y: 80, width: vp.width, height: Math.round(vp.width * 216 / 196) - 40 }))) throw new Error('the picture is not drawn');
      const audio = served.slice(before).filter((s) => s.url.startsWith('/field-notes/historia/audio/') && /\.mp3\?v=/.test(s.url));
      if (!audio.length) throw new Error('no clip was asked for from /field-notes/historia/audio/');
      check(true, `${tag}: clips asked for from /field-notes/historia/audio/ (${audio.length}, e.g. ${audio[0].url})`);
    });
    await step('the browser\'s back from the story returns to the map', async () => {
      await page.goBack();
      await page.waitForFunction(() => location.hash === '#/tab/map', null, { timeout: 15000 });
      await waitFor(page, has(/^1 · La casa$/), 'the map', 15000);
    });
    await step('the story\'s X returns to the map, by the browser\'s own back', async () => {
      const len = await page.evaluate(() => history.length);
      await tapText(page, /^La lluvia$/);
      await page.waitForFunction(() => location.hash === '#/cuento/la-lluvia', null, { timeout: 15000 });
      await waitFor(page, has(/^Close$/), 'the X', 30000);
      await tapText(page, /^Close$/);
      await page.waitForFunction(() => location.hash === '#/tab/map', null, { timeout: 15000 });
      await waitFor(page, has(/^Mapa$/), 'the tab bar back', 15000);
      const after = await page.evaluate(() => history.length);
      if (after !== len) throw new Error(`history.length was ${len}, is ${after}`);
    });
  } else {
    let repasoFrom = 0; // the requests from the moment Repaso is opened
    await step('Repaso opens from the map\'s Today card, at its start', async () => {
      repasoFrom = served.length;
      await tapText(page, /^¿Cuál\?$/);
      await page.waitForFunction(() => location.hash === '#/repaso', null, { timeout: 15000 });
      await waitFor(page, has(/^Start$/), 'Repaso\'s start disc', 30000);
      await shot(page, `${tag}-05-repaso-start`);
    });
    await step('Repaso: Start, and one item of the games (page 15) is played: an Ear answer is written; a "Touch the word you heard" item has asked for its words\' clips', async () => {
      const earAnswers = () => page.evaluate(() => {
        const db = JSON.parse(localStorage.getItem('coqui.palabras.v1') || '{}');
        return Object.values(db.palabras || {}).reduce((n, r) => n + ((r.ear && r.ear.n) || 0), 0);
      });
      const vp = PHONES[phone].viewport;
      const line = /^Listen\. Touch the (word you heard|picture that fits)\.$/;
      // the options under the line: ¿Cuál?'s two pictures, or ¿Qué oyes?'s three word tiles
      const optionsOf = (ns, game, words) => (words
        ? ns.filter((n) => n.role === 'button' && n.y > game.y + 10 && n.y < vp.height - 120 && !/^(Hear the word|Close|Sound|Hear it again|Next)$/.test(n.text) && !line.test(n.text))
        : ns.filter((n) => /^Picture \d$/.test(n.text)));
      // The clips of the three words said alone were asked for when Repaso opened (w_*.mp3 for the words that have no clip
      // in a story), the item's own three words' clips among them, and each tile has its speaker.
      const wordClipsAsked = async (ns, game) => {
        const asked = served.slice(repasoFrom).filter((x) => x.status === 200 && /^\/field-notes\/historia\/audio\/[^/?]+\.mp3(\?|$)/.test(x.url)).map((x) => x.url.split('?')[0].split('/').pop().replace(/\.mp3$/, ''));
        const solas = asked.filter((id) => /^w_/.test(id));
        if (!solas.length) throw new Error('no request for a w_*.mp3 under /field-notes/historia/audio/ since Repaso opened; asked: ' + [...new Set(asked)].slice(0, 12).join(', '));
        const tiles = optionsOf(ns, game, true).map((n) => n.text);
        if (tiles.length !== 3) throw new Error(`the item has ${tiles.length} word tiles (${tiles.join(' | ')}), not 3`);
        const clipOf = (w) => { const r = REPASO.palabras.find((x) => x.w === w); if (!r || !r.solo) throw new Error(`repaso.json has no clip of the word alone for "${w}"`); return r.solo; };
        const missing = tiles.map(clipOf).filter((id) => !asked.includes(id));
        if (missing.length) throw new Error(`the clips of the item's words were not asked for: ${missing.join(', ')} (tiles ${tiles.join(' | ')})`);
        const speakers = ns.filter((n) => n.text === 'Hear the word').length;
        if (speakers !== 3) throw new Error(`${speakers} speakers on the three tiles, not 3`);
        check(true, `${tag}: a "Touch the word you heard" item is shown: ${solas.length} clips w_*.mp3 asked for (e.g. ${solas[0]}.mp3), and the clips of its three words (${tiles.map(clipOf).join(', ')}), each tile with its speaker`);
      };
      // Touches the item's options in turn until an Ear answer is written (a touch before the sentence ends does not
      // count; after a wrong one only the right one is taken).
      const answer = async (game, words, before) => {
        const t0 = Date.now();
        let after = before;
        while (after === before) {
          if (Date.now() - t0 > 40000) throw new Error('no answer was written in 40 s');
          const opts = optionsOf(await nodes(page), game, words);
          if (!opts.length) throw new Error(`no option under the line; on screen: ${JSON.stringify((await nodes(page)).map((n) => n.text)).slice(0, 400)}`);
          for (const o of opts) {
            await page.mouse.click(o.x, o.y);
            await page.waitForTimeout(700);
            after = await earAnswers();
            if (after !== before) break;
          }
        }
        if (after !== before + 1) throw new Error(`ear answers went from ${before} to ${after}`);
        return after;
      };
      let ear = await earAnswers();
      const first = ear;
      await tapText(page, /^Start$/);
      let hearChecked = false;
      for (let item = 1; item <= 6; item++) {
        const ns0 = await waitFor(page, has(line), `item ${item}'s line (the first six items are asked: ¿Cuál? and ¿Qué oyes? take turns for three, then a play game)`, 30000);
        const game = ns0.find((n) => says(n, line));
        const words = game.text.includes('word');
        await page.waitForTimeout(800);
        const ns = await nodes(page);
        if (item === 1) await shot(page, `${tag}-05b-repaso-${words ? 'que-oyes' : 'cual'}`);
        if (words && !hearChecked) {
          await wordClipsAsked(ns, game);
          hearChecked = true;
          if (item > 1) await shot(page, `${tag}-05b-repaso-que-oyes-item-${item}`);
        }
        ear = await answer(game, words, ear);
        if (item === 1) {
          await page.waitForTimeout(1500);
          await shot(page, `${tag}-05c-repaso-answered`);
        }
        if (hearChecked) break;
        // not the game: on to the next item (a wrong touch leaves the right one to be touched; Next shows then)
        for (let k = 0; k < 20 && !has(/^Next$/)(await nodes(page)); k++) {
          const opts = optionsOf(await nodes(page), game, words);
          if (opts.length) await page.mouse.click(opts[k % opts.length].x, opts[k % opts.length].y);
          await page.waitForTimeout(500);
        }
        await tapText(page, /^Next$/);
      }
      if (!hearChecked) throw new Error('no "Touch the word you heard" item among the first six items of the session');
      if (ear <= first) throw new Error('no Ear answer was written');
      await page.goBack();
      await page.waitForFunction(() => location.hash === '#/tab/map', null, { timeout: 15000 });
    });
  }
  for (const [hash, name, sure] of [
    ['/libro/la-lluvia', 'book', seed ? /^feature_library$|^Close$/ : /^feature_library$|^Close$/],
    ['/repaso', 'repaso', /^Start$/],
    ['/nivel', 'level-check', /^Start$/],
  ]) {
    await step(`#${hash} renders (${name})`, async () => {
      await page.evaluate((h) => { location.hash = h; }, hash);
      await waitFor(page, has(sure), name, 30000);
      await page.waitForTimeout(1000);
      const ns = await nodes(page);
      if (ns.some((n) => /^Mapa$/.test(n.text)) && name !== 'book') throw new Error('the tab bar is there on a lesson');
      await shot(page, `${tag}-07-${name}`);
    });
  }
  await step('reloading on a lesson\'s address reopens it', async () => {
    await page.reload({ waitUntil: 'load' });
    await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
    await enableSemantics(page);
    await waitFor(page, has(/^Start$/), 'the level check after the reload', 60000);
    if (tabOf(page) !== '/nivel') throw new Error(`the address is ${page.url()}`);
    if ((await words(page)).includes('Mapa')) throw new Error('the tab bar is there');
  });
  await step('an unknown address opens the map', async () => {
    await page.evaluate(() => { location.hash = '/no-es-nada'; });
    await page.waitForFunction(() => location.hash === '#/tab/map', null, { timeout: 15000 });
    await waitFor(page, has(/^Mapa$/), 'the map', 15000);
  });
  await step('the voice test\'s address (#/prueba-voz)', async () => {
    await page.evaluate(() => { location.hash = '/prueba-voz'; });
    await page.waitForTimeout(2000);
    const at = tabOf(page);
    check(true, `${tag}: #/prueba-voz shows ${at === '/prueba-voz' ? 'the voice test' : `the map (${at}): the voice test is not wired (see the report)`}`);
    await shot(page, `${tag}-08-prueba-voz`);
  });
  // the ElevenLabs library's address is not let out from this machine: each aborted load prints one "Failed to load resource"
  const aborted = w.outside.filter((u) => EL.test(u)).length;
  const own = w.console.filter((m, i) => !(m === 'error: Failed to load resource: net::ERR_FAILED' && w.console.slice(0, i + 1).filter((x) => x === m).length <= aborted));
  check(own.length === 0 && w.errors.length === 0, `${tag}: no console error and no page error${aborted ? ` (but the ${aborted} "Failed to load resource" of the aborted library loads)` : ''}`, [...own, ...w.errors].join(' | ').slice(0, 1500));
  const bad = w.outside.filter((u) => !(EL.test(u) && seed));
  check(bad.length === 0, `${tag}: every request stays on the local server, but the ElevenLabs library's on an open call card`, [...new Set(w.outside)].join(', '));
  await context.close();
}

for (const phone of Object.keys(PHONES)) {
  if (ONLY && ONLY !== phone) continue;
  for (const state of ['empty', 'seed']) await run(phone, state);
}

// ---- timing, on the Android size, with ?perf=1 ----------------------------------------------------------------------
const perf = [];
for (let i = 0; i < PERF_RUNS; i++) {
  const { context, page } = await openPage('android', 'perf', { seed: true });
  const t0 = Date.now();
  await page.goto(`${APP}?perf=1`, { waitUntil: 'commit' });
  let firstMap = null;
  await enableSemantics(page).catch(() => null);
  for (let k = 0; k < 1200 && firstMap === null; k++) {
    const r = await page.evaluate(() => {
      const has = [...document.querySelectorAll('flt-semantics')].some((e) => (e.getAttribute('aria-label') || e.textContent || '').trim() === 'Course map');
      return has ? performance.now() : null;
    }).catch(() => null);
    if (r !== null) firstMap = r;
    else await page.waitForTimeout(50);
  }
  await page.waitForTimeout(6000); // frames
  const chip = (await words(page)).find((t) => /^bake \d+ ms · frame max/.test(t)) || '';
  // El frente's first bake: story 1, by its address (the seed has it played)
  await page.evaluate(() => { location.hash = '/cuento/la-lluvia'; });
  let scene = '';
  for (let k = 0; k < 120 && !/scene bake \d+ ms/.test(scene); k++) {
    scene = (await words(page)).find((t) => /^scene bake/.test(t)) || '';
    await page.waitForTimeout(250);
  }
  await page.screenshot({ path: path.join(OUT, `perf-${i + 1}-story.png`) });
  perf.push({ run: i + 1, navToMapMs: firstMap === null ? null : Math.round(firstMap), wallMs: Date.now() - t0, mapChip: chip, sceneChip: scene, load: os.loadavg().map((x) => x.toFixed(2)).join(' ') });
  console.log(`PERF  run ${i + 1}: navigation to the map's first frame ${firstMap === null ? '?' : Math.round(firstMap)} ms; map: ${chip}; El frente: ${scene}; load ${os.loadavg().map((x) => x.toFixed(2)).join(' ')}`);
  await context.close();
}

await browser.close();
server.close();
console.log('\nrequests that left the site (aborted):');
for (const l of left) console.log(`  ${l.phone}-${l.state}: ${l.url}${l.hablarOpenCard ? ' (Hablar had shown an open call card)' : ''}`);
if (!left.length) console.log('  none');
fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify({ results, left, perf, notFound: served.filter((s) => s.status !== 200) }, null, 2));
console.log(`\n${failed ? `${failed} check(s) FAILED` : 'all checks passed'}; screenshots and report.json in ${OUT}`);
process.exit(failed ? 1 : 0);
