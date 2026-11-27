// La fonda's shared kit in Dart (lib/src/fonda/fonda_base.dart) against the JavaScript (docs/proyecto/pixel/fonda-base.js):
// every piece drawn on its own from empty buffers across both La fonda set origins (entrada [0, -42] and comida [0, -48]):
// tiles, planks, paint (default & custom), openings (ocaso, noche, tarde_noche), sconce (with lightPass),
// table (default & custom), chair, chairEnd, setTable (default, one, full), plus palette constants and inside/onFrame.
// Every case's pix, zb, kinds, ground, shadowMask and staticShadow must equal the JavaScript (0 elements differ).
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/fonda_kit_refs.dart';
import 'support/hash.dart';

const Map<String, List<double>> _origins = {
  'entrada': [0, -42],
  'comida': [0, -48],
};

Object? _plain(Object? v) => switch (v) {
  final List l => [for (final x in l) _plain(x)],
  final Map m => {for (final e in m.entries) '${e.key}': _plain(e.value)},
  final double d when d == d.truncateToDouble() && d.abs() < 1e15 => d.toInt(),
  _ => v,
};

void main() {
  final refs = (jsonDecode(fondaKitRefs) as List).cast<Map<String, dynamic>>();

  test('palette constants match fonda-base.js', () {
    expect(FondaBase.CREAM, const [246, 232, 204]);
    expect(FondaBase.GREEN, const [70, 132, 122]);
    expect(FondaBase.GREEN_D, const [50, 104, 98]);
    expect(FondaBase.WOOD, const [156, 106, 64]);
    expect(FondaBase.WOOD_D, const [108, 72, 46]);
    expect(FondaBase.WOOD_L, const [198, 150, 98]);
    expect(FondaBase.CLOTH, const [250, 246, 236]);
    expect(FondaBase.BRASS, const [222, 178, 82]);
    expect(FondaBase.RED, const [196, 60, 54]);
  });

  test('every La fonda engine origin is here', () {
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
    final k = SetKit(e, PpBuild(e));
    final PZ = PlazaBase(k);
    final FD = FondaBase(PZ);

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
      PZ.CL.NIGHT = false;
    }

    void groundWith(int Function(num u, num v, int ix, int iy) fn) {
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final g = e.unproject(ix + .5, iy + .5);
          final i = iy * e.W + ix;
          final uv = PZ.uv(g.x, g.y);
          e.pix[i] = uv[1] >= -.02
              ? fn(uv[0], uv[1], ix, iy)
              : e.rgb(46, 48, 76);
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
          e.kinds[i] = KIND_ROAD;
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

    void openings(String hora) {
      groundWith(FD.tiles);
      const D = [-3.2, -1.8, 0.0, 2.15];
      const W = [.6, 2.6, 1.1, 2.2];
      PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) {
        if (FD.inside(u, z, D)) return 0;
        if (FD.onFrame(u, z, D, .09)) {
          return e.rgb(FondaBase.WOOD[0], FondaBase.WOOD[1], FondaBase.WOOD[2]);
        }
        if (FD.inside(u, z, W)) {
          final a = (u - W[0]) / (W[1] - W[0]);
          final bb = (z - W[2]) / (W[3] - W[2]);
          return FD.outside(hora, a, bb, jsRoundN(u * 26), jsRoundN(z * 22.5));
        }
        if (FD.onFrame(u, z, W)) {
          return e.rgb(
            FondaBase.WOOD_L[0],
            FondaBase.WOOD_L[1],
            FondaBase.WOOD_L[2],
          );
        }
        return FD.paint(u, z);
      });
      PZ.wall(
        D[0] - .2,
        D[1] + .2,
        -1.2,
        0,
        2.8,
        (u, z) => FD.outside(
          hora,
          (u - D[0]) / (D[1] - D[0]),
          (z + .2) / 3.0,
          jsRoundN(u * 26),
          jsRoundN(z * 22.5),
        ),
      );
      bake();
    }

    final cases = <String, dynamic Function()>{
      'tiles': () => groundWith(FD.tiles),
      'planks': () => groundWith(FD.planks),
      'paint.default': () {
        groundWith(FD.tiles);
        PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => FD.paint(u, z));
        bake();
      },
      'paint.custom': () {
        groundWith(FD.tiles);
        PZ.wall(
          -4.5,
          4.5,
          0,
          0,
          2.8,
          (u, z) => FD.paint(u, z, const [140, 110, 90], const [230, 220, 200]),
        );
        bake();
      },
      'openings.ocaso': () => openings('ocaso'),
      'openings.noche': () => openings('noche'),
      'openings.tarde_noche': () => openings('tarde_noche'),
      'sconce': () {
        groundWith(FD.tiles);
        PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => FD.paint(u, z));
        FD.sconce(-2.4, 0, 2.2);
        FD.sconce(1.8, 0, 2.0);
        bake();
        k.lightPass(const [.72, .74, .88], const [-4, -4, 10], false);
      },
      'table.default': () {
        groundWith(FD.tiles);
        FD.table(0, 2.5, 1.4);
        bake();
      },
      'table.custom': () {
        groundWith(FD.tiles);
        FD.table(-.5, 2.6, 1.6, .55, const [236, 214, 150]);
        bake();
      },
      'chair': () {
        groundWith(FD.tiles);
        FD.chair(-1.0, 2.2);
        FD.chair(1.0, 2.2);
        bake();
      },
      'chairEnd': () {
        groundWith(FD.tiles);
        FD.chairEnd(-1.6, 2.5, -1);
        FD.chairEnd(1.6, 2.5, 1);
        bake();
      },
      'setTable.default': () {
        groundWith(FD.tiles);
        final r = FD.setTable(0, 2.6, 1.5);
        bake();
        return r;
      },
      'setTable.one': () {
        groundWith(FD.tiles);
        final r = FD.setTable(0, 2.6, 1.0, seats: 1);
        bake();
        return r;
      },
      'setTable.full': () {
        groundWith(FD.tiles);
        final r = FD.setTable(
          0,
          2.8,
          1.9,
          seats: 4,
          span: 2.85,
          hd: .55,
          ends: true,
          cloth: const [236, 214, 150],
        );
        bake();
        return r;
      },
    };

    final mine = refs.where((r) => r['engine'] == en.key).toList();
    test('${en.key}: all ${cases.length} kit cases match', () {
      expect(mine.map((r) => r['name']).toList(), [...cases.keys, 'numbers']);
      for (final r in mine) {
        if (r['name'] == 'numbers') continue;
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
        for (final key in hashes.keys) {
          expect(
            hashes[key],
            r[key],
            reason: '${en.key}:${r['name']} $key differs from JS',
          );
        }
        expect(
          _plain(got),
          _plain(r['result']),
          reason: '${en.key}:${r['name']} return value differs from JS',
        );
      }
    });

    test('${en.key}: inside and onFrame match JS boundary values', () {
      final n = mine.firstWhere((r) => r['name'] == 'numbers')['result'];
      const D = [-3.2, -1.8, 0.0, 2.15];
      const W = [.6, 2.6, 1.1, 2.2];
      const dPts = [
        [-3.2, 0.0],
        [-1.8, 2.15],
        [-2.5, 1.0],
        [-3.25, 1.0],
        [-3.29, 1.0],
        [-3.30, 1.0],
        [-2.5, -.05],
        [-2.5, 2.20],
        [-2.5, 2.23],
        [-2.5, 2.25],
      ];
      const wPts = [
        [.6, 1.1],
        [2.6, 2.2],
        [1.5, 1.6],
        [.55, 1.6],
        [.52, 1.6],
        [1.5, 1.05],
        [1.5, 1.02],
        [1.5, 2.25],
        [1.5, 2.28],
        [2.68, 1.6],
      ];
      expect({
        'insideDoor': [for (final p in dPts) FD.inside(p[0], p[1], D)],
        'insideWin': [for (final p in wPts) FD.inside(p[0], p[1], W)],
        'onFrameDoorDefault': [for (final p in dPts) FD.onFrame(p[0], p[1], D)],
        'onFrameDoorCustom': [
          for (final p in dPts) FD.onFrame(p[0], p[1], D, .09),
        ],
        'onFrameWinDefault': [for (final p in wPts) FD.onFrame(p[0], p[1], W)],
        'onFrameWinCustom': [
          for (final p in wPts) FD.onFrame(p[0], p[1], W, .09),
        ],
      }, n);
    });
  }
}
