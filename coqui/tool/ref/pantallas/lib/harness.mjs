// The harness of the screens script: a static server of the worktree, a phone browser context with everything pinned, the paused clock, and the recorder of pictures.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

export const HERE = path.dirname(fileURLToPath(import.meta.url));
export const REPO = path.resolve(HERE, '../../../../..');          // the worktree (coqui/tool/ref/pantallas/lib -> repo root)
export const OUT = path.join(REPO, 'coqui/ref/pantallas');

// ---- what is pinned -----------------------------------------------------------------------------------------------
// The date: 19 Nov 2026, 12:00 in Puerto Rico (UTC-4, no daylight saving). Every page sees it as `Date`, `performance.now()` starts at 0.
export const T0 = Date.parse('2026-11-19T16:00:00Z');
export const TZ = 'America/Puerto_Rico';
export const DEVICES = [
  { id: 'android-412x915', w: 412, h: 915, dsf: 2.625,
    ua: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36' },
  { id: 'iphone-390x844', w: 390, h: 844, dsf: 3,
    ua: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1' },
];

const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.png': 'image/png',
  '.mp3': 'audio/mpeg', '.txt': 'text/plain; charset=utf-8', '.md': 'text/plain; charset=utf-8', '.css': 'text/css' };
// the worktree served so that the pages sit at /field-notes/historia/..., as on the live site. Port 0: any free port (other agents use fixed ones).
export function serve() {
  return new Promise(res => {
    const s = http.createServer((rq, rs) => {
      const u = decodeURIComponent(rq.url.split('?')[0]);
      if (!u.startsWith('/field-notes/')) { rs.writeHead(404); rs.end(); return; }
      let f = path.join(REPO, u.slice('/field-notes/'.length));
      if (!f.startsWith(REPO)) { rs.writeHead(403); rs.end(); return; }
      if (f.endsWith('/')) f += 'index.html';
      fs.readFile(f, (e, b) => {
        if (e) { rs.writeHead(404); rs.end('not found'); return; }
        rs.writeHead(200, { 'content-type': MIME[path.extname(f)] || 'application/octet-stream', 'cache-control': 'no-store' }); rs.end(b);
      });
    });
    s.listen(0, '127.0.0.1', () => res({ server: s, port: s.address().port }));
  });
}

// ---- injected into every page, before the page's own scripts ------------------------------------------------------
// Math.random is Mulberry32 with seed 1. The audio is silent and runs on the page's (paused) clock: a recorded line "plays" for its own length
// and then ends, so the lit line, the speaking mouth and the order of things are the real ones, and nothing makes a sound.
export const INIT = `
(() => {
  let a = 1;
  Math.random = function () { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  window.__PAL_NOW = ${T0};
  try {
    const P = AudioBufferSourceNode.prototype;
    P.start = function (when, off, dur) {
      if (this.loop) { this.__loop = 1; return; }
      const d = (dur != null ? dur : (this.buffer ? this.buffer.duration - (off || 0) : 0)), self = this;
      this.__t = setTimeout(() => { self.__t = null; if (typeof self.onended === 'function') self.onended(new Event('ended')); }, Math.max(0, d) * 1000);
    };
    P.stop = function () {
      const had = this.__t != null; if (had) { clearTimeout(this.__t); this.__t = null; }
      const self = this; if (had) setTimeout(() => { if (typeof self.onended === 'function') self.onended(new Event('ended')); }, 0);
    };
  } catch (e) {}
})();`;

const initSeed = (json) => `try{if(!localStorage.getItem('coqui.palabras.v1')){localStorage.setItem('coqui.palabras.v1',${JSON.stringify(json)});}}catch(e){}`;

export async function launch() {
  return chromium.launch({ args: ['--mute-audio', '--autoplay-policy=no-user-gesture-required'] });
}

// a new phone context and page: the clock paused at T0 + 1 s (it moves only when `adv` says so), storage seeded with the given palabras.v1 JSON (a string) if any
export async function newPage(browser, dev, { seed = null, routes = null, extraInit = '', motion = false } = {}) {
  const ctx = await browser.newContext({ viewport: { width: dev.w, height: dev.h }, deviceScaleFactor: dev.dsf, isMobile: true, hasTouch: true, userAgent: dev.ua,
    reducedMotion: motion ? 'no-preference' : 'reduce', timezoneId: TZ, locale: 'en-US', colorScheme: 'light', serviceWorkers: 'block' });
  await ctx.addInitScript(INIT + (seed ? initSeed(seed) : '') + extraInit);
  const pg = await ctx.newPage();
  pg.errs = [];
  pg.on('pageerror', e => pg.errs.push('pageerror: ' + e.message));
  pg.on('console', m => { if (m.type() === 'error' && !/vibrate/.test(m.text())) pg.errs.push('console: ' + m.text()); });
  await ctx.route(url => !/^http:\/\/127\.0\.0\.1[:/]/.test(url.href), r => r.abort());   // nothing leaves the machine: no CDN, no ElevenLabs
  if (routes) await routes(pg, ctx);
  await pg.clock.install({ time: T0 });
  await pg.clock.pauseAt(T0 + 1000);
  return pg;
}

// ---- driving the page on its fake clock ---------------------------------------------------------------------------
const real = ms => new Promise(r => setTimeout(r, ms));
export const TICKMS = 70;   // the story engine's own tick (TICK in juego.js): one step of the clock is one frame
// move the fake clock forward by ms, in steps of one frame
export async function adv(pg, ms, step = TICKMS) { for (let t = 0; t < ms; t += step) await pg.clock.runFor(Math.min(step, ms - t)); }
// advance the fake clock until the expression is truthy (checked after every step); throws after maxMs of fake time. Returns the fake ms it took.
export async function until(pg, expr, maxMs = 60000, step = TICKMS) {
  let t = 0;
  for (;;) {
    let ok = false;
    try { ok = await pg.evaluate(expr); } catch (e) { ok = false; }
    if (ok) return t;
    if (t >= maxMs) throw new Error('until timed out after ' + maxMs + ' ms (fake): ' + expr);
    await pg.clock.runFor(step); t += step;
  }
}
// wait, in real time and with the clock paused, until the expression is truthy (fetches and decoding run in real time)
export async function untilReal(pg, expr, maxReal = 30000) {
  const t0 = Date.now();
  for (;;) {
    let ok = false;
    try { ok = await pg.evaluate(expr); } catch (e) { ok = false; }
    if (ok) return;
    if (Date.now() - t0 > maxReal) throw new Error('untilReal timed out: ' + expr);
    await real(25);
  }
}
export const sleepReal = real;

// ---- the recorder -------------------------------------------------------------------------------------------------
// the text that shows in the picture: a text node counts when its first line box is inside the viewport and is the thing a finger would hit there (so clipped
// and covered text is left out). Used to tick off the English strings.
const VISIBLE_TEXT = `() => {
  const st = document.createElement('style'); st.textContent = '*{pointer-events:auto!important}'; document.head.appendChild(st);
  const out = [], w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  for (let n; (n = w.nextNode());) {
    const t = n.nodeValue.replace(/\\s+/g, ' ').trim(); if (!t) continue;
    const p = n.parentElement; if (!p || /^(SCRIPT|STYLE)$/.test(p.tagName)) continue;
    const cs = getComputedStyle(p); if (cs.visibility === 'hidden' || cs.display === 'none' || +cs.opacity === 0) continue;
    const r = document.createRange(); r.selectNodeContents(n); const q = r.getClientRects(); if (!q.length) continue;
    const b = q[0], x = b.left + b.width / 2, y = b.top + b.height / 2;
    if (x < 0 || y < 0 || x > innerWidth || y > innerHeight) continue;
    const e = document.elementFromPoint(x, y); if (e && (p.contains(e) || e.contains(p))) out.push(t);
  }
  st.remove();
  document.querySelectorAll('[aria-label],[placeholder]').forEach(e => { const r = e.getBoundingClientRect(), cs = getComputedStyle(e); if (r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < innerHeight && cs.visibility !== 'hidden') ['aria-label', 'placeholder'].forEach(a => { const v = e.getAttribute(a); if (v) out.push('[' + a + '] ' + v); }); });
  return out;
}`;

export class Recorder {
  constructor(dev, sink) { this.dev = dev; this.n = 0; this.items = []; this.sink = sink; }
  // screen, state: the words of the file name. meta: { url, steps[], orders[], seed }. The picture is of the page's viewport, or, with full: true, of the whole
  // page (the viewport is made as tall as the page, so the tab bar sits at its foot, as it would on a phone as tall as the page).
  async shot(pg, screen, state, meta, opts = {}) {
    this.n++;
    const nn = String(this.n).padStart(3, '0');
    const file = `${nn}-${screen}-${state}.png`;
    await pg.evaluate(() => { try { document.activeElement && document.activeElement.blur && document.activeElement.blur(); } catch (e) {} });
    let H = 0;
    if (opts.full) {
      H = await pg.evaluate('document.documentElement.scrollHeight');
      await pg.setViewportSize({ width: this.dev.w, height: H });
      await untilReal(pg, `innerHeight===${H}`);
      await pg.evaluate('scrollTo(0,0)');
      await untilReal(pg, 'document.documentElement.scrollHeight===innerHeight');
    }
    const buf = await pg.screenshot({ animations: opts.motion ? 'allow' : 'disabled', caret: 'hide', scale: 'device', type: 'png' });
    const text = await pg.evaluate(VISIBLE_TEXT);
    if (opts.full) { await pg.setViewportSize({ width: this.dev.w, height: this.dev.h }); await untilReal(pg, `innerHeight===${this.dev.h}`); }
    this.items.push({ file, nn, screen, state, device: this.dev.id, meta, raw: buf, text, full: !!opts.full });
    if (this.sink) this.sink(file);
    return file;
  }
}
export const sha256 = b => crypto.createHash('sha256').update(b).digest('hex');
