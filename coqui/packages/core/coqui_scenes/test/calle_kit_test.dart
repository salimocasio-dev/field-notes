// La calle's kit in Dart (lib/src/calle/calle_base.dart) against the JavaScript (docs/proyecto/pixel/calle-base.js):
// each piece drawn on its own from empty buffers on engines with the origins of the place's four sets, in the order
// tool/make_calle_kit_ref.mjs ran them in headless Chrome. Each case's pix, zb, kinds, ground and shadowMask are the
// JavaScript's (equal hashes: 0 elements differ), and the numbers the pieces give back are the same.
//
// With CALLE_KIT_DUMP=DIR (the tool's --dump DIR) a case that differs says which pixels (the vm only).
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/calle_dump.dart';
import 'support/fixtures/calle_kit_refs.dart';
import 'support/hash.dart';

const Map<String, List<double>> _origins = {
  'esquina': [30, -8],
  'parada': [70, -16],
  'tiendas': [0, 24],
  'cruce': [-24, 10],
};

/// The cases every engine but La esquina's runs (the tool's list).
const List<String> _others = [
  'slab',
  'box',
  'houseX',
  'tree',
  'seat',
  'signPole',
  'vehicle.guagua.i.arbol',
  'baked.street',
  'sky.tarde',
];

Object? _plain(Object? v) => switch (v) {
  final List l => [for (final x in l) _plain(x)],
  final Map m => {for (final e in m.entries) '${e.key}': _plain(e.value)},
  final CalleLight t => {
    'lamps': [
      for (final l in t.lamps)
        {'x': _plain(l.x), 'y': _plain(l.y), 'z': _plain(l.z)},
    ],
    'button': {
      'x': _plain(t.button.x),
      'y': _plain(t.button.y),
      'z': _plain(t.button.z),
    },
  },
  final double d when d == d.truncateToDouble() && d.abs() < 1e15 => d.toInt(),
  _ => v,
};

String? _where(String engine, String name, Uint32List pix, Float32List zb) {
  final p = calleDump('$engine.$name.pix.bin'),
      z = calleDump('$engine.$name.zb.bin');
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
  final refs = (jsonDecode(calleKitRefs) as List).cast<Map<String, dynamic>>();

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
    final k = SetKit(e, PpBuild(e)), cl = CalleBase(k);

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
      cl.NIGHT = false;
    }

    // a ground of one painter over the whole picture (esquina-set.html's ground pass)
    void ground(int Function(double x, double y, int ix, int iy) fn) {
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              i = iy * e.W + ix,
              c = fn(g.x, g.y, ix, iy);
          if (c == 0) continue;
          e.pix[i] = c;
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
          e.kinds[i] = KIND_ROAD;
        }
      }
      e.groundZ.setAll(0, e.zb);
    }

    void baked() {
      e.flushShadows();
      e.pendingShadows.clear();
      e.bakeOcclusion();
      k.joinSlabs();
      e.staticShadow.setAll(0, e.shadowMask);
      e.applyShadows(e.groundZ);
      e.shadeEdges();
    }

    int pic(num u, num v) =>
        math.sqrt((u - .5) * (u - .5) + (v - .5) * (v - .5)) < .3
        ? e.rgb(200, 40, 40)
        : 0;

    final all = <String, dynamic Function()>{
      'slab': () => ground(cl.slab),
      'asphalt': () => ground((x, y, ix, iy) => cl.asphalt(ix, iy)),
      'kerb.paint': () => ground(
        (x, y, ix, iy) =>
            ((x + 40).remainder(2)) < 1 ? cl.kerb() : cl.paint(CalleBase.LINE),
      ),
      'grass': () => ground(cl.grass),
      'faceY': () => cl.faceY(
        1,
        -2,
        2,
        0,
        2,
        (a, z) => ((a * 4).floor() + (z * 4).floor()).remainder(2) != 0
            ? e.rgb(10, 200, 10)
            : 0,
      ),
      'faceX.step': () => cl.faceX(
        1,
        -2,
        2,
        0,
        2,
        (b, z) => e.rgb(100 + b * 20, 50, 200 - z * 30),
        CalleBase.PP,
      ),
      'top': () => cl.top(
        -1,
        -1,
        2,
        1.5,
        .5,
        (a, b) => a > 0 && b > 0 ? 0 : e.rgb(220, 120, 40),
      ),
      'box': () => cl.box(-1, -1, 0, 1, 1, 1.5, const [150, 104, 62]),
      'box.topFn': () => cl.box(-1, -1, 0, 1, 1, 1.5, const [
        70,
        120,
        206,
      ], (a, b) => a > .3 ? e.rgb(250, 250, 250) : 0),
      'wallAlongX': () => cl.wallAlongX(
        0,
        -10,
        0,
        3.5,
        CalleBase.SALMON,
        CalleBase.TEAL,
        const [
          [-2.62, -1.08, 0, 2.67],
          [-6.4, -4.2, .85, 2.3],
        ],
      ),
      'wallAlongY': () =>
          cl.wallAlongY(0, -9, 0, 3.5, CalleBase.SALMON, CalleBase.TEAL, const [
            [-4, -2, 1, 2],
          ]),
      'doorX.shut': () => cl.doorX(0, -2.5, -1.2, 2.55, false),
      'doorX.open': () => cl.doorX(0, -2.5, -1.2, 2.55, true),
      'doorX.plain': () =>
          cl.doorX(0, 1, 2.1, 2.4, false, const [60, 90, 170], false),
      'signX': () => cl.signX(0, -2.95, -.75, 2.75, 3.42, pic),
      'signY': () => cl.signY(0, -4, -2, 2, 2.8, pic),
      'windowY': () => cl.windowY(0, -4, -2.5, 1, 2.2),
      'awningY': () => cl.awningY(0, -5, -1, 2.9, 2.6, .8),
      'tree': () => cl.tree(2, 3, 1.3, .9),
      'tree.colours': () =>
          cl.tree(-1, 4, 1.9, 1.35, const [96, 150, 70], const [140, 190, 90]),
      'trafficLight': () => cl.trafficLight(1.66, 1.5),
      'cone': () {
        cl.cone(1, 4.25);
        cl.cone(-.3, 2.3);
      },
      'windowX': () => cl.windowX(0, -6.3, -4.3, .95, 2.2),
      'windowX.night': () {
        cl.NIGHT = true;
        cl.windowX(0, -6.3, -4.3, .95, 2.2);
      },
      'awningX': () => cl.awningX(0, -6.6, -4.0, 2.9, 2.6, .8),
      'seat': () => cl.seat(-1, 6, 1),
      'seat.bench': () => cl.seat(2, 6.5, 4, false, const [196, 186, 168]),
      'signPole': () =>
          cl.signPole(2, 1.2, 2.3, .62, .62, const [40, 110, 200], pic),
      'houseX': () => cl.houseX(
        0,
        -4.2,
        .2,
        3.2,
        const [244, 170, 150],
        const [200, 110, 96],
        -1.6,
        -3.4,
      ),
      'houseX.none': () => cl.houseX(
        0,
        .2,
        4.6,
        3.4,
        const [196, 220, 150],
        const [120, 160, 90],
        null,
        2.6,
        const [96, 70, 110],
        2.0,
      ),
      'sky.manana': () => k.skyFill(cl.sky('manana', const [60, 30, 12])),
      'sky.tarde': () => k.skyFill(cl.sky('tarde', const [200, 20, 14])),
      'sky.noche': () => k.skyFill(cl.sky('noche', null)),
      'sky.temprano': () => k.skyFill(cl.sky('temprano', const [30, 40, 10])),
      'sky.gris': () => k.skyFill(cl.sky('gris', null)),
      'sky.otra': () => k.skyFill(cl.sky('nada', null)),
      'vehicle.carro.i': () => cl.vehicle('carro', .7, 4.8, 'i'),
      'vehicle.carro.d': () => cl.vehicle('carro', -.9, 4.8, 'd'),
      'vehicle.azul.i': () => cl.vehicle('azul', 5.1, 4.8, 'i'),
      'vehicle.azul.d': () => cl.vehicle('azul', -.9, 4.8, 'd'),
      'vehicle.guagua.i': () => cl.vehicle('guagua', 4.5, 4.8, 'i'),
      'vehicle.guagua.d': () => cl.vehicle('guagua', -1.5, 4.8, 'd'),
      'vehicle.guagua.i.arbol': () =>
          cl.vehicle('guagua', 4.5, 4.8, 'i', 'arbol'),
      'vehicle.guagua.d.toldo': () =>
          cl.vehicle('guagua', -1.5, 4.8, 'd', 'toldo'),
      'vehicle.guagua.i.casa': () =>
          cl.vehicle('guagua', 4.5, 2.8, 'i', 'casa'),
      'vehicle.guagua.i.otro': () =>
          cl.vehicle('guagua', 4.5, 2.8, 'i', 'otro'),
      'baked.street': () {
        ground(
          (x, y, ix, iy) =>
              y > 1.8 && y < 5.8 ? cl.asphalt(ix, iy) : cl.slab(x, y, ix, iy),
        );
        cl.vehicle('carro', .7, 4.8, 'i');
        cl.vehicle('guagua', 4.5, 2.8, 'd', 'arbol');
        cl.trafficLight(1.66, 1.5);
        cl.tree(-3, 7.5, 1.3, .9);
        cl.cone(3, 6.2);
        baked();
      },
    };
    final cases = en.key == 'esquina'
        ? all
        : {
            for (final c in all.entries)
              if (_others.contains(c.key)) c.key: c.value,
          };
    final mine = [
      for (final r in refs)
        if (r['engine'] == en.key) r,
    ];
    test('${en.key}: the cases are the JavaScript\'s, in its order', () {
      expect(cases.keys.toList(), [for (final r in mine) r['name']]);
    });
    for (final r in mine) {
      test('${en.key}: ${r['name']} draws the JavaScript\'s pixels', () {
        reset();
        final got = cases[r['name']]!();
        final hashes = {
          'pix': hashOf(e.pix),
          'zb': hashOf(e.zb),
          'kinds': hashOf(e.kinds),
          'ground': hashOf(e.ground),
          'shadow': hashOf(e.shadowMask),
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
  }
}
