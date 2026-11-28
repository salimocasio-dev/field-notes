// La cuenta's paths: every fixed draw combination (9 for el-postre, 4 for la-cuenta-por-favor, 4 for
// buenas-noches -> 17 x 4 = 68 fixed paths) plus seeded multi-round plays covering all guest deals and totals,
// with worker-isolate parallel execution and CuentaRules checked at every act's end.
import 'dart:convert';
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
import 'cuenta_rules.dart';

export 'mostrador_paths.dart' show letterPlan;

const List<String> cuentaStories = [
  'el-postre',
  'la-cuenta-por-favor',
  'buenas-noches',
];

/// Every distinct fixed-draw assignment for a cuenta story (`da x db` for 93, `ca x cb` for 94, `pa x pb` for 95).
List<Map<String, String>> cuentaDrawsOf(Map<String, dynamic> story) {
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
      if (other != null && ops.toSet().length < 2) {
        throw StateError(
          'draw "$name" sets other "$other" with fewer than 2 distinct options: $ops',
        );
      }
      if (cur.any((x) => x.containsKey(name))) {
        return cur;
      }
      return [
        for (final x in cur)
          for (final o in ops)
            {...x, name: o, ?other: ops.firstWhere((y) => y != o)},
      ];
    }
    if (v['if'] is String) {
      final seen = <String>{};
      final out = <Map<String, String>>[];
      for (final x in [...walk(v['then'], cur), ...walk(v['else'], cur)]) {
        final sig = jsonEncode(
          Map.fromEntries(
            x.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
          ),
        );
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

Future<Map<String, dynamic>> playCuenta(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
  int seed = 1,
}) async {
  final allRules = <CuentaRules>[];
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: seed,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) {
        final r = CuentaRules(s)..wrap();
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

Future<List<int>> cuentaDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playCuenta(
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

typedef CuentaJob = ({Map<String, String> d, String pat, int seed});

Future<List<Map<String, dynamic>>> playCuentaSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<CuentaJob> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/coqui/packages/core/coqui_scenes/assets/sheets/cuenta-sheet.json',
  ).readAsStringSync();
  final workers = math.min(
    jobs.length,
    math.max(1, Platform.numberOfProcessors),
  );
  final slices = <List<CuentaJob>>[for (var w = 0; w < workers; w++) []];
  for (var i = 0; i < jobs.length; i++) {
    slices[i % workers].add(jobs[i]);
  }
  final parts = await Future.wait([
    for (final slice in slices)
      Isolate.run(() async {
        await loadSheet('cuenta', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['cuenta']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playCuenta(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
            seed: j.seed,
          );
          final allRules = t['_rules'] as List<CuentaRules>;
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
