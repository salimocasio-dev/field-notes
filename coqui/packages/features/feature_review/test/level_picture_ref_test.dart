// The level check's cell pictures: `PictureRef.ofLevel` (coqui_ui) against the crop this package drew itself before
// it existed (nivel.js: nivelPanel), over every picture of every item of the real historia/datos/nivel.json, with
// the real review pairs (the sets historia/datos/curso.json names, `cual`, in its order).
//
// `old` below is that crop as the package computed it: the same arithmetic, kept here as the reference. The two
// must give the same scene, the same `set` (the very same map) and the same camera for every picture.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The package is the working directory of its tests; historia/ is at the root of the repository.
const _historia = '../../../../historia';

dynamic _json(String path) =>
    jsonDecode(File('$_historia/$path').readAsStringSync());

/// nivel.js: CW, CH: four cells, each 96 x 106 art pixels; `E2.SW`: the width of a scene, 240.
const _cellWidth = 96;
const _cellHeight = 106;
const _sceneWidth = 240;

({String scene, Map<String, dynamic> set, List<num> cam}) _old(
  List<Object?> pic,
  Map<String, ReviewPair> pairs,
) {
  final it = pairs[pic[0] as String]!;
  final spec = pic[1] == 'no' ? it.no : it.yes;
  final cm = spec.cam;
  final h = cm[3];
  final w = h * _cellWidth / _cellHeight;
  final cx = (pic.length > 2 && pic[2] != null)
      ? pic[2] as num
      : cm[0] + cm[2] / 2;
  final x = math.max(0, math.min(_sceneWidth - w, cx - w / 2));
  return (scene: spec.scene ?? it.scene, set: spec.set, cam: [x, cm[1], w, h]);
}

void main() {
  late final List<LevelItem> items;
  late final Map<String, ReviewPair> pairs;

  setUpAll(() {
    items = [
      for (final q in _json('datos/nivel.json') as List)
        LevelItem.fromJson(q as Map<String, dynamic>),
    ];
    final list = <ReviewPair>[];
    for (final f in (_json('datos/curso.json') as Map)['cual'] as List) {
      final j = _json('cuentos/$f.json') as Map<String, dynamic>;
      for (final it in j['items'] as List) {
        list.add(
          ReviewPair.fromJson(
            it as Map<String, dynamic>,
            scene: j['scene'] as String,
          ),
        );
      }
    }
    pairs = {for (final p in list) p.word: p};
  });

  test('the real data is there: 52 items of four pictures', () {
    expect(items.length, 52);
    expect([for (final q in items) q.pictures.length], everyElement(4));
    for (final q in items) {
      for (final pic in q.pictures) {
        expect(
          pairs.containsKey(pic[0]),
          isTrue,
          reason: 'the pair of "${pic[0]}" (item "${q.word}")',
        );
      }
    }
  });

  test('ofLevel gives the scene, set and camera the level check cropped by itself, for every picture of every item', () {
    final differing = <String>[];
    var checked = 0;
    for (final q in items) {
      for (var k = 0; k < q.pictures.length; k++) {
        final old = _old(q.pictures[k], pairs);
        final ref = PictureRef.ofLevel(q, k, pairs: pairs);
        checked++;
        final sameCam =
            ref.cam.length == old.cam.length &&
            [for (var i = 0; i < old.cam.length; i++) ref.cam[i] == old.cam[i]]
                .every((b) => b);
        if (ref.scene != old.scene ||
            !identical(ref.set, old.set) ||
            !sameCam) {
          differing.add(
            '${q.word}[$k]: ofLevel ${ref.scene} ${ref.set} ${ref.cam}, '
            'old ${old.scene} ${old.set} ${old.cam}',
          );
        }
      }
    }
    expect(checked, 52 * 4);
    expect(differing, isEmpty);
  });

  test('ofLevel names each picture nivel.<word>.<index>', () {
    for (final q in items) {
      for (var k = 0; k < q.pictures.length; k++) {
        expect(
          PictureRef.ofLevel(q, k, pairs: pairs).name,
          'nivel.${q.word}.$k',
        );
      }
    }
  });
}
