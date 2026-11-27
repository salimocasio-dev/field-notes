#!/usr/bin/env node
// El fuerte's shared kit (docs/proyecto/pixel/fuerte-base.js, `FT`) drawn piece by piece in pure Node (V8 vm, no
// playwright), for the test that lib/src/fuerte/fuerte_base.dart draws the same pixels (test/fuerte_kit_test.dart).
// Runs on all three El fuerte engine origins: subida [0, -4], musica [0, -34] (musica, regalos), muralla [0, -24],
// with w: 240, h: 216, s: 26, shadowX: .9, shadowY: -.1.
//
//   node tool/make_fuerte_kit_ref.mjs            (in this package) writes test/support/fixtures/fuerte_kit_refs.dart
//   node tool/make_fuerte_kit_ref.mjs --check    says whether that file is what the kit draws now
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const REPO = path.resolve(import.meta.dirname, '../../../../..');
const PIX = path.join(REPO, 'docs/proyecto/pixel');
const OUT = path.join(import.meta.dirname, '../test/support/fixtures/fuerte_kit_refs.dart');
const CHECK = process.argv.includes('--check');

const ENGINES = [
  { name: 'subida', origin: [0, -4] },
  { name: 'musica', origin: [0, -34] },
  { name: 'muralla', origin: [0, -24] },
];

const SCRIPTS = [
  'pp-engine.js',
  'mapa.js',
  'set-kit.js',
  'calle-base.js',
  'plaza-base.js',
  'fonda-base.js',
  'fuerte-base.js',
];

function runEngine(en) {
  const ctxObj = {
    Math,
    Number,
    String,
    Array,
    Object,
    WeakMap,
    Map,
    Set,
    Uint8Array,
    Uint8ClampedArray,
    Uint32Array,
    Int32Array,
    Float32Array,
    Float64Array,
    console,
    matchMedia: () => ({ matches: false }),
    requestAnimationFrame: () => 0,
    document: {
      getElementById: () => ({
        width: 0,
        height: 0,
        getContext: () => ({
          createImageData: (w, h) => ({ data: new Uint8ClampedArray(w * h * 4) }),
          putImageData: () => {},
        }),
      }),
    },
  };
  ctxObj.window = ctxObj;
  ctxObj.globalThis = ctxObj;
  ctxObj.PP_SCENE = {
    w: 240,
    h: 216,
    s: 26,
    originX: en.origin[0],
    originY: en.origin[1],
    shadowX: .9,
    shadowY: -.1,
  };

  const context = vm.createContext(ctxObj);
  for (const f of SCRIPTS) {
    const code = fs.readFileSync(path.join(PIX, f), 'utf8');
    vm.runInContext(code, context, { filename: f });
  }

  const runner = `(() => {
    const engine = ${JSON.stringify(en.name)};
    const reset = () => {
      zb.fill(-1e9); pix.fill(0); kinds.fill(0); ground.fill(0);
      shadowMask.fill(0); staticShadow.fill(0); groundZ.fill(-1e9);
      tufts.length = 0; leaves.length = 0; pendingShadows.length = 0;
      slabTops.length = 0; glowReset(); PZ.NIGHT = false; CL.NIGHT = false;
    };
    const groundFlags = (fn = FT.flags) => {
      for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
        const g = unproject(ix + .5, iy + .5), i = iy * W + ix, [u, v] = PZ.uv(g.x, g.y);
        if (v < -.62) continue;
        pix[i] = fn(u, v, ix, iy);
        ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS; kinds[i] = KIND_ROAD;
      }
      groundZ.set(zb);
    };
    const groundGrassPath = () => {
      for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
        const g = unproject(ix + .5, iy + .5), i = iy * W + ix, [u, v] = PZ.uv(g.x, g.y);
        const on = FT.onPath(u, v, .15, .62);
        pix[i] = on ? FT.pathStone(u, v, ix, iy) : FT.grass(u, v, ix, iy);
        ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS; kinds[i] = on ? KIND_ROAD : KIND_GRASS;
      }
      groundZ.set(zb);
    };
    const bake = () => {
      flushShadows(); pendingShadows.length = 0; bakeOcclusion(); joinSlabs();
      staticShadow.set(shadowMask); applyShadows(groundZ); shadeEdges();
    };
    const all = [
      ['flags.default', () => groundFlags((u, v, ix, iy) => FT.flags(u, v, ix, iy))],
      ['flags.custom', () => groundFlags((u, v, ix, iy) => FT.flags(u, v, ix, iy, [255, 232, 160]))],
      ['grass.path', () => groundGrassPath()],
      ['stone.custom', () => { groundFlags(); PZ.wall(-4.5, 4.5, 0, 0, 2.2, (u, z) => FT.stone(u, z, [255, 226, 160])); bake(); }],
      ['yardWall.plain', () => { groundFlags(); FT.yardWall(); bake(); }],
      ['yardWall.arch', () => { groundFlags(); FT.yardWall(2.6, [[-1.1, 1.1, 0, 1.9]]); bake(); }],
      ['night.std', () => skyFill((ix, iy) => FT.night(ix, iy, 90))],
      ['night.low', () => skyFill((ix, iy) => FT.night(ix, iy, 90, [70, 81, 9], true))],
      ['day.tarde', () => skyFill((ix, iy) => FT.day('tarde', ix, iy, 90))],
      ['day.ocaso', () => skyFill((ix, iy) => FT.day('ocaso', ix, iy, 90))],
      ['wallLamp.lit', () => { groundFlags(); FT.yardWall(); FT.wallLamp(-2.0, 0, 1.4, true); FT.wallLamp(2.0, 0, 1.4, true); bake(); lightPass([.72, .74, .88], [-4, -4, 10], false); }],
      ['wallLamp.unlit', () => { groundFlags(); FT.yardWall(); FT.wallLamp(-2.0, 0, 1.4, false); bake(); lightPass([.72, .74, .88], [-4, -4, 10], false); }],
      ['garita.plain', () => { groundFlags(); FT.garita(-1.5, 1.5); bake(); }],
      ['garita.door.lit', () => { groundFlags(); FT.garita(1.2, 1.6, [196, 84, 70], true); bake(); }],
      ['garita.door.unlit', () => { groundFlags(); FT.garita(0, 1.6, [70, 132, 122], false, .7, 1.9); bake(); }],
      ['cap', () => { groundFlags(); FT.cap(0, 1.5, .8, .55); bake(); }],
      ['table.default', () => { groundFlags(); FT.table(0, 2.2, 1.4); bake(); }],
      ['table.custom', () => { groundFlags(); FT.table(0, 2.2, 1.6, .6, [96, 150, 206]); bake(); }],
      ['cord', () => { groundFlags(); FT.yardWall(); FT.cord(-3.0, 3.0, .05, 1.8); FT.cord(-2.5, 2.5, .1, 1.5, 1.2, .18, [190, 90, 60]); bake(); }],
      ['stool.ground', () => { groundFlags(); FT.stool(-1.0, 2.0); FT.stool(1.0, 2.0, .52, .3, [190, 140, 92], 0); bake(); }],
      ['stool.elevated', () => { groundFlags(); FT.stool(0, 2.0, .46, .22, [176, 122, 76], .4); bake(); }],
      ['lights', () => { groundFlags(); FT.yardWall(); FT.lights(-3.5, 3.5, .03, 1.85, .16); bake(); lightPass([.72, .74, .88], [-4, -4, 10], false); }],
    ];
    const hash = a => {
      const u = new Uint8Array(a.buffer, a.byteOffset, a.byteLength);
      let x = 0x811C9DC5, y = 0x01234567;
      for (let i = 0; i < u.length; i++) {
        x = Math.imul(x ^ u[i], 0x01000193) >>> 0;
        y = Math.imul(y ^ u[i], 0x5BD1E995) >>> 0;
      }
      return x.toString(16).padStart(8, '0') + y.toString(16).padStart(8, '0');
    };
    const out = [];
    for (const [name, fn] of all) {
      reset();
      fn();
      out.push({
        engine, name,
        pix: hash(pix), zb: hash(zb), kinds: hash(kinds),
        ground: hash(ground), shadow: hash(shadowMask), still: hash(staticShadow),
      });
    }
    return out;
  })()`;

  return vm.runInContext(runner, context);
}

const rows = [];
for (const en of ENGINES) rows.push(...runEngine(en));

const json = JSON.stringify(rows, null, 1);
const made = [
  '// Made by tool/make_fuerte_kit_ref.mjs from docs/proyecto/pixel/fuerte-base.js. Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  "/// El fuerte's kit drawn piece by piece by the JavaScript (Node V8): each case's engine and the hashes of pix, zb,",
  '/// kinds, ground, shadowMask and staticShadow (test/support/hash.dart).',
  "const String fuerteKitRefs = r'''" + json + "''';",
  '',
].join('\n');

if (CHECK) {
  const same = fs.existsSync(OUT) && fs.readFileSync(OUT, 'utf8') === made;
  console.log(same ? 'fuerte_kit_refs.dart: up to date' : 'fuerte_kit_refs.dart: STALE (run node tool/make_fuerte_kit_ref.mjs)');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(OUT, made);
console.log('wrote ' + path.relative(process.cwd(), OUT) + ': ' + rows.length + ' cases');
