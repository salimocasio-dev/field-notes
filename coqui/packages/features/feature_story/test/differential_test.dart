// The runner against the old page's recorded runs (coqui/ref/trazas/, 51 files, three plans each).
//
// - On a stand-in scene that replays what the old scene did (tool/replay_scene.dart, from test/fixtures/acts/): every one of
//   the 153 runs, the whole trace equal: decisions, marks, lost, ending, the story result, the order of clips, the steps,
//   choices and touches, the number of random draws, the memory, and every time (`t`, virtualMs, the minutes). Only the
//   touches' places on the old screen (x, y) are left out.
// - On the real El frente: the traces of every file that plays on it, all three plans, once its scene is in the registry.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:feature_story/src/play/trace_json.dart' show firstDifference;

import '../tool/differential.dart';
import '../tool/disk_course.dart';
import '../tool/frente_order.dart';
import 'real_scene.dart';

void main() {
  final root = findRoot();
  final trazas = Directory('${root.path}/coqui/ref/trazas');
  final acts = Directory('test/fixtures/acts');
  final runs =
      (jsonDecode(File('${trazas.path}/runs.json').readAsStringSync())['runs']
              as List)
          .cast<Map<String, dynamic>>();
  final stories = {for (final r in runs) r['story'] as String}.toList();
  late DiskCourse course;

  setUpAll(() async {
    course = DiskCourse(root);
    await course.load();
  });

  group('the recorded runs, on a scene that replays the old one', () {
    for (final s in stories) {
      test('$s: the three plans, whole', () async {
        for (final plan in ['right', 'wrong', 'alternate']) {
          expect(
            await compareRun(course, s, plan, acts, trazas),
            isNull,
            reason: '$s $plan',
          );
        }
      });
    }
  });

  // The real El frente (order 14): its sheet puts the frog and the views in the new picture, so the runs are the old ones in
  // everything but time. Two reproduce whole; in the other thirteen the first step that differs is a step after a call of the
  // scene that took less time than the old one: `camGo("casa")` is no move (the sheet's `casa` view is its `wide` one: the
  // old one slid 16 ticks and back 12), or `ir`/`tocar` make one hop fewer (each is 5 ticks and 110 ms: 460 ms) because the
  // frog's spots are nearer in the new picture.
  group('the recorded runs, on the real El frente (order 14)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final frente = {
      for (final r in runs)
        if (r['scene'] == 'frente') r['story'] as String,
    };
    const whole = {'el-bizcocho wrong', 'el-bizcocho alternate'};
    for (final s in frente) {
      test(
        '$s: the three plans: every decision, mark, step, clip, touch, draw and the story result as the old run',
        () async {
          for (final plan in ['right', 'wrong', 'alternate']) {
            // a new scene for each run: the scene keeps its own state
            final scene = await realScene('frente');
            final d = await compareWithScene(
              course,
              s,
              plan,
              trazas,
              (rng) => scene,
              thingOrder: frenteThingOrder,
              startFrog: startFrogOf,
              frogShadow: frogShadowOf,
            );
            final c = lastCompared!;
            expect(
              firstDifference(forTimeless(c.committed), forTimeless(c.trace)),
              isNull,
              reason: '$s $plan',
            );
            if (whole.contains('$s $plan')) {
              expect(d, isNull, reason: '$s $plan whole');
            }
          }
        },
      );
    }
  });
}
