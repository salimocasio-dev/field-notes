// El calendario's paths: every reachable combination of each story's random draws, the letters of the plan that play
// its two decisions one way or the other, and worker-isolate parallel runner with CalendarioRules checked at every act.
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

import 'calendario_rules.dart';
import 'mostrador_paths.dart' show letterPlan;

export 'mostrador_paths.dart' show letterPlan;

const List<String> calendarioStories = [
  'el-lunes-hay-frutas',
  'el-fin-de-semana',
  'hoy-y-manana',
];

/// Every reachable combination of a calendario story's random draws.
List<Map<String, String>> calendarioDrawsOf(Map<String, dynamic> story) {
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

/// For `hoy-y-manana` (320 Round A × 80 Round B = 25,600 draws), returns a 320-draw subset covering 100% of all 320
/// Round A tuples `(sa, ta, ea, oa, ha)` AND 100% of all 320 Round B tuples `(sa, tb, eb, ob, hb)`.
/// For stories 69 (256 draws) and 70 (256 draws), returns all draws unchanged.
List<Map<String, String>> calendarioRoundCoverDraws(
  Map<String, dynamic> story,
) {
  if (story['id'] != 'hoy-y-manana') return calendarioDrawsOf(story);
  const days = ['1', '2', '3', '4'];
  const cards = ['cafe', 'flores', 'pan', 'pollo', 'jugo'];
  const es = ['1', '2', '3', '4'];
  const ords = ['hm', 'mh'];
  const hs = ['hoy', 'manana'];
  final perDay = <({String t, String e, String o, String h})>[
    for (final t in cards)
      for (final e in es)
        for (final o in ords)
          for (final h in hs) (t: t, e: e, o: o, h: h),
  ];
  final m = perDay.length; // 80
  return [
    for (final sa in days)
      for (var i = 0; i < m; i++)
        {
          'sa': sa,
          'ta': perDay[i].t,
          'ea': perDay[i].e,
          'oa': perDay[i].o,
          'ha': perDay[i].h,
          'tb': perDay[(i * 7 + 5) % m].t,
          'eb': perDay[(i * 7 + 5) % m].e,
          'ob': perDay[(i * 7 + 5) % m].o,
          'hb': perDay[(i * 7 + 5) % m].h,
        },
  ];
}

class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

Future<Map<String, dynamic>> playCalendario(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  CalendarioRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = CalendarioRules(s)..wrap();
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

Future<List<int>> calendarioDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playCalendario(
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

Future<List<Map<String, dynamic>>> playCalendarioSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<({Map<String, String> d, String pat})> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/docs/proyecto/pixel/calendario-sheet.json',
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
        await loadSheet('calendario', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['calendario']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playCalendario(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
          );
          out.add(calendarioSummary(id, j.d, j.pat, t));
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

Map<String, dynamic> calendarioSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as CalendarioRules;
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
