// La plaza's kit in Dart (lib/src/plaza/plaza_base.dart, with the three pieces of calle-base.js it uses) against the
// JavaScript (docs/proyecto/pixel/plaza-base.js and calle-base.js): each piece drawn on its own from empty buffers, on
// engines with the origins of the sets that load the kit (La plaza's four, and La playa's and La fonda's first), in the
// order tool/make_plaza_kit_ref.mjs ran them in headless Chrome. Each case's pix, zb, kinds, ground, shadowMask and
// staticShadow are the JavaScript's (equal hashes: 0 elements differ), and the numbers the pieces give back are the same.
//
// With PLAZA_KIT_DUMP=DIR (the tool's --dump DIR) a case that differs says which pixels (the vm only).
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/plaza_kit_refs.dart';
import 'support/hash.dart';
import 'support/plaza_dump.dart';

const Map<String, List<double>> _origins = {
  'plaza': [0, 10],
  'reloj': [0, 44],
  'quiosco': [0, 14],
  'calendario': [0, 12],
  'orilla': [0, -30],
  'entrada': [0, -42],
};

Object? _plain(Object? v) => switch (v) {
  final List l => [for (final x in l) _plain(x)],
  final Map m => {for (final e in m.entries) '${e.key}': _plain(e.value)},
  final double d when d == d.truncateToDouble() && d.abs() < 1e15 => d.toInt(),
  _ => v,
};

String? _where(String engine, String name, Uint32List pix, Float32List zb) {
  final p = plazaDump('$engine.$name.pix.bin'),
      z = plazaDump('$engine.$name.zb.bin');
  if (p == null || z == null) return null;
  final ref = Uint32List.view(p.buffer), refZ = Float32List.view(z.buffer);
  final out = <String>[];
  var n = 0;
  for (var i = 0; i < pix.length; i++) {
    if (pix[i] != ref[i] || zb[i] != refZ[i]) {
      n++;
      if (out.length < 12) {
        out.add(
          '(${i % 240},${i ~/ 240}) dart ${pix[i].toRadixString(16)}/${zb[i]} js ${ref[i].toRadixString(16)}/${refZ[i]}',
        );
      }
    }
  }
  return '$n differ: ${out.join('; ')}';
}

void main() {
  final refs = (jsonDecode(plazaKitRefs) as List).cast<Map<String, dynamic>>();

  test('every engine of the tool is here, each with the same cases', () {
    expect(refs.map((r) => r['engine']).toSet(), _origins.keys.toSet());
  });

  for (final en in _origins.entries) {
    final e = PpEngine(
      w: 240,
      h: 216,
      s: 26,
      originX: en.value[0],
      originY: en.value[1],
      shadowX: .9,
      shadowY: -.1,
    );
    final k = SetKit(e, PpBuild(e)), PZ = PlazaBase(k), CL = PZ.CL;

    void reset() {
      e.zb.fillRange(0, e.zb.length, -1e9);
      e.pix.fillRange(0, e.pix.length, 0);
      e.kinds.fillRange(0, e.kinds.length, 0);
      e.ground.fillRange(0, e.ground.length, 0);
      e.shadowMask.fillRange(0, e.shadowMask.length, 0);
      e.staticShadow.fillRange(0, e.staticShadow.length, 0);
      e.groundZ.fillRange(0, e.groundZ.length, -1e9);
      e.tufts.clear();
      e.leaves.clear();
      e.pendingShadows.clear();
      k.slabTops.clear();
      k.glowReset();
      PZ.NIGHT = false;
      CL.NIGHT = false;
    }

    // a ground pass: every pixel takes fn(u, v, ix, iy) of its ground point (as plaza-set.html's groundAt)
    void ground1(int Function(num u, num v, int ix, int iy) fn) {
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              i = iy * e.W + ix,
              p = PZ.uv(g.x, g.y),
              c = fn(p[0], p[1], ix, iy);
          if (c == 0) continue;
          e.pix[i] = c;
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
          e.kinds[i] = p[1] < -3.4 ? e.KIND_GRASS : KIND_ROAD;
        }
      }
      e.groundZ.setAll(0, e.zb);
    }

    void bake() {
      e.flushShadows();
      e.pendingShadows.clear();
      e.bakeOcclusion();
      k.joinSlabs();
      e.staticShadow.setAll(0, e.shadowMask);
      e.applyShadows(e.groundZ);
      e.shadeEdges();
    }

    int pattern(num u, num z) {
      final n = (u * 7).floor() + (z * 5).floor();
      final m = n.remainder(3); // JavaScript: %
      return m == 0
          ? 0
          : m == 1
          ? e.rgb(200, 40, 40)
          : e.rgb(40, 40, 200);
    }

    final cases = <String, dynamic Function()>{
      'paving': () => ground1(PZ.paving),
      'grass': () => ground1(PZ.grass),
      'box': () => PZ.box(.5, .2, 0, .8, 1.1, .4, PlazaBase.STONE),
      'box.fn': () => PZ.box(
        -1.3,
        1.1,
        .2,
        1.4,
        .6,
        .3,
        PlazaBase.TILE,
        (s, t, z, face) => face == 'top'
            ? e.rgb(10, 200, 10)
            : face == 'front' && z > .8
            ? e.rgb(200, 200, 10)
            : 0,
      ),
      'wall': () => PZ.wall(-2, 1.5, -.6, .2, 2.4, pattern),
      'flat': () => PZ.flat(
        -1.5,
        -1,
        2,
        1.5,
        .5,
        (u, v) => ((u * 4).floor() + (v * 4).floor()) % 2 != 0
            ? e.rgb(230, 120, 30)
            : 0,
      ),
      'slope': () => PZ.slope(
        -2,
        2,
        .8,
        1.6,
        -.6,
        2.4,
        (u, bb) => PZ.b.shade(PlazaBase.TILE, bb > .5 ? 3.0 : 2.4, u, bb),
      ),
      'post': () {
        PZ.post(.3, .5, 0, 2.2, .06, PlazaBase.IRON);
        PZ.post(-2.2, 1.4, .5, 1.8, .12, PlazaBase.WOOD_D);
      },
      'ball': () {
        PZ.ball(-.5, .4, .6, .4, PlazaBase.OCHRE);
        PZ.ball(1.4, .6, .3, .2, PlazaBase.CREAM, 'smooth');
        PZ.ball(2.2, -.2, 1.2, .25, PlazaBase.WHITE, 'gloss');
      },
      'shadow': () {
        ground1(PZ.paving);
        PZ.shadow(.4, .8, .5, .5);
        PZ.shadow(-2, -.4, 1.6, .3);
        bake();
      },
      'tree': () {
        ground1(PZ.paving);
        PZ.tree(.6, -2.3, 1.9, 1.45);
        bake();
      },
      'tree.colours': () =>
          PZ.tree(-2.4, .2, 1.2, .8, PlazaCl.LEAF, PlazaCl.LEAF_L),
      'tree.other': () => PZ.tree(
        2.5,
        .4,
        1.6,
        1.0,
        const [180, 90, 140],
        const [230, 150, 190],
      ),
      'seat': () {
        ground1(PZ.paving);
        PZ.seat(.6, 0, 2.0);
        bake();
      },
      'seat.short.noback': () =>
          PZ.seat(-1.5, 1.2, 1.0, false, const [120, 140, 200]),
      'seat.long': () => PZ.seat(.2, -1, 3.1, true),
      'seatSide': () => PZ.seatSide(1.2, -1, 1.4),
      'seatSide.colour': () => PZ.seatSide(-2, .2, 1.1, const [120, 80, 60]),
      'bed': () => PZ.bed(-1.2, -2.95, -.1, -2.3),
      'bed.cols': () => PZ.bed(2.4, -2.95, 4.6, -2.3, const [
        [250, 250, 250],
        [236, 120, 170],
        [250, 206, 70],
      ]),
      'hedge': () => PZ.hedge(-5, -4.75, 5, -4.75),
      'hedge.short': () => PZ.hedge(-1, 1, -.9, 1.1),
      'lamp': () {
        ground1(PZ.paving);
        PZ.lamp(-3.95, -2.6);
        bake();
      },
      'lamp.night': () {
        ground1(PZ.paving);
        PZ.NIGHT = CL.NIGHT = true;
        PZ.lamp(-.5, .4);
        PZ.lamp(2, 1, 2.4);
        bake();
        PZ.light('noche');
      },
      'flags': () => PZ.flags(-3, 2.6, 3, 2.2, .2),
      'flags.cols': () => PZ.flags(-1.1, 1.8, 3.6, 2.2, .14, .25, const [
        [10, 200, 10],
        [200, 10, 200],
      ]),
      'sky.manana.tower': () =>
          k.skyFill(PZ.sky('manana', [PZ.farTower(206, 55)])),
      'sky.mediodia.tower': () =>
          k.skyFill(PZ.sky('mediodia', [PZ.farTower(120, 80, 50)])),
      'sky.tarde': () => k.skyFill(PZ.sky('tarde', [PZ.farTower(40, 60, 30)])),
      'sky.ocaso': () => k.skyFill(PZ.sky('ocaso')),
      'sky.noche': () => k.skyFill(PZ.sky('noche')),
      'sky.otra': () =>
          k.skyFill(PZ.sky('lluvia', [null, PZ.farTower(100, 50)])),
      'light.tarde': () {
        ground1(PZ.paving);
        PZ.seat(.6, 0, 2.0);
        bake();
        PZ.light('tarde');
        k.skyFill(PZ.sky('tarde'));
      },
      'light.ocaso': () {
        ground1(PZ.grass);
        PZ.tree(0, -1, 1.5, 1);
        bake();
        PZ.light('ocaso');
      },
      'light.manana': () {
        ground1(PZ.paving);
        PZ.box(0, 0, 0, 1, 1, 1, PlazaBase.STONE);
        PZ.light('manana');
        PZ.light('mediodia');
      },
      'lit.dim.up': () {
        for (var i = 0; i < 40; i++) {
          final u = -4 + i * .2;
          PZ.wall(
            u,
            u + .2,
            0,
            0,
            1,
            (a, z) => z < .33
                ? PZ.lit(PlazaBase.STONE, a, z)
                : z < .66
                ? PZ.dim(PlazaBase.WOOD, a, z)
                : PZ.up(PlazaBase.TILE, a, z),
          );
        }
      },
    };

    final mine = refs.where((r) => r['engine'] == en.key).toList();
    test('${en.key}: the tool ran the same cases', () {
      expect(mine.map((r) => r['name']).toList(), [...cases.keys, 'numbers']);
    });
    for (final r in mine) {
      if (r['name'] == 'numbers') continue;
      test('${en.key}: ${r['name']} draws the JavaScript\'s pixels', () {
        reset();
        final got = cases[r['name']]!();
        final hashes = {
          'pix': hashOf(e.pix),
          'zb': hashOf(e.zb),
          'kinds': hashOf(e.kinds),
          'ground': hashOf(e.ground),
          'shadow': hashOf(e.shadowMask),
          'still': hashOf(e.staticShadow),
        };
        final where = _where(en.key, r['name'] as String, e.pix, e.zb);
        for (final key in hashes.keys) {
          expect(
            hashes[key],
            r[key],
            reason: '$key differs${where == null ? '' : ': $where'}',
          );
        }
        expect(_plain(got), r['result']);
      });
    }
    test('${en.key}: the numbers the kit gives back are the JavaScript\'s', () {
      final n = mine.firstWhere((r) => r['name'] == 'numbers')['result'];
      const pts = [
        [0, 0],
        [1, 0],
        [0, 1],
        [-2.5, 3.7],
        [3.05, 3.5],
        [-3.72, -1.3],
      ];
      final tower = PZ.farTower(206, 55);
      expect(
        _plain({
          'A': PlazaBase.A,
          'xy': [for (final p in pts) PZ.xy(p[0], p[1])],
          'uv': [for (final p in pts) PZ.uv(p[0], p[1])],
          'P': [for (final p in pts) PZ.P(p[0], p[1], .5)],
          'lit': [
            PZ.lit(PlazaBase.STONE),
            PZ.lit(PlazaBase.WOOD, 1.3, .2),
            PZ.dim(PlazaBase.IRON, .4, .9),
            PZ.up(PlazaBase.TILE, 2, 3),
          ],
          'paving': [
            for (var i = 0; i < pts.length; i++)
              PZ.paving(pts[i][0] + .3, pts[i][1] + .2, i * 17, i * 31),
          ],
          'grass': [
            for (var i = 0; i < pts.length; i++)
              PZ.grass(pts[i][0], pts[i][1], i * 5, i * 9),
          ],
          'tower': [
            for (final p in const [
              [200, 20],
              [206, 33],
              [206, 40],
              [203, 40],
              [212, 15],
              [206, 52],
              [190, 30],
            ])
              tower(p[0], p[1]),
          ],
        }),
        _plain(n),
      );
    });
  }
}
