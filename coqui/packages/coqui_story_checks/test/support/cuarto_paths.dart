// El cuarto's paths: exhaustive fixed-draw combinations covering 100% of all draws across all 3 stories
// (6 for buenos-dias -> 24 paths, 4 for a-las-siete -> 16 paths, 16 for se-viste -> 64 paths -> 104 fixed paths)
// plus seeded multi-round plays, with worker-isolate parallel execution and CuartoRules checked at every act's end
// and at the story's end.
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Scene;
import 'package:coqui_scenes/coqui_scenes.dart'
    show SetScene, loadSheet, sceneRegistry;
import 'package:feature_story/feature_story.dart';
import 'package:flutter/services.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'cuarto_rules.dart';
import 'mostrador_paths.dart' show letterPlan;

export 'mostrador_paths.dart' show letterPlan;

const List<String> cuartoStories = ['buenos-dias', 'a-las-siete', 'se-viste'];

/// Fixed draw assignments covering 100% of all draw tuples in stories 96, 97, and 98.
List<Map<String, String>> cuartoDrawsOf(String storyId) {
  switch (storyId) {
    case 'buenos-dias':
      return [
        for (final da in const ['cama', 'almohada', 'silla'])
          for (final gb in const ['1', '2']) {'da': da, 'gb': gb},
      ];
    case 'a-las-siete':
      return [
        for (final da in const ['despierta', 'levanta'])
          for (final db in const ['despierta', 'levanta']) {'da': da, 'db': db},
      ];
    case 'se-viste':
      return [
        for (final ca in const ['camisa', 'zapatos'])
          for (final oa in const ['primero', 'despues'])
            for (final cb in const ['sombrero', 'reloj'])
              for (final ob in const ['primero', 'despues'])
                {'ca': ca, 'oa': oa, 'cb': cb, 'ob': ob},
      ];
    default:
      throw ArgumentError.value(storyId, 'storyId', 'unknown cuarto story');
  }
}

class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

Future<Map<String, dynamic>> playCuarto(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
  int seed = 1,
}) async {
  final allRules = <CuartoRules>[];
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: seed,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) {
        final r = CuartoRules(s)..wrap();
        allRules.add(r);
      }
      return s;
    },
    course: course,
    progress: ToolProgress(),
    startFrog: startFrogOf,
    frogShadow: frogShadowOf,
  );
  if (allRules.isNotEmpty) {
    allRules.last.check('the end');
    t['_rules'] = allRules;
  }
  return t;
}

Future<List<int>> cuartoDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playCuarto(
      course,
      make,
      story,
      const {},
      (List.filled(16, 'r')..[i] = 'w').join(),
    );
    final ch = [
      for (final c in t['choices'] as List)
        if (c['kind'] == 'decide') c['letter'],
    ];
    for (var k = 0; k < ch.length; k++) {
      if (ch[k] == 'w' && at.length == k) at.add(i);
    }
  }
  return at;
}

typedef CuartoJob = ({Map<String, String> d, String pat, int seed});

Future<List<Map<String, dynamic>>> playCuartoSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<CuartoJob> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/coqui/packages/core/coqui_scenes/assets/sheets/cuarto-sheet.json',
  ).readAsStringSync();
  final workers = math.min(
    jobs.length,
    math.max(1, Platform.numberOfProcessors),
  );
  final slices = <List<CuartoJob>>[for (var w = 0; w < workers; w++) []];
  for (var i = 0; i < jobs.length; i++) {
    slices[i % workers].add(jobs[i]);
  }
  final parts = await Future.wait([
    for (final slice in slices)
      Isolate.run(() async {
        await loadSheet('cuarto', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['cuarto']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playCuarto(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
            seed: j.seed,
          );
          final allRules = t['_rules'] as List<CuartoRules>;
          var checked = 0;
          final breaches = <Map<String, String>>[];
          for (final r in allRules) {
            checked += r.checked;
            for (final b in r.breaches) {
              breaches.add({'at': b.at, 'rule': b.rule, 'what': b.what});
            }
          }
          out.add({
            'story': id,
            'draws': j.d,
            'seed': j.seed,
            'pattern': j.pat,
            'decisionsPlayed': [
              for (final c in t['choices'] as List)
                if (c['kind'] == 'decide') c['letter'],
            ].join(),
            'end': t['end'],
            'lost': t['lost'],
            'errors': t['errors'],
            'checks': checked,
            'breaches': breaches,
          });
        }
        return out;
      }),
  ]);
  return [for (final p in parts) ...p];
}
