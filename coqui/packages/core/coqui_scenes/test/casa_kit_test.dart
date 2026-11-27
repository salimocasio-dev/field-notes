// La casa's shared kit in Dart (lib/src/casa/casa_base.dart) against the JavaScript (docs/proyecto/pixel/casa-base.js):
// every piece drawn on its own from empty buffers at La casa's set origin (casa [0, -42]): boards (default & custom),
// paint (default & custom), tiles (default & custom), window (alba, manana, tarde, noche), clock, door (open, shut
// default & custom), bed (default & custom), armchair (default & custom), sofa (default & custom), rug (default &
// custom), and lamps (lit & unlit with lightPass + custom glowBox). Every case's pix, zb, kinds, ground, shadowMask
// and staticShadow must equal the JavaScript (0 elements differ).
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/casa/casa_base.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/casa_kit_refs.dart';
import 'support/hash.dart';

const Map<String, List<double>> _origins = {
  'casa': [0, -42],
};

void main() {
  final refs = (jsonDecode(casaKitRefs) as List).cast<Map<String, dynamic>>();

  test('every La casa engine origin is here', () {
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
    final CS = CasaBase(FD);

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
              : e.rgb(84, 70, 70);
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

    void win(String hora) {
      groundWith(CS.boards);
      PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) {
        final w = CS.windowAt(u, z, const [-2.0, 0.2, 1.0, 2.2], hora);
        return w != 0 ? w : CS.paint(u, z);
      });
      bake();
    }

    final cases = <String, void Function()>{
      'boards.default': () =>
          groundWith((u, v, ix, iy) => CS.boards(u, v, ix, iy)),
      'boards.custom': () => groundWith(
        (u, v, ix, iy) => CS.boards(u, v, ix, iy, const [210, 170, 120]),
      ),
      'paint.default': () {
        groundWith(CS.boards);
        PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.paint(u, z));
        bake();
      },
      'paint.custom': () {
        groundWith(CS.boards);
        PZ.wall(
          -4.5,
          4.5,
          0,
          0,
          2.8,
          (u, z) => CS.paint(u, z, const [226, 214, 236]),
        );
        bake();
      },
      'tiles.default': () {
        groundWith(CS.boards);
        PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.tiles(u, z));
        bake();
      },
      'tiles.custom': () {
        groundWith(CS.boards);
        PZ.wall(
          -4.5,
          4.5,
          0,
          0,
          2.8,
          (u, z) => CS.tiles(u, z, const [70, 150, 170]),
        );
        bake();
      },
      'window.alba': () => win('alba'),
      'window.manana': () => win('manana'),
      'window.tarde': () => win('tarde'),
      'window.noche': () => win('noche'),
      'clock': () {
        groundWith(CS.boards);
        PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) {
          final cc = CS.clockAt(u, z, 1.6, 1.85);
          return cc != 0 ? cc : CS.paint(u, z);
        });
        bake();
      },
      'door.open': () {
        groundWith(CS.boards);
        PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) {
          final dd = CS.doorAt(u, z, const [-3.6, -2.2, 0, 2.15], true);
          return dd != 0 ? dd : CS.paint(u, z);
        });
        bake();
      },
      'door.shut.default': () {
        groundWith(CS.boards);
        PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) {
          final dd = CS.doorAt(u, z, const [-3.6, -2.2, 0, 2.15], false);
          return dd != 0 ? dd : CS.paint(u, z);
        });
        bake();
      },
      'door.shut.custom': () {
        groundWith(CS.boards);
        PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) {
          final dd = CS.doorAt(
            u,
            z,
            const [-3.6, -2.2, 0, 2.15],
            false,
            const [140, 100, 70],
          );
          return dd != 0 ? dd : CS.paint(u, z);
        });
        bake();
      },
      'bed.default': () {
        groundWith(CS.boards);
        CS.bed(-1.5, .15, 2.35, .8);
        bake();
      },
      'bed.custom': () {
        groundWith(CS.boards);
        CS.bed(1.4, .15, 2.35, .75, const [236, 190, 110]);
        bake();
      },
      'armchair.default': () {
        groundWith(CS.boards);
        CS.armchair(-1.5, 2.2);
        bake();
      },
      'armchair.custom': () {
        groundWith(CS.boards);
        CS.armchair(1.5, 2.2, const [110, 140, 96]);
        bake();
      },
      'sofa.default': () {
        groundWith(CS.boards);
        CS.sofa(0, 2.2, 1.45);
        bake();
      },
      'sofa.custom': () {
        groundWith(CS.boards);
        CS.sofa(0, 2.2, 1.45, const [96, 140, 150]);
        bake();
      },
      'rug.default': () {
        groundWith(CS.boards);
        CS.rug(-2.4, 1.4, 2.4, 3.6);
        bake();
      },
      'rug.custom': () {
        groundWith(CS.boards);
        CS.rug(
          -2.4,
          1.4,
          2.4,
          3.6,
          const [86, 150, 150],
          const [240, 230, 200],
        );
        bake();
      },
      'lamps.lit': () {
        groundWith(CS.boards);
        PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.paint(u, z));
        CS.lampStanding(-2.6, 1.8, true);
        CS.lampSmall(0, .2, 1.2, true);
        CS.lampWall(2.4, 1.9, true);
        bake();
        k.lightPass(const [.72, .74, .88], const [-4, -4, 10], false);
      },
      'lamps.unlit': () {
        groundWith(CS.boards);
        PZ.wall(-4.5, 4.5, 0, 0, 2.8, (u, z) => CS.paint(u, z));
        CS.lampStanding(-2.6, 1.8, false);
        CS.lampSmall(0, .2, 1.2, false);
        CS.lampWall(2.4, 1.9, false);
        CS.glowBox(.8, 2.0, .6, 1.0, .22, false, const [230, 210, 160]);
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
