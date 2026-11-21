// La mesa's asks, every one: at each ask and decide step of every recorded run of its four files (right, wrong and
// alternate), and at each ask picture of the app's two plays of each (coqui/app tool/gate_a_frames_test.dart, the story's
// W at that moment written with ASKW=yes; its asked thing the hint's, else the one the learner touches), the hint frame's
// box and the hint hand's point the Dart scene gives for the asked thing equal what mesa-preview.html gives
// (tool/mesa_asks_ref.mjs: juego.js respBox, else the sheet's hint box, else the scene's box, for the run's W before the
// step moved by the preview's rule, or the play's W as it is), and the thing's drawn pixels lie outside that box no more
// than the preview's do (the old file's own: a person's box, the pot's steam, what someone holds up).
import 'dart:convert';

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/mesa/mesa.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/mesa_asks_fixture.dart';
import 'support/mesa_preview_remap.dart';
import 'support/report.dart';
import 'support/sheet_bundle.dart';

int _round(num v) => (v + .5).floor();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final asks = (jsonDecode(mesaAsks) as List).cast<Map<String, dynamic>>();
  late StillFrame frame;
  late Mesa scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('mesa');
    scene = frame.scene as Mesa;
  });
  final rows = <String>[];

  test(
    'the fixture holds the asks of the recorded runs and of the app\'s plays',
    () {
      expect(asks.where((a) => a['moved'] != true), isNotEmpty);
      expect(asks.where((a) => a['moved'] == true), isNotEmpty);
    },
  );

  // the asked thing taken out of W (mesa_asks_ref.mjs `take`), or a person not shown
  void take(Map<String, dynamic> w, String k) {
    final g = w['gente'] as Map;
    switch (k) {
      case 'platos' || 'tazas' || 'bandeja' || 'comidas' || 'vasos':
        (w['mostrador'] as Map)[k] = 0;
      case 'muestra':
        w['muestra'] = null;
      case 'ofrece':
        (g['abuela'] as Map)['ofrece'] = null;
      case 'bebe':
        (g['mama'] as Map)['bebe'] = 0;
      case 'perro':
        w['perro'] = null;
      case 'olla':
        (w['estufa'] as Map)['olla'] = 0;
      default:
        (g[k] as Map)['vis'] = 0;
    }
  }

  for (final a in asks) {
    final name = '${a['story']} ${a['plan']} ${a['path']} ${a['spot']}';
    test(
      '$name: the box and the hand the preview gives; the thing no further outside it',
      () {
        Map<String, dynamic> moved() => a['moved'] == true
            ? jsonDecode(jsonEncode(a['W'])) as Map<String, dynamic>
            : mesaPreviewRemapW(
                mesaPreviewBaseW(
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
          take(wo, k);
          frame.draw(wo, F: F, cam: cam, tick: 0, allSigns: false);
          final q = frame.picture;
          var drawn = 0, outside = 0;
          for (var i = 0; i < p.length; i++) {
            if ((p[i] & 0xFFFFFF) == (q[i] & 0xFFFFFF)) continue;
            drawn++;
            final x = i % 240, y = i ~/ 240;
            if (!(x >= box![0] &&
                x < box[0] + box[2] &&
                y >= box[1] &&
                y < box[1] + box[3])) {
              outside++;
            }
          }
          line +=
              '; drawn $drawn (preview ${a['drawn']}), outside $outside (preview ${a['outside']})';
          // the canvas's smoothing of a turned sprite's edges (decided, order 05) gives a few pixels either way
          final slack = (drawn * .03).ceil() + 2;
          expect(
            outside,
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
  tearDownAll(() => report('mesa-asks', rows));
}
