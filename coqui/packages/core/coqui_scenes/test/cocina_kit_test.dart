// The kitchen's kit in Dart (lib/src/cocina_kit.dart) against the JavaScript (docs/proyecto/pixel/cocina-kit.js): each
// piece drawn on its own from empty buffers, then whole rooms built by cocinaBuild, on one engine with La estufa's
// settings (240 x 216, S 26, origin (-102, -40), shadows (.9, -.1)), in the order tool/make_cocina_kit_ref.mjs ran them in
// headless Chrome. Each case's pix, zb, kinds and ground are the JavaScript's (equal hashes: 0 elements differ), and the
// numbers the pieces give back are the same.
import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cocina_kit.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/cocina_kit_refs.dart';
import 'support/hash.dart';

Object? _plain(Object? v) => switch (v) {
  final List l => [for (final x in l) _plain(x)],
  final Map m => {for (final e in m.entries) '${e.key}': _plain(e.value)},
  final ({double top, double d1, List<double> box}) r => {
    'top': r.top,
    'd1': r.d1,
    'box': r.box,
  },
  final ({List<double> box}) r => {'box': r.box},
  final ({double top}) r => {'top': r.top},
  final CocinaStoveOut r => {
    'burners': r.burners,
    'top': r.top,
    'a0': r.a0,
    'a1': r.a1,
    'box': r.box,
    'ovenDoor': r.ovenDoor,
  },
  final KWallPoint r => {'a': r.a, 'z': r.z, 'd': r.d, 'x': r.x, 'y': r.y},
  _ => v,
};

void main() {
  final refs = (jsonDecode(cocinaKitRefs) as List).cast<Map<String, dynamic>>();
  final e = PpEngine(
    w: 240,
    h: 216,
    s: 26,
    originX: -102,
    originY: -40,
    shadowX: .9,
    shadowY: -.1,
  );
  final k = SetKit(e, PpBuild(e)), c = CocinaKit(k);

  void reset() {
    e.zb.fillRange(0, e.zb.length, -1e9);
    e.pix.fillRange(0, e.pix.length, 0);
    e.kinds.fillRange(0, e.kinds.length, 0);
    e.ground.fillRange(0, e.ground.length, 0);
    e.shadowMask.fillRange(0, e.shadowMask.length, 0);
    e.staticShadow.fillRange(0, e.staticShadow.length, 0);
    e.groundZ.fillRange(0, e.groundZ.length, -1e9);
  }

  int paint(String f, double p, double q, bool sh) => e.rgb(
    f == 'top'
        ? 200
        : f == 'front'
        ? 100
        : 50,
    p * 40,
    q * 90 + (sh ? 30 : 0),
  );

  CocinaPlan plan(String? occlusion) => CocinaPlan(
    XR: 9,
    YL: 6,
    occlusion: occlusion,
    windows: const [
      CocinaWin(face: 'y', a0: 4, a1: 5.5, z0: 1.6, z1: 2.7, view: 'arbusto'),
      CocinaWin(
        face: 'x',
        a0: 2,
        a1: 3.4,
        z0: 1.5,
        z1: 2.8,
        view: 'patio',
        bars: 'medio',
      ),
      CocinaWin(
        name: 'puerta',
        face: 'y',
        a0: 6.5,
        a1: 7.6,
        z0: 0,
        z1: 2.5,
        door: true,
        view: 'patio',
        horizon: 1.2,
      ),
      CocinaWin(
        face: 'x',
        a0: 4.2,
        a1: 5.2,
        z0: 1.7,
        z1: 2.6,
        bushA: .1,
        bushZ: 2.1,
        bushR: .4,
      ),
    ],
    band: const {
      'y': [
        [0, 4],
        [5.6, 6.4],
      ],
      'x': [
        [0, 2],
      ],
    },
    floor: (x, y, ix, iy, i) =>
        x > 6.5 && x < 7.6 && y < .3 ? e.rgb(90, 90, 90) : 0,
    furnish: () {
      c.cocinaBase('y', 0, 2.4, noEnd: true);
      c.cocinaStove('y', 2.4, noEnd: true);
      c.cocinaBase('y', 2.4 + K.STW, 4.2);
      c.cocinaHood('y', 2.4);
      c.cocinaBackguard('y', 2.4);
      c.cocinaWallCupboard('y', .2, 2.2);
      c.cocinaShelf('x', .5, 1.8, 2.4);
      c.kSolid('y', 1, 1.6, 2.5, 3.1, 0, .7, KC.woodL);
    },
    shadows: () {
      c.cocinaShadowBlock(1, 2.5, 1.6, 3.1);
      c.cocinaShadowFoot(5, 4);
      c.cocinaShadowFoot(5.5, 4.2, .12);
    },
  );

  final cases = <String, Object? Function()>{
    'cocinaFloor': () {
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              col = c.cocinaFloor(g.x, g.y);
          if (col != 0) e.pix[iy * e.W + ix] = col;
        }
      }
      return null;
    },
    'cocinaWallColour': () {
      k.planeFace(
        'y',
        0,
        0,
        8,
        0,
        K.WH,
        (a, z) => c.cocinaWallColour(false, a, z, a > 2 && a < 6),
      );
      k.planeFace(
        'x',
        0,
        0,
        6,
        0,
        K.WH,
        (a, z) => c.cocinaWallColour(true, a, z, a < 3),
      );
      return null;
    },
    'kBox': () {
      c.kBox('y', 1, 3, .2, 1.1, .3, 1.5, paint);
      c.kBox('x', 1, 2.5, .3, 1, .2, 1.8, paint);
      c.kBox('y', 4, 5, 1.5, 2.3, 0, .9, paint, 'tf');
      c.kBox('x', 3, 4, 2, 2.5, 0, 1, paint, 'e');
      return null;
    },
    'kSolid': () {
      c.kSolid('y', 1, 2.5, .2, 1, 0, 1.2, KC.wood);
      c.kSolid('x', 1, 3, .2, .8, .5, 1.6, KC.steel, 'fe');
      return null;
    },
    'cocinaBase': () => [
      c.cocinaBase('y', .5, 3.2),
      c.cocinaBase('y', 3.2, 5, noEnd: true, doors: 1),
      c.cocinaBase('x', .5, 2.5, doors: 3),
    ],
    'cocinaWallCupboard': () => [
      c.cocinaWallCupboard('y', .5, 2.2),
      c.cocinaWallCupboard('x', 1, 2.6, z0: 2.1, z1: 2.9, depth: .4, doors: 3),
    ],
    'cocinaShelf': () => [
      c.cocinaShelf('y', 1, 3.5, 2.5),
      c.cocinaShelf('x', 1, 3, 2.3, depth: .5),
    ],
    'cocinaStove': () => [
      c.cocinaStove('y', 2),
      c.cocinaStove('x', 1.5, knobs: 3, horno: true, noEnd: true),
    ],
    'cocinaHood': () {
      c.cocinaHood('y', 2);
      c.cocinaHood('x', 1.5, top: 3);
      return null;
    },
    'cocinaBackguard': () {
      c.cocinaBackguard('y', 2);
      c.cocinaBackguard('x', 1.5, top: 2.2);
      return null;
    },
    'cocinaWindow': () {
      c.cocinaWindow(
        const CocinaWin(
          face: 'y',
          a0: 3,
          a1: 4.6,
          z0: 1.4,
          z1: 2.6,
          view: 'patio',
        ),
      );
      c.cocinaWindow(
        const CocinaWin(face: 'x', a0: 2, a1: 3, z0: 1.2, z1: 2.4, door: true),
      );
      return null;
    },
    'cocinaBuild': () {
      c.cocinaBuild(plan('shade'));
      return null;
    },
    'cocinaBuild.bakeOcclusion': () {
      c.cocinaBuild(plan(null));
      return null;
    },
    'cocinaBuild.none': () {
      c.cocinaBuild(plan('none'));
      return null;
    },
    'cocinaOcclusion': () {
      c.cocinaBuild(plan('none'));
      c.cocinaOcclusion();
      return null;
    },
  };

  test('the cases are the JavaScript\'s, in its order', () {
    expect([for (final r in refs) r['name']], [...cases.keys, 'numbers']);
  });

  // the cases run in order on one engine, as on the one page (cocinaBuild lays the floor of an engine once)
  final results = <String, Map<String, Object?>>{};
  setUpAll(() {
    c.cocinaCheckScene();
    for (final en in cases.entries) {
      reset();
      final r = en.value();
      results[en.key] = {
        'pix': hashOf(e.pix),
        'zb': hashOf(e.zb),
        'kinds': hashOf(e.kinds),
        'ground': hashOf(e.ground),
        'result': _plain(r),
      };
    }
  });

  for (final r in refs.where((r) => r['name'] != 'numbers')) {
    test(
      '${r['name']}: the same pixels, depth, kinds and ground as cocina-kit.js',
      () {
        final got = results[r['name']]!;
        for (final b in const ['pix', 'zb', 'kinds', 'ground']) {
          expect(got[b], r[b], reason: '${r['name']}: $b');
        }
        expect(
          got['result'],
          r['result'],
          reason: '${r['name']}: what it gives',
        );
      },
    );
  }

  test('the wall\'s frame, the light and the outside: the same numbers', () {
    final want =
        refs.firstWhere((r) => r['name'] == 'numbers')['result']
            as Map<String, dynamic>;
    const win = CocinaWin(face: 'y', a0: 4, a1: 5.5, z0: 1.6, z1: 2.7);
    final got = _plain({
      'kpt': [c.kpt('y', 1.5, .4, 1.3), c.kpt('x', 1.5, .4, 1.3)],
      'kWallPixel': [
        c.kWallPixel('y', 0, 120, 60),
        c.kWallPixel('x', 0, 30, 90),
        c.kWallPixel('y', -1.92, 140, 50),
        c.kWallPixel('x', -1.92, 10, 70),
      ],
      'kLit': [c.kLit(KC.wood, false), c.kLit(KC.wood, true)],
      'KDROP': c.KDROP,
      'kView': [
        c.kView('arbusto', .3, 2.0, 5, 7, win),
        c.kView('arbusto', -.6, 2.6, 6, 7, win),
        c.kView('arbusto', 1.5, 1.7, 1, 2, win),
        c.kView('patio', .4, 3.4, 3, 3, win),
        c.kView('patio', .1, 2.03, 3, 4, win),
        c.kView('patio', .15, 1.9, 5, 5, win),
        c.kView('patio', .7, 1.2, 9, 9, win),
      ],
    });
    expect(got, want);
  });

  test(
    'K.CD can be changed for one call and put back (estufa-set.html base())',
    () {
      final c0 = K.CD;
      K.CD = 1.4;
      try {
        expect(c.cocinaBase('y', 0, 1).d1, 1.4);
      } finally {
        K.CD = c0;
      }
      expect(K.CD, .9);
    },
  );
}
