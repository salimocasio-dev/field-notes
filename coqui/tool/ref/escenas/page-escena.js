// ref/escenas: run inside an OLD page (historia/index.html, cual.html or nivel.html) after it has loaded, as global code, so it sees
// juego.js's top-level names (W, F, cam, S, E, SP, spr, c, sc ...). Read only: it never changes a file and never runs the story.
// It adds window.__E6 with what make.mjs asks for: what a scene was given (cosas, lugar ...), boxes and visibility in a state,
// the hit test over a grid, and a frame drawn by the scene's own draw() with every canvas call recorded (file:line of the caller).
// page-init.js of ref/trazas is injected before the page scripts (virtual clock, seeded Math.random, the KIT.escena catch: __H.escena).
(() => {
  "use strict";
  const H = window.__H, E6 = (window.__E6 = {});
  const CFG = (E6.cfg = { bgFns: {}, charFns: {}, charLines: {}, keepFns: {} });   // filled by make.mjs (config.mjs) before use
  const plain = v => { const seen = new WeakSet(); return JSON.parse(JSON.stringify(v === undefined ? null : v, (k, x) => {   // as ref/trazas' --states: functions out, canvases as a note, a repeated object as "[seen]"
    if (typeof x === "function") return undefined;
    if (x && typeof x === "object") { if (x instanceof HTMLCanvasElement) return "[canvas " + x.width + "x" + x.height + "]"; if (seen.has(x)) return "[seen]"; seen.add(x); }
    return x; })); };
  E6.plain = plain;

  // ---------- stacks: who called ----------
  const FR = /^\s*at (?:(.*?) \()?(.*?):(\d+):(\d+)\)?$/;
  const frames = st => st.split("\n").slice(1).map(l => { const m = FR.exec(l); return m ? { fn: m[1] || "", file: m[2].replace(/^.*\/historia\//, "").replace(/\?.*$/, ""), line: +m[3] } : null; }).filter(Boolean);
  const own = f => /^(escenas\/|juego\.js|engine\.js|cual\.js|nivel\.js)/.test(f.file);
  function who(st) {   // the scene-side frames, innermost first; site = the first frame in a scene or kit file
    const f = frames(st).filter(own), i = f.findIndex(x => /^escenas\//.test(x.file));
    return { site: i >= 0 ? `${f[i].file}:${f[i].line}` : null, fn: i >= 0 ? f[i].fn : null, chain: f.slice(0, 8).map(x => `${x.fn || "?"}@${x.file}:${x.line}`) };
  }

  // ---------- reads of W ----------
  const READS = [];   // active collectors (Sets); every top-level read of W goes into each
  const NREADS = [];  // active collectors of two-level reads ("ab.en")
  function proxyW(t, deep) {
    const sub = new WeakMap();
    const inner = (o, k0) => { if (!o || typeof o !== "object" || o instanceof HTMLCanvasElement) return o; if (sub.has(o)) return sub.get(o);
      const p = new Proxy(o, { get(x, k, r) { const v = Reflect.get(x, k, r); if (typeof k === "string" && NREADS.length && !Array.isArray(x)) for (const s of NREADS) s.add(k0 + "." + k); return v; } }); sub.set(o, p); return p; };
    return new Proxy(t, { get(x, k, r) { const v = Reflect.get(x, k, r); if (typeof k === "string") { for (const s of READS) s.add(k); if (deep && NREADS.length) for (const s of NREADS) s.add(k); } return deep ? inner(v, String(k)) : v; } });
  }
  const collect = (fn, deep) => { const s = new Set(), n = new Set(); READS.push(s); if (deep) NREADS.push(n); let r, err = null;
    try { r = fn(); } catch (e) { err = String(e && e.message || e); } finally { READS.splice(READS.indexOf(s), 1); if (deep) NREADS.splice(NREADS.indexOf(n), 1); }
    return { r, err, reads: [...s].sort(), nreads: [...n].sort() }; };

  // ---------- the sprite cache: which key, made by what, asked for where ----------
  const FACT = (E6.fact = {}), KEYOF = new Map();
  let SCENE = null;   // the scene being drawn (for the background names)
  const isBg = (fn, src) => { const L = (SCENE && CFG.bgFns[SCENE]) || []; return L.includes(fn.name) || L.some(n => new RegExp("^\\(\\)\\s*=>\\s*" + n + "\\(").test(src)); };
  const _spr = spr;
  window.spr = function spr(k, fn) {
    if (!(k in SP)) {
      const src = String(fn), w = who(new Error().stack), f = { src: src.length > 300 ? src.slice(0, 300) + "..." : src, name: fn.name || "", site: w.site, bg: isBg(fn, src), scene: SCENE };
      const r = collect(() => _spr(k, fn));   // what the maker reads of W (a background that reads W itself)
      f.reads = r.reads; FACT[k] = f;
      if (r.err) throw new Error(r.err);
    }
    const v = SP[k]; if (v && typeof v === "object") KEYOF.set(v, k); return v;
  };
  E6.resetSprites = () => { for (const k of Object.keys(SP)) delete SP[k]; for (const k of Object.keys(FACT)) delete FACT[k]; };

  // ---------- the recording context: juego.js's scene canvas context `c`, its own methods wrapped on the instance ----------
  const P = CanvasRenderingContext2D.prototype, X = c;
  const DRAWM = ["drawImage", "fillRect", "clearRect", "strokeRect", "fill", "stroke", "putImageData", "fillText", "strokeText"];
  const PATHM = ["beginPath", "rect", "arc", "ellipse", "moveTo", "lineTo", "closePath", "quadraticCurveTo", "bezierCurveTo", "arcTo"];
  const STATEM = ["save", "restore", "translate", "scale", "rotate", "setTransform", "transform", "resetTransform", "clip"];
  let REC = null, SUP = null, path = [], shapes = [], clipStack = [], clips = [];
  const R2 = v => Math.round(v * 100) / 100;
  const tp = (x, y) => { const m = X.getTransform(); return [m.a * x + m.c * y + m.e, m.b * x + m.d * y + m.f]; };
  const bbox = pts => { if (!pts.length) return null; let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity; for (const [x, y] of pts) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); } return [R2(x0), R2(y0), R2(x1 - x0), R2(y1 - y0)]; };
  const rectPts = (x, y, w, h) => [tp(x, y), tp(x + w, y), tp(x, y + h), tp(x + w, y + h)];
  const keyOf = img => KEYOF.get(img) || (img === sc ? "[scene canvas]" : img && img.width != null ? `[canvas ${img.width}x${img.height}]` : "?");
  for (const m of [...DRAWM, ...PATHM, ...STATEM]) {
    const o = P[m];
    X[m] = function (...a) {
      if (!REC && !SUP) { return o.apply(X, a); }
      if (PATHM.includes(m)) {
        if (m === "beginPath") { path = []; shapes = []; }
        else if (m === "rect") { path.push(...rectPts(a[0], a[1], a[2], a[3])); shapes.push({ t: "rect", r: bbox(rectPts(a[0], a[1], a[2], a[3])), user: a.slice(0, 4) }); }
        else if (m === "arc") { const [x, y, r] = a, p = rectPts(x - r, y - r, 2 * r, 2 * r); path.push(...p); shapes.push({ t: "arc", r: bbox(p), user: [x, y, r] }); }
        else if (m === "ellipse") { const [x, y, rx, ry] = a, p = rectPts(x - rx, y - ry, 2 * rx, 2 * ry); path.push(...p); shapes.push({ t: "ellipse", r: bbox(p), user: [x, y, rx, ry] }); }
        else if (a.length >= 2) path.push(tp(a[a.length - 2], a[a.length - 1]));
        return o.apply(X, a);
      }
      if (m === "save") { clipStack.push(clips.slice()); return o.apply(X, a); }
      if (m === "restore") { clips = clipStack.pop() || []; return o.apply(X, a); }
      if (m === "clip") { const w = who(new Error().stack), cl = { site: w.site, fn: w.fn, chain: w.chain, shapes: shapes.slice(), box: bbox(path) }; clips = clips.concat([cl]); if (REC) REC.push({ m: "clip", ...cl }); return o.apply(X, a); }
      if (STATEM.includes(m)) return o.apply(X, a);
      // a drawing call
      const w = who(new Error().stack);
      let key = null, box = null;
      if (m === "drawImage") { key = keyOf(a[0]); const n = a.length; box = n >= 9 ? bbox(rectPts(a[5], a[6], a[7], a[8])) : n >= 5 ? bbox(rectPts(a[1], a[2], a[3], a[4])) : bbox(rectPts(a[1], a[2], a[0].width, a[0].height)); }
      else if (m === "fillRect" || m === "clearRect" || m === "strokeRect") box = bbox(rectPts(a[0], a[1], a[2], a[3]));
      else if (m === "fill" || m === "stroke") box = bbox(path);
      else if (m === "putImageData") box = [a[1], a[2], a[0].width, a[0].height];
      const e = { m, site: w.site, fn: w.fn, chain: w.chain, key, box, alpha: R2(X.globalAlpha), clip: clips.length ? clips.map(x => x.site) : null, smooth: X.imageSmoothingEnabled };
      if (key && FACT[key]) { e.maker = FACT[key].src; e.bg = FACT[key].bg; }
      if (REC) REC.push(e);
      if (SUP && SUP(e)) return;   // left out of this picture (the background alone, or the picture without characters)
      return o.apply(X, a);
    };
  }
  const isChar = (scene, e) => { const fns = CFG.charFns[scene] || [], lines = CFG.charLines[scene] || [], keep = CFG.keepFns[scene] || [];
    const sc0 = e.chain.filter(x => /@(escenas\/|juego\.js)/.test(x)), fn = x => x.split("@")[0].replace(/^Object\./, ""), loc = x => x.split("@")[1].replace(/^escenas\//, "");
    if (sc0.some(x => keep.includes(fn(x)))) return false;
    return sc0.some(x => fns.includes(fn(x)) || lines.includes(loc(x))); };
  E6.isChar = isChar;

  // ---------- one scene: what it was given ----------
  const src = f => f == null ? null : typeof f === "function" ? String(f) : null;
  E6.desc = id => {   // the object the scene passed to KIT.escena (kit scenes), or ESCENAS[id] (El frente)
    const d = H.escena[id], Es = ESCENAS[id];
    if (!d) return { kit: false, keys: Object.keys(Es), CAM: plain(Es.CAM), heartAt: plain(Es.heartAt), handAt: Object.fromEntries(Object.keys(Es.handAt).map(k => [k, plain(Es.handAt[k])])), handAtSrc: Object.fromEntries(Object.keys(Es.handAt).map(k => [k, (Object.getOwnPropertyDescriptor(Es.handAt, k).get ? "getter: " + String(Object.getOwnPropertyDescriptor(Es.handAt, k).get) : null)])),
      acts: Object.fromEntries(Object.keys(Es.acts).map(k => [k, String(Es.acts[k])])), fresh: src(Es.fresh), SW: Es.SW, SH: Es.SH,
      fns: Object.fromEntries(Object.keys(Es).filter(k => typeof Es[k] === "function").map(k => [k, String(Es[k])])) };
    const T = x => typeof x === "function" ? { fn: String(x) } : plain(x);
    return { kit: true, keys: Object.keys(d), id: d.id, CAM: plain(d.CAM), heartAt: d.heartAt === undefined ? null : plain(d.heartAt), lugar: plain(d.lugar),
      cosas: d.cosas.map(t => { const o = {}; for (const k of Object.keys(t)) o[k] = T(t[k]); return o; }),
      acts: Object.fromEntries(Object.keys(d.acts).map(k => [k, String(d.acts[k])])), fresh: src(d.fresh),
      fns: Object.fromEntries(Object.keys(d).filter(k => typeof d[k] === "function").map(k => [k, String(d[k])])),
      other: Object.fromEntries(Object.keys(d).filter(k => !["id", "CAM", "heartAt", "lugar", "cosas", "acts", "fresh"].includes(k) && typeof d[k] !== "function").map(k => [k, plain(d[k])])),
      SW: ESCENAS[id].SW, SH: ESCENAS[id].SH };
  };
  E6.fresh = (id, story) => { const keep = S; S = story; try { return plain(ESCENAS[id].fresh(story)); } finally { S = keep; } };
  E6.freshFull = (id, story) => { const keep = { S, W, E, cam }; S = story; E = ESCENAS[id]; try { fresh(); return { W: plain(W), cam: cam.slice() }; } finally { S = keep.S; W = keep.W; E = keep.E; cam = keep.cam; } };   // juego.js's own fresh(): the defaults, then the scene's

  // ---------- a state: set W, cam, F as the page had them ----------
  function enter(id, w, cm, f) { const keep = { W, cam, F, E }; W = w; cam = cm.slice(); F = f; E = ESCENAS[id]; return () => { W = keep.W; cam = keep.cam; F = keep.F; E = keep.E; }; }
  const FRENTE_HIT = [   // El frente's hit(), in its order, with the condition it tests (frente.js:185-199)
    ["abuela", w => !!w.ab], ["palma_pequena", w => !!w.escondite], ["casa_pequena", w => !!w.escondite], ["palma_grande", w => !!w.escondite], ["casa_grande", w => !!w.escondite],
    ["pajaro", w => !!(w.ave && w.ave.mode !== "none")], ["bizcocho", w => w.plato != null], ["coqui", w => !!w.cq.vis], ["nube", w => !!(w.storm && w.nube)],
    ["puerta", () => true], ["ventana", () => true], ["casa", () => true], ["sol", w => !w.storm], ["palma", () => true]];
  function frenteAve(v) {   // frente.js:78-79 avePos (inside the scene's closure), copied to read the bird's place
    if (v.mode === "head" && W.tapado) { const b = frogBox(W.cq); return [b.x + b.w / 2, b.y + Math.round(W.cq.dy) + 19]; }
    if (v.mode === "circle") return [Math.round(150 + 56 * Math.cos(F / 13)), Math.round(22 + 7 * Math.sin(F / 13 * 2))];
    if (v.mode === "head") { const b = frogBox(W.cq); return [b.x + b.w / 2, b.y + Math.round(W.cq.dy) + 2]; }
    return [Math.round(v.x), Math.round(v.y)]; }
  E6.measure = (id, wj, cm, f) => {   // every thing: shown or not (si), its box, its hand point, and what of W each reads
    const w0 = typeof wj === "string" ? JSON.parse(wj) : wj, Wp = proxyW(w0, true), out = enter(id, Wp, cm, f), Es = ESCENAS[id], res = { things: {}, extra: {} };
    try {
      if (H.escena[id]) {
        for (const t of H.escena[id].cosas) {
          const s = t.si ? collect(() => !!t.si(Wp), true) : { r: true, reads: [], nreads: [] };
          const b = typeof t.box === "function" ? collect(() => t.box(Wp), true) : { r: t.box, reads: [], nreads: [] };
          const h = collect(() => Es.handAt[t.id], true);
          res.things[t.id] = { si: s.err ? "error: " + s.err : s.r, box: b.err ? "error: " + b.err : plain(b.r), hand: h.err ? null : plain(h.r), siReads: s.nreads, boxReads: b.nreads, handReads: t.hand || typeof t.box === "function" ? h.nreads : [] };
        }
        const v = w0.ave; if (v && v.mode !== "none") { const p = KIT.avePos(v); res.extra.pajaro = { at: p, box: [p[0] - 15, p[1] - 23, 31, 28], rule: "kit.js:34 aveHit: |x-px|<16 and py-24<y<py+5" }; }
      } else {
        for (const [k, cond] of FRENTE_HIT) {
          const s = collect(() => cond(Wp), true), b = ["pajaro", "bizcocho", "coqui", "sol", "palma"].includes(k) ? { r: null, nreads: [] } : collect(() => Es.box(k, Wp), true);
          const h = collect(() => Es.handAt[k], true);
          res.things[k] = { si: s.r, box: plain(b.r) || null, hand: h.err ? null : plain(h.r), siReads: s.nreads, boxReads: b.nreads, handReads: h.nreads };
        }
        const v = w0.ave; if (v && v.mode !== "none") { const p = frenteAve(v); res.things.pajaro.box = [p[0] - 15, p[1] - 23, 31, 28]; res.things.pajaro.at = p; }
        res.things.bizcocho.box = [R2(cam[0]), R2(cam[1]), R2(66 * cam[2] / DW), R2(36 * cam[3] / DH)];   // frente.js:190: the plate in the corner of the view (view x < 66, y < 36)
        res.things.sol.box = [198, 5, 25, 25];   // frente.js:197: inside the circle (210, 17) radius 12
        res.things.palma.box = [34, 36, 30, 70];  // frente.js:198
      }
      const q = w0.cq; res.extra.coqui = q && q.vis ? (b => [b.x, b.y, b.w, b.h])(frogBox(q)) : null;
    } finally { out(); }
    return res;
  };
  E6.hitGrid = (id, wj, cm, f, step) => {   // what the scene's own hit() answers on a grid of points
    const w0 = typeof wj === "string" ? JSON.parse(wj) : wj, out = enter(id, w0, cm, f), Es = ESCENAS[id], n = {};
    try { for (let y = 0; y < Es.SH; y += step) for (let x = 0; x < Es.SW; x += step) { const k = Es.hit(x, y, w0); if (k) { const e = n[k] || (n[k] = { n: 0, at: [x, y] }); e.n++; } } } finally { out(); }
    return n;
  };

  // ---------- a frame ----------
  const views = {};
  const SEEN = new Set();
  async function pix(cv) {   // the pixels, base64, and their SHA-256; the pixels only once per page (make.mjs keeps them)
    const d = cv.getContext("2d").getImageData(0, 0, cv.width, cv.height).data;
    const h = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", d))).map(b => b.toString(16).padStart(2, "0")).join("");
    if (SEEN.has(h)) return { w: cv.width, h: cv.height, sha: h };
    SEEN.add(h); let s = ""; for (let i = 0; i < d.length; i += 8192) s += String.fromCharCode.apply(null, d.subarray(i, i + 8192));
    return { w: cv.width, h: cv.height, sha: h, b64: btoa(s) };
  }
  // variant: full (the scene's draw), nochar (the same without the characters: calls whose stack holds a character function or line of config.mjs),
  // bg (only the calls that draw a background sprite: what the background function made). views: CAM names to cut as the player sees them (with the
  // scene's hud). record: the canvas calls, folded into runs of the same item (an item: the scene frames of the stack and the sprite maker).
  const union = (a, b) => !a ? b : !b ? a : (() => { const x0 = Math.min(a[0], b[0]), y0 = Math.min(a[1], b[1]); return [x0, y0, R2(Math.max(a[0] + a[2], b[0] + b[2]) - x0), R2(Math.max(a[1] + a[3], b[1] + b[3]) - y0)]; })();
  E6.frame = async o => {
    const { id, cm, f, variant, views: viewsOf, record, pixels } = o, w0 = typeof o.w === "string" ? JSON.parse(o.w) : o.w; w0.fx = [];
    const reads = new Set(), Wp = proxyW(w0, false), out = enter(id, Wp, cm, f), Es = ESCENAS[id], a = F >> 1;
    SCENE = id; REC = record ? [] : null;
    SUP = variant === "bg" ? (e => !(e.m === "drawImage" && e.bg)) : variant === "nochar" ? (e => isChar(id, e)) : null;
    const res = { reads: null, bgKeys: [], hudReads: null, views: {} };
    try {
      X.setTransform(1, 0, 0, 1, 0, 0); X.globalAlpha = 1; X.imageSmoothingEnabled = true; X.globalCompositeOperation = "source-over"; X.setLineDash([]); clips = []; clipStack = [];
      P.clearRect.call(X, 0, 0, sc.width, sc.height);
      const bgk = new Set(), _s = window.spr;
      window.spr = function (k, fn) { const v = _s(k, fn); if (FACT[k] && FACT[k].bg) bgk.add(k); return v; };
      READS.push(reads);
      try { Es.draw(X, Wp, a); } finally { READS.splice(READS.indexOf(reads), 1); window.spr = _s; }
      res.bgKeys = [...bgk];
      res.reads = [...reads].sort();
      if (REC) {
        const runs = [], meta = {}, cl = [];
        for (const e of REC) {
          if (e.m === "clip") { cl.push({ site: e.site, chain: e.chain.filter(x => /@escenas\//.test(x)), shapes: e.shapes, box: e.box }); continue; }
          const full = e.chain.filter(x => /@escenas\//.test(x)), mk = e.maker ? (/^\(\)\s*=>\s*([\w.]+)\(/.exec(e.maker) || /^function\s+(\w+)/.exec(e.maker) || [0, e.maker.slice(0, 30)])[1] : null;
          // an item: the functions between draw() and the canvas call, and the line of draw() (or of a lambda written in it) that leads there
          const di = full.findIndex(x => /^(Object\.)?draw@/.test(x)), loc = x => x.split("@")[1].replace(/^escenas\//, "");
          let dl = di >= 0 ? loc(full[di]) : full.length ? loc(full[full.length - 1]) : null;
          if (di > 0 && /^(Object\.d|d|\?)@/.test(full[di - 1])) dl = loc(full[di - 1]);
          const names = (di >= 0 ? full.slice(0, di) : full).map(x => x.split("@")[0].replace(/^Object\./, "")).filter(n => !["d", "?", "fr", "u"].includes(n)).reverse();
          const k = (names.length ? names.join(" > ") + " " : "") + "@" + dl + (mk ? " · " + mk : "");
          if (!meta[k]) meta[k] = { site: e.site, sites: [], chain: full.slice(0, 6), names, drawLine: dl, maker: mk, bg: !!e.bg, char: isChar(id, e), clip: e.clip, m: e.m };
          if (e.site && !meta[k].sites.includes(e.site.replace(/^escenas\//, ""))) meta[k].sites.push(e.site.replace(/^escenas\//, ""));
          const last = runs[runs.length - 1];
          if (last && last.k === k) { last.box = union(last.box, e.box); last.n++; } else runs.push({ k, box: e.box, n: 1 });
        }
        res.runs = runs; res.meta = meta; res.clips = cl;
      }
      REC = null; SUP = null;
      if (pixels) res.pic = await pix(sc);
      for (const v of viewsOf || []) {
        const k = views[v.name] || (views[v.name] = document.createElement("canvas")), g = k.getContext("2d"), vc = v.rect;
        k.width = DW; k.height = DH; g.imageSmoothingEnabled = false; g.fillStyle = "#0E1A24"; g.fillRect(0, 0, DW, DH);
        g.drawImage(sc, vc[0], vc[1], vc[2], vc[3], 0, 0, DW, DH);
        if (typeof w0.retrato === "string" && /^\[canvas/.test(w0.retrato)) {   // sala.js:190 keeps a canvas in W (the photo); the recorded W holds only "[canvas 128x80]": made again as the act makes it, from this picture
          const k2 = document.createElement("canvas"); k2.width = 128; k2.height = 80; const x2 = k2.getContext("2d"); x2.imageSmoothingEnabled = false; x2.drawImage(sc, 22, 88, 198, 124, 0, 0, 128, 80); w0.retrato = k2; res.remade = "retrato"; }
        if (Es.hud && variant !== "bg") { const hr = new Set(); READS.push(hr); try { Es.hud(g, Wp, a); } finally { READS.splice(READS.indexOf(hr), 1); } res.hudReads = [...hr].sort(); }
        if (pixels) res.views[v.name] = await pix(k);
      }
    } finally { REC = null; SUP = null; SCENE = null; out(); }
    return res;
  };

  // ---------- review pairs and level-check pictures, drawn as cual.js and nivel.js draw them ----------
  E6.pairs = () => CU.items.map(it => ({ w: it.w, say: it.say, esc: it.esc, si: plain(it.si), no: plain(it.no) }));
  E6.pairW = (w, k) => { const it = CU.items.find(x => x.w === w), spec = it[k], Ex = ESCENAS[spec.esc || it.esc]; return { scene: spec.esc || it.esc, W: plain(panelW(spec, Ex)), cam: spec.cam }; };
  E6.pairPic = async (w, k, f) => {   // cual.js dibujaPaneles for one panel: the scene's draw, the answer bubbles if set, the camera rectangle stretched to 196 x 104
    const it = CU.items.find(x => x.w === w), spec = it[k], Ex = ESCENAS[spec.esc || it.esc], keep = { W, F };
    F = f; const a = F >> 1; W = panelW(spec, Ex); W.fx = [];
    const t = document.createElement("canvas"); t.width = DW; t.height = PH; const g = t.getContext("2d");
    try { Ex.draw(c, W, a); if (W.resp) respDraw(c, a); g.imageSmoothingEnabled = false; const cm = spec.cam; g.drawImage(sc, cm[0], cm[1], cm[2], cm[3], 0, 0, DW, PH); return await pix(t); }
    finally { W = keep.W; F = keep.F; }
  };
  E6.nivel = () => NV.map(q => ({ w: q.w, s: q.s, p: q.p.map(x => x.slice()) }));
  E6.nivelPic = async (i, j, f) => {   // nivel.js nivelDibuja for one cell: nivelPanel's crop, drawn into 96 x 106
    const byW = {}; CU.items.forEach(it => byW[it.w] = it);
    const pic = NV[i].p[j], P0 = nivelPanel(pic, byW), keep = { W, F }, it = byW[pic[0]], spec = it[pic[1]];
    F = f; const a = F >> 1; W = P0.w; W.fx = [];
    const t = document.createElement("canvas"); t.width = CW; t.height = CH; const g = t.getContext("2d");
    try { P0.E.draw(c, W, a); if (W.resp) respDraw(c, a); g.imageSmoothingEnabled = false; const cm = P0.cam; g.drawImage(sc, cm[0], cm[1], cm[2], cm[3], 0, 0, CW, CH);
      return { crop: cm.map(R2), scene: spec.esc || it.esc, pic: await pix(t) }; }
    finally { W = keep.W; F = keep.F; }
  };
})();
