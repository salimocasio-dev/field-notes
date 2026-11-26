// La playa's shared kit in Dart (lib/src/playa/playa_base.dart) against the JavaScript (docs/proyecto/pixel/playa-base.js):
// every piece drawn on its own from empty buffers across all four La playa set origins (orilla, sombrilla, ropa, cielo):
// ground, palm (plain & lit), blanket, umbrella (open & shut), heap, bucket, sky (4 hours), light (5 hours).
// Every case's pix, zb, kinds, ground, shadowMask and staticShadow must equal the JavaScript (0 elements differ).
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/playa/playa_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/playa_kit_refs.dart';
import 'support/hash.dart';

const Map<String, List<double>> _origins = {
  'orilla': [0, -30],
  'sombrilla': [0, -44],
  'ropa': [0, -48],
  'cielo': [0, 44],
};

void main() {
  final refs = (jsonDecode(playaKitRefs) as List).cast<Map<String, dynamic>>();

  test('every La playa engine origin is here', () {
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
    final PL = PlayaBase(PZ);

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
    }

    void groundBeach() {
      const B = PlayaBeach(edge: 0, wet: .9, deep: -2.2, hor: -4.6);
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final g = e.unproject(ix + .5, iy + .5);
          final i = iy * e.W + ix;
          final uv = PZ.uv(g.x, g.y);
          final c = PL.ground(uv[0], uv[1], ix, iy, B);
          if (c == null) continue;
          e.pix[i] = c.color;
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
          e.kinds[i] = c.kind == 'mar' ? KIND_WATER : KIND_SAND;
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
      'ground': groundBeach,
      'palm': () {
        groundBeach();
        PL.palm(-2.0, 2.0, 3.1, -.4, 2, 1, null);
        bake();
        e.drawLeaves(0);
      },
      'palm.lit': () {
        groundBeach();
        const L = Light([1.0, .86, .74], [16, 0, -12]);
        PL.palm(1.4, 2.0, 2.8, .4, 5, .9, L);
        bake();
        PL.light('ocaso');
        e.drawLeaves(0);
      },
      'blanket': () {
        groundBeach();
        PL.blanket(-3.0, 2.5, -.5, 4.2);
        bake();
      },
      'umbrella.open': () {
        groundBeach();
        PL.umbrella(.4, 2.2, 2.6, 1.5, true);
        bake();
      },
      'umbrella.shut': () {
        groundBeach();
        PL.umbrella(.4, 2.2, 2.6, 1.5, false);
        bake();
      },
      'heap': () {
        groundBeach();
        PL.heap(1.2, 3.0, .6, .34);
        bake();
      },
      'bucket': () {
        groundBeach();
        PL.bucket(-.8, 2.8);
        bake();
      },
      'sky.manana': () => k.skyFill(PL.sky('manana', const [150, 8, 6])),
      'sky.ocaso': () => k.skyFill(PL.sky('ocaso', const [58, 10, 7])),
      'sky.gris': () => k.skyFill(PL.sky('gris')),
      'sky.noche': () => k.skyFill(PL.sky('noche')),
      'light.tarde': () {
        groundBeach();
        PL.bucket(0, 2.5);
        bake();
        PL.light('tarde');
      },
      'light.ocaso': () {
        groundBeach();
        PL.bucket(0, 2.5);
        bake();
        PL.light('ocaso');
      },
      'light.sol': () {
        groundBeach();
        PL.bucket(0, 2.5);
        bake();
        PL.light('sol');
      },
      'light.gris': () {
        groundBeach();
        PL.bucket(0, 2.5);
        bake();
        PL.light('gris');
      },
      'light.noche': () {
        groundBeach();
        PL.bucket(0, 2.5);
        bake();
        PL.light('noche');
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
