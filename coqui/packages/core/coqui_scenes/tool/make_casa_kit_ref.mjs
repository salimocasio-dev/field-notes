#!/usr/bin/env node
// La casa's shared kit (docs/proyecto/pixel/casa-base.js, `CS`) drawn piece by piece in pure Node (V8 vm, no
// playwright), for the test that lib/src/casa/casa_base.dart draws the same pixels (test/casa_kit_test.dart).
// Runs on La casa's engine origin: casa [0, -42] (cuarto, bano, sala_dia, noche all use [0, -42]),
// with w: 240, h: 216, s: 26, shadowX: .9, shadowY: -.1.
//
//   node tool/make_casa_kit_ref.mjs            (in this package) writes test/support/fixtures/casa_kit_refs.dart
//   node tool/make_casa_kit_ref.mjs --check    says whether that file is what the kit draws now
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const REPO = path.resolve(import.meta.dirname, '../../../../..');
const PIX = path.join(REPO, 'docs/proyecto/pixel');
const OUT = path.join(import.meta.dirname, '../test/support/fixtures/casa_kit_refs.dart');
const CHECK = process.argv.includes('--check');

const ENGINES = [
  { name: 'casa', origin: [0, -42] },
];

const SCRIPTS = [
  'pp-engine.js',
  'mapa.js',
  'set-kit.js',
  'calle-base.js',
  'plaza-base.js',
  'fonda-base.js',
  'casa-base.js',
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
        pix[i] = v >= -.02 ? fn(u, v, ix, iy) : rgb(84, 70, 70);
        ground[i] = 1; zb[i] = (g.x + g.y) / R2 * COS; kinds[i] = KIND_ROAD;
      }
      groundZ.set(zb);
    };
    const bake = () => {
      flushShadows(); pendingShadows.length = 0; bakeOcclusion(); joinSlabs();
      staticShadow.set(shadowMask); applyShadows(groundZ); shadeEdges();
    };
    const win = (hora) => {
      groundWith(CS.boards);
      PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.windowAt(u, z, [-2.0, 0.2, 1.0, 2.2], hora) || CS.paint(u, z));
      bake();
    };
    const all = [
      ['boards.default', () => groundWith((u, v, ix, iy) => CS.boards(u, v, ix, iy))],
      ['boards.custom', () => groundWith((u, v, ix, iy) => CS.boards(u, v, ix, iy, [210, 170, 120]))],
      ['paint.default', () => { groundWith(CS.boards); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.paint(u, z)); bake(); }],
      ['paint.custom', () => { groundWith(CS.boards); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.paint(u, z, [226, 214, 236])); bake(); }],
      ['tiles.default', () => { groundWith(CS.boards); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.tiles(u, z)); bake(); }],
      ['tiles.custom', () => { groundWith(CS.boards); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.tiles(u, z, [70, 150, 170])); bake(); }],
      ['window.alba', () => win('alba')],
      ['window.manana', () => win('manana')],
      ['window.tarde', () => win('tarde')],
      ['window.noche', () => win('noche')],
      ['clock', () => { groundWith(CS.boards); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.clockAt(u, z, 1.6, 1.85) || CS.paint(u, z)); bake(); }],
      ['door.open', () => { groundWith(CS.boards); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.doorAt(u, z, [-3.6, -2.2, 0, 2.15], true) || CS.paint(u, z)); bake(); }],
      ['door.shut.default', () => { groundWith(CS.boards); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.doorAt(u, z, [-3.6, -2.2, 0, 2.15], false) || CS.paint(u, z)); bake(); }],
      ['door.shut.custom', () => { groundWith(CS.boards); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.doorAt(u, z, [-3.6, -2.2, 0, 2.15], false, [140, 100, 70]) || CS.paint(u, z)); bake(); }],
      ['bed.default', () => { groundWith(CS.boards); CS.bed(-1.5, .15, 2.35, .8); bake(); }],
      ['bed.custom', () => { groundWith(CS.boards); CS.bed(1.4, .15, 2.35, .75, [236, 190, 110]); bake(); }],
      ['armchair.default', () => { groundWith(CS.boards); CS.armchair(-1.5, 2.2); bake(); }],
      ['armchair.custom', () => { groundWith(CS.boards); CS.armchair(1.5, 2.2, [110, 140, 96]); bake(); }],
      ['sofa.default', () => { groundWith(CS.boards); CS.sofa(0, 2.2, 1.45); bake(); }],
      ['sofa.custom', () => { groundWith(CS.boards); CS.sofa(0, 2.2, 1.45, [96, 140, 150]); bake(); }],
      ['rug.default', () => { groundWith(CS.boards); CS.rug(-2.4, 1.4, 2.4, 3.6); bake(); }],
      ['rug.custom', () => { groundWith(CS.boards); CS.rug(-2.4, 1.4, 2.4, 3.6, [86, 150, 150], [240, 230, 200]); bake(); }],
      ['lamps.lit', () => { groundWith(CS.boards); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.paint(u, z)); CS.lampStanding(-2.6, 1.8, true); CS.lampSmall(0, .2, 1.2, true); CS.lampWall(2.4, 1.9, true); bake(); lightPass([.72, .74, .88], [-4, -4, 10], false); }],
      ['lamps.unlit', () => { groundWith(CS.boards); PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.paint(u, z)); CS.lampStanding(-2.6, 1.8, false); CS.lampSmall(0, .2, 1.2, false); CS.lampWall(2.4, 1.9, false); CS.glowBox(.8, 2.0, .6, 1.0, .22, false, [230, 210, 160]); bake(); lightPass([.72, .74, .88], [-4, -4, 10], false); }],
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
  '// Made by tool/make_casa_kit_ref.mjs from docs/proyecto/pixel/casa-base.js. Do not edit.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  "/// La casa's kit drawn piece by piece by the JavaScript (Node V8): each case's engine and the hashes of pix, zb,",
  '/// kinds, ground, shadowMask and staticShadow (test/support/hash.dart).',
  "const String casaKitRefs = r'''" + json + "''';",
  '',
].join('\n');

if (CHECK) {
  const same = fs.existsSync(OUT) && fs.readFileSync(OUT, 'utf8') === made;
  console.log(same ? 'casa_kit_refs.dart: up to date' : 'casa_kit_refs.dart: STALE (run node tool/make_casa_kit_ref.mjs)');
  process.exit(same ? 0 : 1);
}
fs.writeFileSync(OUT, made);
console.log('wrote ' + path.relative(process.cwd(), OUT) + ': ' + rows.length + ' cases');
