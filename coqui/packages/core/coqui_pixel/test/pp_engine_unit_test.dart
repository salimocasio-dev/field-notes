// The 200 unit values the old engine gave in Chrome for each of hash, noise, project, unproject and rampOf
// (coqui/ref/pp/unit/). project, unproject and rampOf must match exactly; hash and noise to 1e-9, because
// Math.sin differs between engines in its last digits (coqui/tool/ref/pp/README.md, Notes).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/ref_data.dart';

PpEngine engineOf(Map<String, dynamic> settings) {
  final w = settings['W'] as int, h = settings['H'] as int;
  final s = (settings['S'] as num).toDouble();
  // OX = W / 2 + originX, OY = H / 2 + originY: the file holds OX and OY, so give back what it held
  return PpEngine(
    w: w,
    h: h,
    s: s,
    originX: (settings['OX'] as num) - w / 2,
    originY: (settings['OY'] as num) - h / 2,
    shadowX: (settings['SHADOW_X'] as num).toDouble(),
    shadowY: (settings['SHADOW_Y'] as num).toDouble(),
  );
}

List<Map<String, dynamic>> rows(Map<String, dynamic> file, String key) =>
    (file[key] as List).cast<Map<String, dynamic>>();

void main() {
  final unit = jsonDecode(refText('unit/unit.json')) as Map<String, dynamic>;
  final unit26 =
      jsonDecode(refText('unit/unit-s26.json')) as Map<String, dynamic>;
  final map = engineOf(unit['settings'] as Map<String, dynamic>);
  final frente = engineOf(unit26['settings'] as Map<String, dynamic>);

  test('the engines have the settings the files name', () {
    for (final (e, file) in [(map, unit), (frente, unit26)]) {
      final s = file['settings'] as Map<String, dynamic>;
      expect(
        [e.W, e.H, e.S, e.OX, e.OY],
        [s['W'], s['H'], s['S'], s['OX'], s['OY']],
      );
      expect([e.SIN, e.COS, e.R2], [s['SIN'], s['COS'], s['R2']]);
    }
  });

  group('map settings (S = 8)', () {
    test('hash, 200 values, to 1e-9', () {
      final r = rows(unit, 'hash');
      expect(r, hasLength(200));
      for (final v in r) {
        expect(
          map.hash(v['x'] as num, v['y'] as num),
          closeTo(v['v'] as num, 1e-9),
          reason: 'hash(${v['x']}, ${v['y']})',
        );
      }
    });
    test('noise, 200 values, to 1e-9', () {
      final r = rows(unit, 'noise');
      expect(r, hasLength(200));
      for (final v in r) {
        expect(
          map.noise(v['x'] as num, v['y'] as num),
          closeTo(v['v'] as num, 1e-9),
          reason: 'noise(${v['x']}, ${v['y']})',
        );
      }
    });
    test(
      'project, 200 values, exactly (screen position, depth, | 0, float32)',
      () {
        checkProject(map, rows(unit, 'project'));
      },
    );
    test('unproject, 200 values, exactly', () {
      checkUnproject(map, rows(unit, 'unproject'));
    });
    test('rampOf, 200 colours, exactly', () {
      checkRampOf(map, rows(unit, 'rampOf'));
    });
  });

  group('El frente settings (S = 26, originX -30, originY 40)', () {
    test('project, 200 values, exactly', () {
      checkProject(frente, rows(unit26, 'project'));
    });
    test('unproject, 200 values, exactly', () {
      checkUnproject(frente, rows(unit26, 'unproject'));
    });
  });
}

void checkProject(PpEngine e, List<Map<String, dynamic>> r) {
  expect(r, hasLength(200));
  final f32 = Float32List(1);
  for (final v in r) {
    final p = e.project(v['x'] as num, v['y'] as num, v['z'] as num);
    final at = 'project(${v['x']}, ${v['y']}, ${v['z']})';
    expect(p.sx, v['sx'], reason: '$at sx');
    expect(p.sy, v['sy'], reason: '$at sy');
    expect(p.d, v['d'], reason: '$at d');
    expect(p.sx.truncate(), v['ix'], reason: '$at ix = sx | 0');
    expect(p.sy.truncate(), v['iy'], reason: '$at iy = sy | 0');
    // the depth as the Float32Array keeps it
    f32[0] = p.d;
    expect(f32[0], v['d32'], reason: '$at d as float32');
    expect(
      f32.buffer.asUint32List()[0],
      v['d32bits'],
      reason: '$at float32 bits',
    );
  }
}

void checkUnproject(PpEngine e, List<Map<String, dynamic>> r) {
  expect(r, hasLength(200));
  for (final v in r) {
    final p = e.unproject(v['sx'] as num, v['sy'] as num);
    expect(p.x, v['x'], reason: 'unproject(${v['sx']}, ${v['sy']}) x');
    expect(p.y, v['y'], reason: 'unproject(${v['sx']}, ${v['sy']}) y');
  }
}

void checkRampOf(PpEngine e, List<Map<String, dynamic>> r) {
  expect(r, hasLength(200));
  for (final v in r) {
    final c = (v['c'] as List).cast<num>();
    expect(e.rampOf(c), v['ramp'], reason: 'rampOf($c)');
  }
}
