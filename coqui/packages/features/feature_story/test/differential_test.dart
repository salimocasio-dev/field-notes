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

import '../tool/differential.dart';
import '../tool/disk_course.dart';
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

  group('the recorded runs, on the real El frente', () {
    final frente = {
      for (final r in runs)
        if (r['scene'] == 'frente') r['story'] as String,
    };
    for (final s in frente) {
      test(
        '$s: the three plans, whole',
        () async {
          for (final plan in ['right', 'wrong', 'alternate']) {
            expect(
              await compareWithScene(
                course,
                s,
                plan,
                trazas,
                (rng) => realScene('frente', rng),
              ),
              isNull,
              reason: '$s $plan',
            );
          }
        },
        skip: realScenesReady
            ? false
            : 'El frente is not in the scene registry yet (order 14)',
      );
    }
  });
}
