// Runs the OLD pages' session logic (historia/cual.js, historia/nivel.js, with the real historia/palabras.js and
// historia/curso.js) in Node, outside the page, and records what it does. The expected values of the differential
// tests (test/review_differential_test.dart, test/level_differential_test.dart) come from here.
//
// What is real: cual.js and nivel.js whole (cualArranca, cualLista, cualRun, cualItem, cualFin, nivelRun, nivelItem,
// nivelFrontera, nivelPanel ...); palabras.js (PAL: vence, responde, presume); curso.js; and, cut out of juego.js
// BY PATTERN (cutBlock below: the line that starts a definition, and the lines under it that are indented), the
// voice and caption code: say, wait, bien, hush, playClip, letras, letrasFin, muestra, borra, callaLetras, the SFX
// table. What is stubbed: the page (document, canvas, the scenes' drawing), the audio context (a clip "plays" for a
// length that is a function of its id), the clock (virtual: setTimeout, setInterval, performance.now, Date.now) and
// Math.random (Mulberry32 with the scenario's seed, counted).
//
// Nothing in historia/ is changed. Needs Node 22.

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
export const HISTORIA = path.resolve(here, '..', '..', '..', '..', '..', '..', 'historia');
const read = (p) => fs.readFileSync(path.join(HISTORIA, p), 'utf8');

export function mulberry32(a) {
  return function () {
    let t = (a += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** How long a clip "plays" (ms): a function of its id, so that Dart can do the same. */
export function clipLength(id) {
  let s = 0;
  for (let i = 0; i < id.length; i++) s += id.charCodeAt(i);
  return 700 + (s % 13) * 110;
}

/** A definition cut out of a source file by the line that starts it, with the indented lines under it. */
function cutBlock(src, startRe) {
  const lines = src.split('\n');
  const i = lines.findIndex((l) => startRe.test(l));
  if (i < 0) throw new Error('not found in juego.js: ' + startRe);
  let j = i + 1;
  while (j < lines.length && /^\s/.test(lines[j])) j++;
  return lines.slice(i, j).join('\n');
}

// A delay like (360 * 3 + 300) / 1000 * 1000 comes out as 1380.0000000000002 in JavaScript: kept to six decimals,
// so that virtual times stay whole milliseconds. (The real page's setTimeout does the same by rounding to a timer tick.)
const round6 = (x) => Math.round(x * 1e6) / 1e6;

/** Virtual time: timers fire one at a time, in the order of (time, creation). */
export class VirtualTime {
  constructor() {
    this.now = 0;
    this.seq = 0;
    this.timers = [];
  }
  setTimeout(fn, ms) {
    const id = ++this.seq;
    this.timers.push({ id, at: this.now + round6(Math.max(0, +ms || 0)), fn, every: 0 });
    return id;
  }
  setInterval(fn, ms) {
    const id = ++this.seq;
    this.timers.push({ id, at: this.now + ms, fn, every: ms });
    return id;
  }
  clear(id) {
    this.timers = this.timers.filter((t) => t.id !== id);
  }
  next() {
    return this.timers.reduce((a, t) => (!a || t.at < a.at || (t.at === a.at && t.id < a.id) ? t : a), null);
  }
  /** Fires the earliest timer; returns it (so a caller can see who else shares its time). */
  fire() {
    const t = this.next();
    if (!t) return null;
    this.now = t.at;
    if (t.every) {
      t.at += t.every;
      t.id = ++this.seq; // an interval that fires again goes behind what was created before
    } else {
      this.timers = this.timers.filter((x) => x !== t);
    }
    t.fn();
    return t;
  }
  /** Lets every promise settle (a macrotask comes after all microtasks). */
  settle() {
    return new Promise((r) => setImmediate(r));
  }
}

/** A stub DOM element that remembers what it is told. */
function makeEl(name) {
  const classes = new Set();
  const el = {
    name,
    textContent: '',
    innerHTML: '',
    style: {},
    dataset: {},
    onclick: null,
    children: [],
    classList: {
      add: (...c) => c.forEach((x) => classes.add(x)),
      remove: (...c) => c.forEach((x) => classes.delete(x)),
      toggle: (c, on) => {
        const want = on === undefined ? !classes.has(c) : !!on;
        if (want) classes.add(c);
        else classes.delete(c);
        return want;
      },
      contains: (c) => classes.has(c),
    },
    classes,
    appendChild(c) {
      el.children.push(c);
      return c;
    },
    setAttribute() {},
    removeAttribute() {},
    addEventListener() {},
    querySelectorAll: () => [],
    querySelector: () => null,
    getContext: () => new Proxy({}, { get: () => () => {}, set: () => true }),
    getBoundingClientRect: () => ({ left: 0, top: 0, width: 0, height: 0, right: 0, bottom: 0 }),
  };
  return el;
}

/**
 * A fresh old page.
 * opts: { seed, now, store (the stored JSON, an object), query (URL parameters, an object), clips: 'voice'|'silent' }
 */
export async function newOldPage(opts) {
  const vt = new VirtualTime();
  const rnd = mulberry32(opts.seed);
  const log = { calls: [], plays: [], stops: [], tones: [], steps: [], screens: [], groups: [], exits: [], draws: 0 };
  const els = new Map();
  const $ = (sel) => {
    if (!els.has(sel)) els.set(sel, makeEl(sel));
    return els.get(sel);
  };
  const query = new URLSearchParams(opts.query || {});

  const ctx = vm.createContext({});
  const g = (k, v) => {
    ctx[k] = v;
  };
  g('__PAL_NOW', opts.now);
  g('window', ctx);
  g('localStorage', {
    getItem: (k) => (k === 'coqui.palabras.v1' && opts.store ? JSON.stringify(opts.store) : null),
    setItem() {},
  });
  g('document', {
    querySelector: $,
    createElement: (n) => makeEl(n),
    title: '',
  });
  g('location', { search: '?' + query.toString(), href: '' });
  g('URLSearchParams', URLSearchParams);
  g('performance', { now: () => vt.now });
  g('setTimeout', (fn, ms) => vt.setTimeout(fn, ms));
  g('clearTimeout', (id) => vt.clear(id));
  // the 70 ms redraw loops of cual.js and nivel.js only draw: they are left out (they would never end)
  g('setInterval', (fn, ms) => (ms === 70 ? 0 : vt.setInterval(fn, ms)));
  g('clearInterval', (id) => vt.clear(id));
  g('addEventListener', () => {});
  g('console', console);
  g('Promise', Promise);
  g('$', $);
  g('fetch', async (url) => {
    const p = String(url).replace(/\?.*$/, '');
    let text;
    try {
      text = read(p);
    } catch (e) {
      return { ok: false, json: async () => { throw e; } };
    }
    return { ok: true, json: async () => JSON.parse(text) };
  });
  g('__scene', (id) => ({
    id,
    SW: 240,
    SH: 216,
    CAM: { wide: [0, 0, 196, 216] },
    fresh: () => ({}),
    draw() {},
  }));
  g('__log', log);
  g('__sfxTone', (f0, at, dur, type, vol, f1) =>
    log.tones.push({ t: vt.now, hz: f0, at, dur, wave: type ?? null, vol: vol ?? null, toHz: f1 ?? null }),
  );
  g('__audio', () => ({
    currentTime: 0,
    resume() {},
    createBufferSource() {
      const s = {
        _id: null,
        set buffer(b) {
          s._id = b && b.id;
        },
        get buffer() {
          return null;
        },
        connect() {},
        onended: null,
        stopped: false,
        start(when, t0, d) {
          log.plays.push({ t: vt.now, id: s._id });
          s._timer = vt.setTimeout(() => {
            if (!s.stopped && s.onended) s.onended();
          }, d * 1000);
        },
        stop() {
          s.stopped = true;
          if (s._timer) vt.clear(s._timer);
          log.stops.push({ t: vt.now, id: s._id });
        },
      };
      return s;
    },
  }));

  const run = (code, name) => vm.runInContext(code, ctx, { filename: name });

  run(read('palabras.js'), 'palabras.js');
  run(read('curso.js'), 'curso.js');

  // the words of juego.js that the lessons share
  const juego = read('juego.js');
  run(
    `
"use strict";
let S=null,E=null,SW=240,SH=216,W={fx:[]},V={},cam=[0,0,196,216],F=0,runId=0,muted=false,SALIDA=null;
const Q=new URLSearchParams(location.search),FAST=+(Q.get("fast")||1),OIR=Q.get("oir")==="1";
const DW=196,DH=216,TICK=70,ESCENAS=new Proxy({},{get:(o,k)=>(k in o?o[k]:(o[k]=__scene(k)))});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const cv=$("#cv"),dc=cv.getContext("2d"),sc=document.createElement("canvas"),c=sc.getContext("2d");
let blockDim=null,blockFit=null;
const ac=__audio,out=()=>null,tone=(...a)=>__sfxTone(...a);
const HAB={guard:false};
function fit(){}
function respDraw(){}
function cargaEscena(id){ESCENAS[id];return Promise.resolve();}
async function loadVoice(){LINES=S.clips||{};if(__mode==="voice"){for(const id of Object.keys(LINES))CLIPS[id]={buf:{id},t0:0,t1:__len(id)/1000};VOICE=true;}}
const step=n=>{__log.steps.push({t:performance.now(),n});};
function mkDots(n){__log.steps.push({t:performance.now(),dots:n});}
function foot(a,b,c,d){__foot=[!!a,!!b,!!c,!!d];}
let __foot=null;
function estado(s,nopic){__estado=[s,!!nopic];}
let __estado=null;
function pantalla(h,ps){__pantalla={h,ps:ps||[]};__log.screens.push({t:performance.now(),h,ps:ps||[]});}
let __pantalla=null;
function salir(url){__log.exits.push(url);}
`,
    'prelude',
  );
  g('__mode', opts.clips || 'voice');
  g('__len', clipLength);
  // the cut pieces of juego.js
  const pieces = [
    /^const SFX=/,
    /^Object\.assign\(SFX,/,
    /^let SINLETRAS=/,
    /^const words=/,
    /^const dur=/,
    /^function playClip\(/,
    /^function hush\(/,
    /^function say\(/,
    /^const TXT=/,
    /^const capEl=/,
    /^function partes\(/,
    /^function donde\(/,
    /^function muestra\(/,
    /^function borra\(/,
    /^function letras\(/,
    /^function letrasFin\(/,
    /^function callaLetras\(/,
    /^function placeBub\(/,
    /^const wait=/,
    /^const bien=/,
  ];
  const cut = pieces.map((re) => cutBlock(juego, re)).join('\n');
  run('"use strict";\n' + cut, 'juego.js (cut)');
  // PAL wrapped: every call is logged, then done
  vm.runInContext(
    `
(function(){
  for (const k of ["vence","responde","presume"]) {
    const f = PAL[k];
    PAL[k] = function(...a){
      const r = f.apply(PAL, a);
      __log.calls.push({t: performance.now(), op: k, args: JSON.parse(JSON.stringify(a))});
      return r;
    };
  }
})()
`,
    ctx,
  );
  // Math.random: the scenario's generator, counted
  g('__rnd', () => {
    log.draws++;
    return rnd();
  });
  run('Math.random = __rnd; Date.now = () => window.__PAL_NOW;', 'random');
  // the pages themselves
  run(read('cual.js'), 'cual.js');
  if (opts.nivel) run(read('nivel.js'), 'nivel.js');

  return {
    vt,
    log,
    $,
    els,
    ctx,
    run,
    get: (expr) => vm.runInContext(expr, ctx),
    draws: () => log.draws,
    nextDraw: () => rnd(),
  };
}

/** The old page's stored JSON as the page keeps it, from records. */
export function skillRec(over = {}) {
  return Object.assign(
    { etapa: 0, paso: 1, seguidas: 0, fallos: 0, gap: 0, due: 0, aciertos: [], ultima: 0, aparcada: 0, marca: 0, n: 0, bien: 0 },
    over,
  );
}
export function wordRec(w, over = {}) {
  const e = skillRec(Object.assign({ etapa: 1, gap: 1 }, over));
  return { w, primera: (over.due || 0) - 864e5, oida: 1, ear: e, mouth: skillRec() };
}

/**
 * The old page's layout arithmetic, run for phone sizes: juego.js `fit` (the whole-number scale of the block of
 * pictures, the gap between them, the room under it), cual.js `cualSize` / `placeOpts` (where each picture's frame
 * sits) and cual.js `cualGrid` (the end screen's grid). `fit`, `LAND` and `gapFor` are cut out of the page's files
 * by pattern; the page's elements are stubs that have the sizes the CSS gives them.
 *
 * phone: {w, h, dpr, top, bottom, left, right} (CSS px; top and bottom: the safe area), landscape decided by the
 * page's own media query (width > height and height <= 600).
 */
export async function layoutProbe(phones, blocks) {
  const out = [];
  for (const ph of phones) {
    const page = await newOldPage({ seed: 1, now: 0, store: null });
    const { run, get, $, ctx } = page;
    const juego = read('juego.js');
    run(cutBlock(juego, /^const LAND=/), 'LAND');
    run(cutBlock(juego, /^function fit\(/), 'fit');
    run('function finFit(){}', 'finFit');
    const land = ph.w > ph.h && ph.h <= 600;
    ctx.matchMedia = () => ({ matches: land });
    ctx.devicePixelRatio = ph.dpr;
    const padT = land ? ph.top : 0; // #app padding-top: only on its side
    ctx.getComputedStyle = (el) => ({
      paddingLeft: (el.name === '#fin' ? ph.padFin ?? 16 : ph.left) + 'px',
      paddingRight: (el.name === '#fin' ? ph.padFin ?? 16 : ph.right) + 'px',
      paddingTop: padT + 'px',
      paddingBottom: ph.bottom + 'px',
    });
    const app = $('#app');
    app.clientWidth = ph.w;
    app.clientHeight = ph.h;
    const main = $('#main');
    main.clientWidth = ph.w - ph.left - ph.right;
    main.clientHeight = ph.h - ph.bottom - (56 + ph.top); // #top is 56 + the safe area, #app has the bottom padding
    for (const b of blocks) {
      run(`mkOpts(${b.cols * b.rows}, () => {})`, 'mkOpts');
      run(`cualSize(${b.cols}, ${b.rows}, ${b.pw}, ${b.ph})`, 'cualSize');
      run('fit()', 'fit()');
      out.push({
        phone: ph,
        block: b,
        land,
        gap: get('GAP'),
        width: $('#cv').style.width,
        height: $('#cv').style.height,
        marginBottom: $('#stage').style.marginBottom ?? '',
        rects: get('OPT').map((o) => o.style.cssText),
      });
    }
    // the end screen's grid
    const fin = $('#fin');
    fin.clientWidth = ph.w - ph.left - ph.right;
    const props = {};
    fin.style = { setProperty: (k, v) => (props[k] = v) };
    fin.querySelectorAll = (sel) => (sel === '.gw' ? [{}] : []);
    run('cualGrid()', 'cualGrid');
    out.push({ phone: ph, grid: props });
  }
  return out;
}
