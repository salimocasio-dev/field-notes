// The map picture against the picture the old code made in Chrome (coqui/ref/pp/map/): with `hecho`, `abierto`
// and `aqui` set as each state.json records them, the frame at time 0 differs from `pix.bin` in no more than
// 0.5% of the pixels (page 11-pixel-engine, decision 2; order 13). Pure Dart: it runs under `flutter test` and
// `flutter test --platform chrome`.
//
// The bake runs once, when the file loads, so each test's name can carry its measured number: it shows in the
// test report on the vm and in chrome.
import 'dart:convert';

import 'package:feature_map/src/map_layout.dart';
import 'package:feature_map/src/map_picture.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/compare.dart';
import 'support/ref_data.dart';

void main() {
  final bakeWatch = Stopwatch()..start();
  final map = MapPicture(); // `still` is false: the references are made with motion on
  map.bake();
  bakeWatch.stop();

  // Page 11-pixel-engine, decision 2: "up to 0.5% of pixels"
  const limit = 0.5;

  final diffs = <String, Diff>{};
  final states = <String, Map<String, dynamic>>{};
  for (final n in const [0, 3, 10]) {
    final id = 'hecho-$n';
    final st =
        jsonDecode(refText('map/$id/state.json')) as Map<String, dynamic>;
    states[id] = st;
    map.setState(
      MapState(
        hecho: (st['hecho'] as List).cast<bool>(),
        abierto: (st['abierto'] as List).cast<bool>(),
        aqui: st['aqui'] as int,
      ),
    );
    map.placeFrog((st['frog'] as Map<String, dynamic>)['at'] as int);
    map.time = (st['time'] as num).toDouble();
    map.draw();
    diffs[id] = diffExact(map.pix, readU32(refBytes('map/$id/pix.bin')));
  }
  final kinds = diffExact(map.e.kinds, refBytes('map/hecho-0/kinds.bin'));

  test('the settings are the ones the references were made with', () {
    for (final st in states.values) {
      final eng = st['engine'] as Map<String, dynamic>;
      expect(eng['W'], mapW);
      expect(eng['H'], mapH);
      expect(eng['S'], mapS);
      expect(eng['originY'], mapOriginY);
      expect(eng['SHADOW_X'], mapShadowX);
      expect(eng['SHADOW_Y'], mapShadowY);
      expect(eng['STILL'], false);
      expect(st['time'], 0);
    }
    expect(map.pix, hasLength(mapW * mapH));
  });

  test('the comparison is not empty: the picture has as many drawn pixels', () {
    final ref = readU32(refBytes('map/hecho-10/pix.bin'));
    final drawn = ref.where((c) => c != 0).length;
    expect(drawn, greaterThan(60000));
    expect(map.pix.where((c) => c != 0).length, drawn);
  });

  test('the build counts what the old one counted', () {
    final counts = states['hecho-0']!['counts'] as Map<String, dynamic>;
    expect(map.e.tufts, hasLength(counts['tufts'] as int));
    expect(map.e.leaves, hasLength(counts['leaves'] as int));
    expect(map.waterPix.length ~/ 4, counts['waterPix'] as int);
  });

  for (final id in const ['hecho-0', 'hecho-3', 'hecho-10']) {
    final d = diffs[id]!;
    test('$id at time 0: ${d.text} pixels differ, limit $limit%', () {
      expect(
        d.percent,
        lessThanOrEqualTo(limit),
        reason: 'first ones:\n${d.first.join('\n')}',
      );
    });
  }

  test('kinds (as bake leaves them): ${kinds.text} differ, limit $limit%', () {
    expect(
      kinds.percent,
      lessThanOrEqualTo(limit),
      reason: 'first ones:\n${kinds.first.join('\n')}',
    );
  });

  test('bake: ${bakeWatch.elapsedMilliseconds} ms on this machine', () {
    expect(map.baked, isTrue);
  });
}
