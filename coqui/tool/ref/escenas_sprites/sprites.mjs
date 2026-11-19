// ref/sprites/escenas: the sprites each scene file makes for itself, gathered from the story runs of ../trazas/juega.mjs
// (that command writes them; see README.md in this folder). Used by juega.mjs; not run on its own.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

const sha = b => crypto.createHash("sha256").update(b).digest("hex");
// Known working canvases: kept in the sprite cache but drawn into again every frame, so their pixels are whatever the last frame left.
const SCRATCH = { sala: { bor: "sala.js line 120: a 20x18 canvas the scene draws the whole picture into, smoothed, every frame W.borroso is set (the blur). Not a fixed sprite: its pixels are the last such frame of the run, so they differ between runs. Do not compare it." } };

// SPR[j] = { scene, run, cache: [...], outside: [...] } for job j (null when the run failed). Merged in job order.
export function mergeSprites(SPR) {
  const sprites = {};
  for (const R of SPR) {
    if (!R) continue;
    const own = `escenas/${R.scene}.js`, B = sprites[R.scene] || (sprites[R.scene] = { keys: {}, others: {}, outside: {} });
    for (const x of R.cache) {
      if (x.callerFile !== own) { if (!B.others[x.key]) B.others[x.key] = { caller: x.caller || x.type || null }; continue; }
      const b = B.keys[x.key] || (B.keys[x.key] = { meta: x, runs: [], variants: {} });
      b.runs.push(R.run);
      if (!b.variants[x.sha256]) b.variants[x.sha256] = { w: x.w, h: x.h, first: R.run };
    }
    for (const x of R.outside) { const k = `${x.made}|${x.sha256}`, o = B.outside[k] || (B.outside[k] = { meta: x, runs: [] }); o.runs.push(R.run); }
  }
  return sprites;
}

// Every place in a scene file that asks engine.js's cache for a sprite: spr(<key>, <maker>). Line and column as V8 reports a call (1-based, at "spr").
export function sprSites(src) {
  const sites = [], re = /(^|[^A-Za-z0-9_$.])spr\(/g;
  let m;
  while ((m = re.exec(src))) {
    const at = m.index + m[1].length, before = src.slice(0, at), line = before.split("\n").length, col = at - before.lastIndexOf("\n");
    let i = at + 4, depth = 0, q = null, arg = "";
    for (; i < src.length; i++) {   // the first argument, up to its top-level comma
      const c = src[i];
      if (q) { if (c === "\\") { arg += c + src[++i]; continue; } if (c === q) q = null; arg += c; continue; }
      if (c === '"' || c === "'" || c === "`") { q = c; arg += c; continue; }
      if (c === "(" || c === "[" || c === "{") depth++;
      if (c === ")" || c === "]" || c === "}") { if (depth === 0) break; depth--; }
      if (c === "," && depth === 0) break;
      arg += c;
    }
    sites.push({ line, col, key: arg.trim() });
  }
  return sites;
}

export function writeSprites(sprites, PIX, OUT, HIST) {
  fs.mkdirSync(OUT, { recursive: true });
  const top = { made: "node coqui/tool/ref/trazas/juega.mjs (the sprites are read after each story run)", format: "see coqui/tool/ref/escenas_sprites/README.md", scenes: [] };
  const safe = k => k.replace(/[^A-Za-z0-9_.-]/g, c => "~" + c.charCodeAt(0).toString(16).padStart(2, "0"));
  for (const scene of Object.keys(sprites).sort()) {
    const B = sprites[scene], dir = path.join(OUT, scene), src = fs.readFileSync(path.join(HIST, "escenas", scene + ".js"), "utf8");
    fs.mkdirSync(dir, { recursive: true });
    const list = [];
    for (const key of Object.keys(B.keys).sort()) {
      const b = B.keys[key], vs = Object.keys(b.variants);
      vs.forEach((h, i) => {
        const v = b.variants[h], f = `${safe(key)}${vs.length > 1 ? "." + i : ""}.rgba`, px = PIX.get(h);
        if (!px || px.length !== v.w * v.h * 4 || sha(px) !== h) throw new Error(`sprite ${scene}/${key}: pixels missing or not what the page hashed`);
        fs.writeFileSync(path.join(dir, f), px);
        const e = { key, file: f, w: v.w, h: v.h, sha256: h, caller: b.meta.caller, maker: b.meta.maker, firstRun: v.first, runs: b.runs.length, variants: vs.length };
        if (SCRATCH[scene] && SCRATCH[scene][key]) e.scratch = SCRATCH[scene][key];
        list.push(e);
      });
    }
    const outside = [];
    let n = 0;
    for (const k of Object.keys(B.outside).sort()) {
      const o = B.outside[k], f = `outside-${n++}.rgba`;
      fs.writeFileSync(path.join(dir, f), PIX.get(o.meta.sha256));
      outside.push({ made: o.meta.made, file: f, w: o.meta.w, h: o.meta.h, sha256: o.meta.sha256, atLoad: o.meta.atLoad, firstRun: o.runs[0], runs: o.runs.length });
    }
    const others = Object.keys(B.others).sort().map(k => ({ key: k, caller: B.others[k].caller }));
    // completeness: every spr( call site in the scene file, and the keys the runs first made there
    const sites = sprSites(src).map(s => {
      const at = `escenas/${scene}.js:${s.line}:${s.col}`;
      const keys = list.filter(x => x.caller && x.caller.startsWith(at + " ") || x.caller === at).map(x => x.key).filter((k, i, a) => a.indexOf(k) === i);
      return { line: s.line, col: s.col, key: s.key, made: keys };
    });
    for (const e of sites) if (!e.made.length) {   // nothing first made here: is it the same key (or key expression) as a call site where something was made?
      const lit = /^"([^"\\]*)"$/.exec(e.key);
      e.madeElsewhere = lit ? list.some(x => x.key === lit[1]) || others.some(x => x.key === lit[1]) : sites.some(o => o !== e && o.key === e.key && o.made.length > 0);
    }
    const idx = { scene, file: `historia/escenas/${scene}.js`, fileSha256: sha(src), sprites: list, outsideCache: outside, notDumped: others, sites };
    fs.writeFileSync(path.join(dir, "index.json"), JSON.stringify(idx, null, 1) + "\n");
    top.scenes.push({
      scene, files: list.length, keys: Object.keys(B.keys).length,
      differsBetweenRuns: list.filter(x => x.variants > 1).map(x => x.key).filter((k, i, a) => a.indexOf(k) === i),
      outsideCache: outside.length, notDumped: others.length,
      sites: sites.length, sitesNeverReached: sites.filter(s => !s.made.length && !s.madeElsewhere).map(s => `${s.line}:${s.col} spr(${s.key})`),
      bytes: list.reduce((a, x) => a + x.w * x.h * 4, 0) + outside.reduce((a, x) => a + x.w * x.h * 4, 0),
    });
  }
  fs.writeFileSync(path.join(OUT, "index.json"), JSON.stringify(top, null, 1) + "\n");
}
