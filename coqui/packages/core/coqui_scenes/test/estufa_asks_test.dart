// La estufa's asks, every one: at each ask and decide step of every recorded run of its four stories (right, wrong and
// alternate), and at each ask picture of the app's two plays of each (coqui/app tool/gate_a_frames_test.dart, the story's
// W at that moment written with ASKW=yes; its asked thing the hint's, else the one the learner touches), the hint frame's
// box and the hint hand's point the Dart scene gives for the asked thing equal what estufa-preview.html gives
// (tool/estufa_asks_ref.mjs: juego.js respBox, else the sheet's hint box, else the scene's box, for the run's W before the
// step moved by the preview's rule, or the play's W as it is), and the thing's drawn pixels lie outside that box no more
// than the preview's do (the old file's own: a person's box, a pot's steam).
// One fault of the old file is fixed (order 38b, decided): the old box of a piece on abuela's plate is its kind's half
// of the plate, but the pieces are drawn by their order on it, so the egg's ask after Mamá has the drumstick
// (el-pollo-y-el-huevo beats.27, and the app's plays' asks and retries of it) framed and tapped the right half while the
// egg lay alone on the left.
// There the box and the hand are the preview's moved to the half the egg is drawn in, and the egg lies inside its box but
// for an eighth of it at the most.
import 'dart:convert';

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/estufa/estufa.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/estufa_preview_remap.dart';
import 'support/fixtures/estufa_asks_fixture.dart';
import 'support/report.dart';
import 'support/sheet_bundle.dart';

int _round(num v) => (v + .5).floor();

/// A piece on abuela's plate drawn in the other half than its kind's old box (the egg alone, or first): the Dart box is
/// the half it is drawn in, the preview's moved by this many pixels (estufa.dart `_pieceBox`); null for every other ask.
int? _followsPiece(Map<String, dynamic> a) {
  final kind = {'pzpollo': 'muslo', 'pzhuevo': 'frito'}[a['spot']];
  if (kind == null) return null;
  final items = ((a['W'] as Map)['plata'] as Map)['items'] as List;
  final j = items.indexWhere((o) => (o as Map)['k'] == kind);
  return kind == 'frito' && j == 0
      ? -24
      : kind == 'muslo' && j == 1
      ? 24
      : null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final asks = (jsonDecode(estufaAsks) as List).cast<Map<String, dynamic>>();
  late StillFrame frame;
  late Estufa scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('estufa');
    scene = frame.scene as Estufa;
  });
  final rows = <String>[];

  test('the fixture holds every ask and decide step of the 12 recorded runs (105) and every ask picture of the app\'s 8 '
      'plays but one (95: h-estufa\'s olla_fria is no thing, the step\'s alias touches olla0); 7 of them the egg alone on '
      'the plate', () {
    expect(asks.where((a) => a['moved'] != true), hasLength(105));
    expect(asks.where((a) => a['moved'] == true), hasLength(95));
    expect(asks.where((a) => _followsPiece(a) != null), hasLength(7));
  });

  // the asked thing taken out of W (estufa_asks_ref.mjs `take`), or a person not shown
  void take(Map<String, dynamic> w, String k) {
    switch (k) {
      case 'olla0' || 'sarten':
        (w['fuegos'] as List)[0] = <String, dynamic>{};
      case 'olla1':
        (w['fuegos'] as List)[1] = <String, dynamic>{};
      case 'saco' || 'tazon' || 'jarra':
        (w['izq'] as Map)[k] = 0;
      case 'bandeja':
        (w['izq'] as Map)[k] = null;
      case 'pzpollo' || 'pzhuevo':
        final p = w['plata'] as Map;
        final kind = k == 'pzpollo' ? 'muslo' : 'frito';
        p['items'] = [
          for (final o in p['items'] as List)
            if ((o as Map)['k'] != kind) o,
        ];
      default:
        ((w['gente'] as Map)[k] as Map)['vis'] = 0;
    }
  }

  for (final a in asks) {
    final name = '${a['story']} ${a['plan']} ${a['path']} ${a['spot']}';
    test(
      '$name: the box and the hand the preview gives; the thing no further outside it',
      () {
        Map<String, dynamic> moved() => a['moved'] == true
            ? jsonDecode(jsonEncode(a['W'])) as Map<String, dynamic>
            : estufaPreviewRemapW(
                estufaPreviewBaseW(
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
        frame.draw(w, F: F, cam: cam, tick: 0, allSigns: false);
        final s = frame.host.signs;
        final box = s.respBox(k) ?? s.hintBoxOf(k) ?? s.bx(k);
        final hand = s.handPoint();
        final dx = _followsPiece(a), ob = a['box'] as List;
        final oh = a['hand'] as List?;
        expect(
          box,
          dx == null ? ob : [ob[0] + dx, ob[1], ob[2], ob[3]],
          reason: '$name: the box',
        );
        expect(
          hand == null ? null : [_round(hand[0]), _round(hand[1])],
          dx == null || oh == null ? oh : [oh[0] + dx, oh[1]],
          reason: '$name: the hand',
        );
        var line =
            '$name: box $box${dx == null ? '' : ' (the preview: ${a['box']})'}, hand ${a['hand']}';
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
            if (!(x >= box[0] &&
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
            lessThanOrEqualTo(
              // (the egg alone, its box moved: 38 of its 358 pixels outside, its salt's glints and its rim, against 346)
              dx == null ? (a['outside'] as int) + slack : drawn ~/ 8,
            ),
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
  tearDownAll(() => report('estufa-asks', rows));
}
