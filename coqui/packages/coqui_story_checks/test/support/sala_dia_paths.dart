// La sala, de día's paths: exhaustive/representative fixed-draw combinations across all 3 stories
// (16 for lee-y-escribe, 4 for el-telefono, 20 for por-la-tarde -> 40 x 4 = 160 fixed paths) plus seeded multi-round
// plays, with worker-isolate parallel execution and SalaDiaRules checked at every act's end and at the story's end.
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

import 'mostrador_paths.dart' show letterPlan;
import 'sala_dia_rules.dart';

export 'mostrador_paths.dart' show letterPlan;

const List<String> salaDiaStories = [
  'lee-y-escribe',
  'el-telefono',
  'por-la-tarde',
];

/// Fixed draw assignments covering every child/verb pair (102), escucha/habla pair (103), and ra/om/photo pair (104).
List<Map<String, String>> salaDiaDrawsOf(String storyId) {
  switch (storyId) {
    case 'lee-y-escribe':
      // All 2x2x2x2 = 16 combinations of (qa, wa, qb, wb).
      final out = <Map<String, String>>[];
      for (final qa in const ['luis', 'carmen']) {
        for (final wa in const ['lee', 'escribe']) {
          for (final qb in const ['luis', 'carmen']) {
            for (final wb in const ['lee', 'escribe']) {
              out.add({'qa': qa, 'wa': wa, 'qb': qb, 'wb': wb});
            }
          }
        }
      }
      return out;
    case 'el-telefono':
      // All 2x2 = 4 combinations of (wa, wb).
      final out = <Map<String, String>>[];
      for (final wa in const ['escucha', 'habla']) {
        for (final wb in const ['escucha', 'habla']) {
          out.add({'wa': wa, 'wb': wb});
        }
      }
      return out;
    case 'por-la-tarde':
      // All 2 ra x 2 om x 5 distinct (fa, fb) pairs = 20 combinations covering every photo and every time-of-day pair.
      const photos = [
        'abuelo_lee',
        'abuela_escribe',
        'carmen_juega',
        'luis_lee',
        'abuela_juega',
      ];
      final out = <Map<String, String>>[];
      for (final ra in const ['a', 'b']) {
        for (final om in const ['manana', 'noche']) {
          for (var i = 0; i < photos.length; i++) {
            out.add({
              'ra': ra,
              'om': om,
              'fa': photos[i],
              'fb': photos[(i + 1) % photos.length],
            });
          }
        }
      }
      return out;
    default:
      throw ArgumentError.value(storyId, 'storyId', 'unknown sala_dia story');
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

Future<Map<String, dynamic>> playSalaDia(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
  int seed = 1,
}) async {
  final allRules = <SalaDiaRules>[];
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: seed,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) {
        final r = SalaDiaRules(s)..wrap();
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

Future<List<int>> salaDiaDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playSalaDia(
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

typedef SalaDiaJob = ({Map<String, String> d, String pat, int seed});

Future<List<Map<String, dynamic>>> playSalaDiaSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<SalaDiaJob> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/coqui/packages/core/coqui_scenes/assets/sheets/sala_dia-sheet.json',
  ).readAsStringSync();
  final workers = math.min(
    jobs.length,
    math.max(1, Platform.numberOfProcessors),
  );
  final slices = <List<SalaDiaJob>>[for (var w = 0; w < workers; w++) []];
  for (var i = 0; i < jobs.length; i++) {
    slices[i % workers].add(jobs[i]);
  }
  final parts = await Future.wait([
    for (final slice in slices)
      Isolate.run(() async {
        await loadSheet('sala_dia', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['sala_dia']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playSalaDia(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
            seed: j.seed,
          );
          final allRules = t['_rules'] as List<SalaDiaRules>;
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
