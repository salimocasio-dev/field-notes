// El banco de la plaza's paths, as El mostrador's (test/support/mostrador_paths.dart: drawsOf, letterPlan): every
// combination of a story's random draws, the letters of the plan that play its two decisions one way or the other, and
// one play of a story on the real scene with its rules watched (playPlaza). Used by test/plaza_stories_test.dart (a part
// of the paths) and tool/plaza_paths_test.dart (all).
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Scene;
import 'package:coqui_scenes/coqui_scenes.dart'
    show SetScene, loadSheet, sceneRegistry;
import 'package:feature_story/src/play/play.dart';
import 'package:flutter/services.dart';

import '../../tool/disk_course.dart';
import '../../tool/tool_progress.dart';
import '../real_scene.dart';
import 'mostrador_paths.dart' show letterPlan;
import 'plaza_rules.dart';

export 'mostrador_paths.dart' show drawsOf, letterPlan;

const List<String> plazaStories = [
  'mucho-gusto',
  'de-donde-eres',
  'hablo-espanol',
];

class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

/// One play of [story] on the real scene ([make]: the registry's factory), with [draws] fixed and the plan as
/// [letters]; with [watch] the scene's rules are checked at every act's end and at the end (`_rules` in the trace).
Future<Map<String, dynamic>> playPlaza(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  PlazaRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = PlazaRules(s)..wrap();
      return s;
    },
    course: course,
    progress: ToolProgress(),
    startFrog: startFrogOf,
    frogShadow: frogShadowOf,
  );
  if (rules != null) {
    rules!.check('the end');
    t['_rules'] = rules;
  }
  return t;
}

/// The two letters of the plan the story's two decisions take: found by playing it with one `w` at each place in turn.
Future<List<int>> plazaDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playPlaza(
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

/// Plays [jobs] (`(d, pat)`) of [story] on the real `plaza` scene with rules watched, across worker isolates, and
/// returns their [plazaSummary] maps in the order of [jobs].
Future<List<Map<String, dynamic>>> playPlazaSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<({Map<String, String> d, String pat})> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File('${root.path}/docs/proyecto/pixel/plaza-sheet.json')
      .readAsStringSync();
  final workers = math.min(
    jobs.length,
    math.max(1, Platform.numberOfProcessors),
  );
  final slices = <List<({Map<String, String> d, String pat})>>[
    for (var w = 0; w < workers; w++) [],
  ];
  for (var i = 0; i < jobs.length; i++) {
    slices[i % workers].add(jobs[i]);
  }
  final parts = await Future.wait([
    for (final slice in slices)
      Isolate.run(() async {
        await loadSheet('plaza', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) => sceneRegistry['plaza']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playPlaza(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
          );
          out.add(plazaSummary(id, j.d, j.pat, t));
        }
        return out;
      }),
  ]);
  final res = List<Map<String, dynamic>?>.filled(jobs.length, null);
  for (var w = 0; w < workers; w++) {
    for (var k = 0; k < parts[w].length; k++) {
      res[k * workers + w] = parts[w][k];
    }
  }
  return res.cast<Map<String, dynamic>>();
}

/// What a play gives a report: its story, draws, pattern, end, lost, errors, how many checks, what broke a rule and
/// what the rules counted apart.
Map<String, dynamic> plazaSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as PlazaRules;
  return {
    'story': id,
    'draws': draws,
    'pattern': pattern,
    'decisionsPlayed': [
      for (final c in t['choices'] as List)
        if (c['kind'] == 'decide') c['letter'],
    ].join(),
    'end': t['end'],
    'lost': t['lost'],
    'errors': t['errors'],
    'checks': rules.checked,
    'breaches': [
      for (final b in rules.breaches)
        {'at': b.at, 'rule': b.rule, 'what': b.what},
    ],
    'notes': [
      for (final b in rules.notes) {'at': b.at, 'rule': b.rule, 'what': b.what},
    ],
  };
}
