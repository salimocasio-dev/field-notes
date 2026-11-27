// La ropa's paths: every reachable combination of each story's random draws (12 for la-ropa-seca, 24 reparte x 4 qa
// x 3/2 qb = 960 paths for mi-sombrero, 64 for se-pone-y-se-quita -> 48 + 960 + 256 = 1,264 total paths), the letters
// of the plan that play its two decisions one way or the other, and worker-isolate parallel runner with RopaRules
// checked at every act.
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
import 'ropa_rules.dart';

export 'mostrador_paths.dart' show letterPlan;

const List<String> ropaStories = [
  'la-ropa-seca',
  'mi-sombrero',
  'se-pone-y-se-quita',
];

List<Map<String, String>> _permutations(List<String> names, List<String> ops) {
  final out = <Map<String, String>>[];
  void deal(int i, Map<String, String> got) {
    if (i == names.length) {
      out.add(Map.of(got));
      return;
    }
    for (final o in ops) {
      if (got.values.contains(o)) continue;
      got[names[i]] = o;
      deal(i + 1, got);
      got.remove(names[i]);
    }
  }

  deal(0, {});
  return out;
}

/// Every reachable combination of a ropa story's random draws (for `mi-sombrero`, pairs each `reparte` order and
/// `qa` with the valid `qb` options for [pattern], accounting for the deterministic wrong pick `x` when Round A is `w`).
List<Map<String, String>> ropaDrawsOf(
  Map<String, dynamic> story, {
  String pattern = 'rr',
}) {
  final id = story['id'] as String?;
  if (id == 'mi-sombrero') {
    const items = ['sombrero', 'chancletas', 'gafas', 'traje'];
    final orders = _permutations(['oa', 'ob', 'oc', 'od'], items);
    final wrongA = pattern.startsWith('w');
    final out = <Map<String, String>>[];
    for (final ord in orders) {
      for (final qa in items) {
        // In Ropa.cosas, `sombrero` precedes `chancletas` precedes `gafas` precedes `traje`.
        final x = wrongA
            ? (qa == 'sombrero' ? 'chancletas' : 'sombrero')
            : null;
        for (final qb in items) {
          if (qb == qa || qb == x) continue;
          out.add({...ord, 'qa': qa, 'qb': qb});
        }
      }
    }
    return out;
  }

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
      return [
        for (final x in cur)
          for (final o in ops) {...x, name: o},
      ];
    }
    if (v['reparte'] is List) {
      final names = (v['reparte'] as List).cast<String>();
      final ops = [for (final o in v['options'] as List) '$o'];
      final perms = _permutations(names, ops);
      return [
        for (final x in cur)
          for (final p in perms) {...x, ...p},
      ];
    }
    if (v['if'] is String) {
      final cond = (v['if'] as String).trim();
      final eq = cond.indexOf('=');
      if (eq > 0) {
        final k = cond.substring(0, eq), val = cond.substring(eq + 1);
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
      }
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

Future<Map<String, dynamic>> playRopa(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  RopaRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = RopaRules(s)..wrap();
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

Future<List<int>> ropaDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playRopa(
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

Future<List<Map<String, dynamic>>> playRopaSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<({Map<String, String> d, String pat})> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/coqui/packages/core/coqui_scenes/assets/sheets/ropa-sheet.json',
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
        await loadSheet('ropa', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) => sceneRegistry['ropa']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playRopa(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
          );
          out.add(ropaSummary(id, j.d, j.pat, t));
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

Map<String, dynamic> ropaSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as RopaRules;
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
