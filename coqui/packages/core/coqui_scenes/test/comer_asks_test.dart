// A comer's asks, every one: at each ask and decide step of every recorded run of its three stories (right, wrong and
// alternate), and at each ask picture of the app's two plays of each (coqui/app tool/gate_a_frames_test.dart, the story's
// W at that moment written with ASKW=yes; its asked thing the hint's, else the one the learner touches), the answer cards'
// place (W.respEn, set by CARTAS as the frame is drawn), the hint frame's box and the hint hand's point the Dart scene
// gives for the asked thing equal what comer-preview.html gives (tool/comer_asks_ref.mjs: juego.js respBox, else the
// preview's hb: the sheet's hint box, else the scene's box; the hand respBox's foot, else the sheet's hand, else the box's
// middle; for the run's W before the step moved by the preview's rule, or the play's W as it is), and the thing's drawn
// pixels lie outside that box no more than the preview's do (the old file's own: a person's box, the sugar bowl's lid).
import 'dart:convert';

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/comer/comer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/comer_preview_remap.dart';
import 'support/fixtures/comer_asks_fixture.dart';
import 'support/report.dart';
import 'support/sheet_bundle.dart';

int _round(num v) => (v + .5).floor();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final asks = (jsonDecode(comerAsks) as List).cast<Map<String, dynamic>>();
  late StillFrame frame;
  late Comer scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('comer');
    scene = frame.scene as Comer;
  });
  final rows = <String>[];

  test('the fixture holds the asks of the 9 recorded runs and of the app\'s 6 plays', () {
    expect(asks.where((a) => a['moved'] != true), isNotEmpty);
    expect(asks.where((a) => a['moved'] == true), isNotEmpty);
    rows.add(
      'asks: ${asks.where((a) => a['moved'] != true).length} of the recorded runs, '
      '${asks.where((a) => a['moved'] == true).length} of the app\'s plays; '
      '${asks.where((a) => a['card'] == true).length} of them answer cards',
    );
  });

  // the asked thing taken out of W (comer_asks_ref.mjs): a thing by its id, else a person not shown
  void take(Map<String, dynamic> w, String k) {
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

  for (final a in asks) {
    final name = '${a['story']} ${a['plan']} ${a['path']} ${a['spot']}';
    test(
      '$name: the cards\' place, the box and the hand the preview gives; the thing no further outside it',
      () {
        Map<String, dynamic> moved() => a['moved'] == true
            ? jsonDecode(jsonEncode(a['W'])) as Map<String, dynamic>
            : comerPreviewRemapW(
                comerPreviewBaseW(
                  scene.fresh(const {}),
                  a['W'] as Map<String, dynamic>,
                ),
                scene,
                story: a['story'] as String,
              );
        final cam = scene.CAM['wide']!,
            F = a['F'] as int,
            k = a['spot'] as String;
        final w = moved();
        if (a['moved'] == true && w['spot'] == null) w['spot'] = k;
        frame.draw(w, F: F, cam: cam, tick: 0, allSigns: false);
        final s = frame.host.signs;
        if (w['resp'] != null) {
          expect(w['respEn'], a['respEn'], reason: '$name: the cards\' place');
        }
        final box = s.respBox(k) ?? s.hintBoxOf(k) ?? s.bx(k);
        final hand = s.handPoint();
        expect(box, a['box'], reason: '$name: the box');
        expect(
          hand == null ? null : [_round(hand[0]), _round(hand[1])],
          a['hand'],
          reason: '$name: the hand',
        );
        var line = '$name: box $box, hand ${a['hand']}';
        if (a['respEn'] != null) line += ', cards at ${a['respEn']}';
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
  tearDownAll(() => report('comer-asks', rows));
}
