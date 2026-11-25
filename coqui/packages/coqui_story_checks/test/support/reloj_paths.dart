// El reloj's paths, as El banco de la plaza's (test/support/plaza_paths.dart): every combination of a story's random
// draws, the letters of the plan that play its two decisions one way or the other, and one play of a story on the real
// scene with its rules watched (playReloj). Used by test/reloj_stories_test.dart and tool/reloj_paths_test.dart.
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
import 'reloj_rules.dart';

export 'mostrador_paths.dart' show letterPlan;

const List<String> relojStories = ['que-hora-es', 'y-media', 'bingo'];

/// Every reachable combination of a reloj story's random draws, evaluating
/// `if: "var=val"` branches against the values already drawn.
List<Map<String, String>> relojDrawsOf(Map<String, dynamic> story) {
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
      return [
        for (final x in cur)
          for (final o in ops)
            {...x, name: o, ?other: ops.firstWhere((y) => y != o)},
      ];
    }
    if (v['if'] is String) {
      final cond = v['if'] as String;
      final eq = cond.indexOf('=');
      if (eq > 0) {
        final k = cond.substring(0, eq), val = cond.substring(eq + 1);
        final hasKey = cur.any((x) => x.containsKey(k));
        if (!hasKey) return cur;
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
      return cur;
    }
    return cur;
  }

  return walk([story['beats'], story['final']], [{}]);
}

/// A minimal subset of [relojDrawsOf] that visits every reachable Round A tuple
/// `(ha, da, oa, ka)`, every reachable Round B tuple `(hb, db, ob, kb)`, and
/// every reachable `(ha, hb)` pair for `que-hora-es`, and returns all draws
/// unchanged for `y-media` and `bingo`.
List<Map<String, String>> relojRoundCoverDraws(Map<String, dynamic> story) {
  final all = relojDrawsOf(story);
  if (story['id'] != 'que-hora-es') return all;
  final seenA = <String>{}, seenB = <String>{}, seenPair = <String>{};
  final out = <Map<String, String>>[];
  for (final d in all) {
    final ka = '${d['ha']}|${d['da']}|${d['oa']}|${d['ka']}';
    final kb = '${d['hb']}|${d['db']}|${d['ob']}|${d['kb']}';
    final kp = '${d['ha']}|${d['hb']}';
    if (seenA.add(ka) | seenB.add(kb) | seenPair.add(kp)) {
      out.add(d);
    }
  }
  return out;
}

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
Future<Map<String, dynamic>> playReloj(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  RelojRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = RelojRules(s)..wrap();
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
Future<List<int>> relojDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playReloj(
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

/// Plays [jobs] (`(d, pat)`) of [story] on the real `reloj` scene with rules watched, across worker isolates, and
/// returns their [relojSummary] maps in the order of [jobs].
Future<List<Map<String, dynamic>>> playRelojSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<({Map<String, String> d, String pat})> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File('${root.path}/docs/proyecto/pixel/reloj-sheet.json')
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
        await loadSheet('reloj', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) => sceneRegistry['reloj']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playReloj(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
          );
          out.add(relojSummary(id, j.d, j.pat, t));
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
Map<String, dynamic> relojSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as RelojRules;
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
