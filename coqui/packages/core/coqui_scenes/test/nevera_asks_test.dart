// La nevera's asks, every one: at each ask and decide step of every recorded run of its four stories (right, wrong and
// alternate), and at each ask picture of the app's two plays of each (coqui/app tool/gate_a_frames_test.dart, the story's
// W at that moment written with ASKW=yes; its asked thing the hint's, else the one the learner touches), the hint frame's
// box and the hint hand's point the Dart scene gives for the asked thing equal what nevera-preview.html gives
// (tool/nevera_asks_ref.mjs: juego.js respBox, else the preview's hb: the sheet's hint box by state, or its hint box, else
// the scene's box; the hand respBox's foot, else E.handAt; for the run's W before the step moved by the preview's rule, or
// the play's W as it is), and the thing's drawn pixels lie outside that box no more than the preview's do (the old file's
// own: a person's box, the jug's, the butter's dish).
// And whoever stands outside the window, at every step's end of every run (each distinct set of them): drawn only on the
// set's pixels that show the outside (no pixel outside the opening), as many pixels as the preview draws for them; the
// zones of every state the preview baked are nevera-set.html's.
import 'dart:convert';

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/nevera/nevera.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/nevera_asks_fixture.dart';
import 'support/nevera_preview_remap.dart';
import 'support/report.dart';
import 'support/sheet_bundle.dart';

int _round(num v) => (v + .5).floor();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final asks = (jsonDecode(neveraAsks) as List).cast<Map<String, dynamic>>();
  final outside = (jsonDecode(neveraOutside) as List)
      .cast<Map<String, dynamic>>();
  final zones = (jsonDecode(neveraZones) as List).cast<Map<String, dynamic>>();
  late StillFrame frame;
  late Nevera scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('nevera');
    scene = frame.scene as Nevera;
  });
  final rows = <String>[];

  test('the fixture holds the asks of the 12 recorded runs and of the app\'s 8 plays, and the people outside', () {
    expect(asks.where((a) => a['moved'] != true), isNotEmpty);
    expect(asks.where((a) => a['moved'] == true), isNotEmpty);
    expect(outside, isNotEmpty);
    rows.add(
      'asks: ${asks.where((a) => a['moved'] != true).length} of the recorded runs, '
      '${asks.where((a) => a['moved'] == true).length} of the app\'s plays; ${outside.length} sets of people outside',
    );
  });

  test('the zones of every state the preview baked are nevera-set.html\'s', () {
    expect(zones, isNotEmpty);
    for (final z in zones) {
      final k = z['key'] as String, mine = scene.zonesOf(k);
      var sum = 0;
      for (var i = 0; i < mine.zone.length; i++) {
        sum = (sum * 31 + mine.zone.codeUnitAt(i)) % 1000000007;
      }
      expect(sum, z['zone'], reason: '$k: the zone string');
      expect(mine.outside.length, z['outside'], reason: '$k: the outside');
      expect(
        mine.outside.fold<int>(0, (a, b) => a + b),
        z['outsideSum'],
        reason: '$k: the outside',
      );
      rows.add('zones $k: equal (${mine.outside.length} pixels of outside)');
    }
  });

  // the asked thing taken out of W (nevera_asks_ref.mjs `take`), or a person not shown
  void take(Map<String, dynamic> w, String k) {
    switch (k) {
      case 'leche' || 'queso' || 'mantequilla':
        final h = (w['nev'] as Map)['h'] as List;
        for (var i = 0; i < h.length; i++) {
          if (h[i] is Map && (h[i] as Map)['k'] == k) h[i] = null;
        }
      case 'cesta':
        w['cesta'] = null;
      default:
        final named = ((w['cosas'] as List?) ?? const []).where(
          (o) => o is Map && o['id'] == k,
        );
        if (named.isNotEmpty) {
          for (final o in named) {
            (o as Map)['vis'] = 0;
          }
        } else {
          ((w['gente'] as Map)[k] as Map)['vis'] = 0;
        }
    }
  }

  for (final a in asks) {
    final name = '${a['story']} ${a['plan']} ${a['path']} ${a['spot']}';
    test(
      '$name: the box and the hand the preview gives; the thing no further outside it',
      () {
        Map<String, dynamic> moved() => a['moved'] == true
            ? jsonDecode(jsonEncode(a['W'])) as Map<String, dynamic>
            : neveraPreviewRemapW(
                neveraPreviewBaseW(
                  scene.fresh(const {}),
                  a['W'] as Map<String, dynamic>,
                ),
                scene.sheet,
                story: a['story'] as String,
              );
        final cam = scene.CAM['wide']!,
            F = a['F'] as int,
            k = a['spot'] as String;
        final w = moved();
        if (a['moved'] == true && w['spot'] == null) w['spot'] = k;
        frame.draw(w, F: F, cam: cam, tick: 0, allSigns: false);
        final s = frame.host.signs;
        final box = s.respBox(k) ?? s.hintBoxOf(k) ?? s.bx(k);
        final hand = s.handPoint();
        expect(box, a['box'], reason: '$name: the box');
        expect(
          hand == null ? null : [_round(hand[0]), _round(hand[1])],
          a['hand'],
          reason: '$name: the hand',
        );
        var line = '$name: box $box, hand ${a['hand']}';
        if (a['drawn'] != null) {
          final p = [...frame.picture];
          final wo = moved();
          if (a['moved'] == true && wo['spot'] == null) wo['spot'] = k;
          take(wo, k);
          frame.draw(wo, F: F, cam: cam, tick: 0, allSigns: false);
          final q = frame.picture;
          var drawn = 0, out = 0;
          for (var i = 0; i < p.length; i++) {
            if ((p[i] & 0xFFFFFF) == (q[i] & 0xFFFFFF)) continue;
            drawn++;
            final x = i % 240, y = i ~/ 240;
            if (!(x >= box[0] &&
                x < box[0] + box[2] &&
                y >= box[1] &&
                y < box[1] + box[3])) {
              out++;
            }
          }
          line +=
              '; drawn $drawn (preview ${a['drawn']}), outside $out (preview ${a['outside']})';
          // the canvas's smoothing of a turned sprite's edges (decided, order 05) gives a few pixels either way
          final slack = (drawn * .03).ceil() + 2;
          expect(
            out,
            lessThanOrEqualTo((a['outside'] as int) + slack),
            reason: line,
          );
          expect(
            (drawn - (a['drawn'] as int)).abs(),
            lessThanOrEqualTo(slack),
            reason: line,
          );
        }
        rows.add(line);
      },
    );
  }

  test('whoever stands outside the window: no pixel of them outside the opening at any step\'s end of any run', () {
    var all = 0;
    for (final o in outside) {
      final w = jsonDecode(jsonEncode(o['W'])) as Map<String, dynamic>;
      final none = jsonDecode(jsonEncode(o['W'])) as Map<String, dynamic>
        ..['gente'] = <String, dynamic>{};
      final cam = scene.CAM['wide']!, F = o['F'] as int;
      frame.draw(none, F: F, cam: cam, tick: 0, allSigns: false);
      final q = [...frame.picture];
      frame.draw(w, F: F, cam: cam, tick: 0, allSigns: false);
      final p = frame.picture, open = scene.zonesOf(scene.setKey(w)).outside;
      var drawn = 0, beyond = 0;
      for (var i = 0; i < p.length; i++) {
        if ((p[i] & 0xFFFFFF) == (q[i] & 0xFFFFFF)) continue;
        drawn++;
        if (!open.contains(i)) beyond++;
      }
      final name = '${o['story']} ${o['plan']} ${o['path']}';
      expect(beyond, 0, reason: '$name: outside the opening');
      expect(
        drawn,
        o['drawn'],
        reason: '$name: the preview draws ${o['drawn']}',
      );
      all += drawn;
    }
    rows.add(
      'people outside: ${outside.length} sets, $all pixels drawn, 0 outside the opening',
    );
  });
  tearDownAll(() => report('nevera-asks', rows));
}
