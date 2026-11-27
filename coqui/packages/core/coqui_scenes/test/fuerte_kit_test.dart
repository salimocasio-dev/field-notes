// El fuerte's shared kit in Dart (lib/src/fuerte/fuerte_base.dart) against the JavaScript
// (docs/proyecto/pixel/fuerte-base.js): every piece drawn on its own from empty buffers across all three El fuerte set
// origins (subida [0, -4], musica [0, -34], muralla [0, -24]): flags (default & custom), grass/onPath/pathStone,
// stone (custom), yardWall (plain & arch exercising solid/inArch/archRing/stone/flags), night (std & low),
// day (tarde & ocaso), wallLamp (lit & unlit with lightPass), garita (plain, door lit & unlit), cap,
// table (default & custom), cord, stool (ground & elevated), lights (with lightPass), plus palette constants.
// Every case's pix, zb, kinds, ground, shadowMask and staticShadow must equal the JavaScript (0 elements differ).
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/fuerte/fuerte_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/fuerte_kit_refs.dart';
import 'support/hash.dart';

const Map<String, List<double>> _origins = {
  'subida': [0, -4],
  'musica': [0, -34],
  'muralla': [0, -24],
};

void main() {
  final refs = (jsonDecode(fuerteKitRefs) as List).cast<Map<String, dynamic>>();

  test('palette constants match fuerte-base.js', () {
    expect(FuerteBase.STONE, const [214, 186, 140]);
    expect(FuerteBase.STONE_D, const [166, 140, 106]);
    expect(FuerteBase.STONE_L, const [234, 212, 170]);
    expect(FuerteBase.IRON, const [60, 64, 76]);
  });

  test('every El fuerte engine origin is here', () {
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
    final FT = FuerteBase(PZ);

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

    void groundFlags([int Function(num u, num v, int ix, int iy)? fn]) {
      final paint = fn ?? FT.flags;
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final g = e.unproject(ix + .5, iy + .5);
          final i = iy * e.W + ix;
          final uv = PZ.uv(g.x, g.y);
          if (uv[1] < -.62) continue;
          e.pix[i] = paint(uv[0], uv[1], ix, iy);
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
          e.kinds[i] = KIND_ROAD;
        }
      }
      e.groundZ.setAll(0, e.zb);
    }

    void groundGrassPath() {
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final g = e.unproject(ix + .5, iy + .5);
          final i = iy * e.W + ix;
          final uv = PZ.uv(g.x, g.y);
          final on = FT.onPath(uv[0], uv[1], .15, .62);
          e.pix[i] = on
              ? FT.pathStone(uv[0], uv[1], ix, iy)
              : FT.grass(uv[0], uv[1], ix, iy);
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
          e.kinds[i] = on ? KIND_ROAD : e.KIND_GRASS;
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

    final cases = <String, void Function()>{
      'flags.default': () =>
          groundFlags((u, v, ix, iy) => FT.flags(u, v, ix, iy)),
      'flags.custom': () => groundFlags(
        (u, v, ix, iy) => FT.flags(u, v, ix, iy, const [255, 232, 160]),
      ),
      'grass.path': groundGrassPath,
      'stone.custom': () {
        groundFlags();
        PZ.wall(
          -4.5,
          4.5,
          0,
          0,
          2.2,
          (u, z) => FT.stone(u, z, const [255, 226, 160]),
        );
        bake();
      },
      'yardWall.plain': () {
        groundFlags();
        FT.yardWall();
        bake();
      },
      'yardWall.arch': () {
        groundFlags();
        FT.yardWall(2.6, const [
          [-1.1, 1.1, 0, 1.9],
        ]);
        bake();
      },
      'night.std': () => k.skyFill((ix, iy) => FT.night(ix, iy, 90)),
      'night.low': () =>
          k.skyFill((ix, iy) => FT.night(ix, iy, 90, const [70, 81, 9], true)),
      'day.tarde': () => k.skyFill((ix, iy) => FT.day('tarde', ix, iy, 90)),
      'day.ocaso': () => k.skyFill((ix, iy) => FT.day('ocaso', ix, iy, 90)),
      'wallLamp.lit': () {
        groundFlags();
        FT.yardWall();
        FT.wallLamp(-2.0, 0, 1.4, true);
        FT.wallLamp(2.0, 0, 1.4, true);
        bake();
        k.lightPass(const [.72, .74, .88], const [-4, -4, 10], false);
      },
      'wallLamp.unlit': () {
        groundFlags();
        FT.yardWall();
        FT.wallLamp(-2.0, 0, 1.4, false);
        bake();
        k.lightPass(const [.72, .74, .88], const [-4, -4, 10], false);
      },
      'garita.plain': () {
        groundFlags();
        FT.garita(-1.5, 1.5);
        bake();
      },
      'garita.door.lit': () {
        groundFlags();
        FT.garita(1.2, 1.6, const [196, 84, 70], true);
        bake();
      },
      'garita.door.unlit': () {
        groundFlags();
        FT.garita(0, 1.6, const [70, 132, 122], false, .7, 1.9);
        bake();
      },
      'cap': () {
        groundFlags();
        FT.cap(0, 1.5, .8, .55);
        bake();
      },
      'table.default': () {
        groundFlags();
        FT.table(0, 2.2, 1.4);
        bake();
      },
      'table.custom': () {
        groundFlags();
        FT.table(0, 2.2, 1.6, .6, const [96, 150, 206]);
        bake();
      },
      'cord': () {
        groundFlags();
        FT.yardWall();
        FT.cord(-3.0, 3.0, .05, 1.8);
        FT.cord(-2.5, 2.5, .1, 1.5, 1.2, .18, const [190, 90, 60]);
        bake();
      },
      'stool.ground': () {
        groundFlags();
        FT.stool(-1.0, 2.0);
        FT.stool(1.0, 2.0, .52, .3, const [190, 140, 92], 0);
        bake();
      },
      'stool.elevated': () {
        groundFlags();
        FT.stool(0, 2.0, .46, .22, const [176, 122, 76], .4);
        bake();
      },
      'lights': () {
        groundFlags();
        FT.yardWall();
        FT.lights(-3.5, 3.5, .03, 1.85, .16);
        bake();
        k.lightPass(const [.72, .74, .88], const [-4, -4, 10], false);
      },
    };

    final mine = refs.where((r) => r['engine'] == en.key).toList();
    test('${en.key}: all ${cases.length} kit cases match', () {
      expect(mine.map((r) => r['name']).toList(), cases.keys.toList());
      for (final r in mine) {
        reset();
        cases[r['name']]!();
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
      }
    });
  }
}
