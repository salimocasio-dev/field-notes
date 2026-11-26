// La sombrilla's paths: every reachable combination of each story's random draws (9 for la-cara, 9 for
// la-cabeza-y-los-brazos, 18 for me-duele -> 36 + 36 + 72 = 144 total paths), the letters of the plan that play its
// two decisions one way or the other, and worker-isolate parallel runner with SombrillaRules checked at every act.
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
import 'sombrilla_rules.dart';

export 'mostrador_paths.dart' show letterPlan;

const List<String> sombrillaStories = [
  'la-cara',
  'la-cabeza-y-los-brazos',
  'me-duele',
];

/// Every reachable combination of a sombrilla story's random draws.
List<Map<String, String>> sombrillaDrawsOf(Map<String, dynamic> story) {
  List<Map<String, String>> walk(Object? v, List<Map<String, String>> cur) {
    if (v is List) {
      var acc = cur;
      for (final item in v) {
        acc = walk(item, acc);
      }
      return acc;
    }
    if (v is! Map) return cur;
    if (v['draw'] is String) {
      final name = v['draw'] as String;
      final ops = [for (final o in v['options'] as List) '$o'];
      final other = v['other'] as String?;
      if (other != null && ops.length < 2) {
        throw StateError(
          'draw "$name" sets other "$other" with fewer than 2 options: $ops',
        );
      }
      return [
        for (final x in cur)
          for (final o in ops)
            {...x, name: o, ?other: ops.firstWhere((y) => y != o)},
      ];
    }
    if (v['if'] is String) {
      final cond = (v['if'] as String).trim();
      final m = RegExp(r'^([a-zA-Z0-9_]+)=([^=].*)$').firstMatch(cond);
      if (m != null) {
        final k = m.group(1)!, val = m.group(2)!;
        if (cur.any((x) => x.containsKey(k))) {
          final yes = [
            for (final x in cur)
              if (x[k] == val) x,
          ];
          final no = [
            for (final x in cur)
              if (x[k] != val) x,
          ];
          return [
            if (yes.isNotEmpty) ...walk(v['then'], yes),
            if (no.isNotEmpty) ...walk(v['else'], no),
          ];
        }
      } else {
        final draws = {for (final x in cur) ...x.keys};
        if (draws.any(
          (k) => RegExp('\\b${RegExp.escape(k)}\\b').hasMatch(cond),
        )) {
          throw StateError(
            'unsupported if condition on drawn variable: "$cond"',
          );
        }
      }
      // Non-drawn condition (e.g. `ok`, `lost=0`): walk both branches and
      // return the deduplicated union so nested draws are never missed.
      final seen = <String>{};
      final out = <Map<String, String>>[];
      for (final x in [...walk(v['then'], cur), ...walk(v['else'], cur)]) {
        final keys = x.keys.toList()..sort();
        final sig = [for (final k in keys) '$k=${x[k]}'].join('|');
        if (seen.add(sig)) out.add(x);
      }
      return out;
    }
    return cur;
  }

  return walk([story['beats'], story['final']], [{}]);
}

class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

Future<Map<String, dynamic>> playSombrilla(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  SombrillaRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = SombrillaRules(s)..wrap();
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

Future<List<int>> sombrillaDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playSombrilla(
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

Future<List<Map<String, dynamic>>> playSombrillaSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<({Map<String, String> d, String pat})> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/coqui/packages/core/coqui_scenes/assets/sheets/sombrilla-sheet.json',
  ).readAsStringSync();
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
        await loadSheet('sombrilla', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['sombrilla']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playSombrilla(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
          );
          out.add(sombrillaSummary(id, j.d, j.pat, t));
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

Map<String, dynamic> sombrillaSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as SombrillaRules;
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
  };
}
