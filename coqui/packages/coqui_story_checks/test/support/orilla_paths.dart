// La orilla's paths: every reachable combination of each story's random draws, the letters of the plan that play
// its two decisions one way or the other, and worker-isolate parallel runner with OrillaRules checked at every act.
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
import 'orilla_rules.dart';

export 'mostrador_paths.dart' show letterPlan;

const List<String> orillaStories = ['la-playa', 'flota', 'puedo'];

/// Every reachable combination of an orilla story's random draws.
List<Map<String, String>> orillaDrawsOf(Map<String, dynamic> story) {
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
        if (!cur.any((x) => x.containsKey(k))) return cur;
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

/// Round-cover draws: for `flota` (24×24 = 576 draws) returns 24 draws covering 100% of Round A and Round B tuples;
/// for `puedo` (48×48 = 2,304 draws) returns 48 draws covering 100% of Round A and Round B tuples; for `la-playa`
/// (4 draws) returns all 4 draws.
List<Map<String, String>> orillaRoundCoverDraws(Map<String, dynamic> story) {
  final id = story['id'] as String?;
  if (id == 'flota') {
    const cols = ['rojo', 'azul', 'amarillo'];
    const es = ['1', '2'];
    const ords = ['fn', 'nf'];
    const sides = ['bote_a', 'bote_b'];
    final tuples = <({String f, String e, String o, String k, String j})>[
      for (final f in cols)
        for (final e in es)
          for (final o in ords)
            for (final k in sides)
              (f: f, e: e, o: o, k: k, j: k == 'bote_a' ? 'bote_b' : 'bote_a'),
    ];
    final m = tuples.length; // 24
    return [
      for (var i = 0; i < m; i++)
        {
          'fa': tuples[i].f,
          'ea': tuples[i].e,
          'oa': tuples[i].o,
          'ka': tuples[i].k,
          'ja': tuples[i].j,
          'fb': tuples[(i * 5 + 3) % m].f,
          'eb': tuples[(i * 5 + 3) % m].e,
          'ob': tuples[(i * 5 + 3) % m].o,
          'kb': tuples[(i * 5 + 3) % m].k,
          'jb': tuples[(i * 5 + 3) % m].j,
        },
    ];
  }
  if (id == 'puedo') {
    const cols = ['rojo', 'azul', 'amarillo', 'verde'];
    const es = ['1', '2', '3'];
    const ords = ['sm', 'ms'];
    const sides = ['toalla_a', 'toalla_b'];
    final tuples = <({String d, String e, String o, String k, String j})>[
      for (final d in cols)
        for (final e in es)
          for (final o in ords)
            for (final k in sides)
              (
                d: d,
                e: e,
                o: o,
                k: k,
                j: k == 'toalla_a' ? 'toalla_b' : 'toalla_a',
              ),
    ];
    final m = tuples.length; // 48
    return [
      for (var i = 0; i < m; i++)
        {
          'da': tuples[i].d,
          'ea': tuples[i].e,
          'oa': tuples[i].o,
          'ka': tuples[i].k,
          'ja': tuples[i].j,
          'db': tuples[(i * 7 + 5) % m].d,
          'eb': tuples[(i * 7 + 5) % m].e,
          'ob': tuples[(i * 7 + 5) % m].o,
          'kb': tuples[(i * 7 + 5) % m].k,
          'jb': tuples[(i * 7 + 5) % m].j,
        },
    ];
  }
  return orillaDrawsOf(story);
}

class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

Future<Map<String, dynamic>> playOrilla(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  OrillaRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = OrillaRules(s)..wrap();
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

Future<List<int>> orillaDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playOrilla(
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

Future<List<Map<String, dynamic>>> playOrillaSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<({Map<String, String> d, String pat})> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File('${root.path}/docs/proyecto/pixel/orilla-sheet.json')
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
        await loadSheet('orilla', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['orilla']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playOrilla(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
          );
          out.add(orillaSummary(id, j.d, j.pat, t));
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

Map<String, dynamic> orillaSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as OrillaRules;
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
