#!/usr/bin/env node
// La fonda's shared kit (docs/proyecto/pixel/fonda-base.js, `FD`) drawn piece by piece in pure Node (V8 vm, no
// playwright), for the test that lib/src/fonda/fonda_base.dart draws the same pixels (test/fonda_kit_test.dart).
// Runs on both La fonda engine origins: entrada [0, -42] (entrada, pedido, cuenta) and comida [0, -48] (comida),
// all with w: 240, h: 216, s: 26, shadowX: .9, shadowY: -.1.
//
//   node tool/make_fonda_kit_ref.mjs            (in this package) writes test/support/fixtures/fonda_kit_refs.dart
//   node tool/make_fonda_kit_ref.mjs --check    says whether that file is what the kit draws now
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const REPO = path.resolve(import.meta.dirname, '../../../../..');
const PIX = path.join(REPO, 'docs/proyecto/pixel');
const OUT = path.join(import.meta.dirname, '../test/support/fixtures/fonda_kit_refs.dart');
const CHECK = process.argv.includes('--check');

const ENGINES = [
  { name: 'entrada', origin: [0, -42] },
  { name: 'comida', origin: [0, -48] },
];

const SCRIPTS = [
  'pp-engine.js',
  'mapa.js',
  'set-kit.js',
  'calle-base.js',
  'plaza-base.js',
  'fonda-base.js',
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
    const groundWith = fn => {
      for (let iy = 0; iy < H; iy++) for (let ix = 0; ix < W; ix++) {
        const g = unproject(ix + .5, iy + .5), i = iy * W + ix, [u, v] = PZ.uv(g.x, g.y);
        pix[i] = v >= -.02 ? fn(u, v, ix, iy) : rgb(46, 48, 76);
        ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS; kinds[i] = KIND_ROAD;
      }
      groundZ.set(zb);
    };
    const bake = () => {
      flushShadows(); pendingShadows.length = 0; bakeOcclusion(); joinSlabs();
      staticShadow.set(shadowMask); applyShadows(groundZ); shadeEdges();
    };
    const openings = (hora) => {
      groundWith(FD.tiles);
      const D = [-3.2, -1.8, 0, 2.15], W = [.6, 2.6, 1.1, 2.2];
      PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => {
        if (FD.inside(u, z, D)) return 0;
        if (FD.onFrame(u, z, D, .09)) return rgb(...FD.WOOD);
        if (FD.inside(u, z, W)) {
          const a = (u - W[0]) / (W[1] - W[0]), b = (z - W[2]) / (W[3] - W[2]);
          return FD.outside(hora, a, b, Math.round(u * 26), Math.round(z * 22.5));
        }
        if (FD.onFrame(u, z, W)) return rgb(...FD.WOOD_L);
        return FD.paint(u, z);
      });
      PZ.wall(D[0] - .2, D[1] + .2, -1.2, 0, 2.8, (u, z) =>
        FD.outside(hora, (u - D[0]) / (D[1] - D[0]), (z + .2) / 3.0, Math.round(u * 26), Math.round(z * 22.5)));
      bake();
    };
    const all = [
      ['tiles', () => groundWith(FD.tiles)],
      ['planks', () => groundWith(FD.planks)],
      ['paint.default', () => { groundWith(FD.tiles); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => FD.paint(u, z)); bake(); }],
      ['paint.custom', () => { groundWith(FD.tiles); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => FD.paint(u, z, [140, 110, 90], [230, 220, 200])); bake(); }],
      ['openings.ocaso', () => openings('ocaso')],
      ['openings.noche', () => openings('noche')],
      ['openings.tarde_noche', () => openings('tarde_noche')],
      ['sconce', () => { groundWith(FD.tiles); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => FD.paint(u, z)); FD.sconce(-2.4, 0, 2.2); FD.sconce(1.8, 0, 2.0); bake(); lightPass([.72, .74, .88], [-4, -4, 10], false); }],
      ['table.default', () => { groundWith(FD.tiles); FD.table(0, 2.5, 1.4); bake(); }],
      ['table.custom', () => { groundWith(FD.tiles); FD.table(-.5, 2.6, 1.6, .55, [236, 214, 150]); bake(); }],
      ['chair', () => { groundWith(FD.tiles); FD.chair(-1.0, 2.2); FD.chair(1.0, 2.2); bake(); }],
      ['chairEnd', () => { groundWith(FD.tiles); FD.chairEnd(-1.6, 2.5, -1); FD.chairEnd(1.6, 2.5, 1); bake(); }],
      ['setTable.default', () => { groundWith(FD.tiles); const r = FD.setTable(0, 2.6, 1.5); bake(); return r; }],
      ['setTable.one', () => { groundWith(FD.tiles); const r = FD.setTable(0, 2.6, 1.0, { seats: 1 }); bake(); return r; }],
      ['setTable.full', () => { groundWith(FD.tiles); const r = FD.setTable(0, 2.8, 1.9, { seats: 4, span: 2.85, hd: .55, ends: true, cloth: [236, 214, 150] }); bake(); return r; }],
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
      const r = fn();
      out.push({
        engine, name,
        pix: hash(pix), zb: hash(zb), kinds: hash(kinds),
        ground: hash(ground), shadow: hash(shadowMask), still: hash(staticShadow),
        result: r === undefined ? null : r,
      });
    }
    const DOOR = [-3.2, -1.8, 0, 2.15], WIN = [.6, 2.6, 1.1, 2.2];
    const dPts = [[-3.2, 0], [-1.8, 2.15], [-2.5, 1.0], [-3.25, 1.0], [-3.29, 1.0], [-3.30, 1.0], [-2.5, -.05], [-2.5, 2.20], [-2.5, 2.23], [-2.5, 2.25]];
    const wPts = [[.6, 1.1], [2.6, 2.2], [1.5, 1.6], [.55, 1.6], [.52, 1.6], [1.5, 1.05], [1.5, 1.02], [1.5, 2.25], [1.5, 2.28], [2.68, 1.6]];
    out.push({
      engine,
      name: 'numbers',
      result: {
        insideDoor: dPts.map(([u, z]) => FD.inside(u, z, DOOR)),
        insideWin: wPts.map(([u, z]) => FD.inside(u, z, WIN)),
        onFrameDoorDefault: dPts.map(([u, z]) => FD.onFrame(u, z, DOOR)),
        onFrameDoorCustom: dPts.map(([u, z]) => FD.onFrame(u, z, DOOR, .09)),
        onFrameWinDefault: wPts.map(([u, z]) => FD.onFrame(u, z, WIN)),
        onFrameWinCustom: wPts.map(([u, z]) => FD.onFrame(u, z, WIN, .09)),
      },
    });
    return out;
  })()`;

  return vm.runInContext(runner, context);
}

const rows = [];
for (const en of ENGINES) rows.push(...runEngine(en));

const json = JSON.stringify(rows, null, 1);
const made = [
  '// Made by tool/make_fonda_kit_ref.mjs from docs/proyecto/pixel/fonda-base.js. Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  "/// La fonda's kit drawn piece by piece by the JavaScript (Node V8): each case's engine, the hashes of pix, zb,",
  '/// kinds, ground, shadowMask and staticShadow (test/support/hash.dart), and the numbers the pieces give back.',
  "const String fondaKitRefs = r'''" + json + "''';",
  '',
].join('\n');

if (CHECK) {
  const same = fs.existsSync(OUT) && fs.readFileSync(OUT, 'utf8') === made;
  console.log(same ? 'fonda_kit_refs.dart: up to date' : 'fonda_kit_refs.dart: STALE (run node tool/make_fonda_kit_ref.mjs)');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(OUT, made);
console.log('wrote ' + path.relative(process.cwd(), OUT) + ': ' + rows.length + ' cases');
