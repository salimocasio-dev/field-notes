// El quiosco's paths: every reachable combination of each story's random draws, the letters of the plan that play its
// two decisions one way or the other, and worker-isolate parallel runner with QuioscoRules checked at every act's end.
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
import 'quiosco_rules.dart';

export 'mostrador_paths.dart' show letterPlan;

const List<String> quioscoStories = [
  'un-cafe-para-la-maestra',
  'en-que-trabajas',
  'cuantos-anos-tienes',
];

/// Every reachable combination of a quiosco story's random draws, evaluating `calc` and `if: "var=val"` branches.
List<Map<String, String>> quioscoDrawsOf(Map<String, dynamic> story) {
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
    if (v['calc'] is String && v['cond'] is String) {
      final name = v['calc'] as String;
      final cond = v['cond'] as String;
      final eq = cond.indexOf('=');
      if (eq > 0) {
        final k = cond.substring(0, eq), val = cond.substring(eq + 1);
        if (!cur.any((x) => x.containsKey(k))) return cur;
        String eval(Map<String, String> x, Object? expr) {
          final s = '$expr';
          return s.startsWith(r'$') ? (x[s.substring(1)] ?? s) : s;
        }

        return [
          for (final x in cur)
            {...x, name: eval(x, x[k] == val ? v['then'] : v['else'])},
        ];
      }
      return cur;
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

  // Strip derived calc variables so only actual draw variables remain in the returned map
  final drawKeys = <String>{};
  void findDraws(Object? v) {
    if (v is List) {
      v.forEach(findDraws);
    } else if (v is Map) {
      if (v['draw'] is String) drawKeys.add(v['draw'] as String);
      v.values.forEach(findDraws);
    }
  }

  findDraws([story['beats'], story['final']]);
  final raw = walk([story['beats'], story['final']], [{}]);
  return [
    for (final m in raw)
      {
        for (final k in drawKeys)
          if (m.containsKey(k)) k: m[k]!,
      },
  ];
}

/// For `cuantos-anos-tienes` (456 Round A × 456 Round B = 207,936 draws), returns a minimal subset (456 draws) that
/// covers 100% of reachable Round A tuples `(ea, ha, ta, oa)` and 100% of reachable Round B tuples `(eb, hb, tb, ob)`.
/// For stories 66 (144 draws) and 67 (192 draws), returns all draws unchanged.
List<Map<String, String>> quioscoRoundCoverDraws(Map<String, dynamic> story) {
  if (story['id'] != 'cuantos-anos-tienes') return quioscoDrawsOf(story);
  // Build all 456 reachable single-round tuples directly without materializing 207,936 pairs
  final ages = [for (var i = 5; i <= 12; i++) '$i'];
  const sibs = ['2', '3', '4'];
  const ords = ['ed', 'he'];
  List<String> thirds(String ev, String hv) {
    final no = <String>{
      ev,
      hv,
      if (ev == '6') '7',
      if (ev == '7') '6',
      if (ev == '11') '12',
      if (ev == '12') '11',
    };
    return [
      for (var i = 1; i <= 12; i++)
        if (!no.contains('$i')) '$i',
    ];
  }

  final roundTuples = <({String e, String h, String t, String o})>[
    for (final e in ages)
      for (final h in sibs)
        for (final t in thirds(e, h))
          for (final o in ords) (e: e, h: h, t: t, o: o),
  ];
  final n = roundTuples.length;
  return [
    for (var i = 0; i < n; i++)
      {
        'ea': roundTuples[i].e,
        'ha': roundTuples[i].h,
        'ta': roundTuples[i].t,
        'oa': roundTuples[i].o,
        'eb': roundTuples[(i * 7 + 3) % n].e,
        'hb': roundTuples[(i * 7 + 3) % n].h,
        'tb': roundTuples[(i * 7 + 3) % n].t,
        'ob': roundTuples[(i * 7 + 3) % n].o,
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

Future<Map<String, dynamic>> playQuiosco(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  QuioscoRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = QuioscoRules(s)..wrap();
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

Future<List<int>> quioscoDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playQuiosco(
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

Future<List<Map<String, dynamic>>> playQuioscoSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<({Map<String, String> d, String pat})> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File('${root.path}/docs/proyecto/pixel/quiosco-sheet.json')
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
        await loadSheet('quiosco', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['quiosco']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playQuiosco(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
          );
          out.add(quioscoSummary(id, j.d, j.pat, t));
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

Map<String, dynamic> quioscoSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as QuioscoRules;
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
